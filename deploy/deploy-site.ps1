# 
<#
.SYNOPSIS
    Deploys a site in the DocusaurOps infrastructure

.DESCRIPTION
    Deploy a site in the DocusaurOps infrastructure, including resource group, virtual network, app service plan, key vault, and site web app. The script uses Bicep templates for deployment and can be executed from a local machine or CI environment.

.NOTES
    Version:        1.0
    Author:         Franck Cornu - Microsoft 365 Solution Architect
    Creation Date:  17/09/2025
    Purpose/Change: Initial script development

.EXAMPLE

    Deploy a site named "MyApp" with path "myapp" in local environment with manual login:
    > deploy-site.ps1 -Env LOCAL -AppName "MyApp" -AppPath "myapp" -Manual

#>
[CmdletBinding()]
Param (

    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('LOCAL','CI')]
    [string]$Env,

    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [string]$AppName,

    [Parameter(Mandatory = $False)]
    [string]$AppPath,

    [Parameter(Mandatory = $False)]
    [switch]$Manual,

    [Parameter(Mandatory = $False)]
    [bool]$EnableAuthentication = $true
)

. $PSScriptRoot/scripts/Login-Azure.ps1

$ErrorActionPreference = "Stop"

Write-Verbose "`tInitializing variables..."

# Load correct variables according to the targeted environnement
switch ($Env) {
    'CI' {
        . $PSScriptRoot/variables.ci.ps1
        Write-Verbose "Variables from CI have been loaded..."
    }

    'LOCAL' {
        . $PSScriptRoot/variables.local.ps1
        Write-Verbose "Variables from local have been loaded..."
    }
}

# Normalize AppName to comply with deployment stack name regex '^[-\w\._\(\)]+$'
# e.g. " My super site" -> "my-super-site"
$AppName = $AppName.Trim().ToLower()
$AppName = $AppName -replace '[\s]+', '-'       # spaces to hyphens
$AppName = $AppName -replace '[^\w\-\.\(\)]', '' # strip remaining invalid chars
$AppName = $AppName -replace '-{2,}', '-'        # collapse consecutive hyphens
$AppName = $AppName.Trim('-')                    # trim leading/trailing hyphens
if ([string]::IsNullOrEmpty($AppName)) {
    throw "AppName is empty after normalization. It must contain at least one valid character matching '^[-\w\._\(\)]+$'."
}
Write-Verbose "Normalized AppName for Web App name: '$AppName'"

#region ----------------------------------------------------------[Azure resources deployment]---------------------------------------------------------
Import-Module Az.Accounts -Verbose:$false
Import-Module Az.Resources -Verbose:$false
Import-Module Az.Network -Verbose:$false
Import-Module Az.Websites -Verbose:$false

Login-Azure -Manual:$Manual

try {

    $gatewayIpDomain = $null

    $templateTemplateFilePath = Join-Path -Path $PSScriptRoot -ChildPath "./templates/site/add-site.bicep"

    # Add current user
    if ($Manual.IsPresent) {
        $rbacPrincipalsList += @{
            principalId = (az ad signed-in-user show --query id -o tsv)
            principalType = "User"
        }
    }

    #region Replace tokens in Bicep params template for new site
    Write-Verbose "Replacing tokens in Bicep params template...#"

    $ENV_AZURE_DEPLOY_STACK_ENV_NAME = "docusaurops-$ENV_AZURE_ENV_NAME"

    $Tokens = @{
        ENV_AZURE_ENV_NAME = $ENV_AZURE_ENV_NAME
        ENV_AZURE_DEPLOY_LOCATION = $ENV_AZURE_DEPLOY_LOCATION
        ENV_AZURE_DEPLOY_RESOURCE_PREFIX = "docusaurops"
        ENV_AZURE_DEPLOY_STACK_RG_NAME = "rg-$ENV_AZURE_DEPLOY_STACK_ENV_NAME"
        APP_NAME = $AppName
        APP_PATH = $AppPath
        ENV_AZURE_DOCUSAUROPS_ENTRA_ID_CLIENT_ID = if ($EnableAuthentication) { $ENV_AZURE_DOCUSAUROPS_ENTRA_ID_CLIENT_ID } else { "" }
        ENV_SITE_ENABLE_AUTHENTICATION = $EnableAuthentication.ToString().ToLower()
    }
                
    $inputFilePath = Join-Path -Path $PSScriptRoot -ChildPath "./parameters/site.bicepparam.template"
    $outputFilePath = Join-Path -Path $PSScriptRoot -ChildPath "./parameters/site.bicepparam"
    
    & $PSScriptRoot/scripts/Replace-Tokens.ps1 `
        -InputFile $inputFilePath `
        -OutputFile $outputFilePath `
        -Tokens $Tokens `
        -StartTokenPattern "{{" `
        -EndTokenPattern "}}"

    #endregion
    
    #region Provision new site
    try {

        # Need to install Bicep manually with PowerShell https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#install-manually
        $res = New-AzSubscriptionDeploymentStack `
            -Name "$ENV_AZURE_DEPLOY_STACK_ENV_NAME-$( if (-not [string]::IsNullOrEmpty($AppPath)) { $AppPath } else { $AppName } )" `
            -Location $ENV_AZURE_DEPLOY_LOCATION `
            -TemplateFile $templateTemplateFilePath `
            -TemplateParameterFile $outputFilePath `
            -ActionOnUnmanage DeleteResources `
            -DenySettingsMode "none" `
            -Verbose `
            -Force `
    
    } catch {
        Write-Error "Deployment stack provisioning failed: $($_.Exception.Message)"
        throw
    }
    #endregion

    #region Add EasyAuth redirect URI to Entra ID app registration
    if ($EnableAuthentication -and -not [string]::IsNullOrEmpty($ENV_AZURE_DOCUSAUROPS_ENTRA_ID_CLIENT_ID)) {
        try {
            $callbackPath = if (-not [string]::IsNullOrEmpty($AppPath) -and $AppPath -ne "/") { "/$AppPath/.auth/login/aad/callback" } else { "/.auth/login/aad/callback" }
            $newRedirectUri = "https://$ENV_AZURE_DOCUSAUROPS_DOMAIN$callbackPath"

            Write-Verbose "Adding redirect URI '$newRedirectUri' to Entra ID app '$ENV_AZURE_DOCUSAUROPS_ENTRA_ID_CLIENT_ID'..."

            $app = az ad app show --id $ENV_AZURE_DOCUSAUROPS_ENTRA_ID_CLIENT_ID | ConvertFrom-Json
            $existingUris = @($app.web.redirectUris)

            if ($existingUris -contains $newRedirectUri) {
                Write-Verbose "Redirect URI already exists. Skipping."
            } else {
                $allUris = @(@($existingUris) + @($newRedirectUri) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
                az ad app update --id $ENV_AZURE_DOCUSAUROPS_ENTRA_ID_CLIENT_ID --web-redirect-uris @allUris
                Write-Verbose "Redirect URI added successfully."
            }
        } catch {
            Write-Warning "Failed to update Entra ID app redirect URIs: $($_.Exception.Message)"
        }
    }
    #endregion

    #region Configure Application Gateway for new site
    try {

        $AppPath = if (-not [string]::IsNullOrEmpty($AppPath) -and $AppPath -ne "/") { $AppPath } else { $AppName }

        Write-Verbose "Configuring Application Gateway for new site '$AppPath'..."
        
        $rgName = $ENV_AZURE_DEPLOY_STACK_RG_NAME
        $gwName = $res.outputs.appGatewayName.Value
        $siteFqdn = $res.outputs.siteDefaultHostname.Value
        $pathRulePath = "/$AppPath*"
        
        Write-Verbose "Resource Group: $rgName"
        Write-Verbose "Gateway Name: $gwName"
        Write-Verbose "Site FQDN: $siteFqdn"
        
        # Get the Application Gateway
        $gw = Get-AzApplicationGateway -ResourceGroupName $rgName -Name $gwName

        # Resolve gateway host for downstream jobs: prefer private IP, else public IP DNS domain
        $privateFrontendIp = $gw.FrontendIpConfigurations |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_.PrivateIpAddress) } |
            Select-Object -First 1

        if ($privateFrontendIp) {
            $gatewayIpDomain = $privateFrontendIp.PrivateIpAddress
            Write-Verbose "Gateway private IP detected: $gatewayIpDomain"
        } else {
            $publicIpRef = $gw.FrontendIpConfigurations |
                Where-Object { $null -ne $_.PublicIPAddress -and -not [string]::IsNullOrWhiteSpace($_.PublicIPAddress.Id) } |
                Select-Object -First 1

            if ($publicIpRef) {
                $publicIpName = Split-Path -Path $publicIpRef.PublicIPAddress.Id -Leaf
                $publicIp = Get-AzPublicIpAddress -ResourceGroupName $rgName -Name $publicIpName
                $gatewayIpDomain = $publicIp.DnsSettings.Fqdn

                if (-not [string]::IsNullOrWhiteSpace($gatewayIpDomain)) {
                    Write-Verbose "Gateway public IP DNS detected: $gatewayIpDomain"
                } else {
                    Write-Warning "Public IP '$publicIpName' has no DNS domain configured."
                }
            } else {
                Write-Warning "No public IP reference found on Application Gateway frontend IP configurations."
            }
        }
        
        # Check existing resources once
        $existingPool = $gw.BackendAddressPools | Where-Object Name -eq $AppPath
        $existingRule = $gw.UrlPathMaps[0].PathRules | Where-Object Name -eq $AppPath
        $gatewayNeedsUpdate = $false
        
        # Add backend pool if missing
        if (-not $existingPool) {
            Write-Verbose "Adding backend pool '$AppPath' with FQDN '$siteFqdn'..."
            $gw = Add-AzApplicationGatewayBackendAddressPool -ApplicationGateway $gw -Name $AppPath -BackendFqdns $siteFqdn
            $gatewayNeedsUpdate = $true
        } elseif ($existingPool.BackendAddresses.Count -eq 0) {
            Write-Verbose "Backend pool '$AppPath' exists but has no addresses. Updating with FQDN '$siteFqdn'..."
            $gw = Set-AzApplicationGatewayBackendAddressPool -ApplicationGateway $gw -Name $AppPath -BackendFqdns $siteFqdn
            $gatewayNeedsUpdate = $true
        }
                    
        # Add path rule if missing (backend pool must exist at this point)
        if (-not $existingRule) {
            $backendPool = $gw.BackendAddressPools | Where-Object Name -eq $AppPath
            $backendHttpSettings = $gw.BackendHttpSettingsCollection | Where-Object Name -eq "defaultbackendsetting"
            
            Write-Verbose "Adding URL path rule '$AppPath' with path '$pathRulePath'..."
            $pathRule = New-AzApplicationGatewayPathRuleConfig -Name $AppPath -Paths $pathRulePath `
                -BackendAddressPool $backendPool -BackendHttpSettings $backendHttpSettings
            $gw.UrlPathMaps[0].PathRules.Add($pathRule)
            $gatewayNeedsUpdate = $true
        }
        
        if ($gatewayNeedsUpdate) {
            Write-Verbose "Updating Application Gateway '$gwName'..."
            $gw = Set-AzApplicationGateway -ApplicationGateway $gw
            Write-Verbose "Application Gateway configuration complete."
        } else {
            Write-Verbose "Application Gateway '$gwName' is already up to date. No changes needed."
        }
        
    } catch {
        Write-Error "Application Gateway configuration failed: $($_.Exception.Message)"
        throw
    }
    #endregion

    #region Update root site sitemap (ENV_SITE_URLS app setting)
    if (-not [string]::IsNullOrEmpty($ENV_AZURE_DOCUSAUROPS_ROOT_WEBAPP_NAME) -and -not [string]::IsNullOrEmpty($ENV_AZURE_DOCUSAUROPS_DOMAIN)) {
        try {
            $newSiteUrl = "https://$ENV_AZURE_DOCUSAUROPS_DOMAIN/$AppPath"
            Write-Verbose "Registering site URL '$newSiteUrl' in root app service '$ENV_AZURE_DOCUSAUROPS_ROOT_WEBAPP_NAME'..."

            $currentSettings = az webapp config appsettings list `
                --name $ENV_AZURE_DOCUSAUROPS_ROOT_WEBAPP_NAME `
                --resource-group $ENV_AZURE_DEPLOY_STACK_RG_NAME | ConvertFrom-Json

            $currentUrls = ($currentSettings | Where-Object name -eq 'ENV_SITE_URLS').value
            $urlList = @($currentUrls -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })

            if ($urlList -contains $newSiteUrl) {
                Write-Verbose "URL '$newSiteUrl' already in ENV_SITE_URLS. Skipping."
            } else {
                $urlList += $newSiteUrl
                $updatedUrls = $urlList -join ','

                az webapp config appsettings set `
                    --name $ENV_AZURE_DOCUSAUROPS_ROOT_WEBAPP_NAME `
                    --resource-group $ENV_AZURE_DEPLOY_STACK_RG_NAME `
                    --settings "ENV_SITE_URLS=$updatedUrls" | Out-Null

                Write-Verbose "ENV_SITE_URLS updated to: $updatedUrls"
            }
        } catch {
            Write-Warning "Failed to update root site ENV_SITE_URLS: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Skipping root site ENV_SITE_URLS update because ENV_AZURE_DOCUSAUROPS_ROOT_WEBAPP_NAME or ENV_AZURE_DOCUSAUROPS_DOMAIN is not set."
    }
    #endregion

    Write-Output "Deployment done!"

    # If CI, output variable for other job/stages
    if ($Env -eq 'CI') {
        $env:ENV_AZURE_DEPLOY_WEBAPP_NAME = $res.outputs.siteResourceName.Value
        Write-Verbose "Output variable 'ENV_AZURE_DEPLOY_WEBAPP_NAME=https://$($res.outputs.siteResourceName.Value)' for subsequent stages.."

        if (-not [string]::IsNullOrWhiteSpace($gatewayIpDomain)) {
            $env:ENV_AZURE_DOCUSAUROPS_SITE_URL = "https://$gatewayIpDomain"
            Write-Verbose "Output variable 'ENV_AZURE_DOCUSAUROPS_SITE_URL=$($env:ENV_AZURE_DOCUSAUROPS_SITE_URL)' for subsequent stages.."
        } else {
            Write-Warning "ENV_AZURE_DOCUSAUROPS_SITE_URL was not set because no gateway IP domain could be resolved."
        }
    }

} catch {
    Write-Error "Deployment error ... $($_.Exception.Message)"
    exit 1
}

exit 0
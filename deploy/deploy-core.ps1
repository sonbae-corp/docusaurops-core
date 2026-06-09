# 
<#
.SYNOPSIS
    Deploys the Azure infrastructure for DocusaurOps solution

.DESCRIPTION
    Deploy the core Azure infrastructure for DocusaurOps, including resource group, virtual network, app service plan, key vault, and root site web app. The script uses Bicep templates for deployment and can be executed from a local machine or CI environment.

.NOTES
    Version:        1.0
    Author:         Franck Cornu - Microsoft 365 Solution Architect
    Creation Date:  06/07/2026
    Purpose/Change: Initial script development

.EXAMPLE

    Deploy infrastructure with interactive login (will prompt for Azure credentials):
    > deploy-core.ps1 
#>

[CmdletBinding()]
Param (
    
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('LOCAL','CI')]
    [string]$Env,

    [switch]$Manual
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


#region ----------------------------------------------------------[Azure resources deployment]---------------------------------------------------------
Import-Module Az.Accounts -Verbose:$false
Import-Module Az.Resources -Verbose:$false
Import-Module Az.Network -Verbose:$false
Import-Module Az.Websites -Verbose:$false
Import-Module Az.KeyVault -Verbose:$false

Login-Azure -Manual:$Manual

try {

    $templateTemplateFilePath = Join-Path -Path $PSScriptRoot -ChildPath "./templates/core/main.bicep"

    $rbacPrincipalsList = $ENV_AZURE_DEPLOY_STACK_RBAC_PRINCIPALS

    #region Fetch existing Application Gateway configuration to preserve site-specific settings
    $additionalBackendAddressPools = @()
    $additionalPathRules = @()
    $additionalBackendHttpSettings = @()
    $additionalProbes = @()

    $existingGateway = Get-AzApplicationGateway -ResourceGroupName $ENV_AZURE_DEPLOY_STACK_RG_NAME -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($existingGateway) {

        Write-Verbose "Existing Application Gateway '$($existingGateway.Name)' found. Preserving site-specific configurations..."

        # Collect backend pools added by sites (exclude the root pool)
        $additionalBackendAddressPools = @($existingGateway.BackendAddressPools |
            Where-Object { $_.Name -ne 'root' } |
            ForEach-Object {
                @{
                    name = $_.Name
                    properties = @{
                        backendAddresses = @($_.BackendAddresses | ForEach-Object {
                            $addr = @{}
                            if ($_.Fqdn) { $addr.fqdn = $_.Fqdn }
                            if ($_.IpAddress) { $addr.ipAddress = $_.IpAddress }
                            $addr
                        })
                    }
                }
            })

        # Collect path rules added by sites (exclude the root catch-all rule)
        $urlPathMap = $existingGateway.UrlPathMaps | Select-Object -First 1
        if ($urlPathMap) {
            $additionalPathRules = @($urlPathMap.PathRules |
                Where-Object { $_.Name -ne 'root' } |
                ForEach-Object {
                    @{
                        name = $_.Name
                        properties = @{
                            paths = @($_.Paths)
                            backendAddressPool = @{ id = $_.BackendAddressPool.Id }
                            backendHttpSettings = @{ id = $_.BackendHttpSettings.Id }
                        }
                    }
                })
        }

        # Collect backend HTTP settings added by sites (exclude the default setting)
        $additionalBackendHttpSettings = @($existingGateway.BackendHttpSettingsCollection |
            Where-Object { $_.Name -ne 'defaultbackendsetting' } |
            ForEach-Object {
                $setting = @{
                    name = $_.Name
                    properties = @{
                        port = $_.Port
                        protocol = $_.Protocol
                        cookieBasedAffinity = $_.CookieBasedAffinity
                        pickHostNameFromBackendAddress = $_.PickHostNameFromBackendAddress
                        requestTimeout = $_.RequestTimeout
                    }
                }
                if ($_.AffinityCookieName) {
                    $setting.properties.affinityCookieName = $_.AffinityCookieName
                }
                if ($_.Probe -and $_.Probe.Id) {
                    $setting.properties.probe = @{ id = $_.Probe.Id }
                }
                $setting
            })

        # Collect probes added by sites (exclude the default probe)
        $additionalProbes = @($existingGateway.Probes |
            Where-Object { $_.Name -ne 'azurewebsitesprobe' } |
            ForEach-Object {
                $probe = @{
                    name = $_.Name
                    properties = @{
                        protocol = $_.Protocol
                        path = $_.Path
                        interval = $_.Interval
                        timeout = $_.Timeout
                        unhealthyThreshold = $_.UnhealthyThreshold
                        pickHostNameFromBackendHttpSettings = $_.PickHostNameFromBackendHttpSettings
                    }
                }
                if ($_.Match -and $_.Match.StatusCodes) {
                    $probe.properties.match = @{ statusCodes = @($_.Match.StatusCodes) }
                }
                $probe
            })

        Write-Verbose "  Additional backend pools: $($additionalBackendAddressPools.Count)"
        $additionalBackendAddressPools | ForEach-Object { Write-Verbose "    - $($_.name)" }
        Write-Verbose "  Additional path rules: $($additionalPathRules.Count)"
        $additionalPathRules | ForEach-Object { Write-Verbose "    - $($_.name) -> $($_.properties.paths -join ', ')" }
        Write-Verbose "  Additional backend HTTP settings: $($additionalBackendHttpSettings.Count)"
        $additionalBackendHttpSettings | ForEach-Object { Write-Verbose "    - $($_.name) ($($_.properties.protocol):$($_.properties.port))" }
        Write-Verbose "  Additional probes: $($additionalProbes.Count)"
        $additionalProbes | ForEach-Object { Write-Verbose "    - $($_.name) ($($_.properties.protocol) $($_.properties.path))" }

    } else {
        Write-Verbose "No existing Application Gateway found. Deploying with default configuration."
    }
    #endregion

    #region generate PFX certificate file from secrets


    #endregion

    try {

        $templateParameterObject = @{
            environmentName = $ENV_AZURE_ENV_NAME
            location = $ENV_AZURE_DEPLOY_LOCATION
            resourcePrefix = $ENV_AZURE_DEPLOY_RESOURCE_PREFIX
            rgName = $ENV_AZURE_DEPLOY_STACK_RG_NAME
            rbacPrincipalsList = $rbacPrincipalsList
            rootSiteName = 'root'
            sslCertificatePassword = $ENV_AZURE_DOCUSAUROPS_CERT_PASSWORD
            sslCertificateData = $ENV_AZURE_DOCUSAUROPS_CERT_BASE64_PFX
            additionalBackendAddressPools = $additionalBackendAddressPools
            additionalPathRules = $additionalPathRules
            additionalBackendHttpSettings = $additionalBackendHttpSettings
            additionalProbes = $additionalProbes
        }

        # Need to install Bicep manually with PowerShell https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#install-manually
        $res = New-AzSubscriptionDeploymentStack `
            -Name $ENV_AZURE_DEPLOY_STACK_ENV_NAME `
            -Location $ENV_AZURE_DEPLOY_LOCATION `
            -TemplateFile $templateTemplateFilePath `
            -TemplateParameterObject  $templateParameterObject `
            -ActionOnUnmanage DeleteAll `
            -DenySettingsMode "none" `
            -Force `
    
        #region Azure Key Vault

        Write-Verbose "`tUpdated Key Vault Value..."

        $KeyVaultValues = @{
            "MICROSOFTPROVIDERAUTHENTICATIONSECRET" = $ENV_AZURE_DOCUSAUROPS_ENTRA_ID_CLIENT_SECRET;
            "USERMANAGEDIDENTITYCLIENTID" = $res.outputs.userManagedIdentityClientId.Value;
        }

        $KeyVaultValues.Keys | ForEach-Object {

            # Create or update secret
            Write-Information "Creating/Updating Secret '$_'..."
            if ($KeyVaultValues[$_]) {
                Set-AzKeyVaultSecret -VaultName $res.outputs.azureKeyVaultName.Value -Name $_ -SecretValue (ConvertTo-SecureString $KeyVaultValues[$_] -AsPlainText -Force) -ContentType "txt"
            }        
        }   
        #endregion


    } catch {
        Write-Error "Deployment error ... $($_.Exception.Message)"
    }

    Write-Output "Deployment done!"

} catch {
    Write-Error "Deployment error ... $($_.Exception.Message)"
}
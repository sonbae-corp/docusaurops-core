<#
.SYNOPSIS
Initializes plugin files by replacing token placeholders.

.DESCRIPTION
Finds all .md and .json files under the plugins folder and replaces tokens
using deploy/scripts/Replace-Tokens.ps1.

.PARAMETER Tokens
Hashtable of token names and values to replace, e.g.:
@{
  ENV_AZURE_DEPLOY_TENANT_ID = "<tenant-id>"
  ENV_DOCUSAUROPS_HOST_REPO = "<org/repo>"
}

.EXAMPLE
./plugins/init-plugin.ps1 -Tokens @{
  ENV_AZURE_DEPLOY_TENANT_ID = "00000000-0000-0000-0000-000000000000"
  ENV_DOCUSAUROPS_HOST_REPO = "sonbae-corp/docusaurops-core"
} -Verbose
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[ValidateNotNull()]
	[hashtable]$Tokens,

	[Parameter(Mandatory = $false)]
	[string]$StartTokenPattern = "{{",

	[Parameter(Mandatory = $false)]
	[string]$EndTokenPattern = "}}"
)

$ErrorActionPreference = "Stop"

$pluginsRoot = $PSScriptRoot
$replaceTokensScript = Join-Path -Path $PSScriptRoot -ChildPath "../deploy/scripts/Replace-Tokens.ps1"

if (-not (Test-Path -Path $replaceTokensScript -PathType Leaf)) {
	throw "Replace-Tokens script not found at '$replaceTokensScript'."
}

$targetFiles = Get-ChildItem -Path $pluginsRoot -Recurse -File |
	Where-Object { $_.Extension -in @('.template') }

if (-not $targetFiles -or $targetFiles.Count -eq 0) {
	Write-Verbose "No .template files found under '$pluginsRoot'."
	exit 0
}

Write-Verbose "Replacing tokens in $($targetFiles.Count) file(s) under '$pluginsRoot'."

foreach ($file in $targetFiles) {
	$outputFile = $file.FullName -replace '\.template$', ''

	& $replaceTokensScript `
		-InputFile $file.FullName `
		-OutputFile $outputFile `
		-Tokens $Tokens `
		-StartTokenPattern $StartTokenPattern `
		-EndTokenPattern $EndTokenPattern `
		-NoWarning `
		-Verbose:$VerbosePreference

	# Remove the template source after successful token replacement.
	Remove-Item -Path $file.FullName -Force
}

Write-Verbose "Plugin token initialization completed."

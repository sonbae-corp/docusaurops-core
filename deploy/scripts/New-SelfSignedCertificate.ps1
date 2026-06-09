[CmdletBinding()]
param(
    [securestring]$PfxPassword,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Domain,
    [int]$ValidityDays = 365,
    [switch]$InstallRootCA
)

$domain = $Domain.Trim()
$rootCA = $null
$serverCert = $null
$outputPath = Join-Path $PSScriptRoot '..\certificates'

if (-not $PfxPassword) {
    $PfxPassword = Read-Host -Prompt "Enter PFX password" -AsSecureString
}

if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
}

try {
    Write-Host "Creating Root CA certificate..."
    $rootCA = New-SelfSignedCertificate `
        -Subject "CN=DocusaurOps Root CA" `
        -CertStoreLocation 'Cert:\CurrentUser\My' `
        -KeyAlgorithm RSA `
        -KeyLength 4096 `
        -KeyUsage CertSign, CRLSign `
        -KeyExportPolicy Exportable `
        -NotAfter (Get-Date).AddDays($ValidityDays * 2) `
        -FriendlyName "DocusaurOps Root CA" `
        -TextExtension @("2.5.29.19={critical}{text}ca=TRUE")

    Write-Host "Root CA created: $($rootCA.Thumbprint)"

    Write-Host "Creating server certificate for $domain..."
    $serverCert = New-SelfSignedCertificate `
        -DnsName $domain `
        -CertStoreLocation 'Cert:\CurrentUser\My' `
        -KeyAlgorithm RSA `
        -KeyLength 2048 `
        -NotAfter (Get-Date).AddDays($ValidityDays) `
        -FriendlyName "DocusaurOps Server ($domain)" `
        -Signer $rootCA `
        -KeyUsage DigitalSignature, KeyEncipherment `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1")

    Write-Host "Server cert created: $($serverCert.Thumbprint)"

    $pfxCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
    $null = $pfxCollection.Add($serverCert)

    # Add the root cert without private key so the resulting PFX has exactly one private key.
    $rootCaPublicBytes = $rootCA.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    $rootCaPublicOnly = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @(, $rootCaPublicBytes)
    $null = $pfxCollection.Add($rootCaPublicOnly)

    $pfxPasswordBstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($PfxPassword)
    try {
        $pfxPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pfxPasswordBstr)
        $pfxBytes = $pfxCollection.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $pfxPasswordPlain)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pfxPasswordBstr)
    }

    $pfxBase64 = [Convert]::ToBase64String($pfxBytes)
    Write-Host "Server PFX (with chain) generated as Base64."
    try {
        Set-Clipboard -Value $pfxBase64
        Write-Host "Server PFX Base64 copied to clipboard."
    } catch {
        Write-Warning "Could not copy Server PFX Base64 to clipboard automatically."
    }

    $cerPath = Join-Path $outputPath 'docusaurops-rootca.cer'
    Export-Certificate `
        -Cert "Cert:\CurrentUser\My\$($rootCA.Thumbprint)" `
        -FilePath $cerPath | Out-Null

    Write-Host "Root CA CER exported to: $cerPath"

    if ($InstallRootCA) {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        if ($isAdmin) {
            Import-Certificate -FilePath $cerPath -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null
            Write-Host "Root CA installed in Local Machine Trusted Root CA store."
        } else {
            Write-Warning "Installing to Local Machine store requires Administrator. Installing to Current User store instead."
            Import-Certificate -FilePath $cerPath -CertStoreLocation 'Cert:\CurrentUser\Root' | Out-Null
            Write-Host "Root CA installed in Current User Trusted Root CA store."
        }
    }

    Write-Host ""
    Write-Host "===== Summary ====="
    Write-Host "  Domain:          $domain"
    Write-Host "  Server PFX Base64 length: $($pfxBase64.Length)"
    Write-Host "  Root CA CER:     $cerPath"
    Write-Host "  Server thumbprint: $($serverCert.Thumbprint)"
    Write-Host "  Root CA thumbprint: $($rootCA.Thumbprint)"
    Write-Host ""

    if (-not $InstallRootCA) {
        Write-Host "===== Next Steps ====="
        Write-Host "  To trust this cert in Edge, install the Root CA:"
        Write-Host ""
        Write-Host "  Option A (Administrator PowerShell):"
        Write-Host "    Import-Certificate -FilePath '$cerPath' -CertStoreLocation 'Cert:\LocalMachine\Root'"
        Write-Host ""
        Write-Host "  Option B (Current User only):"
        Write-Host "    Import-Certificate -FilePath '$cerPath' -CertStoreLocation 'Cert:\CurrentUser\Root'"
        Write-Host ""
        Write-Host "  Option C (GUI):"
        Write-Host "    Double-click '$cerPath' > Install Certificate > Local Machine > Trusted Root Certification Authorities"
        Write-Host ""
    }

    [pscustomobject]@{
        Domain = $domain
        ServerPfxBase64 = $pfxBase64
        RootCaCerPath = $cerPath
        ServerThumbprint = $serverCert.Thumbprint
        RootCaThumbprint = $rootCA.Thumbprint
    }
} finally {
    if ($serverCert) {
        Remove-Item "Cert:\CurrentUser\My\$($serverCert.Thumbprint)" -Force -ErrorAction SilentlyContinue
    }

    if ($rootCA) {
        Remove-Item "Cert:\CurrentUser\My\$($rootCA.Thumbprint)" -Force -ErrorAction SilentlyContinue
    }

    if ($serverCert -or $rootCA) {
        Write-Host "Cleaned up certificates from Personal store."
    }
}
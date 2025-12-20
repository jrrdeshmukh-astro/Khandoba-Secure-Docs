# ==============================================================================
# Windows Upload to Store Script
# ==============================================================================
# Uploads MSIX package to Microsoft Partner Center
# Usage: .\upload_to_store.ps1 [msix_file]
# ==============================================================================

param(
    [string]$MsixFile = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$BuildDir = Join-Path $ProjectRoot "builds\windows"

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  📤 UPLOAD TO MICROSOFT STORE" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

# Find latest MSIX if not provided
if ([string]::IsNullOrEmpty($MsixFile)) {
    $MsixFiles = Get-ChildItem -Path "$BuildDir\packages" -Filter "*.msix" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($MsixFiles) {
        $MsixFile = $MsixFiles[0].FullName
    }
}

if ([string]::IsNullOrEmpty($MsixFile) -or -not (Test-Path $MsixFile)) {
    Write-Host "❌ MSIX file not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please create package first:"
    Write-Host "  .\create_installer.ps1"
    Write-Host ""
    Write-Host "Or specify MSIX file:"
    Write-Host "  .\upload_to_store.ps1 -MsixFile path\to\app.msix"
    exit 1
}

Write-Host "📦 MSIX File: $MsixFile" -ForegroundColor Green
Write-Host ""

# Check if Partner Center API is configured
$PartnerCenterApiKey = $env:PARTNER_CENTER_API_KEY
if ([string]::IsNullOrEmpty($PartnerCenterApiKey)) {
    Write-Host "📋 Manual Upload Instructions:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Go to Microsoft Partner Center:"
    Write-Host "   https://partner.microsoft.com/dashboard"
    Write-Host ""
    Write-Host "2. Select your app (Khandoba Secure Docs)"
    Write-Host ""
    Write-Host "3. Go to: Submissions → New submission"
    Write-Host ""
    Write-Host "4. Upload MSIX package:"
    Write-Host "   $MsixFile"
    Write-Host ""
    Write-Host "5. Fill in submission details and publish"
    Write-Host ""
    Write-Host "✅ MSIX ready for upload: $MsixFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "For automated upload, set PARTNER_CENTER_API_KEY environment variable"
} else {
    Write-Host "📤 Uploading via Partner Center API..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Note: Partner Center API upload requires:"
    Write-Host "  - Partner Center API credentials"
    Write-Host "  - PartnerCenter PowerShell module"
    Write-Host ""
    Write-Host "Install module with:"
    Write-Host "  Install-Module -Name PartnerCenterModule"
    Write-Host ""
    Write-Host "Then configure credentials and upload"
}

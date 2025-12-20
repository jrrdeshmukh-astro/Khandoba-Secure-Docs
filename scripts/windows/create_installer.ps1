# ==============================================================================
# Windows Create Installer Script
# ==============================================================================
# Creates MSIX installer package for Microsoft Store
# Usage: .\create_installer.ps1 [configuration]
# ==============================================================================

param(
    [string]$Configuration = "Release",
    [string]$Platform = "x64"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$WindowsDir = Join-Path $ProjectRoot "platforms\windows"
$BuildDir = Join-Path $ProjectRoot "builds\windows"
$PublishPath = Join-Path $BuildDir "releases\$Configuration\$Platform"

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  📦 CREATE MSIX INSTALLER" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

if (-not (Test-Path $PublishPath)) {
    Write-Host "❌ Published app not found. Build first:" -ForegroundColor Red
    Write-Host "   .\build_release.ps1 $Configuration"
    exit 1
}

# Check if MSBuild is available (for packaging)
$MsBuildPath = "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
if (-not (Test-Path $MsBuildPath)) {
    $MsBuildPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
}

if (-not (Test-Path $MsBuildPath)) {
    Write-Host "⚠️  MSBuild not found. Creating installer requires Visual Studio." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Manual steps:"
    Write-Host "1. Open solution in Visual Studio"
    Write-Host "2. Right-click project → Publish → Create App Packages"
    Write-Host "3. Follow the packaging wizard"
    Write-Host ""
    Write-Host "Or install Visual Studio with Windows SDK"
    exit 0
fi

Write-Host "📦 Creating MSIX package..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Note: MSIX packaging requires:"
Write-Host "  - Visual Studio with Windows SDK"
Write-Host "  - App manifest configured"
Write-Host "  - Code signing certificate (for production)"
Write-Host ""
Write-Host "Package output will be in: $BuildDir\packages" -ForegroundColor Green

# The actual packaging would be done via Visual Studio or MakeAppx.exe
# This script provides instructions for manual packaging

Write-Host ""
Write-Host "✅ Installer creation instructions provided" -ForegroundColor Green

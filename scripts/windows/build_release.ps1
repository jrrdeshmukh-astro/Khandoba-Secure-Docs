# ==============================================================================
# Windows Build Release Script
# ==============================================================================
# Builds production package for Microsoft Store
# Usage: .\build_release.ps1 [configuration]
# Configurations: Debug | Release (default: Release)
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

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  🪟 WINDOWS PRODUCTION BUILD" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""
Write-Host "📦 Configuration: $Configuration" -ForegroundColor Green
Write-Host "🔧 Platform: $Platform" -ForegroundColor Green
Write-Host "📁 Windows Directory: $WindowsDir"
Write-Host ""

if (-not (Test-Path $WindowsDir)) {
    Write-Host "❌ Windows directory not found: $WindowsDir" -ForegroundColor Red
    exit 1
}

Set-Location $WindowsDir

# Create build directories
New-Item -ItemType Directory -Force -Path "$BuildDir\packages" | Out-Null
New-Item -ItemType Directory -Force -Path "$BuildDir\releases" | Out-Null

# Clean
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
dotnet clean -c $Configuration | Out-Null

# Build
Write-Host ""
Write-Host "🔨 Building Windows app..." -ForegroundColor Yellow
dotnet build -c $Configuration -p:Platform=$Platform --no-incremental

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}

# Publish
Write-Host ""
Write-Host "📦 Publishing Windows app..." -ForegroundColor Yellow
$PublishPath = Join-Path $BuildDir "releases\$Configuration\$Platform"
dotnet publish -c $Configuration -p:Platform=$Platform -o $PublishPath --self-contained false

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Publish failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Build complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Output:" -ForegroundColor Green
Write-Host "   $PublishPath"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Create installer: .\create_installer.ps1"
Write-Host "  2. Create MSIX package for Store"
Write-Host "  3. Or use: .\upload_to_store.ps1"

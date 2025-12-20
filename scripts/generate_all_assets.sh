#!/bin/bash

# Generate All Assets Script
# Generates platform-specific assets from base icon

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS_DIR="$PROJECT_ROOT/assets"
BASE_ICON="$ASSETS_DIR/shared/icons/app-icon-base.png"

echo -e "${GREEN}🎨 Khandoba Secure Docs - Asset Generation${NC}"
echo "=========================================="
echo ""

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${YELLOW}⚠️  ImageMagick not found. Installing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install imagemagick
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install imagemagick
    else
        echo -e "${RED}❌ Please install ImageMagick manually${NC}"
        exit 1
    fi
fi

# Check if base icon exists
if [ ! -f "$BASE_ICON" ]; then
    echo -e "${RED}❌ Base icon not found at: $BASE_ICON${NC}"
    echo -e "${YELLOW}💡 Please create the base icon (1024x1024) first${NC}"
    echo -e "${YELLOW}   Location: assets/shared/icons/app-icon-base.png${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Base icon found${NC}"
echo ""

# Function to create directory if it doesn't exist
create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo -e "${GREEN}📁 Created directory: $1${NC}"
    fi
}

# Generate iOS Icons
echo -e "${GREEN}🍎 Generating iOS icons...${NC}"
IOS_ICONS_DIR="$ASSETS_DIR/apple/Icons/AppIcon.appiconset"
create_dir "$IOS_ICONS_DIR"

# iOS icon sizes
convert "$BASE_ICON" -resize 20x20 "$IOS_ICONS_DIR/icon-20x20@1x.png"
convert "$BASE_ICON" -resize 40x40 "$IOS_ICONS_DIR/icon-20x20@2x.png"
convert "$BASE_ICON" -resize 60x60 "$IOS_ICONS_DIR/icon-20x20@3x.png"

convert "$BASE_ICON" -resize 29x29 "$IOS_ICONS_DIR/icon-29x29@1x.png"
convert "$BASE_ICON" -resize 58x58 "$IOS_ICONS_DIR/icon-29x29@2x.png"
convert "$BASE_ICON" -resize 87x87 "$IOS_ICONS_DIR/icon-29x29@3x.png"

convert "$BASE_ICON" -resize 40x40 "$IOS_ICONS_DIR/icon-40x40@1x.png"
convert "$BASE_ICON" -resize 80x80 "$IOS_ICONS_DIR/icon-40x40@2x.png"
convert "$BASE_ICON" -resize 120x120 "$IOS_ICONS_DIR/icon-40x40@3x.png"

convert "$BASE_ICON" -resize 120x120 "$IOS_ICONS_DIR/icon-60x60@2x.png"
convert "$BASE_ICON" -resize 180x180 "$IOS_ICONS_DIR/icon-60x60@3x.png"

convert "$BASE_ICON" -resize 76x76 "$IOS_ICONS_DIR/icon-76x76@1x.png"
convert "$BASE_ICON" -resize 152x152 "$IOS_ICONS_DIR/icon-76x76@2x.png"

convert "$BASE_ICON" -resize 167x167 "$IOS_ICONS_DIR/icon-83.5x83.5@2x.png"

cp "$BASE_ICON" "$IOS_ICONS_DIR/icon-1024x1024.png"

echo -e "${GREEN}✅ iOS icons generated${NC}"
echo ""

# Generate Android Icons
echo -e "${GREEN}🤖 Generating Android icons...${NC}"

# Create Android icon directories
ANDROID_ICONS_BASE="$ASSETS_DIR/android/Icons"
create_dir "$ANDROID_ICONS_BASE/mipmap-mdpi"
create_dir "$ANDROID_ICONS_BASE/mipmap-hdpi"
create_dir "$ANDROID_ICONS_BASE/mipmap-xhdpi"
create_dir "$ANDROID_ICONS_BASE/mipmap-xxhdpi"
create_dir "$ANDROID_ICONS_BASE/mipmap-xxxhdpi"
create_dir "$ANDROID_ICONS_BASE/adaptive-icon"

# Android icon sizes
convert "$BASE_ICON" -resize 48x48 "$ANDROID_ICONS_BASE/mipmap-mdpi/ic_launcher.png"
convert "$BASE_ICON" -resize 72x72 "$ANDROID_ICONS_BASE/mipmap-hdpi/ic_launcher.png"
convert "$BASE_ICON" -resize 96x96 "$ANDROID_ICONS_BASE/mipmap-xhdpi/ic_launcher.png"
convert "$BASE_ICON" -resize 144x144 "$ANDROID_ICONS_BASE/mipmap-xxhdpi/ic_launcher.png"
convert "$BASE_ICON" -resize 192x192 "$ANDROID_ICONS_BASE/mipmap-xxxhdpi/ic_launcher.png"

# Adaptive icon foreground (centered, 66% safe zone)
convert "$BASE_ICON" -resize 672x672 -gravity center -extent 1024x1024 "$ANDROID_ICONS_BASE/adaptive-icon/ic_launcher_foreground.png"

# Adaptive icon background (solid color - using brand primary)
convert -size 1024x1024 xc:"#E74A48" "$ANDROID_ICONS_BASE/adaptive-icon/ic_launcher_background.png"

echo -e "${GREEN}✅ Android icons generated${NC}"
echo -e "${YELLOW}⚠️  Note: Create adaptive-icon/ic_launcher.xml manually${NC}"
echo ""

# Generate Windows Icons
echo -e "${GREEN}🪟 Generating Windows icons...${NC}"
WINDOWS_ICONS_DIR="$ASSETS_DIR/windows/Icons"
create_dir "$WINDOWS_ICONS_DIR"

convert "$BASE_ICON" -resize 16x16 "$WINDOWS_ICONS_DIR/AppIcon-16x16.png"
convert "$BASE_ICON" -resize 32x32 "$WINDOWS_ICONS_DIR/AppIcon-32x32.png"
convert "$BASE_ICON" -resize 48x48 "$WINDOWS_ICONS_DIR/AppIcon-48x48.png"
convert "$BASE_ICON" -resize 256x256 "$WINDOWS_ICONS_DIR/AppIcon-256x256.png"

echo -e "${GREEN}✅ Windows icons generated${NC}"
echo ""

# Generate Windows Store Assets
echo -e "${GREEN}🪟 Generating Windows Store assets...${NC}"
WINDOWS_STORE_DIR="$ASSETS_DIR/windows/StoreAssets"
create_dir "$WINDOWS_STORE_DIR/StoreLogo"
create_dir "$WINDOWS_STORE_DIR/Square150x150Logo"
create_dir "$WINDOWS_STORE_DIR/Square44x44Logo"
create_dir "$WINDOWS_STORE_DIR/Wide310x150Logo"

convert "$BASE_ICON" -resize 300x300 "$WINDOWS_STORE_DIR/StoreLogo/StoreLogo-300x300.png"
convert "$BASE_ICON" -resize 150x150 "$WINDOWS_STORE_DIR/Square150x150Logo/Square150x150Logo-150x150.png"
convert "$BASE_ICON" -resize 44x44 "$WINDOWS_STORE_DIR/Square44x44Logo/Square44x44Logo-44x44.png"
convert "$BASE_ICON" -resize 310x150 -gravity center -extent 310x150 "$WINDOWS_STORE_DIR/Wide310x150Logo/Wide310x150Logo-310x150.png"

echo -e "${GREEN}✅ Windows Store assets generated${NC}"
echo ""

# Generate Favicons
echo -e "${GREEN}🌐 Generating favicons...${NC}"
FAVICON_DIR="$ASSETS_DIR/shared/branding/favicons"
create_dir "$FAVICON_DIR"

convert "$BASE_ICON" -resize 16x16 "$FAVICON_DIR/favicon-16x16.png"
convert "$BASE_ICON" -resize 32x32 "$FAVICON_DIR/favicon-32x32.png"
convert "$BASE_ICON" -resize 180x180 "$FAVICON_DIR/apple-touch-icon.png"

# Create ICO file (Windows favicon)
convert "$BASE_ICON" -resize 16x16 "$FAVICON_DIR/favicon-16.ico"
convert "$BASE_ICON" -resize 32x32 "$FAVICON_DIR/favicon-32.ico"
convert "$BASE_ICON" -resize 48x48 "$FAVICON_DIR/favicon-48.ico"

echo -e "${GREEN}✅ Favicons generated${NC}"
echo ""

echo -e "${GREEN}🎉 Asset generation complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "1. Review generated icons"
echo "2. Create iOS Contents.json for AppIcon.appiconset"
echo "3. Create Android adaptive-icon/ic_launcher.xml"
echo "4. Add icons to respective platform projects"
echo "5. Create launch screens and splash screens"
echo "6. Capture screenshots for app stores"
echo ""
echo -e "${GREEN}✅ Done!${NC}"


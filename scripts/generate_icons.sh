#!/bin/bash

# Icon Generation Script for Khandoba Secure Docs
# Generates all platform-specific icon sizes from a base image
#
# Usage: ./scripts/generate_icons.sh <base_image_path>
# Example: ./scripts/generate_icons.sh assets/shared/icons/temple-icon-base.png

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo -e "${RED}Error: ImageMagick is not installed.${NC}"
    echo "Install it with: brew install imagemagick (macOS) or apt-get install imagemagick (Linux)"
    exit 1
fi

# Check if base image is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Base image path is required${NC}"
    echo "Usage: $0 <base_image_path>"
    echo "Example: $0 assets/shared/icons/temple-icon-base.png"
    exit 1
fi

BASE_IMAGE="$1"

# Check if base image exists
if [ ! -f "$BASE_IMAGE" ]; then
    echo -e "${RED}Error: Base image not found: $BASE_IMAGE${NC}"
    exit 1
fi

echo -e "${GREEN}🎨 Generating icons from: $BASE_IMAGE${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# iOS Icons
echo -e "${YELLOW}📱 Generating iOS icons...${NC}"
IOS_ICON_DIR="$PROJECT_ROOT/assets/apple/Icons/AppIcon.appiconset"

# iOS icon sizes (in points, @1x, @2x, @3x)
declare -a IOS_SIZES=(
    "20:20:1x"
    "20:20:2x"
    "20:20:3x"
    "29:29:1x"
    "29:29:2x"
    "29:29:3x"
    "40:40:1x"
    "40:40:2x"
    "40:40:3x"
    "60:60:2x"
    "60:60:3x"
    "76:76:1x"
    "76:76:2x"
    "83.5:83.5:2x"
    "1024:1024:1x"
)

for size_info in "${IOS_SIZES[@]}"; do
    IFS=':' read -r width height scale <<< "$size_info"
    
    # Calculate pixel dimensions
    if [[ $scale == "1x" ]]; then
        pixel_width=$width
        pixel_height=$height
    elif [[ $scale == "2x" ]]; then
        pixel_width=$((width * 2))
        pixel_height=$((height * 2))
    elif [[ $scale == "3x" ]]; then
        pixel_width=$((width * 3))
        pixel_height=$((height * 3))
    fi
    
    # Handle decimal sizes (83.5)
    if [[ $width == *.* ]]; then
        pixel_width=$(echo "$width * ${scale/x/}" | bc | cut -d. -f1)
        pixel_height=$(echo "$height * ${scale/x/}" | bc | cut -d. -f1)
    fi
    
    filename="icon-${width}x${height}@${scale}.png"
    if [[ $width == "1024" ]]; then
        filename="icon-1024x1024.png"
    fi
    
    output_path="$IOS_ICON_DIR/$filename"
    
    echo "  Creating: $filename (${pixel_width}x${pixel_height}px)"
    convert "$BASE_IMAGE" -resize "${pixel_width}x${pixel_height}" -unsharp 0x0.5+0.5+0.008 "$output_path"
done

echo -e "${GREEN}✅ iOS icons generated${NC}"
echo ""

# Android Icons
echo -e "${YELLOW}🤖 Generating Android icons...${NC}"

# Android mipmap densities
declare -a ANDROID_DENSITIES=(
    "mdpi:48"
    "hdpi:72"
    "xhdpi:96"
    "xxhdpi:144"
    "xxxhdpi:192"
)

for density_info in "${ANDROID_DENSITIES[@]}"; do
    IFS=':' read -r density size <<< "$density_info"
    ANDROID_ICON_DIR="$PROJECT_ROOT/assets/android/Icons/mipmap-${density}"
    mkdir -p "$ANDROID_ICON_DIR"
    
    output_path="$ANDROID_ICON_DIR/ic_launcher.png"
    
    echo "  Creating: mipmap-${density}/ic_launcher.png (${size}x${size}px)"
    convert "$BASE_IMAGE" -resize "${size}x${size}" -unsharp 0x0.5+0.5+0.008 "$output_path"
done

# Android Adaptive Icon (foreground and background)
echo -e "${YELLOW}  Generating Android adaptive icons...${NC}"
ADAPTIVE_DIR="$PROJECT_ROOT/assets/android/Icons/adaptive-icon"
mkdir -p "$ADAPTIVE_DIR"

# Foreground (icon centered on transparent background, 108dp safe zone)
convert "$BASE_IMAGE" -resize "432x432" -gravity center -background transparent -extent "432x432" "$ADAPTIVE_DIR/ic_launcher_foreground.png"

# Background (solid color from theme - dark teal)
convert -size "432x432" xc:"#2D4A5F" "$ADAPTIVE_DIR/ic_launcher_background.png"

echo -e "${GREEN}✅ Android icons generated${NC}"
echo ""

# Windows Icons
echo -e "${YELLOW}🪟 Generating Windows icons...${NC}"
WINDOWS_ICON_DIR="$PROJECT_ROOT/assets/windows/Icons"
mkdir -p "$WINDOWS_ICON_DIR"

declare -a WINDOWS_SIZES=(
    "16"
    "32"
    "48"
    "256"
)

for size in "${WINDOWS_SIZES[@]}"; do
    output_path="$WINDOWS_ICON_DIR/AppIcon-${size}x${size}.png"
    
    echo "  Creating: AppIcon-${size}x${size}.png"
    convert "$BASE_IMAGE" -resize "${size}x${size}" -unsharp 0x0.5+0.5+0.008 "$output_path"
done

echo -e "${GREEN}✅ Windows icons generated${NC}"
echo ""

# Shared/Favicon
echo -e "${YELLOW}🌐 Generating favicons...${NC}"
SHARED_ICON_DIR="$PROJECT_ROOT/assets/shared/branding/favicons"
mkdir -p "$SHARED_ICON_DIR"

declare -a FAVICON_SIZES=(
    "16"
    "32"
    "48"
)

for size in "${FAVICON_SIZES[@]}"; do
    # PNG
    convert "$BASE_IMAGE" -resize "${size}x${size}" "$SHARED_ICON_DIR/favicon-${size}x${size}.png"
    
    # ICO (requires additional tools, creating PNG for now)
    echo "  Created: favicon-${size}x${size}.png"
done

# Apple touch icon
convert "$BASE_IMAGE" -resize "180x180" "$SHARED_ICON_DIR/apple-touch-icon.png"
echo "  Created: apple-touch-icon.png"

echo -e "${GREEN}✅ Favicons generated${NC}"
echo ""

# Update base icon
echo -e "${YELLOW}📦 Updating base icon...${NC}"
cp "$BASE_IMAGE" "$PROJECT_ROOT/assets/shared/icons/app-icon-base.png"
echo -e "${GREEN}✅ Base icon updated${NC}"
echo ""

echo -e "${GREEN}🎉 All icons generated successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Review generated icons in their respective directories"
echo "2. For iOS: Icons are in assets/apple/Icons/AppIcon.appiconset/"
echo "3. For Android: Icons are in assets/android/Icons/"
echo "4. For Windows: Icons are in assets/windows/Icons/"
echo "5. Update platform-specific configurations if needed"


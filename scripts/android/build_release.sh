#!/bin/bash
# ==============================================================================
# Android Build Release Script
# ==============================================================================
# Builds production AAB and APK for Google Play Store
# Usage: ./build_release.sh [flavor]
# Flavors: dev | test | prod (default: prod)
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ANDROID_DIR="$PROJECT_ROOT/platforms/android"
BUILD_DIR="$PROJECT_ROOT/builds/android"

# Parse arguments
FLAVOR="${1:-prod}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🤖 ANDROID PRODUCTION BUILD${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "📦 Flavor: ${GREEN}$FLAVOR${NC}"
echo -e "📁 Android Directory: $ANDROID_DIR"
echo ""

if [ ! -d "$ANDROID_DIR" ]; then
    echo -e "${RED}❌ Android directory not found: $ANDROID_DIR${NC}"
    exit 1
fi

cd "$ANDROID_DIR"

# Create build directories
mkdir -p "$BUILD_DIR/aabs"
mkdir -p "$BUILD_DIR/apks"

# Clean
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
./gradlew clean

# Build AAB (Android App Bundle - required for Play Store)
echo ""
echo -e "${YELLOW}📦 Building AAB (Android App Bundle)...${NC}"
./gradlew bundle${FLAVOR^}Release

# Copy AAB
AAB_FILE=$(find app/build/outputs/bundle/${FLAVOR}Release -name "*.aab" | head -1)
if [ -n "$AAB_FILE" ]; then
    AAB_NAME="KhandobaSecureDocs-${FLAVOR}-$(date +%Y%m%d).aab"
    cp "$AAB_FILE" "$BUILD_DIR/aabs/$AAB_NAME"
    echo -e "${GREEN}✅ AAB created: $BUILD_DIR/aabs/$AAB_NAME${NC}"
    ls -lh "$BUILD_DIR/aabs/$AAB_NAME"
else
    echo -e "${RED}❌ AAB build failed${NC}"
    exit 1
fi

# Build APK (optional - for direct distribution)
echo ""
echo -e "${YELLOW}📱 Building APK...${NC}"
./gradlew assemble${FLAVOR^}Release

# Copy APK
APK_FILE=$(find app/build/outputs/apk/${FLAVOR}/release -name "*.apk" | head -1)
if [ -n "$APK_FILE" ]; then
    APK_NAME="KhandobaSecureDocs-${FLAVOR}-$(date +%Y%m%d).apk"
    cp "$APK_FILE" "$BUILD_DIR/apks/$APK_NAME"
    echo -e "${GREEN}✅ APK created: $BUILD_DIR/apks/$APK_NAME${NC}"
    ls -lh "$BUILD_DIR/apks/$APK_NAME"
else
    echo -e "${YELLOW}⚠️  APK build failed (non-critical)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo -e "📦 Artifacts:"
echo -e "   AAB: ${GREEN}$BUILD_DIR/aabs/$AAB_NAME${NC}"
[ -n "$APK_NAME" ] && echo -e "   APK: ${GREEN}$BUILD_DIR/apks/$APK_NAME${NC}"
echo ""
echo "Next steps:"
echo "  1. Sign AAB (if not already signed)"
echo "  2. Upload to Google Play Console"
echo "  3. Or use: ./upload_to_playstore.sh"

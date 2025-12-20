#!/bin/bash
# ==============================================================================
# Android Sign Release Script
# ==============================================================================
# Signs AAB/APK with release keystore
# Usage: ./sign_release.sh [aab_file] [apk_file]
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

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🔐 SIGN RELEASE BUILD${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Keystore configuration (should be in secure location, not committed)
KEYSTORE_FILE="${KEYSTORE_FILE:-$ANDROID_DIR/app/release.keystore}"
KEYSTORE_ALIAS="${KEYSTORE_ALIAS:-release}"
KEYSTORE_PASSWORD="${KEYSTORE_PASSWORD:-}"

if [ ! -f "$KEYSTORE_FILE" ]; then
    echo -e "${YELLOW}⚠️  Keystore not found: $KEYSTORE_FILE${NC}"
    echo ""
    echo "Create keystore with:"
    echo "  keytool -genkey -v -keystore $KEYSTORE_FILE -alias $KEYSTORE_ALIAS -keyalg RSA -keysize 2048 -validity 10000"
    echo ""
    echo "Or set KEYSTORE_FILE environment variable:"
    echo "  export KEYSTORE_FILE=/path/to/keystore"
    exit 1
fi

if [ -z "$KEYSTORE_PASSWORD" ]; then
    echo -e "${YELLOW}Enter keystore password:${NC}"
    read -s KEYSTORE_PASSWORD
    echo ""
fi

# Sign AAB if provided
AAB_FILE="$1"
if [ -n "$AAB_FILE" ] && [ -f "$AAB_FILE" ]; then
    echo -e "${YELLOW}📦 Signing AAB...${NC}"
    
    SIGNED_AAB="${AAB_FILE%.aab}-signed.aab"
    
    jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA256 \
        -keystore "$KEYSTORE_FILE" \
        -storepass "$KEYSTORE_PASSWORD" \
        "$AAB_FILE" \
        "$KEYSTORE_ALIAS"
    
    echo -e "${GREEN}✅ AAB signed: $AAB_FILE${NC}"
fi

# Sign APK if provided
APK_FILE="$2"
if [ -n "$APK_FILE" ] && [ -f "$APK_FILE" ]; then
    echo -e "${YELLOW}📱 Signing APK...${NC}"
    
    SIGNED_APK="${APK_FILE%.apk}-signed.apk"
    
    # Align APK first
    zipalign -v 4 "$APK_FILE" "$SIGNED_APK"
    
    # Sign aligned APK
    apksigner sign \
        --ks "$KEYSTORE_FILE" \
        --ks-pass "pass:$KEYSTORE_PASSWORD" \
        --key-pass "pass:$KEYSTORE_PASSWORD" \
        "$SIGNED_APK"
    
    echo -e "${GREEN}✅ APK signed: $SIGNED_APK${NC}"
fi

if [ -z "$AAB_FILE" ] && [ -z "$APK_FILE" ]; then
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./sign_release.sh [aab_file] [apk_file]"
    echo ""
    echo "Example:"
    echo "  ./sign_release.sh ../builds/android/aabs/app.aab"
    echo "  ./sign_release.sh ../builds/android/aabs/app.aab ../builds/android/apks/app.apk"
fi

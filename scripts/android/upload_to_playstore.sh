#!/bin/bash
# ==============================================================================
# Android Upload to Play Store Script
# ==============================================================================
# Uploads AAB to Google Play Console using gcloud or manual instructions
# Usage: ./upload_to_playstore.sh [aab_file]
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
BUILD_DIR="$PROJECT_ROOT/builds/android"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  📤 UPLOAD TO GOOGLE PLAY STORE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Find latest AAB if not provided
AAB_FILE="${1:-}"
if [ -z "$AAB_FILE" ]; then
    AAB_FILE=$(ls -t "$BUILD_DIR/aabs"/*.aab 2>/dev/null | head -1)
fi

if [ -z "$AAB_FILE" ] || [ ! -f "$AAB_FILE" ]; then
    echo -e "${RED}❌ AAB file not found${NC}"
    echo ""
    echo "Please build first:"
    echo "  ./build_release.sh prod"
    echo ""
    echo "Or specify AAB file:"
    echo "  ./upload_to_playstore.sh path/to/app.aab"
    exit 1
fi

echo -e "📦 AAB File: ${GREEN}$AAB_FILE${NC}"
echo ""

# Check if gcloud is available
if command -v gcloud &> /dev/null; then
    echo -e "${YELLOW}📤 Uploading via gcloud...${NC}"
    echo ""
    echo "Note: You need to configure gcloud with:"
    echo "  1. gcloud auth login"
    echo "  2. gcloud config set project YOUR_PROJECT_ID"
    echo ""
    read -p "Continue with upload? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Get package name from AAB (requires aapt2 or bundletool)
        PACKAGE_NAME="com.khandoba.securedocs"
        
        gcloud app deploy "$AAB_FILE" --project="$PACKAGE_NAME" || {
            echo -e "${YELLOW}⚠️  gcloud upload failed. Use manual upload instead.${NC}"
        }
    fi
else
    echo -e "${YELLOW}📋 Manual Upload Instructions:${NC}"
    echo ""
    echo "1. Go to Google Play Console:"
    echo "   https://play.google.com/console"
    echo ""
    echo "2. Select your app (Khandoba Secure Docs)"
    echo ""
    echo "3. Go to: Production → Releases → Create new release"
    echo ""
    echo "4. Upload AAB file:"
    echo "   $AAB_FILE"
    echo ""
    echo "5. Fill in release notes and publish"
    echo ""
    echo -e "${GREEN}✅ AAB ready for upload: $AAB_FILE${NC}"
fi

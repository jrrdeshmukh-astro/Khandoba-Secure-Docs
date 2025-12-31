#!/bin/bash

# Upload to TestFlight using App Store Connect API
# Uses altool for reliable uploads

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "\n${BOLD}${BLUE}🚀 Upload to TestFlight${NC}"
echo "==============================="
echo ""

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
cd "${PROJECT_ROOT}/platforms/apple"
PROJECT="Khandoba Secure Docs.xcodeproj"
SCHEME="Khandoba Secure Docs"
TEAM_ID="Q5Y8754WU4"
BUNDLE_ID="com.khandoba.securedocs"
API_KEY="PR62QK662L"
API_ISSUER="0556f8c8-6856-4d6e-95dc-85d88dcba11f"
API_KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${API_KEY}.p8"

# Check for API key
if [ ! -f "$API_KEY_PATH" ]; then
    echo -e "${YELLOW}⚠️  API key not found at: $API_KEY_PATH${NC}"
    echo "Copying API key..."
    mkdir -p "$HOME/.appstoreconnect/private_keys"
    cp "AuthKey_${API_KEY}.p8" "$API_KEY_PATH"
    chmod 600 "$API_KEY_PATH"
    echo -e "${GREEN}✅ API key installed${NC}"
fi

echo -e "${BLUE}📋 Configuration:${NC}"
echo "  Team: $TEAM_ID"
echo "  Bundle: $BUNDLE_ID"
echo "  API Key: $API_KEY"
echo ""

# Step 1: Clean
echo -e "${BLUE}🧹 Cleaning build folder...${NC}"
xcodebuild clean \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    > /dev/null 2>&1

rm -rf build
mkdir -p build

echo -e "${GREEN}✅ Clean complete${NC}"
echo ""

# Step 2: Archive
echo -e "${BLUE}📦 Creating archive...${NC}"
echo "  (This may take 3-5 minutes)"
echo ""

xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "build/KhandobaSecureDocs.xcarchive" \
    -destination 'generic/platform=iOS' \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    2>&1 | grep -E "Archive Succeeded|error:|warning:" | tail -10

if [ ! -d "build/KhandobaSecureDocs.xcarchive" ]; then
    echo -e "${RED}❌ Archive failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Archive created${NC}"
echo ""

# Step 3: Export IPA
echo -e "${BLUE}📤 Exporting IPA...${NC}"

# Create export options
cat > build/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "build/KhandobaSecureDocs.xcarchive" \
    -exportPath "build" \
    -exportOptionsPlist "build/ExportOptions.plist" \
    2>&1 | grep -E "Export Succeeded|error:|warning:" | tail -5

if [ ! -f "build/Khandoba Secure Docs.ipa" ]; then
    echo -e "${RED}❌ Export failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ IPA exported${NC}"
echo ""

# Step 4: Upload to TestFlight
echo -e "${BLUE}☁️  Uploading to TestFlight...${NC}"
echo "  (This may take 5-10 minutes)"
echo ""

xcrun altool --upload-app \
    --type ios \
    --file "build/Khandoba Secure Docs.ipa" \
    --apiKey "$API_KEY" \
    --apiIssuer "$API_ISSUER" \
    2>&1 | tail -10

echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  ✅ UPLOAD COMPLETE!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⏰ Processing:${NC} Apple is now processing your build (~10 minutes)"
echo -e "${BLUE}📱 Check:${NC} https://appstoreconnect.apple.com/apps/$APP_ID/testflight/ios"
echo ""
echo -e "${GREEN}✨ Your new build will appear in TestFlight shortly!${NC}"
echo ""


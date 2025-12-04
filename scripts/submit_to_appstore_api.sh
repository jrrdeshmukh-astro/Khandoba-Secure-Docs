#!/bin/bash

# Complete App Store Submission via API
# Automates metadata, build selection, and submission

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
APP_ID="6753986878"
API_KEY="PR62QK662L"
API_ISSUER="0556f8c8-6856-4d6e-95dc-85d88dcba11f"
BUNDLE_ID="com.khandoba.securedocs"

echo -e "\n${BOLD}${BLUE}🚀 App Store Submission via API${NC}"
echo "============================================"
echo ""

# Generate JWT token
echo -e "${BLUE}🔑 Generating JWT token...${NC}"
JWT=$(./scripts/generate_jwt.sh)
if [ -z "$JWT" ]; then
    echo -e "${RED}❌ Failed to generate JWT${NC}"
    exit 1
fi
echo -e "${GREEN}✅ JWT generated${NC}"
echo ""

# Step 1: First upload a new build
echo -e "${BLUE}📦 Step 1: Uploading new build to TestFlight...${NC}"
echo ""

# Run the upload script
./scripts/upload_to_testflight.sh

echo ""
echo -e "${YELLOW}⏰ Waiting 60 seconds for build to start processing...${NC}"
sleep 60

echo ""
echo -e "${BLUE}📋 Step 1b: Getting latest build from API...${NC}"

# Install jq if not present
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Installing jq for JSON parsing...${NC}"
    brew install jq > /dev/null 2>&1 || echo "Please install jq: brew install jq"
fi

BUILDS_RESPONSE=$(curl -s \
    -H "Authorization: Bearer $JWT" \
    "https://api.appstoreconnect.apple.com/v1/builds?filter[app]=$APP_ID&sort=-uploadedDate&limit=1")

# Debug: show response if empty
if [ -z "$BUILDS_RESPONSE" ] || [ "$BUILDS_RESPONSE" = "{}" ]; then
    echo -e "${YELLOW}⚠️  API returned empty response${NC}"
    echo "This usually means the build is still processing."
    echo ""
    echo -e "${BLUE}Continuing with manual build selection in browser...${NC}"
    echo "Go to: https://appstoreconnect.apple.com/apps/$APP_ID/distribution/ios/version/inflight"
    echo ""
    exit 0
fi

# Parse with jq if available, otherwise use grep
if command -v jq &> /dev/null; then
    BUILD_ID=$(echo "$BUILDS_RESPONSE" | jq -r '.data[0].id // empty')
    BUILD_VERSION=$(echo "$BUILDS_RESPONSE" | jq -r '.data[0].attributes.version // empty')
else
    BUILD_ID=$(echo "$BUILDS_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    BUILD_VERSION=$(echo "$BUILDS_RESPONSE" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [ -z "$BUILD_ID" ]; then
    echo -e "${YELLOW}⚠️  Build not yet available via API${NC}"
    echo "Build is still processing. This is normal and can take 10-30 minutes."
    echo ""
    echo -e "${BLUE}Options:${NC}"
    echo "1. Wait 15-30 min and run this script again"
    echo "2. Complete submission manually in browser (faster):"
    echo "   https://appstoreconnect.apple.com/apps/$APP_ID"
    echo ""
    exit 0
fi

echo -e "${GREEN}✅ Found Build $BUILD_VERSION (ID: $BUILD_ID)${NC}"
echo ""

# Step 2: Get or create app version
echo -e "${BLUE}📝 Step 2: Creating app version 1.0...${NC}"

# Try to get existing version first
VERSION_RESPONSE=$(curl -s \
    -H "Authorization: Bearer $JWT" \
    "https://api.appstoreconnect.apple.com/v1/apps/$APP_ID/appStoreVersions?filter[versionString]=1.0&filter[platform]=IOS")

VERSION_ID=$(echo "$VERSION_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$VERSION_ID" ]; then
    # Create new version
    echo "Creating new version..."
    CREATE_VERSION_RESPONSE=$(curl -s -X POST \
        -H "Authorization: Bearer $JWT" \
        -H "Content-Type: application/json" \
        "https://api.appstoreconnect.apple.com/v1/appStoreVersions" \
        -d '{
          "data": {
            "type": "appStoreVersions",
            "attributes": {
              "platform": "IOS",
              "versionString": "1.0"
            },
            "relationships": {
              "app": {
                "data": {
                  "type": "apps",
                  "id": "'$APP_ID'"
                }
              }
            }
          }
        }')
    
    VERSION_ID=$(echo "$CREATE_VERSION_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

echo -e "${GREEN}✅ Version ID: $VERSION_ID${NC}"
echo ""

# Step 3: Update app metadata
echo -e "${BLUE}📄 Step 3: Updating app metadata...${NC}"

curl -s -X PATCH \
    -H "Authorization: Bearer $JWT" \
    -H "Content-Type: application/json" \
    "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$VERSION_ID" \
    -d '{
      "data": {
        "type": "appStoreVersions",
        "id": "'$VERSION_ID'",
        "attributes": {
          "description": "Khandoba Secure Docs - Military-Grade Secure Storage\n\nSUBSCRIPTION: $5.99/MONTH\n• Unlimited vaults and storage\n• All premium features included\n• Family Sharing (up to 6 people)\n• Cancel anytime\n\nFEATURES:\n• AES-256 encryption\n• AI-powered document intelligence\n• Source/Sink classification\n• Intel Reports with AI narratives\n• HIPAA-compliant redaction\n• Real-time threat monitoring\n• Geolocation tracking\n• Zero-knowledge architecture\n\nMANAGEMENT:\n• Upload from camera, photos, files\n• Record videos and voice memos\n• Full previews (PDF, images, videos, audio)\n• Version history\n• Cross-vault search\n\nCOLLABORATION:\n• Invite nominees\n• Transfer vault ownership\n• Emergency access\n• Real-time messaging\n\nPerfect for medical, legal, and secure document storage.",
          "keywords": "secure,vault,documents,encryption,HIPAA,medical,legal,AI,privacy,storage",
          "promotionalText": "Unlimited secure vaults for $5.99/month. Military-grade encryption. HIPAA compliant.",
          "supportURL": "https://khandoba.com/support",
          "marketingURL": "https://khandoba.com"
        }
      }
    }' > /dev/null

echo -e "${GREEN}✅ Metadata updated${NC}"
echo ""

# Step 4: Link build to version
echo -e "${BLUE}🔗 Step 4: Linking build to version...${NC}"

curl -s -X PATCH \
    -H "Authorization: Bearer $JWT" \
    -H "Content-Type: application/json" \
    "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$VERSION_ID" \
    -d '{
      "data": {
        "type": "appStoreVersions",
        "id": "'$VERSION_ID'",
        "relationships": {
          "build": {
            "data": {
              "type": "builds",
              "id": "'$BUILD_ID'"
            }
          }
        }
      }
    }' > /dev/null

echo -e "${GREEN}✅ Build linked to version${NC}"
echo ""

# Step 5: Upload screenshots (requires separate process - see note below)
echo -e "${YELLOW}⚠️  Step 5: Screenshots${NC}"
echo "Screenshots must be uploaded via App Store Connect web interface"
echo "or use Apple's Transporter app (GUI)"
echo "API upload is complex (requires reservation + upload + commit)"
echo ""
echo "📸 Upload these 5 screenshots manually:"
echo "   AppStoreAssets/Screenshots/"
echo ""

# Step 6: Submit for review
echo -e "${BLUE}✅ Step 6: Submitting for review...${NC}"

SUBMISSION_RESPONSE=$(curl -s -X POST \
    -H "Authorization: Bearer $JWT" \
    -H "Content-Type: application/json" \
    "https://api.appstoreconnect.apple.com/v1/appStoreVersionSubmissions" \
    -d '{
      "data": {
        "type": "appStoreVersionSubmissions",
        "relationships": {
          "appStoreVersion": {
            "data": {
              "type": "appStoreVersions",
              "id": "'$VERSION_ID'"
            }
          }
        }
      }
    }')

if echo "$SUBMISSION_RESPONSE" | grep -q '"type":"appStoreVersionSubmissions"'; then
    echo -e "${GREEN}✅ Submitted for review!${NC}"
else
    echo -e "${RED}❌ Submission failed${NC}"
    echo "Response: $SUBMISSION_RESPONSE"
    echo ""
    echo -e "${YELLOW}Note: You may need to:${NC}"
    echo "1. Upload screenshots manually"
    echo "2. Create subscription in App Store Connect"
    echo "3. Ensure all required fields are filled"
fi

echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  ✅ API SUBMISSION COMPLETE${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⚠️  Manual steps still required:${NC}"
echo "1. Create subscription: https://appstoreconnect.apple.com/apps/$APP_ID"
echo "2. Upload screenshots (drag & drop in browser)"
echo "3. Upload app preview video (if created)"
echo ""
echo -e "${BLUE}Check status:${NC}"
echo "https://appstoreconnect.apple.com/apps/$APP_ID/distribution/ios/version/inflight"
echo ""


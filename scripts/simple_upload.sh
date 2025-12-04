#!/bin/bash

# Simplified TestFlight Upload + App Store Submission
# Hybrid approach: API upload, browser completion

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "\n${BOLD}${BLUE}🚀 Khandoba Secure Docs - Submission${NC}"
echo "============================================="
echo ""

# Step 1: Upload to TestFlight
echo -e "${BLUE}📦 Step 1: Uploading to TestFlight...${NC}"
echo ""

cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Increment build
echo "Incrementing build number..."
agvtool next-version -all

# Upload
./scripts/upload_to_testflight.sh

echo ""
echo -e "${GREEN}✅ Build uploaded to TestFlight!${NC}"
echo ""

# Step 2: Wait for processing
echo -e "${YELLOW}⏰ Build is processing at Apple (~10-30 minutes)${NC}"
echo ""
echo "While you wait, complete these manual steps:"
echo ""

# Step 3: Manual steps
echo -e "${BOLD}${BLUE}📋 Manual Steps (in browser):${NC}"
echo ""

APP_ID="6753986878"

echo "1️⃣  CREATE SUBSCRIPTION (10 min) - REQUIRED:"
echo "   https://appstoreconnect.apple.com/apps/$APP_ID/features"
echo "   → Subscriptions → Create"
echo "   → Product ID: com.khandoba.premium.monthly"
echo "   → Price: \$5.99/month"
echo "   → Family Sharing: ON"
echo "   → Skip promotional image"
echo ""

echo "2️⃣  CHECK BUILD STATUS:"
echo "   https://appstoreconnect.apple.com/apps/$APP_ID/testflight/ios"
echo "   → Wait for 'Ready to Test' status"
echo ""

echo "3️⃣  SELECT BUILD & UPLOAD SCREENSHOTS:"
echo "   https://appstoreconnect.apple.com/apps/$APP_ID/distribution/ios/version/inflight"
echo "   → Select your new build"
echo "   → Upload 5 screenshots from AppStoreAssets/Screenshots/"
echo "   → (Drag and drop)"
echo ""

echo "4️⃣  ADD METADATA:"
echo "   → Description: (see AppStoreAssets/METADATA.md)"
echo "   → Keywords: secure,vault,documents,encryption,HIPAA,medical,legal,AI"
echo "   → Promotional Text: Unlimited secure vaults for \$5.99/month"
echo ""

echo "5️⃣  ADD SUBSCRIPTION TO VERSION:"
echo "   → In-App Purchases section"
echo "   → Add the subscription you created"
echo ""

echo "6️⃣  SUBMIT FOR REVIEW:"
echo "   → Click 'Submit for Review'"
echo "   → Answer questionnaire"
echo "   → Done!"
echo ""

echo -e "${BOLD}${GREEN}════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  ✅ UPLOAD COMPLETE${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Next:${NC} Complete manual steps above while build processes"
echo -e "${BLUE}Time:${NC} ~30 minutes to full submission"
echo ""


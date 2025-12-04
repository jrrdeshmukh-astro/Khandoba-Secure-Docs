#!/bin/bash

# Complete App Store Submission
# Single script to handle everything

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

APP_ID="6753986878"
BUNDLE_ID="com.khandoba.securedocs"
TEAM_ID="Q5Y8754WU4"

echo -e "\n${BOLD}${BLUE}🚀 Khandoba Secure Docs - App Store Submission${NC}"
echo "=================================================="
echo ""

# Get Issuer ID for API calls
echo -e "${YELLOW}Enter App Store Connect Issuer ID:${NC}"
echo "(Get from: https://appstoreconnect.apple.com/access/api)"
read -p "Issuer ID: " ISSUER_ID

if [ -z "$ISSUER_ID" ]; then
    echo -e "${RED}❌ Issuer ID required${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Configuration complete${NC}"
echo ""

# Open App Store Connect
echo -e "${BLUE}🌐 Opening App Store Connect...${NC}"
open "https://appstoreconnect.apple.com/apps/$APP_ID/distribution/ios/version/inflight"

echo ""
echo -e "${BOLD}${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  📝 COMPLETE THESE STEPS IN BROWSER:${NC}"
echo -e "${BOLD}${BLUE}════════════════════════════════════════════════${NC}"
echo ""

# Show metadata
cat << 'EOF'
1. VERSION 1.0 → Description:
   Copy this complete description ↓

Khandoba Secure Docs - Military-Grade Secure Storage

SUBSCRIPTION: $5.99/MONTH
• Unlimited vaults and storage
• All premium features included
• Family Sharing (up to 6 people)
• Cancel anytime

FEATURES:
• AES-256 encryption
• AI-powered document intelligence
• Source/Sink classification
• Intel Reports with AI narratives
• HIPAA-compliant redaction
• Real-time threat monitoring
• Geolocation tracking
• Zero-knowledge architecture

MANAGEMENT:
• Upload from camera, photos, files
• Record videos and voice memos
• Full previews (PDF, images, videos, audio)
• Version history
• Cross-vault search

COLLABORATION:
• Invite nominees
• Transfer vault ownership
• Emergency access
• Real-time messaging

Perfect for medical, legal, and secure document storage.

2. Keywords:
secure,vault,documents,encryption,HIPAA,medical,legal,AI,privacy,storage

3. Promotional Text:
Unlimited secure vaults for $5.99/month. Military-grade encryption. HIPAA compliant.

4. URLs:
Support: https://khandoba.com/support
Marketing: https://khandoba.com

5. Create Subscription (Features tab):
Product ID: com.khandoba.premium.monthly
Price: $5.99/month
Family Sharing: ON

6. Upload 5 screenshots (take with Cmd+S in simulator)

7. Select TestFlight build

8. Click "Submit for Review"
EOF

echo ""
echo -e "${BOLD}${GREEN}✅ Follow steps above, then app is submitted!${NC}"
echo ""

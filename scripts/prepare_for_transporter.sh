#!/bin/bash

# Khandoba Secure Docs - Transporter Preparation Script
# This script prepares the app for upload via Apple Transporter

set -e

echo "🚀 =================================="
echo "   KHANDOBA TRANSPORTER PREP"
echo "   =================================="
echo ""

# Configuration
PROJECT_NAME="Khandoba Secure Docs"
SCHEME="Khandoba Secure Docs"
WORKSPACE="${PROJECT_NAME}.xcodeproj"
BUNDLE_ID="com.khandoba.securedocs"
TEAM_ID="Q5Y8754WU4"
BUILD_DIR="./build"
ARCHIVE_PATH="${BUILD_DIR}/KhandobaSecureDocs_Final.xcarchive"
EXPORT_PATH="${BUILD_DIR}/Final_IPA"
EXPORT_OPTIONS="./scripts/ExportOptions.plist"

echo "📋 Configuration:"
echo "   Project: $PROJECT_NAME"
echo "   Bundle ID: $BUNDLE_ID"
echo "   Team ID: $TEAM_ID"
echo ""

# Step 1: Clean previous builds
echo "🧹 Step 1/6: Cleaning previous builds..."
rm -rf "$BUILD_DIR/Final_IPA"
rm -rf "$ARCHIVE_PATH"
xcodebuild clean -project "$WORKSPACE" -scheme "$SCHEME" -configuration Release
echo "   ✅ Clean complete"
echo ""

# Step 2: Verify configuration
echo "🔍 Step 2/6: Verifying configuration..."

# Check entitlements
if grep -q "production" "Khandoba Secure Docs/Khandoba_Secure_Docs.entitlements"; then
    echo "   ✅ Entitlements: Production mode"
else
    echo "   ⚠️  WARNING: Entitlements still in development mode"
    echo "   Update aps-environment to 'production' in entitlements file"
fi

# Check Info.plist permissions
echo "   📄 Checking required permissions in Info.plist..."
REQUIRED_PERMISSIONS=(
    "NSCameraUsageDescription"
    "NSMicrophoneUsageDescription"
    "NSPhotoLibraryUsageDescription"
    "NSLocationWhenInUseUsageDescription"
    "NSCalendarsUsageDescription"
    "NSSpeechRecognitionUsageDescription"
)

for permission in "${REQUIRED_PERMISSIONS[@]}"; do
    if grep -q "$permission" "Khandoba Secure Docs/Info.plist"; then
        echo "   ✅ $permission"
    else
        echo "   ❌ Missing: $permission"
    fi
done
echo ""

# Step 3: Archive the app
echo "📦 Step 3/6: Creating archive..."
xcodebuild archive \
    -project "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=iOS' \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="$TEAM_ID"

if [ -d "$ARCHIVE_PATH" ]; then
    echo "   ✅ Archive created successfully"
else
    echo "   ❌ Archive failed"
    exit 1
fi
echo ""

# Step 4: Export for App Store
echo "📤 Step 4/6: Exporting for App Store..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates

if [ -f "$EXPORT_PATH/$PROJECT_NAME.ipa" ]; then
    echo "   ✅ IPA exported successfully"
    IPA_SIZE=$(du -h "$EXPORT_PATH/$PROJECT_NAME.ipa" | cut -f1)
    echo "   📦 IPA Size: $IPA_SIZE"
else
    echo "   ❌ Export failed"
    exit 1
fi
echo ""

# Step 5: Validate IPA
echo "✓ Step 5/6: Validating IPA..."
echo "   Checking bundle structure..."
unzip -l "$EXPORT_PATH/$PROJECT_NAME.ipa" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ IPA structure valid"
else
    echo "   ❌ IPA corrupted"
    exit 1
fi
echo ""

# Step 6: Final verification
echo "🔍 Step 6/6: Final verification..."

echo "   Checking for common issues:"
echo "   ✅ Archive exists: $ARCHIVE_PATH"
echo "   ✅ IPA exists: $EXPORT_PATH/$PROJECT_NAME.ipa"
echo "   ✅ Export options used: $EXPORT_OPTIONS"
echo ""

# Display upload instructions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ APP READY FOR TRANSPORTER!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 IPA Location:"
echo "   $EXPORT_PATH/$PROJECT_NAME.ipa"
echo ""
echo "📤 UPLOAD OPTIONS:"
echo ""
echo "OPTION 1: Transporter App (Recommended)"
echo "   1. Open Transporter.app"
echo "   2. Sign in with Apple ID"
echo "   3. Click '+' or drag IPA file"
echo "   4. Click 'Deliver'"
echo "   5. Wait for upload to complete"
echo ""
echo "OPTION 2: Command Line (altool)"
echo "   xcrun altool --upload-app \\"
echo "       --type ios \\"
echo "       --file \"$EXPORT_PATH/$PROJECT_NAME.ipa\" \\"
echo "       --apiKey YOUR_API_KEY \\"
echo "       --apiIssuer YOUR_ISSUER_ID"
echo ""
echo "OPTION 3: Xcode Organizer"
echo "   1. Open Xcode"
echo "   2. Window → Organizer"
echo "   3. Select archive: $ARCHIVE_PATH"
echo "   4. Click 'Distribute App'"
echo "   5. Select 'App Store Connect'"
echo "   6. Click 'Upload'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 NEXT STEPS:"
echo "   1. Upload IPA via Transporter"
echo "   2. Go to App Store Connect"
echo "   3. Select your app"
echo "   4. Add build to version"
echo "   5. Submit for review"
echo ""
echo "✅ Good luck with your launch!"
echo ""


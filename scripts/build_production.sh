#!/bin/bash

# Build for Production
# Clean build with Xcode CLI

set -e

echo "🔨 Building Khandoba Secure Docs for Production"
echo "==============================================="
echo ""

cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

PROJECT="Khandoba Secure Docs.xcodeproj"
SCHEME="Khandoba Secure Docs"
CONFIGURATION="Release"

# Clean
echo "🧹 Cleaning..."
xcodebuild clean \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    > /dev/null 2>&1

# Build for iOS
echo "📱 Building for iOS..."
xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination 'generic/platform=iOS' \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    | xcpretty || grep -E "error:|warning:|succeeded|failed"

echo ""
echo "✅ Production build complete!"
echo ""
echo "Next: ./scripts/submit_to_appstore.sh"


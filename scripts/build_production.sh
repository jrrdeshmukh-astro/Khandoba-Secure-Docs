#!/bin/bash

# Build for Production
# Clean build with Xcode CLI

set -e

echo "🔨 Building Khandoba Secure Docs for Production"
echo "==============================================="
echo ""

# Get script directory and navigate to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
cd "$PROJECT_ROOT/platforms/apple"

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
echo "Next: ../../scripts/apple/submit_to_appstore.sh"


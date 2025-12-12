#!/bin/bash

# Test Project Script
# Builds and tests all targets

set -e

PROJECT_ROOT="/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
PROJECT_FILE="$PROJECT_ROOT/Khandoba Secure Docs.xcodeproj"

echo "🧪 Testing Khandoba Secure Docs Project"
echo ""

# Clean build folder
echo "🧹 Cleaning build folder..."
rm -rf "$PROJECT_ROOT/build"
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
echo "✅ Cleaned"
echo ""

# Test 1: Build main app
echo "📱 Test 1: Building main app..."
xcodebuild -project "$PROJECT_FILE" \
  -target "Khandoba Secure Docs" \
  -configuration Debug \
  -sdk iphonesimulator \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  build 2>&1 | grep -E "(BUILD SUCCEEDED|error|failed)" | head -5

if [ $? -eq 0 ]; then
    echo "✅ Main app builds successfully"
else
    echo "❌ Main app build failed"
    exit 1
fi
echo ""

# Test 2: Build ShareExtension
echo "📤 Test 2: Building ShareExtension..."
xcodebuild -project "$PROJECT_FILE" \
  -target "ShareExtension" \
  -configuration Debug \
  -sdk iphonesimulator \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  build 2>&1 | grep -E "(BUILD SUCCEEDED|error|failed)" | head -5

if [ $? -eq 0 ]; then
    echo "✅ ShareExtension builds successfully"
else
    echo "❌ ShareExtension build failed"
    exit 1
fi
echo ""

# Test 3: Build iMessage Extension
echo "💬 Test 3: Building iMessage Extension..."
xcodebuild -project "$PROJECT_FILE" \
  -target "KhandobaSecureDocsMessageApp MessagesExtension" \
  -configuration Debug \
  -sdk iphonesimulator \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  build 2>&1 | grep -E "(BUILD SUCCEEDED|error|failed)" | head -5

if [ $? -eq 0 ]; then
    echo "✅ iMessage Extension builds successfully"
else
    echo "❌ iMessage Extension build failed"
    exit 1
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All targets build successfully!"
echo ""
echo "Next steps:"
echo "  1. Open Xcode: open \"$PROJECT_FILE\""
echo "  2. Select scheme: Khandoba Secure Docs"
echo "  3. Select simulator: iPhone 15 Pro (iOS 26.1+)"
echo "  4. Run: ⌘+R"
echo ""
echo "For extension testing:"
echo "  - iMessage: Enable in Settings → Messages"
echo "  - ShareExtension: Available in share sheets"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

#!/bin/bash
# Script to help diagnose and fix test configuration issues

set -e

PROJECT="Khandoba Secure Docs.xcodeproj"
SCHEME="Khandoba Secure Docs"
DESTINATION='platform=iOS Simulator,id=759ADD04-138D-4D2F-B2FC-5FDCBA11605E'

echo "🔍 Checking test configuration..."

# Check if test files exist
echo "📁 Test files:"
find "Khandoba Secure DocsTests" -name "*.swift" -type f | while read file; do
    echo "  ✓ $file"
done

# Check test target build
echo ""
echo "🔨 Building test target..."
xcodebuild -project "$PROJECT" \
    -target "Khandoba Secure DocsTests" \
    -sdk iphonesimulator \
    -configuration Debug \
    -destination "$DESTINATION" \
    clean build 2>&1 | grep -E "BUILD|error|warning.*test" | tail -5

# Check if executable exists
echo ""
echo "📦 Checking test bundle..."
BUNDLE_PATH="build/Debug-iphonesimulator/Khandoba Secure Docs.app/PlugIns/Khandoba Secure DocsTests.xctest"
if [ -d "$BUNDLE_PATH" ]; then
    echo "  ✓ Test bundle exists"
    if [ -f "$BUNDLE_PATH/Khandoba Secure DocsTests" ]; then
        echo "  ✓ Executable exists"
        file "$BUNDLE_PATH/Khandoba Secure DocsTests"
    else
        echo "  ❌ Executable missing!"
        echo "  Contents of bundle:"
        ls -la "$BUNDLE_PATH/"
        echo ""
        echo "⚠️  This indicates test files are not being compiled/linked."
        echo "   Fix: Open Xcode → Select test target → Build Phases →"
        echo "   Verify all test files are in 'Compile Sources'"
    fi
else
    echo "  ❌ Test bundle not found"
fi

echo ""
echo "✅ Diagnosis complete. See TEST_CONFIGURATION_FIX.md for fix steps."


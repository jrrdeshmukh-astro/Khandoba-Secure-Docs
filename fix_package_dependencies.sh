#!/bin/bash

echo "🔧 Fixing Package Dependencies Issue"
echo "===================================="
echo ""

# Step 1: Clean DerivedData
echo "1. Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
echo "   ✅ DerivedData cleaned"

# Step 2: Clean package caches
echo "2. Cleaning package caches..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages 2>/dev/null
echo "   ✅ Package caches cleaned"

# Step 3: Clean build folder
echo "3. Cleaning build folder..."
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
xcodebuild clean -project "Khandoba Secure Docs.xcodeproj" -scheme "Khandoba Secure Docs" 2>/dev/null || echo "   ⚠️  Clean command had warnings (this is OK)"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📋 Next Steps:"
echo "   1. Open Xcode"
echo "   2. File → Packages → Reset Package Caches"
echo "   3. File → Packages → Resolve Package Versions"
echo "   4. Wait for packages to resolve (2-5 minutes)"
echo "   5. Try building again: ./scripts/prepare_for_transporter.sh"
echo ""

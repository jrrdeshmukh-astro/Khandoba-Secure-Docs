#!/bin/bash

# Verify iMessage Extension Setup

PROJECT_ROOT="/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
EXTENSION_DIR="$PROJECT_ROOT/KhandobaSecureDocsMessageApp MessagesExtension"

echo "🔍 Verifying iMessage Extension Setup..."
echo ""

# Check Step 2: Files exist
echo "📁 Step 2 Verification:"
echo ""

if [ -f "$EXTENSION_DIR/MessagesViewController.swift" ]; then
    echo "   ✅ MessagesViewController.swift exists"
    # Check if it's the full implementation (not template)
    if grep -q "presentMainInterface" "$EXTENSION_DIR/MessagesViewController.swift"; then
        echo "      ✅ Contains full implementation"
    else
        echo "      ⚠️  Still contains template code"
    fi
else
    echo "   ❌ MessagesViewController.swift missing"
fi

if [ -d "$EXTENSION_DIR/Views" ]; then
    echo "   ✅ Views folder exists"
    view_count=$(find "$EXTENSION_DIR/Views" -name "*.swift" | wc -l | tr -d ' ')
    echo "      Found $view_count Swift file(s)"
    
    for view in MainMenuMessageView NomineeInvitationMessageView InvitationResponseMessageView FileSharingMessageView; do
        if [ -f "$EXTENSION_DIR/Views/${view}.swift" ]; then
            echo "      ✅ ${view}.swift"
        else
            echo "      ❌ ${view}.swift missing"
        fi
    done
else
    echo "   ❌ Views folder missing"
fi

if [ -f "$EXTENSION_DIR/KhandobaSecureDocsMessageApp.entitlements" ]; then
    echo "   ✅ Entitlements file exists"
else
    echo "   ❌ Entitlements file missing"
fi

echo ""
echo "📋 Step 3 Verification:"
echo "   Note: Target membership must be verified in Xcode"
echo "   or by building the extension target"
echo ""

# Try to build and check for errors
echo "🔨 Building extension target to verify setup..."
echo ""

cd "$PROJECT_ROOT"

xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -target "KhandobaSecureDocsMessageApp MessagesExtension" \
  -configuration Debug \
  -sdk iphoneos \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | grep -E "(error|warning|succeeded|failed)" | head -20

echo ""
echo "✅ Verification complete!"
echo ""
echo "If you see 'Cannot find' errors, run:"
echo "   python3 scripts/add_target_membership.py"
echo ""

#!/bin/bash
echo "🧹 Cleaning Xcode build artifacts for device installation..."
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Clean derived data
echo "Removing derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*

# Clean build folder
echo "Cleaning build folder..."
xcodebuild clean -scheme "Khandoba Secure Docs" 2>&1 | grep -E "(Cleaning|error|succeeded)" || echo "Clean command executed"

echo ""
echo "✅ Clean complete!"
echo ""
echo "Next steps:"
echo "1. On your iPhone, manually delete the app if it exists"
echo "2. Restart your iPhone"
echo "3. In Xcode, try installing again (⌘R)"
echo ""
echo "If still failing, check:"
echo "- Device has enough storage (Settings → General → iPhone Storage)"
echo "- Provisioning profiles are valid (Xcode → Preferences → Accounts)"
echo "- Bundle identifiers are correct in project settings"

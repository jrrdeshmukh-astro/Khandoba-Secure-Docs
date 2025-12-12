#!/bin/bash

# Remove old MessageExtension target from Xcode project
# This fixes the "Multiple commands produce Info.plist" error

set -e

PROJECT_ROOT="/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
PROJECT_FILE="$PROJECT_ROOT/Khandoba Secure Docs.xcodeproj/project.pbxproj"

echo "🗑️  Removing old MessageExtension target..."
echo ""

# Backup project file
cp "$PROJECT_FILE" "$PROJECT_FILE.backup_before_remove_extension"

echo "✅ Backup created: project.pbxproj.backup_before_remove_extension"
echo ""
echo "⚠️  Note: This script will remove the old MessageExtension target references."
echo "   For complete removal, you'll need to:"
echo "   1. Open Xcode"
echo "   2. Select 'MessageExtension' target"
echo "   3. Right-click → Delete"
echo "   4. Choose 'Remove' (not 'Move to Trash')"
echo ""
echo "   OR run: python3 scripts/remove_message_extension_target.py"
echo ""

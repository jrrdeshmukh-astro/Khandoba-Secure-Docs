#!/bin/bash

# Complete extension removal script
# Removes both ShareExtension and MessageExtension from project

set -e

PROJECT_FILE="Khandoba Secure Docs.xcodeproj/project.pbxproj"
BACKUP_FILE="${PROJECT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

echo "🧹 Cleaning Extensions from Project"
echo "===================================="
echo ""

# Create backup
if [ -f "$PROJECT_FILE" ]; then
    cp "$PROJECT_FILE" "$BACKUP_FILE"
    echo "✅ Backup created: $BACKUP_FILE"
fi

# Remove extension folders
echo ""
echo "📁 Removing extension folders..."

if [ -d "ShareExtension" ]; then
    rm -rf "ShareExtension"
    echo "   ✅ Removed ShareExtension/"
else
    echo "   ℹ️  ShareExtension/ not found"
fi

if [ -d "MessageExtension" ]; then
    rm -rf "MessageExtension"
    echo "   ✅ Removed MessageExtension/"
else
    echo "   ℹ️  MessageExtension/ not found"
fi

# List current targets
echo ""
echo "📋 Current targets in project:"
xcodebuild -project "Khandoba Secure Docs.xcodeproj" -list 2>/dev/null | grep -A 20 "Targets:" || echo "   (Could not list targets - project may need to be opened in Xcode)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  MANUAL STEPS REQUIRED IN XCODE:"
echo ""
echo "1. Open 'Khandoba Secure Docs.xcodeproj' in Xcode"
echo ""
echo "2. Remove ShareExtension target:"
echo "   - Project Navigator → Right-click 'ShareExtension' target"
echo "   - Select 'Delete' → 'Move to Trash'"
echo ""
echo "3. Remove MessageExtension target (if exists):"
echo "   - Project Navigator → Right-click 'MessageExtension' target"
echo "   - Select 'Delete' → 'Move to Trash'"
echo ""
echo "4. Remove embedded extensions from main app:"
echo "   - Select 'Khandoba Secure Docs' target"
echo "   - General tab → Frameworks, Libraries, and Embedded Content"
echo "   - Remove ShareExtension.appex and MessageExtension.appex"
echo ""
echo "5. Clean build folder:"
echo "   - Product → Clean Build Folder (Shift+Cmd+K)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Extension folders removed from filesystem"
echo "📝 Project backup: $BACKUP_FILE"
echo ""
echo "Next: Run './scripts/add_extensions.sh' for re-adding instructions"
echo ""


#!/bin/bash

# Script to remove ShareExtension and MessageExtension from Xcode project
# Usage: ./scripts/remove_extensions.sh

set -e

PROJECT_FILE="Khandoba Secure Docs.xcodeproj/project.pbxproj"
PROJECT_DIR="$(dirname "$PROJECT_FILE")"

echo "🗑️  Removing extensions from Xcode project..."

# Backup project file
if [ ! -f "${PROJECT_FILE}.backup" ]; then
    cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"
    echo "✅ Created backup: ${PROJECT_FILE}.backup"
fi

# Remove extension folders
echo "📁 Removing extension folders..."
if [ -d "ShareExtension" ]; then
    rm -rf "ShareExtension"
    echo "   ✅ Removed ShareExtension folder"
fi

if [ -d "MessageExtension" ]; then
    rm -rf "MessageExtension"
    echo "   ✅ Removed MessageExtension folder"
fi

# Note: We cannot fully remove targets from project.pbxproj via script safely
# The project.pbxproj file is complex and requires careful editing
# Manual removal via Xcode is recommended

echo ""
echo "⚠️  IMPORTANT: Manual steps required in Xcode:"
echo ""
echo "1. Open Xcode project"
echo "2. Select project in navigator"
echo "3. Select 'Khandoba Secure Docs' target"
echo "4. Go to 'General' tab → 'Frameworks, Libraries, and Embedded Content'"
echo "5. Remove ShareExtension.appex and MessageExtension.appex if present"
echo "6. In Project Navigator, right-click ShareExtension and MessageExtension targets"
echo "7. Select 'Delete' → 'Move to Trash'"
echo "8. Clean build folder (Shift+Cmd+K)"
echo ""
echo "✅ Extension folders removed from filesystem"
echo "📝 Project file backup saved to: ${PROJECT_FILE}.backup"


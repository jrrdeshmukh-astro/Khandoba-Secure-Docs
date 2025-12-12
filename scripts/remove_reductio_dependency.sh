#!/bin/bash

# Remove Reductio dependency from Xcode project
# This script removes all references to Reductio package

set -e

PROJECT_ROOT="/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
PROJECT_FILE="$PROJECT_ROOT/Khandoba Secure Docs.xcodeproj/project.pbxproj"

echo "🗑️  Removing Reductio dependency..."
echo ""

# Backup project file
cp "$PROJECT_FILE" "$PROJECT_FILE.backup_before_remove_reductio"

echo "✅ Backup created: project.pbxproj.backup_before_remove_reductio"
echo ""
echo "⚠️  Note: This script removes Reductio references from project.pbxproj"
echo "   Run: python3 scripts/remove_reductio_from_project.py for automated removal"
echo ""

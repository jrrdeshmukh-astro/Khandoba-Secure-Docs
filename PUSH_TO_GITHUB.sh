#!/bin/bash

# Quick Push to GitHub Script
# Replace YOUR_USERNAME with your actual GitHub username

echo "🚀 PUSHING TO GITHUB"
echo "==================="
echo ""

# Check if username is provided
if [ "$1" == "" ]; then
    echo "Usage: ./PUSH_TO_GITHUB.sh YOUR_GITHUB_USERNAME"
    echo ""
    echo "Example:"
    echo "  ./PUSH_TO_GITHUB.sh jaideshmukh80"
    echo ""
    exit 1
fi

GITHUB_USER="$1"
REPO_NAME="Khandoba-Secure-Docs"

echo "GitHub User: $GITHUB_USER"
echo "Repository: $REPO_NAME"
echo ""

# Set remote URL
echo "📝 Setting remote URL..."
git remote set-url origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"

# Verify
echo "✅ Remote configured:"
git remote -v
echo ""

# Check git status
echo "📊 Checking git status..."
git status --short
echo ""

# Check if there are changes to commit
if [ -n "$(git status --porcelain)" ]; then
    echo "📦 Staging all changes (including new files)..."
    git add -A
    
    # Show what will be committed
    echo ""
    echo "📋 Files to be committed:"
    git status --short
    echo ""
    
    echo "💾 Committing changes..."
    COMMIT_MESSAGE="feat: CloudKit sync, push notifications, and file upload improvements

- Enable CloudKit sync for nominee invitations and cross-device sync
- Add CloudKitAPIService for sync monitoring and token verification
- Implement PushNotificationService for nominee invitations and vault alerts
- Add manual token entry for TestFlight nominee invitation testing
- Expand bulk upload to support all file types (PDFs, DOCX, XLSX, etc.)
- Fix document upload to show correct user name in access history
- Update PermissionsSetupView to request notification permissions
- Add comprehensive CloudKit and push notification documentation
- Fix compiler errors in BulkOperationsView and UnifiedShareView"
    
    git commit -m "$COMMIT_MESSAGE"
    
    if [ $? -eq 0 ]; then
        echo "✅ Changes committed successfully!"
        echo ""
    else
        echo "❌ Commit failed. Aborting push."
        exit 1
    fi
else
    echo "ℹ️  No changes to commit."
    echo ""
fi

# Push
echo "🚀 Pushing to GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS! Pushed to GitHub!"
    echo ""
    echo "View your repo:"
    echo "https://github.com/$GITHUB_USER/$REPO_NAME"
else
    echo ""
    echo "❌ Push failed. Common fixes:"
    echo "1. Create repo on GitHub first: https://github.com/new"
    echo "2. Make sure repo name is: $REPO_NAME"
    echo "3. Use Personal Access Token if password doesn't work"
fi

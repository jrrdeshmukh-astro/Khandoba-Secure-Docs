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
    echo "📦 Staging all changes..."
    git add -A
    
    echo "💾 Committing changes..."
    COMMIT_MESSAGE="feat: HIPAA compliance improvements, redaction fix, and Llama unified media description

- Add comprehensive HIPAA compliance assessment
- Fix redaction to actually remove PHI from PDFs and images
- Remove second layer of summarization from intelligence services
- Add LlamaMediaDescriptionService for unified media descriptions
- Update RedactionView to use new RedactionService"
    
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

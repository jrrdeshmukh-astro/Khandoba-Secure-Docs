#!/bin/bash

# Install Cursor Extensions for Cross-Platform Development
# This script installs recommended extensions for Apple, Android, and Windows development

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Installing Cursor Extensions for Cross-Platform Development...${NC}\n"

# Check if cursor command exists
if ! command -v cursor &> /dev/null; then
    echo -e "${RED}❌ Error: 'cursor' command not found${NC}"
    echo -e "${YELLOW}Please ensure Cursor is installed and added to PATH${NC}"
    echo -e "${YELLOW}On macOS, you may need to:${NC}"
    echo -e "  1. Open Cursor"
    echo -e "  2. Press Cmd+Shift+P"
    echo -e "  3. Type 'Shell Command: Install cursor command in PATH'"
    echo -e "  4. Run this script again"
    exit 1
fi

echo -e "${GREEN}✅ Cursor command found${NC}\n"

# Universal Extensions (All Platforms)
echo -e "${BLUE}📦 Installing Universal Extensions...${NC}"
UNIVERSAL_EXTENSIONS=(
    "eamodio.gitlens"                          # GitLens
    "usernamehw.errorlens"                     # Error Lens
    "Gruntfuggly.todo-tree"                    # Todo Tree
    "yzhang.markdown-all-in-one"               # Markdown All in One
)

for ext in "${UNIVERSAL_EXTENSIONS[@]}"; do
    echo -e "${YELLOW}Installing: $ext${NC}"
    cursor --install-extension "$ext" || echo -e "${YELLOW}⚠️  Failed to install $ext (may already be installed)${NC}"
done

echo ""

# Apple Platform Extensions
echo -e "${BLUE}🍎 Installing Apple/Swift Extensions...${NC}"
APPLE_EXTENSIONS=(
    "sswg.swift-lang"                          # Swift Language Support
    # Note: Sweetpad and FlowDeck need to be installed manually from marketplace
    # as they may not have stable extension IDs
)

for ext in "${APPLE_EXTENSIONS[@]}"; do
    echo -e "${YELLOW}Installing: $ext${NC}"
    cursor --install-extension "$ext" || echo -e "${YELLOW}⚠️  Failed to install $ext${NC}"
done

echo -e "${YELLOW}📝 Note: Install 'Sweetpad' or 'FlowDeck' manually from Cursor marketplace for Swift build support${NC}"
echo ""

# Android Platform Extensions
echo -e "${BLUE}🤖 Installing Android/Kotlin Extensions...${NC}"
ANDROID_EXTENSIONS=(
    "fwcd.kotlin"                              # Kotlin Language
    "vscjava.vscode-java-pack"                 # Extension Pack for Java
    "vscjava.vscode-gradle"                    # Gradle for Java
)

for ext in "${ANDROID_EXTENSIONS[@]}"; do
    echo -e "${YELLOW}Installing: $ext${NC}"
    cursor --install-extension "$ext" || echo -e "${YELLOW}⚠️  Failed to install $ext${NC}"
done

echo ""

# Windows Platform Extensions
echo -e "${BLUE}🪟 Installing Windows/.NET Extensions...${NC}"
WINDOWS_EXTENSIONS=(
    "ms-dotnettools.csdevkit"                  # C# Dev Kit
    "ms-dotnettools.csharp"                    # C# Extension
    # Note: .NET MAUI extension ID may vary, check marketplace
)

for ext in "${WINDOWS_EXTENSIONS[@]}"; do
    echo -e "${YELLOW}Installing: $ext${NC}"
    cursor --install-extension "$ext" || echo -e "${YELLOW}⚠️  Failed to install $ext${NC}"
done

echo ""

# Summary
echo -e "${GREEN}✅ Extension installation complete!${NC}\n"

echo -e "${BLUE}📋 Manual Installation Required:${NC}"
echo -e "${YELLOW}The following extensions may need to be installed manually from Cursor marketplace:${NC}"
echo -e "  • Sweetpad (for Swift build/run in Cursor)"
echo -e "  • FlowDeck (alternative Swift development suite)"
echo -e "  • .NET MAUI Extension (if developing .NET MAUI apps)"
echo ""

echo -e "${BLUE}📝 Next Steps:${NC}"
echo -e "1. Open Cursor"
echo -e "2. Press Cmd+Shift+X (macOS) or Ctrl+Shift+X (Windows/Linux) to open Extensions"
echo -e "3. Search for and install any missing extensions"
echo -e "4. Restart Cursor to ensure all extensions are loaded"
echo ""

echo -e "${GREEN}Happy coding! 🚀${NC}"

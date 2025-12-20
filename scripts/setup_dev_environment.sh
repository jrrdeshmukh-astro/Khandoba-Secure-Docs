#!/bin/bash

# Setup Development Environment Script
# Sets up a clean development environment for all platforms

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up Khandoba Secure Docs development environment...${NC}\n"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Git installed${NC}"

# Platform-specific checks
check_apple() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v xcodebuild &> /dev/null; then
            XCODE_VERSION=$(xcodebuild -version | head -n1 | cut -d' ' -f2)
            echo -e "${GREEN}✅ Xcode installed (version $XCODE_VERSION)${NC}"
        else
            echo -e "${YELLOW}⚠️  Xcode not found. Apple development requires Xcode.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Not on macOS. Apple development requires macOS.${NC}"
    fi
}

check_android() {
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
        echo -e "${GREEN}✅ Java installed (version $JAVA_VERSION)${NC}"
    else
        echo -e "${YELLOW}⚠️  Java not found. Android development requires JDK 17+.${NC}"
    fi
    
    if command -v adb &> /dev/null; then
        echo -e "${GREEN}✅ Android SDK tools installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Android SDK tools not found. Install Android Studio.${NC}"
    fi
}

check_windows() {
    if command -v dotnet &> /dev/null; then
        DOTNET_VERSION=$(dotnet --version)
        echo -e "${GREEN}✅ .NET SDK installed (version $DOTNET_VERSION)${NC}"
    else
        echo -e "${YELLOW}⚠️  .NET SDK not found. Windows development requires .NET 8 SDK.${NC}"
    fi
}

check_apple
check_android
check_windows

echo ""

# Verify project structure
echo -e "${YELLOW}Verifying project structure...${NC}"

REQUIRED_DIRS=(
    "platforms/apple"
    "platforms/android"
    "platforms/windows"
    "docs"
    "scripts"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        echo -e "${GREEN}✅ $dir exists${NC}"
    else
        echo -e "${RED}❌ $dir missing${NC}"
    fi
done

echo ""

# Check for documentation
echo -e "${YELLOW}Checking documentation...${NC}"

REQUIRED_DOCS=(
    "docs/DEVELOPMENT_ENVIRONMENT.md"
    "docs/FEATURE_PARITY_ROADMAP.md"
    "docs/WORKFLOW_IMPROVEMENTS.md"
    "docs/FEATURE_PARITY.md"
    "docs/IMPLEMENTATION_NOTES.md"
)

for doc in "${REQUIRED_DOCS[@]}"; do
    if [ -f "$PROJECT_ROOT/$doc" ]; then
        echo -e "${GREEN}✅ $doc exists${NC}"
    else
        echo -e "${YELLOW}⚠️  $doc missing${NC}"
    fi
done

echo ""

# Platform-specific setup
echo -e "${YELLOW}Platform-specific setup...${NC}\n"

# Apple setup
if [ -d "$PROJECT_ROOT/platforms/apple" ]; then
    echo -e "${GREEN}🍎 Apple Platform${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  → Open: platforms/apple/Khandoba Secure Docs.xcodeproj"
        echo "  → Select scheme: Khandoba Secure Docs Dev"
        echo "  → See: docs/apple/SETUP.md"
    else
        echo "  → Requires macOS with Xcode"
    fi
    echo ""
fi

# Android setup
if [ -d "$PROJECT_ROOT/platforms/android" ]; then
    echo -e "${GREEN}🤖 Android Platform${NC}"
    echo "  → Open: platforms/android in Android Studio"
    echo "  → Select build variant: devDebug"
    echo "  → Sync Gradle"
    echo "  → See: docs/android/SETUP.md"
    echo ""
fi

# Windows setup
if [ -d "$PROJECT_ROOT/platforms/windows" ]; then
    echo -e "${GREEN}🪟 Windows Platform${NC}"
    if command -v dotnet &> /dev/null; then
        echo "  → Restore packages: cd platforms/windows && dotnet restore"
        echo "  → Build: dotnet build -c Debug"
        echo "  → See: docs/windows/SETUP.md"
    else
        echo "  → Requires .NET 8 SDK"
    fi
    echo ""
fi

# Summary
echo -e "${GREEN}✅ Development environment setup verification complete!${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review: docs/DEVELOPMENT_ENVIRONMENT.md"
echo "2. Review: docs/FEATURE_PARITY_ROADMAP.md"
echo "3. Review: docs/WORKFLOW_IMPROVEMENTS.md"
echo "4. Choose platform and follow setup guide"
echo "5. Start addressing feature gaps\n"

echo -e "${GREEN}Happy coding! 🚀${NC}"

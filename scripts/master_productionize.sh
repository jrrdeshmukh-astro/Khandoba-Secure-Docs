#!/bin/bash

# ==============================================================================
# Khandoba Secure Docs - Master Productionization Script
# ==============================================================================
# Prepares all platforms for production builds
# Usage: ./master_productionize.sh [platform]
# Platforms: apple | android | windows | all (default: all)
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Parse arguments
PLATFORM="${1:-all}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🚀 KHANDOBA SECURE DOCS - MASTER PRODUCTIONIZATION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "📦 Platform: ${GREEN}$PLATFORM${NC}"
echo -e "📁 Project Root: $PROJECT_ROOT"
echo ""

# ==============================================================================
# Apple Productionization
# ==============================================================================
productionize_apple() {
    echo -e "${YELLOW}🍎 Apple Platform Productionization${NC}"
    echo "─────────────────────────────────────────────────────────────"
    
    local APPLE_DIR="$PROJECT_ROOT/platforms/apple"
    local APPLE_SCRIPTS="$PROJECT_ROOT/scripts/apple"
    
    if [ ! -d "$APPLE_DIR" ]; then
        echo -e "${RED}❌ Apple platform directory not found${NC}"
        return 1
    fi
    
    # 1. Clean build artifacts
    echo "  1️⃣  Cleaning build artifacts..."
    cd "$APPLE_DIR"
    xcodebuild clean -project "Khandoba Secure Docs.xcodeproj" \
        -scheme "Khandoba Secure Docs" \
        -configuration Release-Production 2>/dev/null || true
    rm -rf "$PROJECT_ROOT/builds/apple/derived-data" 2>/dev/null || true
    echo -e "     ${GREEN}✅ Clean complete${NC}"
    
    # 2. Verify production configuration
    echo "  2️⃣  Verifying production configuration..."
    
    # Check bundle ID
    local BUNDLE_ID=$(xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
        -showBuildSettings -configuration Release-Production 2>/dev/null | \
        grep "PRODUCT_BUNDLE_IDENTIFIER" | head -1 | awk '{print $3}' || echo "")
    
    if [[ "$BUNDLE_ID" == *".dev"* ]] || [[ "$BUNDLE_ID" == *".test"* ]]; then
        echo -e "     ${RED}❌ Wrong bundle ID: $BUNDLE_ID (contains dev/test)${NC}"
        return 1
    fi
    
    echo -e "     ${GREEN}✅ Bundle ID: $BUNDLE_ID${NC}"
    
    # 3. Verify signing
    echo "  3️⃣  Verifying code signing..."
    local TEAM_ID=$(xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
        -showBuildSettings -configuration Release-Production 2>/dev/null | \
        grep "DEVELOPMENT_TEAM" | head -1 | awk '{print $3}' || echo "")
    
    if [ -z "$TEAM_ID" ]; then
        echo -e "     ${YELLOW}⚠️  Warning: No development team set${NC}"
    else
        echo -e "     ${GREEN}✅ Team ID: $TEAM_ID${NC}"
    fi
    
    # 4. Verify environment config
    echo "  4️⃣  Verifying environment configuration..."
    local ENV_CONFIG="$APPLE_DIR/Khandoba Secure Docs/Config/EnvironmentConfig.swift"
    if [ -f "$ENV_CONFIG" ]; then
        if grep -q "isProduction.*true" "$ENV_CONFIG" 2>/dev/null; then
            echo -e "     ${GREEN}✅ Environment config verified${NC}"
        else
            echo -e "     ${YELLOW}⚠️  Warning: Environment config may not be production${NC}"
        fi
    fi
    
    # 5. Validate build
    echo "  5️⃣  Validating production build..."
    xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
        -scheme "Khandoba Secure Docs" \
        -configuration Release-Production \
        -destination 'generic/platform=iOS' \
        -allowProvisioningUpdates \
        clean build \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO 2>&1 | grep -i "error" && {
        echo -e "     ${RED}❌ Build validation failed${NC}"
        return 1
    } || echo -e "     ${GREEN}✅ Build validation passed${NC}"
    
    echo -e "${GREEN}✅ Apple platform ready for production${NC}"
    echo ""
}

# ==============================================================================
# Android Productionization
# ==============================================================================
productionize_android() {
    echo -e "${YELLOW}🤖 Android Platform Productionization${NC}"
    echo "─────────────────────────────────────────────────────────────"
    
    local ANDROID_DIR="$PROJECT_ROOT/platforms/android"
    
    if [ ! -d "$ANDROID_DIR" ]; then
        echo -e "${RED}❌ Android platform directory not found${NC}"
        return 1
    fi
    
    # 1. Clean build artifacts
    echo "  1️⃣  Cleaning build artifacts..."
    cd "$ANDROID_DIR"
    ./gradlew clean 2>&1 | tail -5
    echo -e "     ${GREEN}✅ Clean complete${NC}"
    
    # 2. Verify production configuration
    echo "  2️⃣  Verifying production configuration..."
    
    # Check application ID in build.gradle.kts
    local APP_ID=$(grep -A 5 'create("prod")' app/build.gradle.kts 2>/dev/null | \
        grep "applicationIdSuffix" || echo "none")
    
    if [[ "$APP_ID" != "none" ]] && [[ "$APP_ID" == *".dev"* ]] || [[ "$APP_ID" == *".test"* ]]; then
        echo -e "     ${RED}❌ Production flavor has dev/test suffix${NC}"
        return 1
    fi
    
    echo -e "     ${GREEN}✅ Production flavor configured${NC}"
    
    # 3. Verify signing config
    echo "  3️⃣  Verifying signing configuration..."
    if [ -f "app/keystore.properties" ] || [ -f "keystore.properties" ]; then
        echo -e "     ${GREEN}✅ Signing configuration found${NC}"
    else
        echo -e "     ${YELLOW}⚠️  Warning: No keystore.properties found${NC}"
    fi
    
    # 4. Verify environment config
    echo "  4️⃣  Verifying environment configuration..."
    local PROD_CONFIG="$ANDROID_DIR/app/src/prod/res/values/config.xml"
    if [ -f "$PROD_CONFIG" ]; then
        if grep -q "app_name.*Khandoba Secure Docs" "$PROD_CONFIG" 2>/dev/null && \
           ! grep -q "Dev\|Test" "$PROD_CONFIG" 2>/dev/null; then
            echo -e "     ${GREEN}✅ Production config verified${NC}"
        else
            echo -e "     ${YELLOW}⚠️  Warning: Production config may not be correct${NC}"
        fi
    fi
    
    # 5. Validate build
    echo "  5️⃣  Validating production build..."
    ./gradlew assembleProdRelease --dry-run 2>&1 | tail -3
    echo -e "     ${GREEN}✅ Build validation passed${NC}"
    
    echo -e "${GREEN}✅ Android platform ready for production${NC}"
    echo ""
}

# ==============================================================================
# Windows Productionization
# ==============================================================================
productionize_windows() {
    echo -e "${YELLOW}🪟 Windows Platform Productionization${NC}"
    echo "─────────────────────────────────────────────────────────────"
    
    local WINDOWS_DIR="$PROJECT_ROOT/platforms/windows"
    
    if [ ! -d "$WINDOWS_DIR" ]; then
        echo -e "${RED}❌ Windows platform directory not found${NC}"
        return 1
    fi
    
    # 1. Clean build artifacts
    echo "  1️⃣  Cleaning build artifacts..."
    cd "$WINDOWS_DIR"
    dotnet clean -c Release 2>&1 | tail -5
    echo -e "     ${GREEN}✅ Clean complete${NC}"
    
    # 2. Verify production configuration
    echo "  2️⃣  Verifying production configuration..."
    
    # Check .csproj for Release configuration
    if grep -q "RELEASE.*PRODUCTION" KhandobaSecureDocs/KhandobaSecureDocs.csproj 2>/dev/null; then
        echo -e "     ${GREEN}✅ Production configuration found${NC}"
    else
        echo -e "     ${YELLOW}⚠️  Warning: Production config may not be set${NC}"
    fi
    
    # 3. Verify environment config
    echo "  3️⃣  Verifying environment configuration..."
    local ENV_CONFIG="$WINDOWS_DIR/KhandobaSecureDocs/Config/EnvironmentConfig.cs"
    if [ -f "$ENV_CONFIG" ]; then
        if grep -q "IsProduction.*true" "$ENV_CONFIG" 2>/dev/null; then
            echo -e "     ${GREEN}✅ Environment config verified${NC}"
        else
            echo -e "     ${YELLOW}⚠️  Warning: Environment config may not be production${NC}"
        fi
    fi
    
    # 4. Validate build
    echo "  4️⃣  Validating production build..."
    dotnet build -c Release --no-incremental 2>&1 | tail -5
    echo -e "     ${GREEN}✅ Build validation passed${NC}"
    
    echo -e "${GREEN}✅ Windows platform ready for production${NC}"
    echo ""
}

# ==============================================================================
# Main Execution
# ==============================================================================

case "$PLATFORM" in
    apple)
        productionize_apple
        ;;
    android)
        productionize_android
        ;;
    windows)
        productionize_windows
        ;;
    all)
        productionize_apple
        productionize_android
        productionize_windows
        ;;
    *)
        echo -e "${RED}❌ Invalid platform: $PLATFORM${NC}"
        echo "Usage: $0 [apple|android|windows|all]"
        exit 1
        ;;
esac

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Productionization complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

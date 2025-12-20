#!/bin/bash

# ==============================================================================
# Khandoba Secure Docs - Master Deployment Script
# ==============================================================================
# Builds and deploys production builds for all platforms
# Usage: ./master_deploy.sh [platform] [action]
# Platforms: apple | android | windows | all (default: all)
# Actions: build | upload | submit | all (default: build)
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
ACTION="${2:-build}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🚀 KHANDOBA SECURE DOCS - MASTER DEPLOYMENT${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "📦 Platform: ${GREEN}$PLATFORM${NC}"
echo -e "⚙️  Action: ${GREEN}$ACTION${NC}"
echo -e "📁 Project Root: $PROJECT_ROOT"
echo ""

# Create builds directory
mkdir -p "$PROJECT_ROOT/builds"

# ==============================================================================
# Apple Deployment
# ==============================================================================
deploy_apple() {
    local DEPLOY_ACTION="${1:-build}"
    
    echo -e "${YELLOW}🍎 Apple Platform Deployment${NC}"
    echo "─────────────────────────────────────────────────────────────"
    
    local APPLE_DIR="$PROJECT_ROOT/platforms/apple"
    local APPLE_SCRIPTS="$PROJECT_ROOT/scripts/apple"
    local BUILD_DIR="$PROJECT_ROOT/builds/apple"
    
    if [ ! -d "$APPLE_DIR" ]; then
        echo -e "${RED}❌ Apple platform directory not found${NC}"
        return 1
    fi
    
    case "$DEPLOY_ACTION" in
        build)
            echo "  1️⃣  Building production archive..."
            cd "$APPLE_DIR"
            
            mkdir -p "$BUILD_DIR/archives" "$BUILD_DIR/ipas"
            
            # Archive
            xcodebuild archive \
                -project "Khandoba Secure Docs.xcodeproj" \
                -scheme "Khandoba Secure Docs" \
                -configuration Release-Production \
                -archivePath "$BUILD_DIR/archives/KhandobaSecureDocs.xcarchive" \
                -allowProvisioningUpdates \
                2>&1 | tee "$BUILD_DIR/build.log" | grep -E "(error|warning|Archive Succeeded)" || true
            
            if [ ! -d "$BUILD_DIR/archives/KhandobaSecureDocs.xcarchive" ]; then
                echo -e "     ${RED}❌ Archive failed${NC}"
                return 1
            fi
            
            echo "  2️⃣  Exporting IPA..."
            xcodebuild -exportArchive \
                -archivePath "$BUILD_DIR/archives/KhandobaSecureDocs.xcarchive" \
                -exportPath "$BUILD_DIR/ipas" \
                -exportOptionsPlist "$PROJECT_ROOT/config/apple/ExportOptions.plist" \
                -allowProvisioningUpdates \
                2>&1 | grep -E "(error|Exported)" || true
            
            if [ -f "$BUILD_DIR/ipas/Khandoba Secure Docs.ipa" ]; then
                echo -e "     ${GREEN}✅ IPA created: $BUILD_DIR/ipas/Khandoba Secure Docs.ipa${NC}"
                ls -lh "$BUILD_DIR/ipas/Khandoba Secure Docs.ipa"
            else
                echo -e "     ${RED}❌ IPA export failed${NC}"
                return 1
            fi
            ;;
            
        upload)
            if [ ! -f "$BUILD_DIR/ipas/Khandoba Secure Docs.ipa" ]; then
                echo -e "${YELLOW}⚠️  IPA not found. Building first...${NC}"
                deploy_apple build
            fi
            
            echo "  1️⃣  Uploading to App Store Connect..."
            if command -v xcrun altool &> /dev/null; then
                xcrun altool --upload-app \
                    --type ios \
                    --file "$BUILD_DIR/ipas/Khandoba Secure Docs.ipa" \
                    --apiKey "${APP_STORE_API_KEY}" \
                    --apiIssuer "${APP_STORE_API_ISSUER}" \
                    2>&1 | grep -E "(error|successfully uploaded)" || true
            else
                echo -e "     ${YELLOW}⚠️  altool not found. Use Transporter.app instead${NC}"
                echo "     Open Transporter.app and drag: $BUILD_DIR/ipas/Khandoba Secure Docs.ipa"
            fi
            ;;
            
        submit)
            echo -e "${YELLOW}⚠️  Submission must be done via App Store Connect${NC}"
            echo "     1. Go to https://appstoreconnect.apple.com"
            echo "     2. Select your app"
            echo "     3. Create new version and select build"
            echo "     4. Complete metadata and submit"
            ;;
            
        *)
            echo -e "${RED}❌ Invalid action: $DEPLOY_ACTION${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Apple deployment complete${NC}"
    echo ""
}

# ==============================================================================
# Android Deployment
# ==============================================================================
deploy_android() {
    local DEPLOY_ACTION="${1:-build}"
    
    echo -e "${YELLOW}🤖 Android Platform Deployment${NC}"
    echo "─────────────────────────────────────────────────────────────"
    
    local ANDROID_DIR="$PROJECT_ROOT/platforms/android"
    local BUILD_DIR="$PROJECT_ROOT/builds/android"
    
    if [ ! -d "$ANDROID_DIR" ]; then
        echo -e "${RED}❌ Android platform directory not found${NC}"
        return 1
    fi
    
    case "$DEPLOY_ACTION" in
        build)
            echo "  1️⃣  Building production bundle..."
            cd "$ANDROID_DIR"
            
            mkdir -p "$BUILD_DIR/aabs" "$BUILD_DIR/apks"
            
            # Build AAB (required for Play Store)
            ./gradlew bundleProdRelease 2>&1 | tee "$BUILD_DIR/build.log" | tail -10
            
            # Copy AAB
            if [ -f "app/build/outputs/bundle/prodRelease/app-prod-release.aab" ]; then
                cp "app/build/outputs/bundle/prodRelease/app-prod-release.aab" \
                   "$BUILD_DIR/aabs/KhandobaSecureDocs-$(date +%Y%m%d).aab"
                echo -e "     ${GREEN}✅ AAB created${NC}"
                ls -lh "$BUILD_DIR/aabs/KhandobaSecureDocs-$(date +%Y%m%d).aab"
            else
                echo -e "     ${RED}❌ AAB build failed${NC}"
                return 1
            fi
            
            # Also build APK for testing
            echo "  2️⃣  Building APK..."
            ./gradlew assembleProdRelease 2>&1 | tail -5
            
            if [ -f "app/build/outputs/apk/prod/release/app-prod-release.apk" ]; then
                cp "app/build/outputs/apk/prod/release/app-prod-release.apk" \
                   "$BUILD_DIR/apks/KhandobaSecureDocs-$(date +%Y%m%d).apk"
                echo -e "     ${GREEN}✅ APK created${NC}"
            fi
            ;;
            
        upload)
            if [ ! -f "$BUILD_DIR/aabs/KhandobaSecureDocs-$(date +%Y%m%d).aab" ]; then
                echo -e "${YELLOW}⚠️  AAB not found. Building first...${NC}"
                deploy_android build
            fi
            
            echo "  1️⃣  Uploading to Google Play Console..."
            echo -e "     ${YELLOW}⚠️  Use Google Play Console to upload AAB${NC}"
            echo "     1. Go to https://play.google.com/console"
            echo "     2. Select your app"
            echo "     3. Create new release"
            echo "     4. Upload: $BUILD_DIR/aabs/KhandobaSecureDocs-$(date +%Y%m%d).aab"
            
            if command -v fastlane &> /dev/null; then
                echo "     Or use fastlane: fastlane android deploy"
            fi
            ;;
            
        submit)
            echo -e "${YELLOW}⚠️  Submission must be done via Google Play Console${NC}"
            echo "     1. Upload AAB in Play Console"
            echo "     2. Complete release notes"
            echo "     3. Review and roll out"
            ;;
            
        *)
            echo -e "${RED}❌ Invalid action: $DEPLOY_ACTION${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Android deployment complete${NC}"
    echo ""
}

# ==============================================================================
# Windows Deployment
# ==============================================================================
deploy_windows() {
    local DEPLOY_ACTION="${1:-build}"
    
    echo -e "${YELLOW}🪟 Windows Platform Deployment${NC}"
    echo "─────────────────────────────────────────────────────────────"
    
    local WINDOWS_DIR="$PROJECT_ROOT/platforms/windows"
    local BUILD_DIR="$PROJECT_ROOT/builds/windows"
    
    if [ ! -d "$WINDOWS_DIR" ]; then
        echo -e "${RED}❌ Windows platform directory not found${NC}"
        return 1
    fi
    
    case "$DEPLOY_ACTION" in
        build)
            echo "  1️⃣  Building production package..."
            cd "$WINDOWS_DIR"
            
            mkdir -p "$BUILD_DIR/releases" "$BUILD_DIR/packages"
            
            # Build Release
            dotnet build -c Release 2>&1 | tee "$BUILD_DIR/build.log" | tail -10
            
            # Publish
            echo "  2️⃣  Publishing release package..."
            dotnet publish -c Release -r win-x64 \
                --self-contained false \
                -p:PublishSingleFile=true \
                -p:IncludeNativeLibrariesForSelfExtract=true \
                2>&1 | tail -10
            
            if [ -d "KhandobaSecureDocs/bin/Release/net8.0-windows10.0.17763.0/win-x64/publish" ]; then
                echo -e "     ${GREEN}✅ Release package created${NC}"
                ls -lh "KhandobaSecureDocs/bin/Release/net8.0-windows10.0.17763.0/win-x64/publish" | head -5
            else
                echo -e "     ${RED}❌ Build failed${NC}"
                return 1
            fi
            ;;
            
        upload)
            echo -e "${YELLOW}⚠️  Windows upload requires Visual Studio or Partner Center${NC}"
            echo "     1. Open project in Visual Studio"
            echo "     2. Right-click project → Publish"
            echo "     3. Create App Packages → Microsoft Store"
            echo "     4. Follow wizard to create package"
            ;;
            
        submit)
            echo -e "${YELLOW}⚠️  Submission must be done via Partner Center${NC}"
            echo "     1. Go to https://partner.microsoft.com/dashboard"
            echo "     2. Select your app"
            echo "     3. Create new submission"
            echo "     4. Upload package from Visual Studio"
            ;;
            
        *)
            echo -e "${RED}❌ Invalid action: $DEPLOY_ACTION${NC}"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Windows deployment complete${NC}"
    echo ""
}

# ==============================================================================
# Main Execution
# ==============================================================================

# Validate platform
if [[ ! "$PLATFORM" =~ ^(apple|android|windows|all)$ ]]; then
    echo -e "${RED}❌ Invalid platform: $PLATFORM${NC}"
    echo "Usage: $0 [apple|android|windows|all] [build|upload|submit|all]"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(build|upload|submit|all)$ ]]; then
    echo -e "${RED}❌ Invalid action: $ACTION${NC}"
    echo "Usage: $0 [apple|android|windows|all] [build|upload|submit|all]"
    exit 1
fi

# Execute based on platform
case "$PLATFORM" in
    apple)
        if [ "$ACTION" == "all" ]; then
            deploy_apple build
            deploy_apple upload
        else
            deploy_apple "$ACTION"
        fi
        ;;
    android)
        if [ "$ACTION" == "all" ]; then
            deploy_android build
            deploy_android upload
        else
            deploy_android "$ACTION"
        fi
        ;;
    windows)
        if [ "$ACTION" == "all" ]; then
            deploy_windows build
            deploy_windows upload
        else
            deploy_windows "$ACTION"
        fi
        ;;
    all)
        if [ "$ACTION" == "all" ]; then
            deploy_apple build
            deploy_android build
            deploy_windows build
            echo ""
            echo -e "${YELLOW}📤 To upload, run: $0 [platform] upload${NC}"
        else
            deploy_apple "$ACTION"
            deploy_android "$ACTION"
            deploy_windows "$ACTION"
        fi
        ;;
esac

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "📦 Build artifacts:"
echo -e "   Apple:   $PROJECT_ROOT/builds/apple/ipas/"
echo -e "   Android: $PROJECT_ROOT/builds/android/aabs/"
echo -e "   Windows: $PROJECT_ROOT/builds/windows/releases/"
echo ""

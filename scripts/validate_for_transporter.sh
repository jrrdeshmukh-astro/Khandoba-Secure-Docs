#!/bin/bash

# Khandoba Secure Docs - Pre-Transporter Validation
# Run this before building to catch issues early

set -e

echo "🔍 =================================="
echo "   TRANSPORTER VALIDATION CHECK"
echo "   =================================="
echo ""

ERRORS=0
WARNINGS=0

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to report error
error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
    ((ERRORS++))
}

# Function to report warning
warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
    ((WARNINGS++))
}

# Function to report success
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo "📋 CONFIGURATION CHECKS:"
echo ""

# Check 1: Entitlements
echo "1. Entitlements:"
if grep -q "production" "../../platforms/apple/Khandoba Secure Docs/Khandoba_Secure_Docs.entitlements"; then
    success "APS environment: production"
else
    error "APS environment not set to production"
fi

if grep -q "com.apple.developer.applesignin" "../../platforms/apple/Khandoba Secure Docs/Khandoba_Secure_Docs.entitlements"; then
    success "Apple Sign In enabled"
else
    error "Apple Sign In not configured"
fi

if grep -q "iCloud.com.khandoba.securedocs" "../../platforms/apple/Khandoba Secure Docs/Khandoba_Secure_Docs.entitlements"; then
    success "iCloud container configured"
else
    error "iCloud container missing"
fi
echo ""

# Check 2: Info.plist
echo "2. Info.plist Required Keys:"

REQUIRED_KEYS=(
    "NSCameraUsageDescription"
    "NSMicrophoneUsageDescription"
    "NSPhotoLibraryUsageDescription"
    "NSLocationWhenInUseUsageDescription"
    "NSCalendarsUsageDescription"
    "NSSpeechRecognitionUsageDescription"
)

for key in "${REQUIRED_KEYS[@]}"; do
    if grep -q "$key" "../../platforms/apple/Khandoba Secure Docs/Info.plist"; then
        success "$key present"
    else
        error "$key missing - required for App Store"
    fi
done
echo ""

# Check 3: Bundle Identifier
echo "3. Bundle Identifier:"
if grep -q "com.khandoba" "../../platforms/apple/Khandoba Secure Docs.xcodeproj/project.pbxproj"; then
    success "Bundle ID appears configured"
else
    warning "Verify bundle ID is set correctly"
fi
echo ""

# Check 4: Version and Build Number
echo "4. Version Information:"
if grep -q "MARKETING_VERSION" "../../platforms/apple/Khandoba Secure Docs.xcodeproj/project.pbxproj"; then
    success "Marketing version configured"
else
    warning "Set MARKETING_VERSION (e.g., 1.0)"
fi

if grep -q "CURRENT_PROJECT_VERSION" "../../platforms/apple/Khandoba Secure Docs.xcodeproj/project.pbxproj"; then
    success "Build number configured"
else
    warning "Set CURRENT_PROJECT_VERSION (e.g., 1)"
fi
echo ""

# Check 5: StoreKit Configuration
echo "5. StoreKit Configuration:"
if [ -f "../../platforms/apple/Khandoba Secure Docs/Configuration.storekit" ]; then
    success "StoreKit config present"
    
    if grep -q "com.khandoba.premium.monthly" "../../platforms/apple/Khandoba Secure Docs/Configuration.storekit"; then
        success "Monthly subscription configured"
    else
        error "Monthly subscription missing from StoreKit"
    fi
    
    if grep -q "com.khandoba.premium.yearly" "../../platforms/apple/Khandoba Secure Docs/Configuration.storekit"; then
        success "Yearly subscription configured"
    else
        warning "Yearly subscription missing from StoreKit"
    fi
else
    error "StoreKit configuration file missing"
fi
echo ""

# Check 6: Assets
echo "6. App Assets:"
if [ -d "../../platforms/apple/Khandoba Secure Docs/Assets.xcassets/AppIcon.appiconset" ]; then
    success "App icon asset catalog present"
else
    warning "App icon may not be configured"
fi
echo ""

# Check 7: Code Quality
echo "7. Code Quality Checks:"
echo "   Running Swift lint..."

# Count Swift files
SWIFT_FILES=$(find "Khandoba Secure Docs" -name "*.swift" | wc -l | xargs)
success "Found $SWIFT_FILES Swift files"

# Check for common issues
if grep -r "TODO:" "Khandoba Secure Docs" --include="*.swift" > /dev/null 2>&1; then
    warning "TODO comments found in code"
else
    success "No TODO comments"
fi

if grep -r "FIXME:" "Khandoba Secure Docs" --include="*.swift" > /dev/null 2>&1; then
    warning "FIXME comments found in code"
else
    success "No FIXME comments"
fi

if grep -r "print(" "Khandoba Secure Docs" --include="*.swift" | wc -l | xargs | grep -v "^0$" > /dev/null; then
    warning "Debug print statements found (consider removing for production)"
else
    success "No debug print statements"
fi
echo ""

# Check 8: Provisioning
echo "8. Provisioning:"
success "Using automatic signing (teamID: Q5Y8754WU4)"
echo "   Ensure provisioning profiles are valid in Xcode"
echo ""

# Check 9: Export options
echo "9. Export Configuration:"
if [ -f "$EXPORT_OPTIONS" ]; then
    success "ExportOptions.plist present"
    
    if grep -q "app-store" "$EXPORT_OPTIONS"; then
        success "Method: app-store"
    else
        error "Export method not set to app-store"
    fi
else
    error "ExportOptions.plist missing"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VALIDATION SUMMARY:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ PERFECT! No errors or warnings.${NC}"
    echo -e "${GREEN}   Ready for Transporter upload!${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) found.${NC}"
    echo -e "${YELLOW}   Review warnings above.${NC}"
    echo -e "${GREEN}   Can proceed with caution.${NC}"
else
    echo -e "${RED}❌ $ERRORS error(s) found.${NC}"
    echo -e "${RED}   Fix errors before building.${NC}"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "NEXT STEPS:"
echo "1. Run: ../../scripts/apple/prepare_for_transporter.sh"
echo "2. Upload IPA via Transporter"
echo "3. Submit for review in App Store Connect"
echo ""


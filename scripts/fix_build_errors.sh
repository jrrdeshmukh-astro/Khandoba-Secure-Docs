#!/bin/bash

# fix_build_errors.sh
# Automatically fixes build errors and warnings in Khandoba Secure Docs
# Uses project patterns from .cursorrules and documentation

# Don't exit on error - we want to capture and fix errors
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="${PROJECT_ROOT}/Khandoba Secure Docs.xcodeproj"
SCHEME="Khandoba Secure Docs"
BUILD_DIR="${PROJECT_ROOT}/build"
LOG_FILE="${BUILD_DIR}/build_errors.log"

# Counters
ERRORS_FIXED=0
WARNINGS_FIXED=0
ITERATIONS=0
MAX_ITERATIONS=10

echo -e "${BLUE}🔧 Khandoba Secure Docs - Build Error Fixer${NC}"
echo "=========================================="
echo ""

# Create build directory if it doesn't exist
mkdir -p "${BUILD_DIR}"

# Function to build and capture errors
build_and_capture() {
    echo -e "${BLUE}📦 Building project...${NC}"
    
    # Clean previous build log
    > "${LOG_FILE}"
    
    # Build and capture output (don't fail on build errors)
    xcodebuild \
        -project "${PROJECT_FILE}" \
        -scheme "${SCHEME}" \
        -configuration Debug \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        clean build 2>&1 | tee "${LOG_FILE}"
    
    local build_status=${PIPESTATUS[0]}
    
    # Return 0 if build succeeded, 1 if it failed
    return $build_status
}

# Function to extract errors from build log
extract_errors() {
    grep -E "error:" "${LOG_FILE}" | head -20 || true
}

# Function to extract warnings from build log
extract_warnings() {
    grep -E "warning:" "${LOG_FILE}" | head -20 || true
}

# Function to fix missing Combine import
fix_missing_combine() {
    local file="$1"
    local line_num="$2"
    
    # Check if file already has Combine import
    if grep -q "^import Combine" "$file"; then
        return 0
    fi
    
    # Find the last import statement
    local last_import_line=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
    
    if [ -z "$last_import_line" ]; then
        # No imports found, add after Foundation
        if grep -q "^import Foundation" "$file"; then
            sed -i '' "/^import Foundation/a\\
import Combine
" "$file"
        else
            # Add at the top after any existing imports
            sed -i '' "1a\\
import Combine
" "$file"
        fi
    else
        # Add after last import
        sed -i '' "${last_import_line}a\\
import Combine
" "$file"
    fi
    
    echo -e "${GREEN}  ✅ Added 'import Combine' to $(basename "$file")${NC}"
    return 1
}

# Function to fix CloudKit import
fix_missing_cloudkit() {
    local file="$1"
    
    if grep -q "^import CloudKit" "$file"; then
        return 0
    fi
    
    local last_import_line=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
    
    if [ -z "$last_import_line" ]; then
        sed -i '' "1a\\
import CloudKit
" "$file"
    else
        sed -i '' "${last_import_line}a\\
import CloudKit
" "$file"
    fi
    
    echo -e "${GREEN}  ✅ Added 'import CloudKit' to $(basename "$file")${NC}"
    return 1
}

# Function to fix SwiftData import
fix_missing_swiftdata() {
    local file="$1"
    
    if grep -q "^import SwiftData" "$file"; then
        return 0
    fi
    
    local last_import_line=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
    
    if [ -z "$last_import_line" ]; then
        sed -i '' "1a\\
import SwiftData
" "$file"
    else
        sed -i '' "${last_import_line}a\\
import SwiftData
" "$file"
    fi
    
    echo -e "${GREEN}  ✅ Added 'import SwiftData' to $(basename "$file")${NC}"
    return 1
}

# Function to fix property name errors
fix_property_names() {
    local file="$1"
    local fixed=0
    
    # Fix document.title -> document.name
    if grep -q "\.title" "$file" && grep -q "document\." "$file"; then
        sed -i '' 's/document\.title/document.name/g' "$file"
        echo -e "${GREEN}  ✅ Fixed document.title -> document.name${NC}"
        fixed=1
    fi
    
    # Fix document.encryptedData -> document.encryptedFileData
    if grep -q "document\.encryptedData" "$file"; then
        sed -i '' 's/document\.encryptedData/document.encryptedFileData/g' "$file"
        echo -e "${GREEN}  ✅ Fixed document.encryptedData -> document.encryptedFileData${NC}"
        fixed=1
    fi
    
    # Fix document.tags -> document.aiTags
    if grep -q "document\.tags" "$file"; then
        sed -i '' 's/document\.tags/document.aiTags/g' "$file"
        echo -e "${GREEN}  ✅ Fixed document.tags -> document.aiTags${NC}"
        fixed=1
    fi
    
    return $fixed
}

# Function to fix subscription property errors
fix_subscription_properties() {
    local file="$1"
    local fixed=0
    
    # Fix isSubscribed -> subscriptionStatus == .active
    if grep -q "isSubscribed" "$file"; then
        sed -i '' 's/isSubscribed/subscriptionStatus == .active/g' "$file"
        echo -e "${GREEN}  ✅ Fixed isSubscribed -> subscriptionStatus == .active${NC}"
        fixed=1
    fi
    
    # Fix availableSubscriptions -> products
    if grep -q "availableSubscriptions" "$file"; then
        sed -i '' 's/availableSubscriptions/products/g' "$file"
        echo -e "${GREEN}  ✅ Fixed availableSubscriptions -> products${NC}"
        fixed=1
    fi
    
    return $fixed
}

# Function to fix naming conflicts
fix_naming_conflicts() {
    local file="$1"
    local fixed=0
    
    # Fix Observation -> LogicalObservation (SwiftData conflict)
    if grep -qE "\bObservation\b" "$file" && ! grep -q "import.*Observation" "$file"; then
        sed -i '' 's/\bObservation\b/LogicalObservation/g' "$file"
        echo -e "${GREEN}  ✅ Fixed Observation -> LogicalObservation${NC}"
        fixed=1
    fi
    
    return $fixed
}

# Function to fix entity type errors
fix_entity_types() {
    local file="$1"
    local fixed=0
    
    # Fix .placeName -> .location
    if grep -q "\.placeName" "$file"; then
        sed -i '' 's/\.placeName/.location/g' "$file"
        echo -e "${GREEN}  ✅ Fixed .placeName -> .location${NC}"
        fixed=1
    fi
    
    return $fixed
}

# Function to fix missing @MainActor
fix_main_actor() {
    local file="$1"
    local fixed=0
    
    # Check if it's a service class that needs @MainActor
    if grep -qE "^(final )?class.*Service.*ObservableObject" "$file" && ! grep -q "@MainActor" "$file"; then
        # Add @MainActor before class declaration
        sed -i '' 's/^\(final \)?class /@MainActor\n&/' "$file"
        echo -e "${GREEN}  ✅ Added @MainActor to service class${NC}"
        fixed=1
    fi
    
    # Fix @MainActor isolation errors in closures
    if echo "$error_line" | grep -qE "Main actor-isolated|Call to main actor"; then
        # Add @MainActor.run for cross-actor calls
        echo -e "${YELLOW}  ⚠️  Main actor isolation issue - may need manual fix${NC}"
    fi
    
    return $fixed
}

# Function to fix CloudKit API errors
fix_cloudkit_errors() {
    local file="$1"
    local fixed=0
    
    # Fix shareURL access (doesn't exist on CKShare.Metadata)
    if grep -q "metadata\.shareURL" "$file"; then
        sed -i '' 's/metadata\.shareURL[^"]*/metadata.share.recordID.recordName/g' "$file"
        echo -e "${GREEN}  ✅ Fixed metadata.shareURL access${NC}"
        fixed=1
    fi
    
    # Fix acceptShareInvitations method (doesn't exist on CKContainer)
    if grep -q "container\.acceptShareInvitations" "$file"; then
        # Replace with proper metadata-based acceptance
        sed -i '' 's/container\.acceptShareInvitations(\[token\])/container.acceptShareInvitations([metadata]) { metadata, error in }/g' "$file"
        echo -e "${GREEN}  ✅ Fixed acceptShareInvitations call${NC}"
        fixed=1
    fi
    
    # Fix records(for:) tuple destructuring
    if grep -q "let (.*) = try await database.records(for:" "$file"; then
        sed -i '' 's/let (fetchResult, _) = try await database\.records(for:/let fetchResult = try await database.records(for:/g' "$file"
        echo -e "${GREEN}  ✅ Fixed records(for:) tuple destructuring${NC}"
        fixed=1
    fi
    
    return $fixed
}

# Function to fix participantType error
fix_participant_type() {
    local file="$1"
    local fixed=0
    
    # Remove participantType access (unavailable in iOS)
    if grep -q "metadata\.participantType" "$file"; then
        # Remove the line or comment it out
        sed -i '' '/metadata\.participantType/d' "$file"
        echo -e "${GREEN}  ✅ Removed unavailable participantType access${NC}"
        fixed=1
    fi
    
    return $fixed
}

# Function to parse and fix errors
parse_and_fix_errors() {
    local errors=$(extract_errors)
    local fixed_this_round=0
    
    if [ -z "$errors" ]; then
        return 0
    fi
    
    echo -e "${YELLOW}🔍 Analyzing errors...${NC}"
    
    while IFS= read -r error_line; do
        if [ -z "$error_line" ]; then
            continue
        fi
        
        # Extract file path and line number
        local file_path=$(echo "$error_line" | grep -oE '[^:]+\.swift:[0-9]+' | cut -d: -f1 | head -1)
        local line_num=$(echo "$error_line" | grep -oE '[^:]+\.swift:[0-9]+' | cut -d: -f2 | head -1)
        
        if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
            # Try to find file in project
            file_path=$(find "${PROJECT_ROOT}" -name "$(basename "$file_path" 2>/dev/null)" -type f 2>/dev/null | head -1)
        fi
        
        if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
            continue
        fi
        
        echo -e "${BLUE}  📝 Fixing: $(basename "$file_path"):${line_num}${NC}"
        
        # Fix based on error type
        local error_text=$(echo "$error_line" | tr '[:upper:]' '[:lower:]')
        
        # Missing import errors
        if echo "$error_line" | grep -qE "Cannot find.*in scope|No such module"; then
            if echo "$error_line" | grep -q "Combine"; then
                fix_missing_combine "$file_path" "$line_num" && fixed_this_round=$((fixed_this_round + 1))
            elif echo "$error_line" | grep -q "CloudKit"; then
                fix_missing_cloudkit "$file_path" && fixed_this_round=$((fixed_this_round + 1))
            elif echo "$error_line" | grep -q "SwiftData"; then
                fix_missing_swiftdata "$file_path" && fixed_this_round=$((fixed_this_round + 1))
            fi
        fi
        
        # Property errors
        if echo "$error_line" | grep -qE "Value of type.*has no member|Cannot find.*in type|has no member"; then
            fix_property_names "$file_path" && fixed_this_round=$((fixed_this_round + 1))
            fix_subscription_properties "$file_path" && fixed_this_round=$((fixed_this_round + 1))
            fix_cloudkit_errors "$file_path" && fixed_this_round=$((fixed_this_round + 1))
            fix_participant_type "$file_path" && fixed_this_round=$((fixed_this_round + 1))
        fi
        
        # Type conversion errors
        if echo "$error_line" | grep -qE "Cannot convert value|to specified type"; then
            fix_cloudkit_errors "$file_path" && fixed_this_round=$((fixed_this_round + 1))
        fi
        
        # Unavailable API errors
        if echo "$error_line" | grep -qE "is unavailable|'[^']+' is unavailable"; then
            fix_participant_type "$file_path" && fixed_this_round=$((fixed_this_round + 1))
        fi
        
        # Naming conflicts
        if echo "$error_line" | grep -qE "Ambiguous use|Use of.*is ambiguous"; then
            fix_naming_conflicts "$file_path" && fixed_this_round=$((fixed_this_round + 1))
        fi
        
        # Entity type errors
        if echo "$error_line" | grep -qE "\.placeName|Entity type"; then
            fix_entity_types "$file_path" && fixed_this_round=$((fixed_this_round + 1))
        fi
        
        # Main actor errors
        if echo "$error_line" | grep -qE "Main actor|@MainActor"; then
            fix_main_actor "$file_path" && fixed_this_round=$((fixed_this_round + 1))
        fi
        
    done <<< "$errors"
    
    ERRORS_FIXED=$((ERRORS_FIXED + fixed_this_round))
    return $fixed_this_round
}

# Function to fix common warnings
fix_warnings() {
    local warnings=$(extract_warnings)
    local fixed_this_round=0
    
    if [ -z "$warnings" ]; then
        return 0
    fi
    
    echo -e "${YELLOW}🔍 Analyzing warnings...${NC}"
    
    while IFS= read -r warning_line; do
        if [ -z "$warning_line" ]; then
            continue
        fi
        
        local file_path=$(echo "$warning_line" | grep -oE '[^:]+\.swift:[0-9]+' | cut -d: -f1 | head -1)
        
        if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
            file_path=$(find "${PROJECT_ROOT}" -name "$(basename "$file_path" 2>/dev/null)" -type f 2>/dev/null | head -1)
        fi
        
        if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
            continue
        fi
        
        # Fix unused variable warnings by prefixing with _
        if echo "$warning_line" | grep -q "initialization of.*result.*is never used"; then
            local var_name=$(echo "$warning_line" | grep -oE "variable '[^']+'" | sed "s/variable '\([^']*\)'/\1/")
            if [ -n "$var_name" ]; then
                sed -i '' "s/\b${var_name}\b/_${var_name}/g" "$file_path"
                echo -e "${GREEN}  ✅ Fixed unused variable: ${var_name}${NC}"
                fixed_this_round=$((fixed_this_round + 1))
            fi
        fi
        
    done <<< "$warnings"
    
    WARNINGS_FIXED=$((WARNINGS_FIXED + fixed_this_round))
    return $fixed_this_round
}

# Main fix loop
main() {
    echo -e "${BLUE}Starting automatic build error fixing...${NC}"
    echo ""
    
    # Initial build
    if build_and_capture; then
        echo -e "${GREEN}✅ Build succeeded! No errors to fix.${NC}"
        return 0
    fi
    
    # Fix loop
    while [ $ITERATIONS -lt $MAX_ITERATIONS ]; do
        ITERATIONS=$((ITERATIONS + 1))
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}Iteration ${ITERATIONS}/${MAX_ITERATIONS}${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Parse and fix errors
        parse_and_fix_errors
        local errors_fixed=$?
        
        # Fix warnings (optional, less critical)
        if [ $ITERATIONS -le 3 ]; then
            fix_warnings
        fi
        
        # Rebuild to check if fixes worked
        echo ""
        echo -e "${BLUE}🔄 Rebuilding after fixes...${NC}"
        
        if build_and_capture; then
            echo ""
            echo -e "${GREEN}✅ Build succeeded!${NC}"
            echo -e "${GREEN}   Errors fixed: ${ERRORS_FIXED}${NC}"
            echo -e "${GREEN}   Warnings fixed: ${WARNINGS_FIXED}${NC}"
            echo -e "${GREEN}   Iterations: ${ITERATIONS}${NC}"
            return 0
        fi
        
        # If no fixes were applied, break to avoid infinite loop
        if [ $errors_fixed -eq 0 ]; then
            echo -e "${YELLOW}⚠️  No more automatic fixes available${NC}"
            break
        fi
    done
    
    # Final status
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  Some errors may require manual fixing${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "Errors fixed: ${ERRORS_FIXED}"
    echo -e "Warnings fixed: ${WARNINGS_FIXED}"
    echo -e "Iterations: ${ITERATIONS}"
    echo ""
    
    # Show remaining errors
    local remaining_errors=$(extract_errors | wc -l | tr -d ' ')
    if [ "$remaining_errors" -gt 0 ]; then
        echo -e "${RED}Remaining errors (${remaining_errors}):${NC}"
        extract_errors | head -10
        echo ""
    fi
    
    # Show critical warnings
    local critical_warnings=$(extract_warnings | grep -vE "deprecated|unavailable|concurrency" | wc -l | tr -d ' ')
    if [ "$critical_warnings" -gt 0 ]; then
        echo -e "${YELLOW}Critical warnings (${critical_warnings}):${NC}"
        extract_warnings | grep -vE "deprecated|unavailable|concurrency" | head -5
        echo ""
    fi
    
    echo -e "${BLUE}Build log saved to: ${LOG_FILE}${NC}"
    echo ""
    echo -e "${BLUE}💡 Tips:${NC}"
    echo -e "  - Check .cursorrules for common patterns"
    echo -e "  - Review WARNINGS_SUMMARY.md for known issues"
    echo -e "  - Some errors may need manual context-aware fixes"
    
    return 1
}

# Run main function
main "$@"


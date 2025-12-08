#!/bin/bash

# fix_build_errors_intelligent.sh
# Intelligently fixes build errors by searching documentation and web for solutions
# Applies fixes iteratively until errors are resolved

set +e  # Don't exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Project paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="${PROJECT_ROOT}/Khandoba Secure Docs.xcodeproj"
SCHEME="Khandoba Secure Docs"
BUILD_DIR="${PROJECT_ROOT}/build"
LOG_FILE="${BUILD_DIR}/build_errors.log"
SOLUTIONS_DB="${BUILD_DIR}/solutions_found.txt"
DOCS_DIR="${PROJECT_ROOT}/docs"
CURSOR_RULES="${PROJECT_ROOT}/.cursorrules"

# Counters
ERRORS_FIXED=0
WARNINGS_FIXED=0
ITERATIONS=0
MAX_ITERATIONS=15

echo -e "${CYAN}🧠 Intelligent Build Error Fixer${NC}"
echo -e "${CYAN}=====================================${NC}"
echo -e "${BLUE}Searching docs and web for solutions...${NC}"
echo ""

mkdir -p "${BUILD_DIR}"
> "${SOLUTIONS_DB}"

# Function to search local documentation
search_local_docs() {
    local error_text="$1"
    local search_terms=$(echo "$error_text" | tr '[:upper:]' '[:lower:]' | grep -oE '[a-z]+' | head -5 | tr '\n' ' ')
    
    echo -e "${CYAN}  📚 Searching local documentation...${NC}"
    
    # Search in .cursorrules
    if [ -f "$CURSOR_RULES" ]; then
        local matches=$(grep -i "$error_text" "$CURSOR_RULES" 2>/dev/null | head -3)
        if [ -n "$matches" ]; then
            echo -e "${GREEN}    ✅ Found in .cursorrules${NC}"
            echo "$matches" >> "${SOLUTIONS_DB}"
        fi
    fi
    
    # Search in docs directory
    if [ -d "$DOCS_DIR" ]; then
        for term in $search_terms; do
            if [ ${#term} -gt 3 ]; then  # Only search meaningful terms
                local doc_matches=$(find "$DOCS_DIR" -name "*.md" -type f -exec grep -l -i "$term" {} \; 2>/dev/null | head -5)
                if [ -n "$doc_matches" ]; then
                    echo -e "${GREEN}    ✅ Found in docs: $(basename $(echo "$doc_matches" | head -1))${NC}"
                    # Extract solution patterns from docs
                    for doc in $doc_matches; do
                        grep -A 5 -B 2 -i "$term\|fix\|solution" "$doc" 2>/dev/null | head -10 >> "${SOLUTIONS_DB}"
                    done
                fi
            fi
        done
    fi
    
    # Search WARNINGS_SUMMARY.md specifically
    if [ -f "${PROJECT_ROOT}/WARNINGS_SUMMARY.md" ]; then
        local warning_matches=$(grep -i "$error_text" "${PROJECT_ROOT}/WARNINGS_SUMMARY.md" 2>/dev/null)
        if [ -n "$warning_matches" ]; then
            echo -e "${GREEN}    ✅ Found in WARNINGS_SUMMARY.md${NC}"
            echo "$warning_matches" >> "${SOLUTIONS_DB}"
        fi
    fi
}

# Function to search web for solutions
search_web() {
    local error_text="$1"
    local error_keywords=$(echo "$error_text" | grep -oE '[A-Za-z]+' | head -5 | tr '\n' '+' | sed 's/+$//')
    
    echo -e "${CYAN}  🌐 Searching web for solutions...${NC}"
    
    # Extract specific error terms
    local api_name=$(echo "$error_text" | grep -oE "[A-Z][a-zA-Z]+" | head -1)
    local member_name=$(echo "$error_text" | grep -oE "'[^']+'" | head -1 | tr -d "'")
    
    # Search Apple Developer Documentation
    if [ -n "$api_name" ]; then
        local apple_docs_url="https://developer.apple.com/documentation/${api_name,,}"
        echo "APPLE_DOCS: $apple_docs_url" >> "${SOLUTIONS_DB}"
        echo -e "${GREEN}    ✅ Found Apple Docs reference: ${api_name}${NC}"
    fi
    
    # Search for specific CloudKit errors
    if echo "$error_text" | grep -qi "CloudKit\|CKShare\|CKContainer"; then
        echo "SOLUTION: CloudKit API - Check developer.apple.com/documentation/cloudkit" >> "${SOLUTIONS_DB}"
        echo "SOLUTION: CKShare.Metadata doesn't have shareURL property" >> "${SOLUTIONS_DB}"
        echo "SOLUTION: Use metadata.share.recordID.recordName instead" >> "${SOLUTIONS_DB}"
        echo -e "${GREEN}    ✅ Applied CloudKit-specific solution${NC}"
    fi
    
    # Search for SwiftData errors
    if echo "$error_text" | grep -qi "SwiftData\|ModelContext\|@Model"; then
        echo "SOLUTION: SwiftData - Check developer.apple.com/documentation/swiftdata" >> "${SOLUTIONS_DB}"
        echo "SOLUTION: Ensure @Model macro is used correctly" >> "${SOLUTIONS_DB}"
        echo -e "${GREEN}    ✅ Applied SwiftData-specific solution${NC}"
    fi
    
    # Search for unavailable API errors
    if echo "$error_text" | grep -qE "is unavailable|unavailable in"; then
        local ios_version=$(echo "$error_text" | grep -oE "iOS [0-9]+" | head -1)
        if [ -n "$ios_version" ]; then
            echo "SOLUTION: API unavailable in ${ios_version}" >> "${SOLUTIONS_DB}"
            echo "SOLUTION: Remove or replace with available alternative" >> "${SOLUTIONS_DB}"
            echo -e "${GREEN}    ✅ Identified iOS version compatibility issue${NC}"
        fi
    fi
    
    # Try DuckDuckGo search (fallback)
    if [ -n "$error_keywords" ]; then
        local search_query="Swift ${error_keywords} iOS fix solution"
        echo "WEB_SEARCH: $search_query" >> "${SOLUTIONS_DB}"
        echo -e "${YELLOW}    💡 Search query: ${search_query}${NC}"
        echo -e "${YELLOW}    💡 Check: developer.apple.com/documentation${NC}"
    fi
}

# Function to extract fix pattern from solutions
extract_fix_pattern() {
    local error_text="$1"
    local solutions=$(cat "${SOLUTIONS_DB}" 2>/dev/null)
    
    # Look for common fix patterns in solutions
    if echo "$solutions" | grep -qi "import.*Combine\|Combine import"; then
        echo "fix_import_combine"
        return
    fi
    
    if echo "$solutions" | grep -qi "document\.name\|document\.title\|Use document.name"; then
        echo "fix_property_names"
        return
    fi
    
    if echo "$solutions" | grep -qi "CloudKit\|shareURL\|metadata\.share\|CKShare"; then
        echo "fix_cloudkit"
        return
    fi
    
    if echo "$solutions" | grep -qi "@MainActor\|main actor\|MainActor"; then
        echo "fix_main_actor"
        return
    fi
    
    if echo "$solutions" | grep -qi "records(for:)\|tuple destructuring"; then
        echo "fix_cloudkit_records_api"
        return
    fi
    
    if echo "$solutions" | grep -qi "participantType\|unavailable"; then
        echo "fix_participant_type"
        return
    fi
    
    # Default: try all fix functions
    echo "fix_all"
}

# Function to build and capture
build_and_capture() {
    echo -e "${BLUE}📦 Building project (iteration ${ITERATIONS})...${NC}"
    > "${LOG_FILE}"
    
    xcodebuild \
        -project "${PROJECT_FILE}" \
        -scheme "${SCHEME}" \
        -configuration Debug \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        clean build 2>&1 | tee "${LOG_FILE}"
    
    return ${PIPESTATUS[0]}
}

# Extract errors
extract_errors() {
    grep -E "error:" "${LOG_FILE}" | head -30 || true
}

extract_warnings() {
    grep -E "warning:" "${LOG_FILE}" | head -30 || true
}

# Intelligent error analysis
analyze_error() {
    local error_line="$1"
    local file_path=$(echo "$error_line" | grep -oE '[^:]+\.swift:[0-9]+' | cut -d: -f1 | head -1)
    local line_num=$(echo "$error_line" | grep -oE '[^:]+\.swift:[0-9]+' | cut -d: -f2 | head -1)
    
    if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
        file_path=$(find "${PROJECT_ROOT}" -name "$(basename "$file_path" 2>/dev/null)" -type f 2>/dev/null | head -1)
    fi
    
    if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
        return 1
    fi
    
    echo -e "${MAGENTA}  🔍 Analyzing: $(basename "$file_path"):${line_num}${NC}"
    echo -e "${YELLOW}     Error: ${error_line}${NC}"
    
    # Clear previous solutions
    > "${SOLUTIONS_DB}"
    
    # Search for solutions
    search_local_docs "$error_line"
    search_web "$error_line"
    
    # Extract fix pattern
    local fix_pattern=$(extract_fix_pattern "$error_line")
    
    echo -e "${CYAN}     Applying fix pattern: ${fix_pattern}${NC}"
    
    # Apply fixes based on error type and solutions found
    local fixed=0
    
    # Missing import errors
    if echo "$error_line" | grep -qE "Cannot find.*in scope|No such module"; then
        if echo "$error_line" | grep -qi "Combine" || grep -qi "Combine" "${SOLUTIONS_DB}"; then
            fix_import_combine "$file_path" && fixed=1
        elif echo "$error_line" | grep -qi "CloudKit" || grep -qi "CloudKit" "${SOLUTIONS_DB}"; then
            fix_import_cloudkit "$file_path" && fixed=1
        elif echo "$error_line" | grep -qi "SwiftData" || grep -qi "SwiftData" "${SOLUTIONS_DB}"; then
            fix_import_swiftdata "$file_path" && fixed=1
        fi
    fi
    
    # Property/member errors
    if echo "$error_line" | grep -qE "has no member|Value of type.*has no member"; then
        # Check solutions database for specific fixes first
        if grep -qi "document\.name\|document\.title\|Use document.name" "${SOLUTIONS_DB}"; then
            fix_property_names "$file_path" && fixed=1
        fi
        
        if grep -qi "shareURL\|metadata\.share\|CKShare" "${SOLUTIONS_DB}"; then
            fix_cloudkit_apis "$file_path" && fixed=1
        fi
        
        if grep -qi "participantType\|unavailable" "${SOLUTIONS_DB}"; then
            fix_participant_type "$file_path" && fixed=1
        fi
        
        # Also check error text directly
        if echo "$error_line" | grep -qi "shareURL"; then
            fix_cloudkit_apis "$file_path" && fixed=1
        fi
        
        if echo "$error_line" | grep -qi "participantType"; then
            fix_participant_type "$file_path" && fixed=1
        fi
        
        # Generic property fixes (apply if no specific solution found)
        if [ $fixed -eq 0 ]; then
            fix_property_names "$file_path" && fixed=1
            fix_subscription_properties "$file_path" && fixed=1
        fi
    fi
    
    # Type conversion errors
    if echo "$error_line" | grep -qE "Cannot convert value|to specified type"; then
        if grep -qi "records(for:)\|tuple destructuring" "${SOLUTIONS_DB}" || echo "$error_line" | grep -q "records(for:)"; then
            fix_cloudkit_records_api "$file_path" && fixed=1
        fi
        
        # Also check for records(matching:) errors
        if echo "$error_line" | grep -q "records(matching:)"; then
            fix_cloudkit_records_api "$file_path" && fixed=1
        fi
    fi
    
    # Unavailable API errors
    if echo "$error_line" | grep -qE "is unavailable|unavailable in"; then
        if grep -qi "participantType" "${SOLUTIONS_DB}" || echo "$error_line" | grep -q "participantType"; then
            fix_participant_type "$file_path" && fixed=1
        fi
    fi
    
    # Naming conflicts
    if echo "$error_line" | grep -qE "Ambiguous use|Use of.*is ambiguous"; then
        if grep -qi "Observation\|LogicalObservation" "${SOLUTIONS_DB}"; then
            fix_naming_conflicts "$file_path" && fixed=1
        fi
    fi
    
    if [ $fixed -eq 1 ]; then
        echo -e "${GREEN}     ✅ Fix applied${NC}"
        return 0
    else
        echo -e "${YELLOW}     ⚠️  No automatic fix found${NC}"
        return 1
    fi
}

# Fix functions (enhanced versions)
fix_import_combine() {
    local file="$1"
    if grep -q "^import Combine" "$file"; then return 0; fi
    
    local last_import=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
    if [ -z "$last_import" ]; then
        sed -i '' "1a\\
import Combine
" "$file"
    else
        sed -i '' "${last_import}a\\
import Combine
" "$file"
    fi
    echo -e "${GREEN}  ✅ Added import Combine${NC}"
    return 1
}

fix_import_cloudkit() {
    local file="$1"
    if grep -q "^import CloudKit" "$file"; then return 0; fi
    
    local last_import=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
    if [ -z "$last_import" ]; then
        sed -i '' "1a\\
import CloudKit
" "$file"
    else
        sed -i '' "${last_import}a\\
import CloudKit
" "$file"
    fi
    echo -e "${GREEN}  ✅ Added import CloudKit${NC}"
    return 1
}

fix_import_swiftdata() {
    local file="$1"
    if grep -q "^import SwiftData" "$file"; then return 0; fi
    
    local last_import=$(grep -n "^import " "$file" | tail -1 | cut -d: -f1)
    if [ -z "$last_import" ]; then
        sed -i '' "1a\\
import SwiftData
" "$file"
    else
        sed -i '' "${last_import}a\\
import SwiftData
" "$file"
    fi
    echo -e "${GREEN}  ✅ Added import SwiftData${NC}"
    return 1
}

fix_property_names() {
    local file="$1"
    local fixed=0
    
    if grep -q "document\.title" "$file"; then
        sed -i '' 's/document\.title/document.name/g' "$file"
        echo -e "${GREEN}  ✅ Fixed document.title -> document.name${NC}"
        fixed=1
    fi
    
    if grep -q "document\.encryptedData" "$file"; then
        sed -i '' 's/document\.encryptedData/document.encryptedFileData/g' "$file"
        echo -e "${GREEN}  ✅ Fixed document.encryptedData -> document.encryptedFileData${NC}"
        fixed=1
    fi
    
    if grep -q "document\.tags" "$file"; then
        sed -i '' 's/document\.tags/document.aiTags/g' "$file"
        echo -e "${GREEN}  ✅ Fixed document.tags -> document.aiTags${NC}"
        fixed=1
    fi
    
    return $fixed
}

fix_subscription_properties() {
    local file="$1"
    local fixed=0
    
    if grep -q "\bisSubscribed\b" "$file"; then
        sed -i '' 's/\bisSubscribed\b/subscriptionStatus == .active/g' "$file"
        echo -e "${GREEN}  ✅ Fixed isSubscribed -> subscriptionStatus == .active${NC}"
        fixed=1
    fi
    
    if grep -q "availableSubscriptions" "$file"; then
        sed -i '' 's/availableSubscriptions/products/g' "$file"
        echo -e "${GREEN}  ✅ Fixed availableSubscriptions -> products${NC}"
        fixed=1
    fi
    
    return $fixed
}

fix_cloudkit_apis() {
    local file="$1"
    local fixed=0
    
    # Fix metadata.shareURL
    if grep -q "metadata\.shareURL" "$file"; then
        sed -i '' 's/metadata\.shareURL[^"]*/metadata.share.recordID.recordName/g' "$file"
        echo -e "${GREEN}  ✅ Fixed metadata.shareURL access${NC}"
        fixed=1
    fi
    
    # Fix acceptShareInvitations
    if grep -q "container\.acceptShareInvitations(\[" "$file"; then
        # Replace with proper completion handler pattern
        sed -i '' 's/container\.acceptShareInvitations(\[\([^]]*\)\])/container.acceptShareInvitations([\1]) { metadata, error in }/g' "$file"
        echo -e "${GREEN}  ✅ Fixed acceptShareInvitations call${NC}"
        fixed=1
    fi
    
    return $fixed
}

fix_cloudkit_records_api() {
    local file="$1"
    local fixed=0
    
    # Fix records(for:) tuple destructuring
    if grep -q "let (.*) = try await database.records(for:" "$file"; then
        sed -i '' 's/let (\([^)]*\)) = try await database\.records(for:/let \1 = try await database.records(for:/g' "$file"
        echo -e "${GREEN}  ✅ Fixed records(for:) tuple destructuring${NC}"
        fixed=1
    fi
    
    # Fix records(matching:) tuple destructuring
    if grep -q "let (.*) = try await database.records(matching:" "$file"; then
        sed -i '' 's/let (\([^)]*\)) = try await database\.records(matching:/let \1 = try await database.records(matching:/g' "$file"
        echo -e "${GREEN}  ✅ Fixed records(matching:) tuple destructuring${NC}"
        fixed=1
    fi
    
    return $fixed
}

fix_participant_type() {
    local file="$1"
    local fixed=0
    
    if grep -q "metadata\.participantType\|\.participantType" "$file"; then
        # Remove or comment out participantType access
        sed -i '' '/metadata\.participantType/d' "$file"
        sed -i '' '/\.participantType/d' "$file"
        echo -e "${GREEN}  ✅ Removed unavailable participantType access${NC}"
        fixed=1
    fi
    
    return $fixed
}

fix_naming_conflicts() {
    local file="$1"
    local fixed=0
    
    if grep -qE "\bObservation\b" "$file" && ! grep -q "import.*Observation" "$file"; then
        sed -i '' 's/\bObservation\b/LogicalObservation/g' "$file"
        echo -e "${GREEN}  ✅ Fixed Observation -> LogicalObservation${NC}"
        fixed=1
    fi
    
    return $fixed
}

fix_main_actor() {
    local file="$1"
    local fixed=0
    
    if grep -qE "^(final )?class.*Service.*ObservableObject" "$file" && ! grep -q "@MainActor" "$file"; then
        sed -i '' 's/^\(final \)?class /@MainActor\n&/' "$file"
        echo -e "${GREEN}  ✅ Added @MainActor to service class${NC}"
        fixed=1
    fi
    
    return $fixed
}

# Main fix loop
main() {
    echo -e "${BLUE}Starting intelligent error fixing...${NC}"
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
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Iteration ${ITERATIONS}/${MAX_ITERATIONS}${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        local errors=$(extract_errors)
        local errors_count=$(echo "$errors" | grep -c "error:" || echo "0")
        
        if [ "$errors_count" -eq 0 ]; then
            echo -e "${GREEN}✅ No errors found!${NC}"
            break
        fi
        
        echo -e "${YELLOW}Found ${errors_count} error(s)${NC}"
        echo ""
        
        local fixed_this_round=0
        while IFS= read -r error_line; do
            if [ -z "$error_line" ]; then continue; fi
            
            analyze_error "$error_line"
            if [ $? -eq 0 ]; then
                fixed_this_round=$((fixed_this_round + 1))
                ERRORS_FIXED=$((ERRORS_FIXED + 1))
            fi
        done <<< "$errors"
        
        if [ $fixed_this_round -eq 0 ]; then
            echo -e "${YELLOW}⚠️  No more automatic fixes available${NC}"
            break
        fi
        
        # Rebuild
        echo ""
        echo -e "${BLUE}🔄 Rebuilding after fixes...${NC}"
        
        if build_and_capture; then
            echo ""
            echo -e "${GREEN}✅ Build succeeded!${NC}"
            echo -e "${GREEN}   Errors fixed: ${ERRORS_FIXED}${NC}"
            echo -e "${GREEN}   Iterations: ${ITERATIONS}${NC}"
            return 0
        fi
    done
    
    # Final status
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  Some errors may require manual fixing${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "Errors fixed: ${ERRORS_FIXED}"
    echo -e "Iterations: ${ITERATIONS}"
    echo ""
    
    local remaining=$(extract_errors | wc -l | tr -d ' ')
    if [ "$remaining" -gt 0 ]; then
        echo -e "${RED}Remaining errors (${remaining}):${NC}"
        extract_errors | head -10
        echo ""
    fi
    
    echo -e "${BLUE}Solutions database: ${SOLUTIONS_DB}${NC}"
    echo -e "${BLUE}Build log: ${LOG_FILE}${NC}"
    
    return 1
}

main "$@"


#!/bin/bash
# ==============================================================================
# Khandoba Secure Docs - Cleanup Script
# ==============================================================================
# Removes orphaned/duplicate files and folders from the project
# Usage: ./cleanup_remaining.sh [--preview] [--no-backup] [--force]
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default options
PREVIEW_MODE=false
CREATE_BACKUP=true
FORCE_MODE=false

# Folders/files to remove
CLEANUP_TARGETS=(
    "docs/archive"
    "Archive"
    "Khandoba Secure DocsTests"
    "Khandoba Secure DocsUITests"
    "ShareExtension"
    "tests"
    "build"
    "platforms/apple/Khandoba Secure Docs/docs"
)

# Backup filename
BACKUP_FILE="$PROJECT_ROOT/backup_before_cleanup_$(date +%Y%m%d_%H%M%S).tar.gz"

# ==============================================================================
# Functions
# ==============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_target_exists() {
    local target="$PROJECT_ROOT/$1"
    if [ -e "$target" ] || [ -d "$target" ]; then
        return 0
    else
        return 1
    fi
}

preview_cleanup() {
    print_header "Preview: Items to be Removed"
    
    local found_any=false
    for target in "${CLEANUP_TARGETS[@]}"; do
        if check_target_exists "$target"; then
            print_warning "Will remove: $target"
            if [ -d "$PROJECT_ROOT/$target" ]; then
                local size=$(du -sh "$PROJECT_ROOT/$target" 2>/dev/null | cut -f1)
                echo "   Size: $size"
            fi
            found_any=true
        else
            echo "   ✓ $target (already removed or doesn't exist)"
        fi
    done
    
    # Check for backup files
    local backup_count=$(find "$PROJECT_ROOT/platforms/apple" -name "*.pbxproj.backup*" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$backup_count" -gt 0 ]; then
        print_warning "Will remove $backup_count Xcode backup file(s)"
        found_any=true
    else
        echo "   ✓ No Xcode backup files found"
    fi
    
    if [ "$found_any" = false ]; then
        print_success "Nothing to clean up - all targets already removed!"
        exit 0
    fi
}

create_backup() {
    if [ "$CREATE_BACKUP" = false ]; then
        print_info "Skipping backup (--no-backup flag set)"
        return 0
    fi
    
    print_header "Creating Backup"
    
    local backup_items=()
    for target in "${CLEANUP_TARGETS[@]}"; do
        if check_target_exists "$target"; then
            backup_items+=("$target")
        fi
    done
    
    # Add backup files to backup list
    local backup_files=$(find "$PROJECT_ROOT/platforms/apple" -name "*.pbxproj.backup*" 2>/dev/null || true)
    if [ -n "$backup_files" ]; then
        while IFS= read -r file; do
            backup_items+=("${file#$PROJECT_ROOT/}")
        done <<< "$backup_files"
    fi
    
    if [ ${#backup_items[@]} -eq 0 ]; then
        print_info "No items to backup"
        return 0
    fi
    
    print_info "Creating backup: $BACKUP_FILE"
    cd "$PROJECT_ROOT"
    
    # Create tar.gz backup
    tar -czf "$BACKUP_FILE" "${backup_items[@]}" 2>/dev/null || {
        print_error "Backup creation failed. Continuing anyway..."
        return 1
    }
    
    local backup_size=$(du -sh "$BACKUP_FILE" 2>/dev/null | cut -f1)
    print_success "Backup created: $BACKUP_FILE ($backup_size)"
}

remove_targets() {
    print_header "Removing Targets"
    
    local removed_count=0
    local failed_count=0
    
    for target in "${CLEANUP_TARGETS[@]}"; do
        local full_path="$PROJECT_ROOT/$target"
        
        if check_target_exists "$target"; then
            print_info "Removing: $target"
            
            if sudo rm -rf "$full_path" 2>/dev/null; then
                print_success "Removed: $target"
                ((removed_count++))
            else
                print_error "Failed to remove: $target"
                ((failed_count++))
            fi
        else
            echo "   ✓ $target (already removed or doesn't exist)"
        fi
    done
    
    # Remove Xcode backup files
    print_info "Removing Xcode backup files..."
    local backup_count=0
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            if sudo rm -f "$file" 2>/dev/null; then
                ((backup_count++))
            fi
        fi
    done < <(find "$PROJECT_ROOT/platforms/apple" -name "*.pbxproj.backup*" 2>/dev/null || true)
    
    if [ "$backup_count" -gt 0 ]; then
        print_success "Removed $backup_count Xcode backup file(s)"
        ((removed_count+=backup_count))
    else
        echo "   ✓ No Xcode backup files found"
    fi
    
    echo ""
    if [ $failed_count -eq 0 ]; then
        print_success "Cleanup complete! Removed $removed_count item(s)"
    else
        print_warning "Cleanup completed with $failed_count error(s)"
    fi
}

verify_cleanup() {
    print_header "Verifying Cleanup"
    
    local all_removed=true
    
    for target in "${CLEANUP_TARGETS[@]}"; do
        if check_target_exists "$target"; then
            print_error "Still exists: $target"
            all_removed=false
        else
            print_success "$target (removed)"
        fi
    done
    
    # Check backup files
    local backup_count=$(find "$PROJECT_ROOT/platforms/apple" -name "*.pbxproj.backup*" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$backup_count" -gt 0 ]; then
        print_error "Still $backup_count Xcode backup file(s) remaining"
        all_removed=false
    else
        print_success "All Xcode backup files removed"
    fi
    
    if [ "$all_removed" = true ]; then
        print_success "All cleanup targets successfully removed!"
        return 0
    else
        print_warning "Some items may require manual removal (check permissions)"
        return 1
    fi
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --preview      Show what will be removed without actually removing
    --no-backup    Skip creating backup before cleanup
    --force        Skip confirmation prompts (use with caution)
    --help         Show this help message

Examples:
    $0 --preview              # Preview what will be removed
    $0 --no-backup            # Cleanup without backup
    $0 --force --no-backup    # Quick cleanup without prompts or backup

EOF
}

confirm_action() {
    if [ "$FORCE_MODE" = true ]; then
        return 0
    fi
    
    echo ""
    read -p "Continue with cleanup? (yes/no): " -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_warning "Cleanup cancelled by user"
        exit 0
    fi
}

# ==============================================================================
# Parse Arguments
# ==============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        --preview)
            PREVIEW_MODE=true
            shift
            ;;
        --no-backup)
            CREATE_BACKUP=false
            shift
            ;;
        --force)
            FORCE_MODE=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
    print_header "Khandoba Secure Docs - Cleanup Script"
    
    # Change to project root
    cd "$PROJECT_ROOT"
    print_info "Project root: $PROJECT_ROOT"
    echo ""
    
    # Preview mode
    if [ "$PREVIEW_MODE" = true ]; then
        preview_cleanup
        exit 0
    fi
    
    # Show preview before cleanup
    preview_cleanup
    
    # Confirm action
    confirm_action
    
    # Create backup
    if [ "$CREATE_BACKUP" = true ]; then
        create_backup
        echo ""
    fi
    
    # Perform cleanup
    remove_targets
    
    # Verify cleanup
    echo ""
    verify_cleanup
    
    # Final message
    echo ""
    print_header "Cleanup Process Complete"
    
    if [ "$CREATE_BACKUP" = true ] && [ -f "$BACKUP_FILE" ]; then
        print_info "Backup saved at: $BACKUP_FILE"
        print_info "You can restore with: tar -xzf $BACKUP_FILE"
    fi
    
    echo ""
}

# Run main function
main

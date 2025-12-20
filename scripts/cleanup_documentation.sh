#!/bin/bash

# Documentation Cleanup Script
# Removes duplicate and unnecessary documentation files

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "🧹 Cleaning up duplicate documentation files..."

# Files to remove (duplicates/outdated)
FILES_TO_REMOVE=(
    # Duplicate database files (merged into CLEAN_SCHEMA_REBUILD.sql)
    "docs/shared/database/schema.sql"
    "docs/shared/database/setup_rls_policies.sql"
    "docs/shared/database/purge_all.sql"
    "docs/shared/database/fix_rls_policies.sql"
    "docs/shared/database/fix_rls_policies_v2.sql"
    "docs/shared/database/enable_realtime.sql"
    "docs/shared/database/add_fidelity_antivault_tables.sql"
    "docs/shared/database/add_subset_nomination_fields.sql"
    "database/add_emergency_pass_and_broadcast_vault.sql"
    "database/add_vault_transfer_and_document_versions.sql"
    "database/add_subset_nomination_fields.sql"
    "database/check_vault_transfer_table.sql"
    "database/QUICK_FIX_requested_by_user_id.sql"
    "database/fix_rls_policies.sql"
    "database/fix_rls_policies_v2.sql"
    "database/rls_policies.sql"
    "database/setup_rls_policies.sql"
    
    # Duplicate documentation
    "docs/shared/features/VAULT_WORKFLOWS.md"
    "docs/shared/features/VAULT_WORKFLOWS_SUMMARY.md"
    "docs/shared/features/VAULT_WORKFLOWS_IMPLEMENTATION.md"
    "docs/FEATURE_PARITY.md"
    "database/SUPABASE_RLS_POLICIES.md"
    "docs/shared/database/SUPABASE_RLS_POLICIES.md"
    "database/DB_MIGRATION_INSTRUCTIONS.md"
    "database/SETUP_INSTRUCTIONS.md"
    
    # Old schema file (replaced by CLEAN_SCHEMA_REBUILD.sql)
    "database/schema.sql"
)

cd "$PROJECT_ROOT"

REMOVED_COUNT=0
NOT_FOUND_COUNT=0

for file in "${FILES_TO_REMOVE[@]}"; do
    full_path="$PROJECT_ROOT/$file"
    if [ -f "$full_path" ]; then
        echo "  ❌ Removing: $file"
        rm "$full_path"
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    else
        echo "  ⚠️  Not found (may already be removed): $file"
        NOT_FOUND_COUNT=$((NOT_FOUND_COUNT + 1))
    fi
done

echo ""
echo "✅ Cleanup complete!"
echo "   Removed: $REMOVED_COUNT files"
echo "   Not found: $NOT_FOUND_COUNT files"
echo ""
echo "📋 Next steps:"
echo "   1. Review DOCUMENTATION_CLEANUP_PLAN.md for details"
echo "   2. Run database/CLEAN_SCHEMA_REBUILD.sql in Supabase"
echo "   3. Update any broken references in remaining documentation"

# Documentation Cleanup Plan

## Overview
This document outlines which documentation files should be kept, merged, or removed to eliminate duplication and inconsistencies.

## Files to REMOVE (Duplicates/Outdated)

### 1. Duplicate Database Files
- `docs/shared/database/schema.sql` - **REMOVE** (duplicate of `database/schema.sql`)
- `docs/shared/database/setup_rls_policies.sql` - **REMOVE** (merged into clean schema)
- `docs/shared/database/purge_all.sql` - **REMOVE** (clean schema handles drops)
- `docs/shared/database/fix_rls_policies.sql` - **REMOVE** (merged into clean schema)
- `docs/shared/database/fix_rls_policies_v2.sql` - **REMOVE** (merged into clean schema)
- `docs/shared/database/enable_realtime.sql` - **REMOVE** (can be added if needed)
- `docs/shared/database/add_fidelity_antivault_tables.sql` - **REMOVE** (merged into clean schema)
- `docs/shared/database/add_subset_nomination_fields.sql` - **REMOVE** (merged into clean schema)
- `database/add_emergency_pass_and_broadcast_vault.sql` - **REMOVE** (merged into clean schema)
- `database/add_vault_transfer_and_document_versions.sql` - **REMOVE** (merged into clean schema)
- `database/add_subset_nomination_fields.sql` - **REMOVE** (merged into clean schema)
- `database/check_vault_transfer_table.sql` - **REMOVE** (diagnostic only)
- `database/QUICK_FIX_requested_by_user_id.sql` - **REMOVE** (no longer needed with clean schema)
- `database/fix_rls_policies.sql` - **REMOVE** (merged)
- `database/fix_rls_policies_v2.sql` - **REMOVE** (merged)
- `database/rls_policies.sql` - **REMOVE** (merged)
- `database/setup_rls_policies.sql` - **REMOVE** (merged)

### 2. Duplicate Documentation Files
- `docs/shared/features/VAULT_WORKFLOWS.md` - **REMOVE** (superseded by VAULT_WORKFLOWS_COMPLETE.md)
- `docs/shared/features/VAULT_WORKFLOWS_SUMMARY.md` - **REMOVE** (if VAULT_WORKFLOWS_COMPLETE.md covers it)
- `docs/shared/features/VAULT_WORKFLOWS_IMPLEMENTATION.md` - **REMOVE** (if VAULT_WORKFLOWS_COMPLETE.md covers it)
- `docs/FEATURE_PARITY.md` - **REMOVE** (superseded by FEATURE_PARITY_ROADMAP.md)
- `docs/VERSION_COMPARISON.md` - **EVALUATE** (may be useful, check if outdated)
- `database/SUPABASE_RLS_POLICIES.md` - **REMOVE** (merged into clean schema documentation)
- `database/SETUP_INSTRUCTIONS.md` - **MERGE** into main README if needed
- `docs/shared/database/SUPABASE_RLS_POLICIES.md` - **REMOVE** (duplicate)

### 3. Temporary/Migration Files
- `database/MIGRATION_TROUBLESHOOTING.md` - **KEEP** (useful for future migrations)
- `database/README_BACKEND_INTEGRATION.md` - **MERGE** into main backend guide
- `database/DB_MIGRATION_INSTRUCTIONS.md` - **REMOVE** (no longer needed with clean rebuild)

## Files to KEEP (Essential)

### Core Documentation
- `docs/00_START_HERE.md` - **KEEP** (entry point)
- `docs/README.md` - **KEEP** (main documentation index)
- `docs/shared/README.md` - **KEEP**
- `README.md` (root) - **KEEP**

### Platform-Specific Guides
- `docs/apple/README.md` - **KEEP**
- `docs/apple/SETUP.md` - **KEEP**
- `docs/apple/DEPLOYMENT.md` - **KEEP**
- `docs/apple/IMPLEMENTATION_NOTES.md` - **KEEP**
- `docs/android/README.md` - **KEEP**
- `docs/android/SETUP.md` - **KEEP**
- `docs/android/DEPLOYMENT.md` - **KEEP**
- `docs/android/IMPLEMENTATION_NOTES.md` - **KEEP**
- `docs/windows/README.md` - **KEEP**
- `docs/windows/SETUP.md` - **KEEP**
- `docs/windows/DEPLOYMENT.md` - **KEEP**
- `docs/windows/IMPLEMENTATION_NOTES.md` - **KEEP**
- `docs/windows/setup/WINDOWS_PORT_GUIDE.md` - **KEEP**

### Architecture & Design
- `docs/shared/architecture/COMPLETE_SYSTEM_ARCHITECTURE.md` - **KEEP**
- `docs/shared/architecture/README.md` - **KEEP**
- `docs/shared/architecture/CONTACT_GRID_ARCHITECTURE.md` - **EVALUATE** (may be outdated)

### Feature Guides
- `docs/shared/features/VAULT_MANAGEMENT.md` - **KEEP**
- `docs/shared/features/DOCUMENT_MANAGEMENT.md` - **KEEP**
- `docs/shared/features/SECURITY_FEATURES.md` - **KEEP**
- `docs/shared/features/AI_INTELLIGENCE.md` - **KEEP**
- `docs/shared/features/MEDIA_FEATURES.md` - **KEEP**
- `docs/shared/features/SUBSCRIPTIONS.md` - **KEEP**
- `docs/shared/features/CROSS_PLATFORM_SYNC.md` - **KEEP**
- `docs/shared/features/VAULT_WORKFLOWS_COMPLETE.md` - **KEEP** (most complete)

### Security Guides
- `docs/shared/security/ML_THREAT_ANALYSIS_GUIDE.md` - **KEEP**
- `docs/shared/security/ML_AUTO_APPROVAL_GUIDE.md` - **KEEP**
- `docs/shared/security/ML_INTELLIGENCE_SYSTEM_GUIDE.md` - **KEEP**
- `docs/shared/security/FORMAL_LOGIC_REASONING_GUIDE.md` - **KEEP**

### Backend Guides
- `docs/shared/backend/BACKEND_INTEGRATION_GUIDE.md` - **KEEP**
- `docs/shared/database/SCHEMA.md` - **UPDATE** to reference clean schema
- `docs/shared/database/MIGRATIONS.md` - **UPDATE** to reference clean rebuild

### Development Guides
- `docs/DEVELOPMENT_ENVIRONMENT.md` - **KEEP**
- `docs/DEVELOPMENT_CHECKLIST.md` - **KEEP**
- `docs/CURSOR_EXTENSIONS_INSTALL.md` - **KEEP**
- `docs/DEPLOYMENT.md` - **KEEP**

### Planning Documents
- `docs/FEATURE_PARITY_ROADMAP.md` - **KEEP**
- `docs/WORKFLOW_IMPROVEMENTS.md` - **KEEP**

## Database Files Structure (After Cleanup)

### Keep:
- `database/CLEAN_SCHEMA_REBUILD.sql` - **NEW** (comprehensive clean schema)
- `database/schema.sql` - **UPDATE** or **REMOVE** (if CLEAN_SCHEMA_REBUILD.sql replaces it)
- `database/MIGRATION_TROUBLESHOOTING.md` - **KEEP**

### Remove all migration files (merged into clean schema):
- All `add_*.sql` files
- All `fix_*.sql` files
- All diagnostic/quick fix files

## Action Plan

1. **Create clean database schema** ✅ (CLEAN_SCHEMA_REBUILD.sql created)
2. **Remove duplicate database files** ✅ (24 files removed)
3. **Remove duplicate documentation** ✅ (7 files removed)
4. **Update references in remaining docs** ✅ (New READMEs created)
5. **Create new README for database directory** ✅ (README.md created)

## Status: ✅ COMPLETE

All cleanup tasks have been completed. The database can now be rebuilt from scratch using `CLEAN_SCHEMA_REBUILD.sql`.

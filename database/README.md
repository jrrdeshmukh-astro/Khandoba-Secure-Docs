# Database Schema & Migrations

## Overview

This directory contains the database schema and migration scripts for Khandoba Secure Docs. The database is rebuilt from scratch using a clean, comprehensive schema script.

## Quick Start

### Rebuild Database from Scratch

**⚠️ WARNING: This will delete all existing data!**

1. Open Supabase SQL Editor
2. Run `CLEAN_SCHEMA_REBUILD.sql`
3. Verify installation with the verification queries at the end of the script

### What's Included

- **Complete schema** - All tables, indexes, functions, triggers, and RLS policies
- **Cross-platform support** - Works with Apple, Android, and Windows platforms
- **Threat monitoring** - Real-time threat index calculation
- **ML threat assessment** - Integrated ML scoring functions
- **All features** - Broadcast vaults, emergency access, document versions, transfer requests

## Files

### `CLEAN_SCHEMA_REBUILD.sql`
**Main schema file** - Comprehensive database schema with all tables, RLS policies, functions, and triggers. Use this to rebuild your database from scratch.

### `MIGRATION_TROUBLESHOOTING.md`
Troubleshooting guide for common migration errors.

## Database Schema

### Core Tables

1. **users** - User accounts (supports Apple, Android, Windows user IDs)
2. **user_roles** - User roles (deprecated but kept for compatibility)
3. **vaults** - Document vaults with threat monitoring
4. **vault_sessions** - Active vault access sessions
5. **vault_access_logs** - Audit trail of vault access
6. **documents** - Encrypted documents with AI tagging
7. **document_versions** - Version history for documents
8. **nominees** - Vault sharing and nominee management
9. **vault_access_requests** - Access request workflow
10. **dual_key_requests** - Dual-key approval requests
11. **emergency_access_requests** - Emergency access with pass codes
12. **emergency_access_passes** - Generated pass codes for emergency access
13. **vault_transfer_requests** - Ownership transfer requests
14. **threat_events** - Security threat event tracking
15. **anti_vaults** - Anti-vault monitoring configuration
16. **document_fidelity** - Document integrity verification
17. **chat_messages** - LLM support chat messages

### Key Features

- **Platform-Agnostic User IDs**: Supports `apple_user_id`, `google_user_id`, and `microsoft_user_id`
- **Threat Monitoring**: Automatic threat index calculation via triggers
- **ML Integration**: Threat assessment functions for transfer requests
- **Broadcast Vaults**: Public vault support with access levels
- **Emergency Access**: Pass code system for dual-key vaults
- **Document Versioning**: Complete version history tracking
- **RLS Security**: Comprehensive row-level security policies

## Migration History

All previous migration files have been consolidated into `CLEAN_SCHEMA_REBUILD.sql`. The following migrations are included:

- ✅ Emergency access passes
- ✅ Broadcast vaults
- ✅ Vault transfer requests
- ✅ Document version history
- ✅ Threat monitoring and ML assessment
- ✅ Anti-vault and document fidelity
- ✅ Subset nomination fields

## Usage

### For New Installations

```sql
-- Run in Supabase SQL Editor
\i CLEAN_SCHEMA_REBUILD.sql
```

### For Existing Installations (Rebuild)

```sql
-- This will DROP ALL TABLES and recreate them
-- Backup your data first!
\i CLEAN_SCHEMA_REBUILD.sql
```

### Verify Installation

After running the schema, execute the verification queries at the end of `CLEAN_SCHEMA_REBUILD.sql` to ensure everything was created correctly.

## RLS Policies

All tables have Row-Level Security (RLS) enabled with policies that:
- Allow users to access their own data
- Allow vault owners to manage their vaults
- Allow nominees to access shared vaults
- Allow authenticated users to access broadcast vaults
- Prevent unauthorized access

## Functions

### `calculate_vault_threat_index(vault_id UUID)`
Calculates real-time threat index (0-100) based on recent threat events and pending transfer requests.

### `update_vault_threat_index()`
Trigger function that automatically updates vault threat index when threat events or transfer requests change.

### `assess_transfer_request_threat(transfer_request_id UUID)`
Performs ML threat assessment on transfer requests, returning threat score, recommendation, and threat index.

## Views

### `vault_threat_dashboard`
Provides real-time threat monitoring data including:
- Threat index and level
- Unresolved threat events count
- Pending transfer requests
- Latest threat event timestamp
- Highest current threat score

## Notes

- All timestamps use `TIMESTAMPTZ` (timezone-aware)
- UUIDs are used for all primary keys
- Encryption keys are stored as `BYTEA`
- JSONB is used for flexible metadata storage
- Arrays are used for tags and document IDs

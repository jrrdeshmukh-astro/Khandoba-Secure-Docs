# Database Rebuild Instructions

## Overview

This guide explains how to rebuild your Supabase database from scratch using the clean schema script. This removes all inconsistencies and duplications.

## ⚠️ Important Warnings

1. **This will DELETE ALL EXISTING DATA** - Backup your database first if you have important data
2. **All tables will be dropped and recreated** - This is a complete rebuild
3. **RLS policies will be reset** - All security policies will be recreated
4. **Functions and triggers will be recreated** - All database functions and triggers will be reset

## Prerequisites

- Access to Supabase SQL Editor
- Backup of any important data (if needed)
- Understanding that this is a destructive operation

## Steps to Rebuild

### Step 1: Backup (Optional but Recommended)

If you have existing data you want to preserve:

```sql
-- Export specific tables if needed
-- Use Supabase Dashboard > Database > Backups for full backup
```

### Step 2: Run Clean Schema Script

1. Open Supabase SQL Editor
2. Open `database/CLEAN_SCHEMA_REBUILD.sql`
3. Copy the entire contents
4. Paste into SQL Editor
5. Click "Run" or press Cmd/Ctrl + Enter

### Step 3: Verify Installation

The script includes verification queries at the end. After running, check:

- ✅ All tables exist (17 tables)
- ✅ RLS is enabled on all tables
- ✅ Indexes are created
- ✅ Functions exist (3 functions)
- ✅ Triggers are active (2 triggers)
- ✅ View exists (vault_threat_dashboard)

### Step 4: Test Basic Operations

```sql
-- Test user creation (if using service role)
INSERT INTO users (apple_user_id, full_name) 
VALUES ('test_user_123', 'Test User') 
RETURNING id;

-- Test vault creation
INSERT INTO vaults (name, owner_id) 
VALUES ('Test Vault', (SELECT id FROM users LIMIT 1)) 
RETURNING id;
```

## What Gets Created

### Tables (17 total)
1. users
2. user_roles
3. vaults
4. vault_sessions
5. vault_access_logs
6. documents
7. document_versions
8. nominees
9. vault_access_requests
10. dual_key_requests
11. emergency_access_requests
12. emergency_access_passes
13. vault_transfer_requests
14. threat_events
15. anti_vaults
16. document_fidelity
17. chat_messages

### Features Included
- ✅ Cross-platform user ID support (Apple, Android, Windows)
- ✅ Threat monitoring with automatic index calculation
- ✅ ML threat assessment for transfer requests
- ✅ Broadcast vault support
- ✅ Emergency access with pass codes
- ✅ Document versioning
- ✅ Anti-vault and document fidelity
- ✅ Complete RLS security policies
- ✅ All indexes for performance

## Troubleshooting

### Error: "relation already exists"
- The script includes `DROP TABLE IF EXISTS` statements
- If you see this error, tables may be locked
- Try running the DROP statements manually first

### Error: "permission denied"
- Ensure you're using the service role or have appropriate permissions
- Check that you're connected to the correct database

### Error: "function already exists"
- Functions use `CREATE OR REPLACE FUNCTION`, so this shouldn't occur
- If it does, manually drop the function first

### Verification queries fail
- Check that the script completed successfully
- Look for error messages in the SQL Editor
- Re-run the script if needed

## After Rebuild

1. **Update Application Code**: Ensure your app code matches the schema
2. **Test Authentication**: Verify user creation and authentication flow
3. **Test Vault Operations**: Create a test vault and verify access
4. **Test Threat Monitoring**: Create a threat event and verify index calculation
5. **Review RLS Policies**: Verify policies work as expected for your use case

## Migration from Old Schema

If you're migrating from an old schema:

1. **Export Data** (if needed): Use Supabase exports or pg_dump
2. **Run Clean Schema**: Execute CLEAN_SCHEMA_REBUILD.sql
3. **Import Data** (if needed): Transform and import your exported data
4. **Verify**: Run verification queries and test operations

## Support

For issues or questions:
- Check `MIGRATION_TROUBLESHOOTING.md` for common errors
- Review the schema comments in `CLEAN_SCHEMA_REBUILD.sql`
- Check Supabase logs for detailed error messages

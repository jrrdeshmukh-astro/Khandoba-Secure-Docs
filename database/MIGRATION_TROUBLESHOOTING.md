# Migration Troubleshooting Guide

## Common Errors and Solutions

### Error: Policy Already Exists

**Error Message:**
```
ERROR: 42710: policy "Users can view their own emergency passes" for table "emergency_access_passes" already exists
```

**Solution:**
The migration scripts have been updated to use `DROP POLICY IF EXISTS` before creating policies. If you're still seeing this error:

1. **Option 1: Run the updated migration script**
   - The scripts now include `DROP POLICY IF EXISTS` statements
   - This allows safe re-running of migrations

2. **Option 2: Manually drop existing policies**
   ```sql
   DROP POLICY IF EXISTS "Users can view their own emergency passes" ON emergency_access_passes;
   DROP POLICY IF EXISTS "Vault owners can view emergency passes for their vaults" ON emergency_access_passes;
   -- Then re-run the migration
   ```

3. **Option 3: Check existing policies and decide**
   ```sql
   SELECT policyname, tablename, cmd
   FROM pg_policies
   WHERE tablename = 'emergency_access_passes';
   ```
   If policies exist and are correct, you can skip the policy creation step.

### Error: Function Already Exists

**Error Message:**
```
ERROR: 42710: function "calculate_vault_threat_index" already exists
```

**Solution:**
Functions use `CREATE OR REPLACE FUNCTION`, so this should not occur. If it does:

1. Check if function signature changed:
   ```sql
   SELECT routine_name, routine_definition
   FROM information_schema.routines
   WHERE routine_name = 'calculate_vault_threat_index';
   ```

2. Drop and recreate if needed:
   ```sql
   DROP FUNCTION IF EXISTS calculate_vault_threat_index(UUID);
   -- Then re-run the migration
   ```

### Error: Trigger Already Exists

**Error Message:**
```
ERROR: 42710: trigger "trigger_update_vault_threat_index_on_threat_events" already exists
```

**Solution:**
The migration scripts now include `DROP TRIGGER IF EXISTS` before creating triggers. If you still see this:

```sql
DROP TRIGGER IF EXISTS trigger_update_vault_threat_index_on_threat_events ON threat_events;
DROP TRIGGER IF EXISTS trigger_update_vault_threat_index_on_transfer_requests ON vault_transfer_requests;
-- Then re-run the migration
```

### Error: View Already Exists

**Error Message:**
```
ERROR: 42710: relation "vault_threat_dashboard" already exists
```

**Solution:**
The migration now uses `DROP VIEW IF EXISTS`. If you still see this:

```sql
DROP VIEW IF EXISTS vault_threat_dashboard;
-- Then re-run the migration
```

### Error: Column Does Not Exist

**Error Message:**
```
ERROR: 42703: column "requested_by_user_id" does not exist
```

**Solution:**
This happens when the table exists but doesn't have the expected column. Run the quick fix script:

```sql
-- Run: database/QUICK_FIX_requested_by_user_id.sql
```

Or manually add the column:
```sql
ALTER TABLE vault_transfer_requests
ADD COLUMN IF NOT EXISTS requested_by_user_id UUID REFERENCES users(id);

-- Set default for existing rows
UPDATE vault_transfer_requests
SET requested_by_user_id = (SELECT id FROM users LIMIT 1)
WHERE requested_by_user_id IS NULL;
```

Then re-run the main migration script.

### Error: Column Already Exists

**Error Message:**
```
ERROR: 42701: column "threat_index" of relation "vaults" already exists
```

**Solution:**
Column additions use `ADD COLUMN IF NOT EXISTS`, so this should not occur. If it does, the column already exists and you can skip that part of the migration.

To verify columns exist:
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'vaults'
AND column_name IN ('threat_index', 'threat_level', 'last_threat_assessment_at');
```

### Error: Table Already Exists

**Error Message:**
```
ERROR: 42710: relation "vault_transfer_requests" already exists
```

**Solution:**
Table creation uses `CREATE TABLE IF NOT EXISTS`, so this should not occur. If you see this:

1. **Check if table exists and has correct structure:**
   ```sql
   SELECT column_name, data_type
   FROM information_schema.columns
   WHERE table_name = 'vault_transfer_requests'
   ORDER BY ordinal_position;
   ```

2. **If structure is correct, skip table creation**
3. **If structure is wrong, you may need to drop and recreate:**
   ```sql
   -- WARNING: This will delete all data!
   DROP TABLE IF EXISTS vault_transfer_requests CASCADE;
   -- Then re-run the migration
   ```

### Error: Foreign Key Constraint Violation

**Error Message:**
```
ERROR: 23503: insert or update on table "vault_transfer_requests" violates foreign key constraint
```

**Solution:**
Ensure referenced tables exist and contain the referenced data:

1. **Check if vault exists:**
   ```sql
   SELECT id, name FROM vaults WHERE id = 'your-vault-id';
   ```

2. **Check if user exists:**
   ```sql
   SELECT id, email FROM users WHERE id = 'your-user-id';
   ```

### Error: Permission Denied

**Error Message:**
```
ERROR: 42501: permission denied for table vaults
```

**Solution:**
Ensure you're running migrations with appropriate permissions:

1. **Use Supabase SQL Editor** (recommended) - uses service role
2. **Or grant necessary permissions:**
   ```sql
   GRANT ALL ON vaults TO authenticated;
   GRANT ALL ON vault_transfer_requests TO authenticated;
   GRANT ALL ON document_versions TO authenticated;
   GRANT ALL ON threat_events TO authenticated;
   ```

### Error: Type Mismatch

**Error Message:**
```
ERROR: 42804: column "threat_index" is of type double precision but expression is of type text
```

**Solution:**
Check column types match:
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'vaults'
AND column_name = 'threat_index';
```

Should be `double precision`. If not, alter the column:
```sql
ALTER TABLE vaults
ALTER COLUMN threat_index TYPE DOUBLE PRECISION USING threat_index::double precision;
```

## Safe Migration Pattern

To avoid errors when re-running migrations:

1. **Use IF NOT EXISTS / IF EXISTS** - Already included in updated scripts
2. **Use DROP ... IF EXISTS before CREATE** - Already included
3. **Run verification queries first** to check current state
4. **Run migrations in transaction** (optional, for rollback capability)

Example safe pattern:
```sql
BEGIN;

-- Drop existing objects
DROP POLICY IF EXISTS ...;
DROP TRIGGER IF EXISTS ...;
DROP VIEW IF EXISTS ...;

-- Create new objects
CREATE POLICY ...;
CREATE TRIGGER ...;
CREATE VIEW ...;

-- Verify
SELECT ...;

COMMIT;
```

## Verification Checklist

After running migrations, verify:

```sql
-- 1. Tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN (
    'vault_transfer_requests', 
    'document_versions', 
    'threat_events'
);

-- 2. Columns added to vaults
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'vaults' 
AND column_name IN (
    'threat_index', 
    'threat_level', 
    'last_threat_assessment_at'
);

-- 3. Functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name IN (
    'calculate_vault_threat_index',
    'update_vault_threat_index',
    'assess_transfer_request_threat'
);

-- 4. Triggers are active
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_name LIKE '%threat_index%';

-- 5. Views exist
SELECT table_name 
FROM information_schema.views 
WHERE table_name = 'vault_threat_dashboard';

-- 6. Policies exist
SELECT policyname, tablename
FROM pg_policies
WHERE tablename IN (
    'vault_transfer_requests',
    'document_versions',
    'threat_events'
);
```

## Getting Help

If you continue to experience issues:

1. Check the full error message in Supabase SQL Editor
2. Verify your database version and Supabase setup
3. Check if you're running migrations in the correct order
4. Review the verification queries above to see what's already installed
5. Consider running migrations in smaller chunks if issues persist

# Database Migrations Guide

> Guide for applying and managing database migrations

---

## Overview

This guide covers how to apply database migrations to the Supabase PostgreSQL database.

---

## Migration Files

### Core Schema

- **`schema.sql`** - Complete database schema (all tables)

### Additional Migrations

- **`setup_rls_policies.sql`** - Row-Level Security policies
- **`add_fidelity_antivault_tables.sql`** - Fidelity and anti-vault tables
- **`add_subset_nomination_fields.sql`** - Nominee subset fields
- **`enable_realtime.sql`** - Real-time subscriptions setup
- **`fix_rls_policies.sql`** - RLS policy fixes
- **`fix_rls_policies_v2.sql`** - Additional RLS fixes
- **`purge_all.sql`** - Cleanup script (use with caution)

---

## Migration Order

### Initial Setup (New Database)

1. **`schema.sql`** - Create all tables
2. **`setup_rls_policies.sql`** - Enable RLS and add policies
3. **`add_fidelity_antivault_tables.sql`** - Add additional tables
4. **`add_subset_nomination_fields.sql`** - Add nominee fields
5. **`enable_realtime.sql`** - Enable real-time

### Updates (Existing Database)

1. Check current schema version
2. Apply only missing migrations
3. Test RLS policies
4. Verify real-time subscriptions

---

## Applying Migrations

### Via Supabase Dashboard

1. Go to Supabase Dashboard
2. Navigate to SQL Editor
3. Copy migration SQL
4. Execute SQL
5. Verify results

### Via Supabase CLI

```bash
# Apply schema
supabase db reset

# Or apply specific migration
supabase migration up
```

### Via psql (Direct)

```bash
# Connect to database
psql -h [host] -U [user] -d [database]

# Apply migration
\i schema.sql
\i setup_rls_policies.sql
```

---

## Migration Steps

### Step 1: Create Tables

Run `schema.sql` to create all tables:

```sql
-- This creates:
-- - users
-- - user_roles
-- - vaults
-- - documents
-- - document_versions
-- - nominees
-- - vault_sessions
-- - vault_access_logs
-- - dual_key_requests
-- - emergency_access_requests
-- - vault_transfer_requests
-- - vault_access_requests
-- - chat_messages
```

### Step 2: Enable RLS

Run `setup_rls_policies.sql` to:
- Enable Row-Level Security on all tables
- Create RLS policies for access control
- Set up proper permissions

### Step 3: Additional Tables

Run `add_fidelity_antivault_tables.sql` if needed:
- Adds fidelity tracking columns
- Adds anti-vault support
- Adds additional indexes

### Step 4: Enable Real-Time

Run `enable_realtime.sql` to:
- Enable real-time for tables
- Set up publication for changes
- Configure real-time channels

---

## Rollback Procedures

### Manual Rollback

If a migration fails or needs to be rolled back:

1. **Identify the migration** that needs rollback
2. **Create reverse migration** (DROP statements)
3. **Test rollback** in development
4. **Apply rollback** in production

### Example Rollback

```sql
-- Rollback: Remove a table
DROP TABLE IF EXISTS example_table CASCADE;

-- Rollback: Remove a column
ALTER TABLE vaults DROP COLUMN IF EXISTS example_column;

-- Rollback: Remove an index
DROP INDEX IF EXISTS idx_example;
```

---

## Verification

### After Migration

Verify the migration:

1. **Check tables exist:**
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

2. **Check RLS is enabled:**
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

3. **Check indexes:**
```sql
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public';
```

4. **Test RLS policies:**
```sql
-- Test as different users
SET ROLE authenticated;
SELECT * FROM vaults; -- Should only see own vaults
```

---

## Common Issues

### Issue: RLS Blocks All Access

**Solution:** Check RLS policies are correct:
```sql
SELECT * FROM pg_policies WHERE tablename = 'vaults';
```

### Issue: Foreign Key Constraints

**Solution:** Ensure related tables exist before creating foreign keys:
- Create `users` before `vaults`
- Create `vaults` before `documents`

### Issue: Real-Time Not Working

**Solution:** 
1. Verify publication enabled:
```sql
SELECT * FROM pg_publication_tables;
```

2. Check replication enabled in Supabase dashboard

---

## Best Practices

1. **Test First** - Always test migrations in development
2. **Backup** - Backup database before migrations
3. **Incremental** - Apply migrations incrementally
4. **Document** - Document any custom migrations
5. **Version Control** - Keep migrations in version control
6. **Review** - Review SQL before executing
7. **Monitor** - Monitor after migration for issues

---

## Migration Checklist

- [ ] Backup database
- [ ] Review migration SQL
- [ ] Test in development environment
- [ ] Verify table creation
- [ ] Verify RLS policies
- [ ] Verify indexes
- [ ] Test real-time (if applicable)
- [ ] Test application functionality
- [ ] Monitor for errors
- [ ] Document any custom changes

---

**Last Updated:** December 2024

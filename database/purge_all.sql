-- PURGE ALL TABLES AND DATA - START FRESH
-- ⚠️ WARNING: This will DELETE ALL DATA in your Supabase database
-- Run this in Supabase SQL Editor to completely reset the database
-- 
-- After running this, you can run the schema scripts in order:
-- 1. schema.sql
-- 2. add_fidelity_antivault_tables.sql
-- 3. add_subset_nomination_fields.sql
-- 4. fix_rls_policies_v2.sql
-- 5. enable_realtime.sql

-- ============================================================================
-- STEP 1: DROP ALL TRIGGERS
-- ============================================================================

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_vaults_updated_at ON vaults;
DROP TRIGGER IF EXISTS update_documents_updated_at ON documents;
DROP TRIGGER IF EXISTS update_document_versions_updated_at ON document_versions;
DROP TRIGGER IF EXISTS update_nominees_updated_at ON nominees;
DROP TRIGGER IF EXISTS update_vault_sessions_updated_at ON vault_sessions;
DROP TRIGGER IF EXISTS update_dual_key_requests_updated_at ON dual_key_requests;
DROP TRIGGER IF EXISTS update_vault_transfer_requests_updated_at ON vault_transfer_requests;
DROP TRIGGER IF EXISTS update_vault_access_requests_updated_at ON vault_access_requests;
DROP TRIGGER IF EXISTS update_emergency_access_requests_updated_at ON emergency_access_requests;
DROP TRIGGER IF EXISTS update_chat_messages_updated_at ON chat_messages;
DROP TRIGGER IF EXISTS update_document_fidelity_updated_at ON document_fidelity;
DROP TRIGGER IF EXISTS update_anti_vaults_updated_at ON anti_vaults;

-- ============================================================================
-- STEP 2: DROP ALL FUNCTIONS
-- ============================================================================

DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS check_vault_ownership(UUID) CASCADE;
DROP FUNCTION IF EXISTS check_nominee_access(UUID) CASCADE;
DROP FUNCTION IF EXISTS revoke_expired_subset_nominations() CASCADE;

-- ============================================================================
-- STEP 3: DROP ALL POLICIES (RLS Policies)
-- ============================================================================

-- Drop policies from all tables (CASCADE will handle dependencies)
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "user_roles_insert_own" ON ' || quote_ident(r.tablename) || ' CASCADE';
        EXECUTE 'DROP POLICY IF EXISTS "nominees_select_accessible" ON ' || quote_ident(r.tablename) || ' CASCADE';
        EXECUTE 'DROP POLICY IF EXISTS "nominees_insert_owner" ON ' || quote_ident(r.tablename) || ' CASCADE';
        EXECUTE 'DROP POLICY IF EXISTS "nominees_update_accessible" ON ' || quote_ident(r.tablename) || ' CASCADE';
        EXECUTE 'DROP POLICY IF EXISTS "nominees_delete_owner" ON ' || quote_ident(r.tablename) || ' CASCADE';
        EXECUTE 'DROP POLICY IF EXISTS "vaults_select_accessible" ON ' || quote_ident(r.tablename) || ' CASCADE';
        EXECUTE 'DROP POLICY IF EXISTS "vault_access_logs_insert_accessible" ON ' || quote_ident(r.tablename) || ' CASCADE';
        EXECUTE 'DROP POLICY IF EXISTS "Users can read own document fidelity" ON ' || quote_ident(r.tablename) || ' CASCADE';
        EXECUTE 'DROP POLICY IF EXISTS "Service can manage document fidelity" ON ' || quote_ident(r.tablename) || ' CASCADE';
        EXECUTE 'DROP POLICY IF EXISTS "Authorized departments can manage anti-vaults" ON ' || quote_ident(r.tablename) || ' CASCADE';
        EXECUTE 'DROP POLICY IF EXISTS "Anti-vault owners can read" ON ' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END $$;

-- Drop all policies using pg_policies (more comprehensive)
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I CASCADE', 
            r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- ============================================================================
-- STEP 4: DISABLE RLS ON ALL TABLES
-- ============================================================================

ALTER TABLE IF EXISTS users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS vaults DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS document_versions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS nominees DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS vault_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS vault_access_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS dual_key_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS vault_transfer_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS vault_access_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS emergency_access_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS chat_messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS document_fidelity DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS anti_vaults DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 5: REMOVE TABLES FROM REALTIME PUBLICATION
-- ============================================================================

-- Remove tables from realtime publication (ignore errors if tables don't exist in publication)
DO $$ 
BEGIN
    -- Only try to drop if publication exists and table is in it
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        BEGIN
            ALTER PUBLICATION supabase_realtime DROP TABLE vaults;
        EXCEPTION WHEN undefined_table OR undefined_object THEN NULL;
        END;
        
        BEGIN
            ALTER PUBLICATION supabase_realtime DROP TABLE documents;
        EXCEPTION WHEN undefined_table OR undefined_object THEN NULL;
        END;
        
        BEGIN
            ALTER PUBLICATION supabase_realtime DROP TABLE nominees;
        EXCEPTION WHEN undefined_table OR undefined_object THEN NULL;
        END;
        
        BEGIN
            ALTER PUBLICATION supabase_realtime DROP TABLE chat_messages;
        EXCEPTION WHEN undefined_table OR undefined_object THEN NULL;
        END;
        
        BEGIN
            ALTER PUBLICATION supabase_realtime DROP TABLE vault_sessions;
        EXCEPTION WHEN undefined_table OR undefined_object THEN NULL;
        END;
    END IF;
END $$;

-- ============================================================================
-- STEP 6: DROP ALL TABLES (in reverse dependency order)
-- ============================================================================

-- Drop tables with foreign keys first (child tables)
DROP TABLE IF EXISTS document_fidelity CASCADE;
DROP TABLE IF EXISTS anti_vaults CASCADE;
DROP TABLE IF EXISTS document_versions CASCADE;
DROP TABLE IF EXISTS vault_access_logs CASCADE;
DROP TABLE IF EXISTS vault_sessions CASCADE;
DROP TABLE IF EXISTS nominees CASCADE;
DROP TABLE IF EXISTS dual_key_requests CASCADE;
DROP TABLE IF EXISTS vault_transfer_requests CASCADE;
DROP TABLE IF EXISTS vault_access_requests CASCADE;
DROP TABLE IF EXISTS emergency_access_requests CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS documents CASCADE;
DROP TABLE IF EXISTS vaults CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================================================
-- STEP 7: DROP EXTENSIONS (optional - only if you want to remove them)
-- ============================================================================

-- Uncomment if you want to remove UUID extension (usually keep it)
-- DROP EXTENSION IF EXISTS "uuid-ossp" CASCADE;

-- ============================================================================
-- VERIFICATION: Check that everything is dropped
-- ============================================================================

-- Verify no tables remain (should return empty)
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Verify no policies remain (should return empty)
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Verify no functions remain (should return empty or only system functions)
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'update_updated_at_column',
    'check_vault_ownership',
    'check_nominee_access',
    'revoke_expired_subset_nominations'
)
ORDER BY routine_name;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Database purged successfully!';
    RAISE NOTICE '📋 Next steps:';
    RAISE NOTICE '   1. Run database/schema.sql';
    RAISE NOTICE '   2. Run database/add_fidelity_antivault_tables.sql';
    RAISE NOTICE '   3. Run database/add_subset_nomination_fields.sql';
    RAISE NOTICE '   4. Run database/fix_rls_policies_v2.sql';
    RAISE NOTICE '   5. Run database/enable_realtime.sql';
END $$;

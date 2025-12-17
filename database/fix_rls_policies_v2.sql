-- Fix RLS Policy Issues - Version 2 (Complete Fix)
-- Run this in Supabase SQL Editor
-- 
-- This version uses security definer functions to break circular dependencies
-- 
-- Issues Fixed:
-- 1. user_roles: Users cannot insert their own role during signup
-- 2. vaults: Infinite recursion between vaults and nominees policies

-- ============================================================================
-- FIX 1: Allow users to insert their own role during signup
-- ============================================================================

DROP POLICY IF EXISTS "user_roles_insert_own" ON user_roles;

CREATE POLICY "user_roles_insert_own"
ON user_roles FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- FIX 2: Break infinite recursion using security definer functions
-- ============================================================================

-- Create helper functions that bypass RLS to check ownership
-- This breaks the circular dependency

-- Function to check if user owns a vault (bypasses RLS)
CREATE OR REPLACE FUNCTION check_vault_ownership(vault_uuid UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM vaults
        WHERE id = vault_uuid
        AND owner_id = auth.uid()
    );
END;
$$;

-- Function to check if user is an accepted nominee for a vault (bypasses RLS)
CREATE OR REPLACE FUNCTION check_nominee_access(vault_uuid UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM nominees
        WHERE vault_id = vault_uuid
        AND user_id = auth.uid()
        AND status = 'accepted'
    );
END;
$$;

-- ============================================================================
-- FIX NOMINEES POLICIES (use functions to avoid recursion)
-- ============================================================================

-- Drop existing nominees policies
DROP POLICY IF EXISTS "nominees_select_accessible" ON nominees;
DROP POLICY IF EXISTS "nominees_insert_owner" ON nominees;
DROP POLICY IF EXISTS "nominees_update_accessible" ON nominees;
DROP POLICY IF EXISTS "nominees_delete_owner" ON nominees;

-- Nominees SELECT: Users can see nominees where they're the nominee OR for vaults they own
CREATE POLICY "nominees_select_accessible"
ON nominees FOR SELECT
USING (
    user_id = auth.uid() OR
    check_vault_ownership(vault_id)
);

-- Nominees INSERT: Vault owners can create nominees
CREATE POLICY "nominees_insert_owner"
ON nominees FOR INSERT
WITH CHECK (check_vault_ownership(vault_id));

-- Nominees UPDATE: Nominees can update their status, owners can update any field
CREATE POLICY "nominees_update_accessible"
ON nominees FOR UPDATE
USING (
    user_id = auth.uid() OR
    check_vault_ownership(vault_id)
)
WITH CHECK (
    user_id = auth.uid() OR
    check_vault_ownership(vault_id)
);

-- Nominees DELETE: Vault owners can delete nominees
CREATE POLICY "nominees_delete_owner"
ON nominees FOR DELETE
USING (check_vault_ownership(vault_id));

-- ============================================================================
-- FIX VAULTS POLICIES (use functions to avoid recursion)
-- ============================================================================

-- Drop existing vaults SELECT policy
DROP POLICY IF EXISTS "vaults_select_accessible" ON vaults;

-- Vaults SELECT: Users can see vaults they own OR where they're accepted nominees
CREATE POLICY "vaults_select_accessible"
ON vaults FOR SELECT
USING (
    owner_id = auth.uid() OR
    check_nominee_access(id)
);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check policies are created
SELECT 
    tablename, 
    policyname, 
    cmd as operation
FROM pg_policies
WHERE tablename IN ('user_roles', 'vaults', 'nominees')
ORDER BY tablename, policyname;

-- Check functions are created
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('check_vault_ownership', 'check_nominee_access');

-- Test queries (should not cause recursion)
-- SELECT * FROM vaults LIMIT 1;
-- SELECT * FROM nominees LIMIT 1;

-- Fix RLS Policy Issues
-- Run this in Supabase SQL Editor
-- 
-- Issues Fixed:
-- 1. user_roles: Users cannot insert their own role during signup
-- 2. vaults: Infinite recursion between vaults and nominees policies

-- ============================================================================
-- FIX 1: Allow users to insert their own role during signup
-- ============================================================================

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "user_roles_insert_own" ON user_roles;

-- Allow users to insert their own role (for signup)
CREATE POLICY "user_roles_insert_own"
ON user_roles FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- FIX 2: Fix infinite recursion in vaults/nominees policies
-- ============================================================================

-- The problem: Circular dependency
-- - vaults SELECT policy checks nominees table
-- - nominees SELECT policy checks vaults table (via subquery)
-- This creates infinite recursion

-- Solution: Fix nominees policy first to use EXISTS instead of IN subquery
-- This breaks the recursion cycle

-- Step 1: Fix nominees SELECT policy
DROP POLICY IF EXISTS "nominees_select_accessible" ON nominees;

CREATE POLICY "nominees_select_accessible"
ON nominees FOR SELECT
USING (
    -- Users can see nominees where they're the nominee
    user_id = auth.uid() OR
    -- Users can see nominees for vaults they own
    -- Use EXISTS with direct vault check to avoid recursion
    EXISTS (
        SELECT 1 FROM vaults
        WHERE vaults.id = nominees.vault_id
        AND vaults.owner_id = auth.uid()
    )
);

-- Step 2: Fix nominees INSERT policy (also uses vaults subquery)
DROP POLICY IF EXISTS "nominees_insert_owner" ON nominees;

CREATE POLICY "nominees_insert_owner"
ON nominees FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM vaults
        WHERE vaults.id = nominees.vault_id
        AND vaults.owner_id = auth.uid()
    )
);

-- Step 3: Fix nominees UPDATE policy
DROP POLICY IF EXISTS "nominees_update_accessible" ON nominees;

CREATE POLICY "nominees_update_accessible"
ON nominees FOR UPDATE
USING (
    user_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM vaults
        WHERE vaults.id = nominees.vault_id
        AND vaults.owner_id = auth.uid()
    )
)
WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (
        SELECT 1 FROM vaults
        WHERE vaults.id = nominees.vault_id
        AND vaults.owner_id = auth.uid()
    )
);

-- Step 4: Fix nominees DELETE policy
DROP POLICY IF EXISTS "nominees_delete_owner" ON nominees;

CREATE POLICY "nominees_delete_owner"
ON nominees FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM vaults
        WHERE vaults.id = nominees.vault_id
        AND vaults.owner_id = auth.uid()
    )
);

-- Step 5: Fix vaults SELECT policy (use EXISTS instead of IN)
DROP POLICY IF EXISTS "vaults_select_accessible" ON vaults;

CREATE POLICY "vaults_select_accessible"
ON vaults FOR SELECT
USING (
    -- Users can see vaults they own
    owner_id = auth.uid() OR
    -- Users can see vaults where they're accepted nominees
    -- Using EXISTS to avoid recursion
    EXISTS (
        SELECT 1 FROM nominees
        WHERE nominees.vault_id = vaults.id
        AND nominees.user_id = auth.uid()
        AND nominees.status = 'accepted'
    )
);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check policies are created correctly
SELECT 
    tablename, 
    policyname, 
    cmd as operation,
    CASE 
        WHEN qual IS NOT NULL THEN 'Has USING clause'
        ELSE 'No USING clause'
    END as using_clause,
    CASE 
        WHEN with_check IS NOT NULL THEN 'Has WITH CHECK clause'
        ELSE 'No WITH CHECK clause'
    END as with_check_clause
FROM pg_policies
WHERE tablename IN ('user_roles', 'vaults', 'nominees')
ORDER BY tablename, policyname;

-- Test: Try to select vaults (should not cause recursion error)
-- SELECT * FROM vaults LIMIT 1;

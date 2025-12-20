-- Migration: Add Emergency Access Pass and Broadcast Vault Support
-- Run this migration in your Supabase SQL editor

-- ============================================
-- 1. Add columns to vaults table for broadcast support
-- ============================================

ALTER TABLE vaults 
ADD COLUMN IF NOT EXISTS is_broadcast BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS access_level TEXT DEFAULT 'private';

-- Create index for broadcast vaults
CREATE INDEX IF NOT EXISTS idx_vaults_is_broadcast ON vaults(is_broadcast);

-- ============================================
-- 2. Add columns to emergency_access_requests table
-- ============================================

ALTER TABLE emergency_access_requests
ADD COLUMN IF NOT EXISTS pass_code TEXT,
ADD COLUMN IF NOT EXISTS ml_score DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS ml_recommendation TEXT;

-- Create index for pass code lookups
CREATE INDEX IF NOT EXISTS idx_emergency_access_requests_pass_code ON emergency_access_requests(pass_code) 
WHERE pass_code IS NOT NULL;

-- ============================================
-- 3. Create emergency_access_passes table
-- ============================================

CREATE TABLE IF NOT EXISTS emergency_access_passes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES users(id),
    emergency_request_id UUID NOT NULL REFERENCES emergency_access_requests(id) ON DELETE CASCADE,
    pass_code TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for emergency_access_passes
CREATE INDEX IF NOT EXISTS idx_emergency_access_passes_pass_code ON emergency_access_passes(pass_code);
CREATE INDEX IF NOT EXISTS idx_emergency_access_passes_vault_id ON emergency_access_passes(vault_id);
CREATE INDEX IF NOT EXISTS idx_emergency_access_passes_requester_id ON emergency_access_passes(requester_id);
CREATE INDEX IF NOT EXISTS idx_emergency_access_passes_expires_at ON emergency_access_passes(expires_at);
CREATE INDEX IF NOT EXISTS idx_emergency_access_passes_is_active ON emergency_access_passes(is_active);

-- ============================================
-- 4. Enable Row-Level Security on emergency_access_passes
-- ============================================

ALTER TABLE emergency_access_passes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view passes they created (as requester)
DROP POLICY IF EXISTS "Users can view their own emergency passes" ON emergency_access_passes;
CREATE POLICY "Users can view their own emergency passes"
ON emergency_access_passes FOR SELECT
USING (auth.uid()::text = requester_id::text);

-- Policy: Users can view passes for vaults they own (as vault owner)
DROP POLICY IF EXISTS "Vault owners can view emergency passes for their vaults" ON emergency_access_passes;
CREATE POLICY "Vault owners can view emergency passes for their vaults"
ON emergency_access_passes FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = emergency_access_passes.vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
);

-- Policy: System can insert passes (via service role)
-- Note: In practice, passes are created when requests are approved
-- This is handled by the application logic, not direct inserts

-- ============================================
-- 5. RLS Policies for Broadcast Vaults
-- ============================================

-- Policy: All authenticated users can view broadcast vaults
DROP POLICY IF EXISTS "Broadcast vaults are visible to all authenticated users" ON vaults;
CREATE POLICY "Broadcast vaults are visible to all authenticated users"
ON vaults FOR SELECT
USING (
    is_broadcast = true AND
    auth.uid() IS NOT NULL
);

-- Policy: Broadcast vault write access based on access_level
-- Note: For now, we'll allow vault owners to update broadcast vaults
-- Additional policies can be added based on access_level
DROP POLICY IF EXISTS "Broadcast vault write access" ON vaults;
CREATE POLICY "Broadcast vault write access"
ON vaults FOR UPDATE
USING (
    is_broadcast = true AND
    (
        -- Owner can always update
        owner_id::text = auth.uid()::text
        OR
        -- Public write if access_level allows
        (access_level = 'public_write' AND auth.uid() IS NOT NULL)
    )
);

-- ============================================
-- 6. Create "Open Street" broadcast vault (optional - can be done by app)
-- ============================================

-- Note: The app will create this vault automatically on first launch
-- If you want to create it manually, uncomment the following:
-- 
-- INSERT INTO vaults (
--     id,
--     name,
--     vault_description,
--     owner_id,
--     status,
--     key_type,
--     vault_type,
--     is_system_vault,
--     is_broadcast,
--     access_level,
--     is_encrypted,
--     is_zero_knowledge,
--     created_at,
--     updated_at
-- ) VALUES (
--     gen_random_uuid(),
--     'Open Street',
--     'A public vault for everyone to share and access documents',
--     (SELECT id FROM users LIMIT 1), -- Replace with actual system user ID or first user
--     'active',
--     'single',
--     'both',
--     false,
--     true,
--     'public_read',
--     true,
--     true,
--     NOW(),
--     NOW()
-- ) ON CONFLICT DO NOTHING;

-- ============================================
-- 7. Add real-time subscription for emergency_access_passes (optional)
-- ============================================

-- Add to Supabase Realtime publication if needed
-- ALTER PUBLICATION supabase_realtime ADD TABLE emergency_access_passes;

-- ============================================
-- Verification Queries
-- ============================================

-- Verify columns added
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'vaults' 
AND column_name IN ('is_broadcast', 'access_level');

SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'emergency_access_requests' 
AND column_name IN ('pass_code', 'ml_score', 'ml_recommendation');

-- Verify table created
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'emergency_access_passes';

-- Verify indexes
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename IN ('vaults', 'emergency_access_requests', 'emergency_access_passes')
AND indexname LIKE '%broadcast%' OR indexname LIKE '%pass_code%' OR indexname LIKE '%emergency_access%';

-- Verify RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('vaults', 'emergency_access_passes')
AND (policyname LIKE '%broadcast%' OR policyname LIKE '%emergency%');

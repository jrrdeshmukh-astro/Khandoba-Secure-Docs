-- Migration: Add Vault Transfer Requests and Document Version History
-- Run this migration in your Supabase SQL editor

-- ============================================
-- 1. Create vault_transfer_requests table
-- ============================================

-- Drop table if it exists with wrong structure (be careful - this deletes data!)
-- Uncomment only if you need to recreate the table:
-- DROP TABLE IF EXISTS vault_transfer_requests CASCADE;

CREATE TABLE IF NOT EXISTS vault_transfer_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    requested_by_user_id UUID NOT NULL REFERENCES users(id),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'denied', 'completed'
    reason TEXT,
    new_owner_id UUID REFERENCES users(id),
    new_owner_name TEXT,
    new_owner_phone TEXT,
    new_owner_email TEXT,
    transfer_token TEXT NOT NULL UNIQUE,
    approved_at TIMESTAMPTZ,
    approver_id UUID REFERENCES users(id),
    ml_score DOUBLE PRECISION, -- ML threat analysis score
    ml_recommendation TEXT, -- ML recommendation (approve/deny/review)
    threat_index DOUBLE PRECISION, -- Real-time threat index for this transfer
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add missing columns if table already existed (MUST happen before indexes and policies)
-- This handles the case where the table was created previously without all columns
DO $$
BEGIN
    -- Add requested_by_user_id if missing (nullable first)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'vault_transfer_requests'
        AND column_name = 'requested_by_user_id'
    ) THEN
        ALTER TABLE vault_transfer_requests
        ADD COLUMN requested_by_user_id UUID REFERENCES users(id);
        
        -- Set a default value for existing rows (use first user if available)
        IF EXISTS (SELECT 1 FROM users LIMIT 1) THEN
            UPDATE vault_transfer_requests
            SET requested_by_user_id = (SELECT id FROM users ORDER BY created_at LIMIT 1)
            WHERE requested_by_user_id IS NULL;
        END IF;
    END IF;
    
    -- Add other missing columns
    ALTER TABLE vault_transfer_requests
    ADD COLUMN IF NOT EXISTS ml_score DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS ml_recommendation TEXT,
    ADD COLUMN IF NOT EXISTS threat_index DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS new_owner_email TEXT,
    ADD COLUMN IF NOT EXISTS new_owner_name TEXT,
    ADD COLUMN IF NOT EXISTS new_owner_phone TEXT,
    ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;
END $$;

-- Indexes for vault_transfer_requests
CREATE INDEX IF NOT EXISTS idx_vault_transfer_requests_vault_id ON vault_transfer_requests(vault_id);
CREATE INDEX IF NOT EXISTS idx_vault_transfer_requests_requested_by_user_id ON vault_transfer_requests(requested_by_user_id);
CREATE INDEX IF NOT EXISTS idx_vault_transfer_requests_transfer_token ON vault_transfer_requests(transfer_token);
CREATE INDEX IF NOT EXISTS idx_vault_transfer_requests_status ON vault_transfer_requests(status);
CREATE INDEX IF NOT EXISTS idx_vault_transfer_requests_new_owner_email ON vault_transfer_requests(new_owner_email) WHERE new_owner_email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_vault_transfer_requests_threat_index ON vault_transfer_requests(threat_index) WHERE threat_index IS NOT NULL;

-- ============================================
-- 2. Create document_versions table
-- ============================================

CREATE TABLE IF NOT EXISTS document_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    file_size BIGINT NOT NULL,
    storage_path TEXT, -- Path in Supabase Storage
    changes TEXT, -- Description of changes
    created_by_user_id UUID REFERENCES users(id),
    encryption_key_data BYTEA, -- Encrypted key for this version
    created_at_timestamp BIGINT NOT NULL DEFAULT EXTRACT(EPOCH FROM NOW()),
    
    -- Ensure unique version numbers per document
    CONSTRAINT unique_document_version UNIQUE(document_id, version_number)
);

-- Indexes for document_versions
CREATE INDEX IF NOT EXISTS idx_document_versions_document_id ON document_versions(document_id);
CREATE INDEX IF NOT EXISTS idx_document_versions_version_number ON document_versions(document_id, version_number);
CREATE INDEX IF NOT EXISTS idx_document_versions_created_at ON document_versions(created_at DESC);

-- ============================================
-- 3. Add threat assessment columns to existing tables
-- ============================================

-- Add threat_index to vaults table for real-time monitoring
ALTER TABLE vaults 
ADD COLUMN IF NOT EXISTS threat_index DOUBLE PRECISION DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS last_threat_assessment_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS threat_level TEXT DEFAULT 'low'; -- 'low', 'medium', 'high', 'critical'

-- Create index for threat monitoring queries
CREATE INDEX IF NOT EXISTS idx_vaults_threat_index ON vaults(threat_index) WHERE threat_index > 0;
CREATE INDEX IF NOT EXISTS idx_vaults_threat_level ON vaults(threat_level);

-- ============================================
-- 4. Create threat_events table for tracking security events
-- ============================================

CREATE TABLE IF NOT EXISTS threat_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID REFERENCES vaults(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    event_type TEXT NOT NULL, -- 'access_anomaly', 'transfer_request', 'ownership_change', 'deletion_spike', etc.
    severity TEXT NOT NULL DEFAULT 'low', -- 'low', 'medium', 'high', 'critical'
    threat_score DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    description TEXT,
    metadata JSONB, -- Additional event data
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolved_by_user_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for threat_events
CREATE INDEX IF NOT EXISTS idx_threat_events_vault_id ON threat_events(vault_id);
CREATE INDEX IF NOT EXISTS idx_threat_events_user_id ON threat_events(user_id);
CREATE INDEX IF NOT EXISTS idx_threat_events_event_type ON threat_events(event_type);
CREATE INDEX IF NOT EXISTS idx_threat_events_severity ON threat_events(severity);
CREATE INDEX IF NOT EXISTS idx_threat_events_detected_at ON threat_events(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_threat_events_unresolved ON threat_events(vault_id, detected_at DESC) WHERE resolved_at IS NULL;

-- ============================================
-- 5. Enable Row-Level Security on new tables
-- ============================================

ALTER TABLE vault_transfer_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE threat_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies for vault_transfer_requests
-- Users can view transfer requests they created
DROP POLICY IF EXISTS "Users can view transfer requests they created" ON vault_transfer_requests;
CREATE POLICY "Users can view transfer requests they created"
ON vault_transfer_requests FOR SELECT
USING (auth.uid()::text = requested_by_user_id::text);

-- Users can view transfer requests for vaults they own
DROP POLICY IF EXISTS "Vault owners can view transfer requests for their vaults" ON vault_transfer_requests;
CREATE POLICY "Vault owners can view transfer requests for their vaults"
ON vault_transfer_requests FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = vault_transfer_requests.vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
);

-- Users can view transfer requests where they are the new owner (via token)
-- Note: Token-based access is handled in application logic
DROP POLICY IF EXISTS "Users can view transfer requests for their email" ON vault_transfer_requests;
CREATE POLICY "Users can view transfer requests for their email"
ON vault_transfer_requests FOR SELECT
USING (
    new_owner_email = (SELECT email FROM users WHERE id::text = auth.uid()::text)
);

-- Users can create transfer requests for vaults they own
DROP POLICY IF EXISTS "Vault owners can create transfer requests" ON vault_transfer_requests;
CREATE POLICY "Vault owners can create transfer requests"
ON vault_transfer_requests FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = vault_transfer_requests.vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
    AND requested_by_user_id::text = auth.uid()::text
);

-- Users can update transfer requests they created (to complete/deny)
DROP POLICY IF EXISTS "Users can update their own transfer requests" ON vault_transfer_requests;
CREATE POLICY "Users can update their own transfer requests"
ON vault_transfer_requests FOR UPDATE
USING (requested_by_user_id::text = auth.uid()::text)
WITH CHECK (requested_by_user_id::text = auth.uid()::text);

-- RLS Policies for document_versions
-- Users can view versions for documents they have access to (via vault access)
DROP POLICY IF EXISTS "Users can view document versions for accessible documents" ON document_versions;
CREATE POLICY "Users can view document versions for accessible documents"
ON document_versions FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM documents d
        JOIN vaults v ON v.id = d.vault_id
        WHERE d.id = document_versions.document_id
        AND (
            v.owner_id::text = auth.uid()::text
            OR EXISTS (
                SELECT 1 FROM nominees n 
                WHERE n.vault_id = v.id 
                AND n.user_id::text = auth.uid()::text 
                AND n.status = 'accepted'
            )
            OR v.is_broadcast = true
        )
    )
);

-- Users can create versions for documents they have write access to
DROP POLICY IF EXISTS "Users can create document versions" ON document_versions;
CREATE POLICY "Users can create document versions"
ON document_versions FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM documents d
        JOIN vaults v ON v.id = d.vault_id
        WHERE d.id = document_versions.document_id
        AND (
            v.owner_id::text = auth.uid()::text
            OR EXISTS (
                SELECT 1 FROM nominees n 
                WHERE n.vault_id = v.id 
                AND n.user_id::text = auth.uid()::text 
                AND n.status = 'accepted'
            )
        )
    )
);

-- RLS Policies for threat_events
-- Users can view threat events for vaults they own
DROP POLICY IF EXISTS "Users can view threat events for their vaults" ON threat_events;
CREATE POLICY "Users can view threat events for their vaults"
ON threat_events FOR SELECT
USING (
    vault_id IS NULL OR
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = threat_events.vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
    OR user_id::text = auth.uid()::text
);

-- System can insert threat events (via service role or application logic)
-- Note: Threat events are typically created by ML services

-- Users can update threat events to mark as resolved
DROP POLICY IF EXISTS "Vault owners can resolve threat events" ON threat_events;
CREATE POLICY "Vault owners can resolve threat events"
ON threat_events FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = threat_events.vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
);

-- ============================================
-- 6. Create function to calculate real-time threat index for a vault
-- ============================================

CREATE OR REPLACE FUNCTION calculate_vault_threat_index(p_vault_id UUID)
RETURNS DOUBLE PRECISION AS $$
DECLARE
    v_threat_score DOUBLE PRECISION := 0.0;
    v_recent_events_count INTEGER := 0;
    v_critical_events_count INTEGER := 0;
    v_high_severity_count INTEGER := 0;
    v_transfer_requests_pending INTEGER := 0;
    v_high_threat_transfers DOUBLE PRECISION := 0.0;
BEGIN
    -- Count recent unresolved threat events (last 24 hours)
    SELECT COUNT(*), 
           COUNT(*) FILTER (WHERE severity = 'critical'),
           COUNT(*) FILTER (WHERE severity = 'high')
    INTO v_recent_events_count, v_critical_events_count, v_high_severity_count
    FROM threat_events
    WHERE vault_id = p_vault_id
      AND resolved_at IS NULL
      AND detected_at > NOW() - INTERVAL '24 hours';
    
    -- Base score from event counts
    v_threat_score := v_threat_score + (COALESCE(v_critical_events_count, 0) * 50.0);
    v_threat_score := v_threat_score + (COALESCE(v_high_severity_count, 0) * 20.0);
    v_threat_score := v_threat_score + (COALESCE(v_recent_events_count, 0) * 5.0);
    
    -- Check for pending transfer requests with high threat scores
    SELECT COUNT(*), COALESCE(SUM(threat_index), 0.0)
    INTO v_transfer_requests_pending, v_high_threat_transfers
    FROM vault_transfer_requests
    WHERE vault_id = p_vault_id
      AND status = 'pending'
      AND threat_index > 50.0;
    
    v_threat_score := v_threat_score + (COALESCE(v_transfer_requests_pending, 0) * 10.0);
    v_threat_score := v_threat_score + (COALESCE(v_high_threat_transfers, 0) * 0.5);
    
    -- Normalize to 0-100 scale
    v_threat_score := LEAST(100.0, GREATEST(0.0, v_threat_score));
    
    RETURN v_threat_score;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. Create function to update vault threat index
-- ============================================

CREATE OR REPLACE FUNCTION update_vault_threat_index()
RETURNS TRIGGER AS $$
DECLARE
    v_vault_id UUID;
    v_threat_index DOUBLE PRECISION;
BEGIN
    -- Get vault_id from the trigger context
    IF TG_TABLE_NAME = 'threat_events' THEN
        v_vault_id := NEW.vault_id;
    ELSIF TG_TABLE_NAME = 'vault_transfer_requests' THEN
        v_vault_id := NEW.vault_id;
    ELSE
        RETURN NEW;
    END IF;
    
    -- Skip if vault_id is NULL
    IF v_vault_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Calculate threat index
    v_threat_index := calculate_vault_threat_index(v_vault_id);
    
    -- Update threat index for the affected vault
    UPDATE vaults
    SET threat_index = v_threat_index,
        last_threat_assessment_at = NOW(),
        threat_level = CASE
            WHEN v_threat_index >= 80 THEN 'critical'
            WHEN v_threat_index >= 50 THEN 'high'
            WHEN v_threat_index >= 25 THEN 'medium'
            ELSE 'low'
        END,
        updated_at = NOW()
    WHERE id = v_vault_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update threat index when threat events change
DROP TRIGGER IF EXISTS trigger_update_vault_threat_index_on_threat_events ON threat_events;
CREATE TRIGGER trigger_update_vault_threat_index_on_threat_events
AFTER INSERT OR UPDATE ON threat_events
FOR EACH ROW
EXECUTE FUNCTION update_vault_threat_index();

-- Trigger to auto-update threat index when transfer requests change
DROP TRIGGER IF EXISTS trigger_update_vault_threat_index_on_transfer_requests ON vault_transfer_requests;
CREATE TRIGGER trigger_update_vault_threat_index_on_transfer_requests
AFTER INSERT OR UPDATE ON vault_transfer_requests
FOR EACH ROW
EXECUTE FUNCTION update_vault_threat_index();

-- ============================================
-- 8. Create function for ML threat assessment of transfer requests
-- ============================================

CREATE OR REPLACE FUNCTION assess_transfer_request_threat(
    p_transfer_request_id UUID
)
RETURNS TABLE(
    threat_score DOUBLE PRECISION,
    recommendation TEXT,
    threat_index DOUBLE PRECISION
) AS $$
DECLARE
    v_request RECORD;
    v_threat_score DOUBLE PRECISION := 0.0;
    v_recommendation TEXT := 'review';
    v_threat_index DOUBLE PRECISION := 0.0;
BEGIN
    -- Get transfer request details
    SELECT * INTO v_request
    FROM vault_transfer_requests
    WHERE id = p_transfer_request_id;
    
    -- Check for suspicious patterns:
    -- 1. Multiple recent transfer requests from same user
    -- Only check if requested_by_user_id exists and is not null
    IF v_request.requested_by_user_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_threat_score
        FROM vault_transfer_requests
        WHERE requested_by_user_id = v_request.requested_by_user_id
          AND requested_at > NOW() - INTERVAL '7 days'
          AND status != 'denied'
          AND id != v_request.id; -- Exclude current request
    ELSE
        v_threat_score := 0;
    END IF;
    
    IF v_threat_score > 3 THEN
        v_threat_score := v_threat_score * 10.0;
        v_recommendation := 'deny';
    END IF;
    
    -- 2. Check for unusual timing (late night transfers)
    IF EXTRACT(HOUR FROM v_request.requested_at) BETWEEN 0 AND 5 THEN
        v_threat_score := v_threat_score + 15.0;
    END IF;
    
    -- 3. Check if new owner email matches existing user
    IF EXISTS (
        SELECT 1 FROM users WHERE email = v_request.new_owner_email
    ) THEN
        v_threat_score := v_threat_score - 5.0; -- Lower risk if user exists
    ELSE
        v_threat_score := v_threat_score + 10.0; -- Higher risk for new users
    END IF;
    
    -- 4. Check vault's current threat index
    SELECT threat_index INTO v_threat_index
    FROM vaults
    WHERE id = v_request.vault_id;
    
    v_threat_score := v_threat_score + (v_threat_index * 0.3);
    
    -- Determine recommendation
    IF v_threat_score >= 70 THEN
        v_recommendation := 'deny';
    ELSIF v_threat_score >= 40 THEN
        v_recommendation := 'review';
    ELSE
        v_recommendation := 'approve';
    END IF;
    
    -- Normalize to 0-100
    v_threat_score := LEAST(100.0, GREATEST(0.0, v_threat_score));
    v_threat_index := v_threat_score; -- Use same value for threat_index
    
    RETURN QUERY SELECT v_threat_score, v_recommendation, v_threat_index;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 9. Create view for real-time threat dashboard
-- ============================================

DROP VIEW IF EXISTS vault_threat_dashboard;
CREATE VIEW vault_threat_dashboard AS
SELECT 
    v.id as vault_id,
    v.name as vault_name,
    v.owner_id,
    v.threat_index,
    v.threat_level,
    v.last_threat_assessment_at,
    COUNT(DISTINCT te.id) FILTER (WHERE te.resolved_at IS NULL) as unresolved_threat_events,
    COUNT(DISTINCT vtr.id) FILTER (WHERE vtr.status = 'pending') as pending_transfer_requests,
    MAX(te.detected_at) FILTER (WHERE te.resolved_at IS NULL) as latest_threat_event_at,
    MAX(te.threat_score) FILTER (WHERE te.resolved_at IS NULL) as highest_threat_score
FROM vaults v
LEFT JOIN threat_events te ON te.vault_id = v.id
LEFT JOIN vault_transfer_requests vtr ON vtr.vault_id = v.id
GROUP BY v.id, v.name, v.owner_id, v.threat_index, v.threat_level, v.last_threat_assessment_at;

-- ============================================
-- 10. Verification Queries
-- ============================================

-- Verify tables created
SELECT table_name 
FROM information_schema.tables 
WHERE table_name IN ('vault_transfer_requests', 'document_versions', 'threat_events');

-- Verify columns added to vaults
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'vaults' 
AND column_name IN ('threat_index', 'last_threat_assessment_at', 'threat_level');

-- Verify indexes
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename IN ('vault_transfer_requests', 'document_versions', 'threat_events', 'vaults')
AND indexname LIKE '%transfer%' OR indexname LIKE '%version%' OR indexname LIKE '%threat%';

-- Verify RLS policies
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('vault_transfer_requests', 'document_versions', 'threat_events');

-- Test threat index calculation (replace with actual vault_id)
-- SELECT calculate_vault_threat_index('your-vault-id-here');

-- ============================================
-- Notes:
-- ============================================
-- 1. ML threat assessment should be enhanced with actual ML models
-- 2. Threat index calculation can be customized based on business rules
-- 3. Real-time updates via Supabase Realtime subscriptions
-- 4. Consider adding background jobs to periodically recalculate threat indices
-- 5. Document version history should be automatically created on document updates

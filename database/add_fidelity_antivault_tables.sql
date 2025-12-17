-- Add Document Fidelity and Anti-Vault Tables
-- Migration script for document fidelity tracking and anti-vault fraud detection

-- ============================================================================
-- DOCUMENT FIDELITY TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS document_fidelity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    transfer_count INT DEFAULT 0,
    edit_count INT DEFAULT 0,
    transfer_history JSONB DEFAULT '[]'::jsonb,
    edit_history JSONB DEFAULT '[]'::jsonb,
    fidelity_score INT DEFAULT 100 CHECK (fidelity_score >= 0 AND fidelity_score <= 100),
    threat_indicators JSONB DEFAULT '[]'::jsonb,
    unique_device_count INT DEFAULT 0,
    unique_ip_count INT DEFAULT 0,
    unique_location_count INT DEFAULT 0,
    last_computed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(document_id)
);

CREATE INDEX idx_document_fidelity_document_id ON document_fidelity(document_id);
CREATE INDEX idx_document_fidelity_score ON document_fidelity(fidelity_score);
CREATE INDEX idx_document_fidelity_last_computed ON document_fidelity(last_computed_at);

-- ============================================================================
-- ANTI-VAULTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS anti_vaults (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    monitored_vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'locked' CHECK (status IN ('locked', 'active', 'archived')),
    auto_unlock_policy JSONB DEFAULT '{"unlock_on_session_nomination": true, "unlock_on_subset_nomination": true, "require_approval": false, "approval_user_ids": []}'::jsonb,
    threat_detection_settings JSONB DEFAULT '{"detect_content_discrepancies": true, "detect_metadata_mismatches": true, "detect_access_pattern_anomalies": true, "detect_geographic_inconsistencies": true, "detect_edit_history_discrepancies": true, "min_threat_severity": "medium"}'::jsonb,
    last_intel_report_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_unlocked_at TIMESTAMPTZ
);

CREATE INDEX idx_anti_vaults_vault_id ON anti_vaults(vault_id);
CREATE INDEX idx_anti_vaults_monitored_vault_id ON anti_vaults(monitored_vault_id);
CREATE INDEX idx_anti_vaults_owner_id ON anti_vaults(owner_id);
CREATE INDEX idx_anti_vaults_status ON anti_vaults(status);

-- ============================================================================
-- UPDATE EXISTING TABLES
-- ============================================================================

-- Add is_anti_vault flag to vaults table
ALTER TABLE vaults ADD COLUMN IF NOT EXISTS is_anti_vault BOOLEAN DEFAULT FALSE;
ALTER TABLE vaults ADD COLUMN IF NOT EXISTS monitored_vault_id UUID REFERENCES vaults(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_vaults_is_anti_vault ON vaults(is_anti_vault);
CREATE INDEX IF NOT EXISTS idx_vaults_monitored_vault_id ON vaults(monitored_vault_id);

-- Add fidelity_tracked flag to documents table
ALTER TABLE documents ADD COLUMN IF NOT EXISTS fidelity_tracked BOOLEAN DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_documents_fidelity_tracked ON documents(fidelity_tracked);

-- ============================================================================
-- ROW-LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on document_fidelity
ALTER TABLE document_fidelity ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own document fidelity records
CREATE POLICY "Users can read own document fidelity"
    ON document_fidelity
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM documents d
            JOIN vaults v ON d.vault_id = v.id
            WHERE d.id = document_fidelity.document_id
            AND (v.owner_id = auth.uid() OR EXISTS (
                SELECT 1 FROM nominees n
                WHERE n.vault_id = v.id
                AND n.user_id = auth.uid()
                AND n.status = 'accepted'
            ))
        )
    );

-- Policy: System can insert/update fidelity records (via service role)
CREATE POLICY "Service can manage document fidelity"
    ON document_fidelity
    FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- Enable RLS on anti_vaults
ALTER TABLE anti_vaults ENABLE ROW LEVEL SECURITY;

-- Policy: Only authorized departments (users with specific role) can create/manage anti-vaults
CREATE POLICY "Authorized departments can manage anti-vaults"
    ON anti_vaults
    FOR ALL
    USING (
        owner_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM user_roles ur
            WHERE ur.user_id = auth.uid()
            AND ur.role_raw_value = 'authorized_department'
            AND ur.is_active = TRUE
        )
    )
    WITH CHECK (
        owner_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM user_roles ur
            WHERE ur.user_id = auth.uid()
            AND ur.role_raw_value = 'authorized_department'
            AND ur.is_active = TRUE
        )
    );

-- Policy: Anti-vault owners can read their anti-vaults
CREATE POLICY "Anti-vault owners can read"
    ON anti_vaults
    FOR SELECT
    USING (owner_id = auth.uid());

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for document_fidelity updated_at
CREATE TRIGGER update_document_fidelity_updated_at
    BEFORE UPDATE ON document_fidelity
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for anti_vaults updated_at
CREATE TRIGGER update_anti_vaults_updated_at
    BEFORE UPDATE ON anti_vaults
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE document_fidelity IS 'Tracks document fidelity metrics including transfers, edits, and threat patterns';
COMMENT ON TABLE anti_vaults IS 'Special vaults for fraud detection that monitor other vaults and auto-unlock on session nominations';
COMMENT ON COLUMN document_fidelity.fidelity_score IS 'Computed score 0-100 where 100 = pristine, 0 = highly suspicious';
COMMENT ON COLUMN anti_vaults.monitored_vault_id IS 'The vault being monitored (many-to-one: multiple anti-vaults can monitor one vault)';

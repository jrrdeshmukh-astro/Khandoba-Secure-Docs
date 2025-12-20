-- ============================================================================
-- KHANDOBA SECURE DOCS - CLEAN DATABASE SCHEMA REBUILD
-- ============================================================================
-- This script creates a clean, consistent database schema from scratch
-- Run this to rebuild your database and remove all inconsistencies
--
-- WARNING: This will DROP ALL EXISTING TABLES and recreate them
-- Backup your data before running if needed
--
-- Usage: Run in Supabase SQL Editor
-- ============================================================================

BEGIN;

-- ============================================================================
-- DROP ALL EXISTING TABLES (in reverse dependency order)
-- ============================================================================

DROP TABLE IF EXISTS threat_events CASCADE;
DROP TABLE IF EXISTS vault_transfer_requests CASCADE;
DROP TABLE IF EXISTS document_versions CASCADE;
DROP TABLE IF EXISTS emergency_access_passes CASCADE;
DROP TABLE IF EXISTS emergency_access_requests CASCADE;
DROP TABLE IF EXISTS dual_key_requests CASCADE;
DROP TABLE IF EXISTS vault_access_logs CASCADE;
DROP TABLE IF EXISTS vault_sessions CASCADE;
DROP TABLE IF EXISTS nominees CASCADE;
DROP TABLE IF EXISTS vault_access_requests CASCADE;
DROP TABLE IF EXISTS document_fidelity CASCADE;
DROP TABLE IF EXISTS documents CASCADE;
DROP TABLE IF EXISTS anti_vaults CASCADE;
DROP TABLE IF EXISTS vaults CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop functions and views
DROP FUNCTION IF EXISTS calculate_vault_threat_index(UUID) CASCADE;
DROP FUNCTION IF EXISTS update_vault_threat_index() CASCADE;
DROP FUNCTION IF EXISTS assess_transfer_request_threat(UUID) CASCADE;
DROP VIEW IF EXISTS vault_threat_dashboard CASCADE;

-- ============================================================================
-- ENABLE EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. USERS TABLE
-- ============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Platform-specific user IDs (one will be populated per platform)
    -- Note: These are optional to allow flexibility, but at least one should be set by application logic
    apple_user_id TEXT UNIQUE, -- For Apple platforms (iOS, macOS, etc.)
    google_user_id TEXT UNIQUE, -- For Android
    microsoft_user_id TEXT UNIQUE, -- For Windows
    
    full_name TEXT NOT NULL,
    email TEXT,
    profile_picture_url TEXT,
    
    -- Subscription info
    is_premium_subscriber BOOLEAN DEFAULT FALSE,
    subscription_expiry_date TIMESTAMPTZ,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    
    -- Note: Platform ID check removed - application layer should enforce this
    -- This allows more flexibility for user creation flows
    -- At least one of apple_user_id, google_user_id, or microsoft_user_id should be set
    -- by application logic when creating users
);

CREATE INDEX idx_users_apple_user_id ON users(apple_user_id) WHERE apple_user_id IS NOT NULL;
CREATE INDEX idx_users_google_user_id ON users(google_user_id) WHERE google_user_id IS NOT NULL;
CREATE INDEX idx_users_microsoft_user_id ON users(microsoft_user_id) WHERE microsoft_user_id IS NOT NULL;
CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_is_active ON users(is_active);

-- ============================================================================
-- 2. USER ROLES TABLE (deprecated - autopilot mode, but keeping for compatibility)
-- ============================================================================

CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_raw_value TEXT NOT NULL DEFAULT 'client',
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, role_raw_value)
);

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_is_active ON user_roles(is_active);

-- ============================================================================
-- 3. VAULTS TABLE
-- ============================================================================

CREATE TABLE vaults (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    vault_description TEXT,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Vault properties
    status TEXT NOT NULL DEFAULT 'locked', -- 'active', 'locked', 'archived'
    key_type TEXT NOT NULL DEFAULT 'single', -- 'single', 'dual'
    vault_type TEXT NOT NULL DEFAULT 'both', -- 'source', 'sink', 'both'
    
    -- System and broadcast vaults
    is_system_vault BOOLEAN NOT NULL DEFAULT FALSE,
    is_broadcast BOOLEAN NOT NULL DEFAULT FALSE,
    access_level TEXT DEFAULT 'private', -- 'private', 'public_read', 'public_write', 'moderated'
    
    -- Anti-vault support
    is_anti_vault BOOLEAN NOT NULL DEFAULT FALSE,
    monitored_vault_id UUID REFERENCES vaults(id) ON DELETE SET NULL,
    anti_vault_id UUID REFERENCES vaults(id) ON DELETE SET NULL,
    
    -- Encryption
    encryption_key_data BYTEA,
    is_encrypted BOOLEAN NOT NULL DEFAULT TRUE,
    is_zero_knowledge BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Relationship officer (deprecated but kept for compatibility)
    relationship_officer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Threat monitoring (added in recent migrations)
    threat_index DOUBLE PRECISION DEFAULT 0.0,
    threat_level TEXT DEFAULT 'low', -- 'low', 'medium', 'high', 'critical'
    last_threat_assessment_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vaults_owner_id ON vaults(owner_id);
CREATE INDEX idx_vaults_status ON vaults(status);
CREATE INDEX idx_vaults_key_type ON vaults(key_type);
CREATE INDEX idx_vaults_is_system_vault ON vaults(is_system_vault);
CREATE INDEX idx_vaults_is_broadcast ON vaults(is_broadcast);
CREATE INDEX idx_vaults_is_anti_vault ON vaults(is_anti_vault);
CREATE INDEX idx_vaults_monitored_vault_id ON vaults(monitored_vault_id) WHERE monitored_vault_id IS NOT NULL;
CREATE INDEX idx_vaults_threat_index ON vaults(threat_index) WHERE threat_index > 0;
CREATE INDEX idx_vaults_threat_level ON vaults(threat_level);

-- ============================================================================
-- 4. VAULT SESSIONS TABLE
-- ============================================================================

CREATE TABLE vault_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    was_extended BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vault_sessions_vault_id ON vault_sessions(vault_id);
CREATE INDEX idx_vault_sessions_user_id ON vault_sessions(user_id);
CREATE INDEX idx_vault_sessions_is_active ON vault_sessions(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_vault_sessions_expires_at ON vault_sessions(expires_at);

-- ============================================================================
-- 5. VAULT ACCESS LOGS TABLE
-- ============================================================================

CREATE TABLE vault_access_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    access_type TEXT NOT NULL DEFAULT 'viewed', -- 'opened', 'closed', 'viewed', 'modified', 'deleted', etc.
    user_name TEXT,
    device_info TEXT,
    location_latitude DOUBLE PRECISION,
    location_longitude DOUBLE PRECISION,
    ip_address TEXT,
    document_id UUID, -- References documents(id) but no FK to allow deletion
    document_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vault_access_logs_vault_id ON vault_access_logs(vault_id);
CREATE INDEX idx_vault_access_logs_user_id ON vault_access_logs(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_vault_access_logs_timestamp ON vault_access_logs(timestamp DESC);
CREATE INDEX idx_vault_access_logs_access_type ON vault_access_logs(access_type);
CREATE INDEX idx_vault_access_logs_document_id ON vault_access_logs(document_id) WHERE document_id IS NOT NULL;

-- ============================================================================
-- 6. DOCUMENTS TABLE
-- ============================================================================

CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    
    -- File properties
    file_extension TEXT,
    mime_type TEXT,
    file_size BIGINT NOT NULL DEFAULT 0,
    storage_path TEXT, -- Path in Supabase Storage bucket
    
    -- Encryption
    encryption_key_data BYTEA, -- Document-specific encryption key
    is_encrypted BOOLEAN NOT NULL DEFAULT TRUE,
    
    -- Classification
    document_type TEXT NOT NULL DEFAULT 'other', -- 'image', 'pdf', 'video', 'audio', 'text', 'other'
    source_sink_type TEXT DEFAULT 'both', -- 'source', 'sink', 'both'
    
    -- Status
    status TEXT NOT NULL DEFAULT 'active', -- 'active', 'archived', 'deleted'
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    is_redacted BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Content analysis
    extracted_text TEXT,
    ai_tags TEXT[], -- Array of tags from NLP analysis
    file_hash TEXT, -- SHA-256 hash for deduplication
    
    -- Metadata
    metadata JSONB, -- Additional metadata (camera info, device info, etc.)
    author TEXT,
    camera_info TEXT,
    device_id TEXT,
    uploaded_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_modified_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_documents_vault_id ON documents(vault_id);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_document_type ON documents(document_type);
CREATE INDEX idx_documents_is_archived ON documents(is_archived);
CREATE INDEX idx_documents_created_at ON documents(created_at DESC);
CREATE INDEX idx_documents_ai_tags ON documents USING GIN(ai_tags);

-- ============================================================================
-- 7. DOCUMENT VERSIONS TABLE
-- ============================================================================

CREATE TABLE document_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    file_size BIGINT NOT NULL,
    storage_path TEXT,
    changes TEXT, -- Description of changes
    created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    encryption_key_data BYTEA,
    created_at_timestamp BIGINT NOT NULL DEFAULT EXTRACT(EPOCH FROM NOW()),
    
    -- Ensure unique version numbers per document
    CONSTRAINT unique_document_version UNIQUE(document_id, version_number)
);

CREATE INDEX idx_document_versions_document_id ON document_versions(document_id);
CREATE INDEX idx_document_versions_version_number ON document_versions(document_id, version_number);
CREATE INDEX idx_document_versions_created_at ON document_versions(created_at DESC);

-- ============================================================================
-- 8. NOMINEES TABLE
-- ============================================================================

CREATE TABLE nominees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invited_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Status
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'revoked', 'active', 'inactive'
    
    -- Access control
    access_level TEXT NOT NULL DEFAULT 'read', -- 'read', 'write', 'admin'
    is_subset_access BOOLEAN NOT NULL DEFAULT FALSE,
    selected_document_ids UUID[], -- Array of document IDs for subset access (stored as UUID array)
    session_expires_at TIMESTAMPTZ, -- Time-bound access expiration
    
    -- Note: Name, email, phone_number should come from users table via user_id join
    -- user_id is the primary reference to the users table
    
    -- Timestamps
    invited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    declined_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Ensure unique nominee per vault
    UNIQUE(vault_id, user_id)
);

CREATE INDEX idx_nominees_vault_id ON nominees(vault_id);
CREATE INDEX idx_nominees_user_id ON nominees(user_id);
CREATE INDEX idx_nominees_status ON nominees(status);
CREATE INDEX idx_nominees_invited_by_user_id ON nominees(invited_by_user_id) WHERE invited_by_user_id IS NOT NULL;

-- ============================================================================
-- 9. VAULT ACCESS REQUESTS TABLE
-- ============================================================================

CREATE TABLE vault_access_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'denied'
    request_type TEXT NOT NULL DEFAULT 'request', -- 'request', 'send'
    message TEXT,
    expires_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,
    response_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vault_access_requests_vault_id ON vault_access_requests(vault_id);
CREATE INDEX idx_vault_access_requests_requester_id ON vault_access_requests(requester_id);
CREATE INDEX idx_vault_access_requests_status ON vault_access_requests(status);

-- ============================================================================
-- 10. DUAL KEY REQUESTS TABLE
-- ============================================================================

CREATE TABLE dual_key_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'denied'
    reason TEXT,
    approved_at TIMESTAMPTZ,
    denied_at TIMESTAMPTZ,
    approver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- ML and logic reasoning
    ml_score DOUBLE PRECISION,
    logical_reasoning TEXT,
    decision_method TEXT, -- 'ml_auto', 'logic_reasoning', 'manual'
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dual_key_requests_vault_id ON dual_key_requests(vault_id);
CREATE INDEX idx_dual_key_requests_requester_id ON dual_key_requests(requester_id);
CREATE INDEX idx_dual_key_requests_status ON dual_key_requests(status);

-- ============================================================================
-- 11. EMERGENCY ACCESS REQUESTS TABLE
-- ============================================================================

CREATE TABLE emergency_access_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reason TEXT NOT NULL,
    urgency TEXT NOT NULL DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'denied'
    approved_at TIMESTAMPTZ,
    approver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    expires_at TIMESTAMPTZ, -- 24 hours from approval
    
    -- Emergency pass code
    pass_code TEXT UNIQUE, -- Generated identification pass code (UUID string)
    
    -- ML assessment
    ml_score DOUBLE PRECISION,
    ml_recommendation TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_emergency_access_requests_vault_id ON emergency_access_requests(vault_id);
CREATE INDEX idx_emergency_access_requests_requester_id ON emergency_access_requests(requester_id);
CREATE INDEX idx_emergency_access_requests_status ON emergency_access_requests(status);
CREATE INDEX idx_emergency_access_requests_pass_code ON emergency_access_requests(pass_code) WHERE pass_code IS NOT NULL;

-- ============================================================================
-- 12. EMERGENCY ACCESS PASSES TABLE
-- ============================================================================

CREATE TABLE emergency_access_passes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emergency_request_id UUID NOT NULL REFERENCES emergency_access_requests(id) ON DELETE CASCADE,
    pass_code TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_emergency_access_passes_pass_code ON emergency_access_passes(pass_code);
CREATE INDEX idx_emergency_access_passes_vault_id ON emergency_access_passes(vault_id);
CREATE INDEX idx_emergency_access_passes_requester_id ON emergency_access_passes(requester_id);
CREATE INDEX idx_emergency_access_passes_expires_at ON emergency_access_passes(expires_at);
CREATE INDEX idx_emergency_access_passes_is_active ON emergency_access_passes(is_active);

-- ============================================================================
-- 13. VAULT TRANSFER REQUESTS TABLE
-- ============================================================================

CREATE TABLE vault_transfer_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    requested_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'denied', 'completed'
    
    -- New owner info
    new_owner_id UUID REFERENCES users(id) ON DELETE SET NULL,
    new_owner_name TEXT,
    new_owner_phone TEXT,
    new_owner_email TEXT,
    transfer_token TEXT NOT NULL UNIQUE,
    
    -- Approval info
    approved_at TIMESTAMPTZ,
    approver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    completed_at TIMESTAMPTZ,
    reason TEXT,
    
    -- ML threat assessment
    ml_score DOUBLE PRECISION,
    ml_recommendation TEXT, -- 'approve', 'deny', 'review'
    threat_index DOUBLE PRECISION,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vault_transfer_requests_vault_id ON vault_transfer_requests(vault_id);
CREATE INDEX idx_vault_transfer_requests_requested_by_user_id ON vault_transfer_requests(requested_by_user_id);
CREATE INDEX idx_vault_transfer_requests_transfer_token ON vault_transfer_requests(transfer_token);
CREATE INDEX idx_vault_transfer_requests_status ON vault_transfer_requests(status);
CREATE INDEX idx_vault_transfer_requests_new_owner_email ON vault_transfer_requests(new_owner_email) WHERE new_owner_email IS NOT NULL;
CREATE INDEX idx_vault_transfer_requests_threat_index ON vault_transfer_requests(threat_index) WHERE threat_index IS NOT NULL;

-- ============================================================================
-- 14. THREAT EVENTS TABLE
-- ============================================================================

CREATE TABLE threat_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID REFERENCES vaults(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL, -- 'access_anomaly', 'transfer_request', 'ownership_change', 'deletion_spike', etc.
    severity TEXT NOT NULL DEFAULT 'low', -- 'low', 'medium', 'high', 'critical'
    threat_score DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    description TEXT,
    metadata JSONB, -- Additional event data
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolved_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_threat_events_vault_id ON threat_events(vault_id);
CREATE INDEX idx_threat_events_user_id ON threat_events(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_threat_events_event_type ON threat_events(event_type);
CREATE INDEX idx_threat_events_severity ON threat_events(severity);
CREATE INDEX idx_threat_events_detected_at ON threat_events(detected_at DESC);
CREATE INDEX idx_threat_events_unresolved ON threat_events(vault_id, detected_at DESC) WHERE resolved_at IS NULL;

-- ============================================================================
-- 15. ANTI-VAULTS TABLE (for document fidelity monitoring)
-- ============================================================================

CREATE TABLE anti_vaults (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    monitored_vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'locked', -- 'active', 'locked', 'archived'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_unlocked_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Anti-vault specific settings (stored as JSONB for flexibility)
    auto_unlock_policy JSONB,
    threat_detection_settings JSONB,
    last_intel_report_id UUID,
    
    UNIQUE(monitored_vault_id)
);

CREATE INDEX idx_anti_vaults_monitored_vault_id ON anti_vaults(monitored_vault_id);
CREATE INDEX idx_anti_vaults_status ON anti_vaults(status);

-- ============================================================================
-- 16. DOCUMENT FIDELITY TABLE (Enhanced - matches SupabaseDocumentFidelity model)
-- ============================================================================

CREATE TABLE document_fidelity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    anti_vault_id UUID NOT NULL REFERENCES anti_vaults(id) ON DELETE CASCADE,
    fidelity_score INTEGER NOT NULL DEFAULT 0, -- 0 to 100 (matching model)
    transfer_count INTEGER NOT NULL DEFAULT 0,
    edit_count INTEGER NOT NULL DEFAULT 0,
    transfer_history JSONB, -- Array of TransferEvent objects
    edit_history JSONB, -- Array of EditEvent objects
    threat_indicators JSONB, -- Array of ThreatIndicator objects
    unique_device_count INTEGER NOT NULL DEFAULT 0,
    unique_ip_count INTEGER NOT NULL DEFAULT 0,
    unique_location_count INTEGER NOT NULL DEFAULT 0,
    last_computed_at TIMESTAMPTZ,
    last_verified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    verification_method TEXT, -- 'hash', 'size', 'content', etc.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(document_id, anti_vault_id)
);

CREATE INDEX idx_document_fidelity_document_id ON document_fidelity(document_id);
CREATE INDEX idx_document_fidelity_anti_vault_id ON document_fidelity(anti_vault_id);

-- ============================================================================
-- 17. CHAT MESSAGES TABLE (for LLM support chat)
-- ============================================================================

CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    is_from_system BOOLEAN NOT NULL DEFAULT FALSE, -- True for LLM/system messages
    receiver_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Optional: for direct messages
    vault_id UUID REFERENCES vaults(id) ON DELETE SET NULL, -- Optional: for vault-specific chat
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX idx_chat_messages_receiver_id ON chat_messages(receiver_id) WHERE receiver_id IS NOT NULL;
CREATE INDEX idx_chat_messages_vault_id ON chat_messages(vault_id) WHERE vault_id IS NOT NULL;
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at DESC);

-- ============================================================================
-- 18. ENABLE ROW-LEVEL SECURITY
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaults ENABLE ROW LEVEL SECURITY;
ALTER TABLE vault_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE vault_access_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE nominees ENABLE ROW LEVEL SECURITY;
ALTER TABLE vault_access_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE dual_key_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_access_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_access_passes ENABLE ROW LEVEL SECURITY;
ALTER TABLE vault_transfer_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE threat_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE anti_vaults ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_fidelity ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 19. RLS POLICIES
-- ============================================================================

-- Users: Can view/update their own profile
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
CREATE POLICY "Users can view their own profile"
ON users FOR SELECT
USING (auth.uid()::text = id::text);

DROP POLICY IF EXISTS "Users can update their own profile" ON users;
CREATE POLICY "Users can update their own profile"
ON users FOR UPDATE
USING (auth.uid()::text = id::text);

-- Vaults: Users can view vaults they own or are nominees of
DROP POLICY IF EXISTS "Users can view their vaults" ON vaults;
CREATE POLICY "Users can view their vaults"
ON vaults FOR SELECT
USING (
    owner_id::text = auth.uid()::text
    OR EXISTS (
        SELECT 1 FROM nominees 
        WHERE nominees.vault_id = vaults.id 
        AND nominees.user_id::text = auth.uid()::text 
        AND nominees.status IN ('accepted', 'active')
    )
    OR (is_broadcast = true AND auth.uid() IS NOT NULL)
);

-- Vaults: Users can create vaults
DROP POLICY IF EXISTS "Users can create vaults" ON vaults;
CREATE POLICY "Users can create vaults"
ON vaults FOR INSERT
WITH CHECK (owner_id::text = auth.uid()::text);

-- Vaults: Owners can update their vaults
DROP POLICY IF EXISTS "Vault owners can update their vaults" ON vaults;
CREATE POLICY "Vault owners can update their vaults"
ON vaults FOR UPDATE
USING (owner_id::text = auth.uid()::text);

-- Broadcast vault write access
DROP POLICY IF EXISTS "Broadcast vault write access" ON vaults;
CREATE POLICY "Broadcast vault write access"
ON vaults FOR UPDATE
USING (
    is_broadcast = true AND
    (
        owner_id::text = auth.uid()::text
        OR (access_level = 'public_write' AND auth.uid() IS NOT NULL)
    )
);

-- Documents: Users can view documents in vaults they have access to
DROP POLICY IF EXISTS "Users can view documents in accessible vaults" ON documents;
CREATE POLICY "Users can view documents in accessible vaults"
ON documents FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = documents.vault_id
        AND (
            vaults.owner_id::text = auth.uid()::text
            OR EXISTS (
                SELECT 1 FROM nominees 
                WHERE nominees.vault_id = vaults.id 
                AND nominees.user_id::text = auth.uid()::text 
                AND nominees.status IN ('accepted', 'active')
            )
            OR vaults.is_broadcast = true
        )
    )
);

-- Documents: Users can create documents in vaults they have write access to
DROP POLICY IF EXISTS "Users can create documents" ON documents;
CREATE POLICY "Users can create documents"
ON documents FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = documents.vault_id
        AND (
            vaults.owner_id::text = auth.uid()::text
            OR EXISTS (
                SELECT 1 FROM nominees 
                WHERE nominees.vault_id = vaults.id 
                AND nominees.user_id::text = auth.uid()::text 
                AND nominees.status IN ('accepted', 'active')
                AND nominees.access_level IN ('write', 'admin')
            )
        )
    )
);

-- Documents: Users can update documents in vaults they own or have write access to
DROP POLICY IF EXISTS "Users can update documents" ON documents;
CREATE POLICY "Users can update documents"
ON documents FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = documents.vault_id
        AND (
            vaults.owner_id::text = auth.uid()::text
            OR EXISTS (
                SELECT 1 FROM nominees 
                WHERE nominees.vault_id = vaults.id 
                AND nominees.user_id::text = auth.uid()::text 
                AND nominees.status IN ('accepted', 'active')
                AND nominees.access_level IN ('write', 'admin')
            )
        )
    )
);

-- Nominees: Users can view nominees for vaults they own
DROP POLICY IF EXISTS "Vault owners can view nominees" ON nominees;
CREATE POLICY "Vault owners can view nominees"
ON nominees FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = nominees.vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
    OR user_id::text = auth.uid()::text -- Users can see their own nominations
);

-- Nominees: Vault owners can create nominees
DROP POLICY IF EXISTS "Vault owners can create nominees" ON nominees;
CREATE POLICY "Vault owners can create nominees"
ON nominees FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = nominees.vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
);

-- Nominees: Vault owners can update nominees
DROP POLICY IF EXISTS "Vault owners can update nominees" ON nominees;
CREATE POLICY "Vault owners can update nominees"
ON nominees FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = nominees.vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
);

-- Nominees: Users can update their own nominee status (to accept/decline)
DROP POLICY IF EXISTS "Users can update their own nominee status" ON nominees;
CREATE POLICY "Users can update their own nominee status"
ON nominees FOR UPDATE
USING (user_id::text = auth.uid()::text)
WITH CHECK (user_id::text = auth.uid()::text);

-- Document Versions: Same access as documents
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
                AND n.status IN ('accepted', 'active')
            )
            OR v.is_broadcast = true
        )
    )
);

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
                AND n.status IN ('accepted', 'active')
                AND n.access_level IN ('write', 'admin')
            )
        )
    )
);

-- Vault Transfer Requests: Users can view requests they created or for their vaults
DROP POLICY IF EXISTS "Users can view transfer requests they created" ON vault_transfer_requests;
CREATE POLICY "Users can view transfer requests they created"
ON vault_transfer_requests FOR SELECT
USING (auth.uid()::text = requested_by_user_id::text);

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

DROP POLICY IF EXISTS "Users can view transfer requests for their email" ON vault_transfer_requests;
CREATE POLICY "Users can view transfer requests for their email"
ON vault_transfer_requests FOR SELECT
USING (
    new_owner_email = (SELECT email FROM users WHERE id::text = auth.uid()::text)
);

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

DROP POLICY IF EXISTS "Users can update their own transfer requests" ON vault_transfer_requests;
CREATE POLICY "Users can update their own transfer requests"
ON vault_transfer_requests FOR UPDATE
USING (requested_by_user_id::text = auth.uid()::text)
WITH CHECK (requested_by_user_id::text = auth.uid()::text);

-- Emergency Access Requests: Similar to transfer requests
DROP POLICY IF EXISTS "Users can view their emergency access requests" ON emergency_access_requests;
CREATE POLICY "Users can view their emergency access requests"
ON emergency_access_requests FOR SELECT
USING (auth.uid()::text = requester_id::text);

DROP POLICY IF EXISTS "Vault owners can view emergency access requests for their vaults" ON emergency_access_requests;
CREATE POLICY "Vault owners can view emergency access requests for their vaults"
ON emergency_access_requests FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = emergency_access_requests.vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
);

DROP POLICY IF EXISTS "Users can create emergency access requests" ON emergency_access_requests;
CREATE POLICY "Users can create emergency access requests"
ON emergency_access_requests FOR INSERT
WITH CHECK (auth.uid()::text = requester_id::text);

-- Emergency Access Passes: Users can view passes they created
DROP POLICY IF EXISTS "Users can view their own emergency passes" ON emergency_access_passes;
CREATE POLICY "Users can view their own emergency passes"
ON emergency_access_passes FOR SELECT
USING (auth.uid()::text = requester_id::text);

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

-- Threat Events: Users can view threat events for vaults they own
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

-- Vault Sessions: Users can view their own sessions
DROP POLICY IF EXISTS "Users can view their vault sessions" ON vault_sessions;
CREATE POLICY "Users can view their vault sessions"
ON vault_sessions FOR SELECT
USING (auth.uid()::text = user_id::text);

-- Vault Access Logs: Users can view logs for vaults they own
DROP POLICY IF EXISTS "Users can view access logs for their vaults" ON vault_access_logs;
CREATE POLICY "Users can view access logs for their vaults"
ON vault_access_logs FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = vault_access_logs.vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
);

-- Chat Messages: Users can view their own messages
DROP POLICY IF EXISTS "Users can view their chat messages" ON chat_messages;
CREATE POLICY "Users can view their chat messages"
ON chat_messages FOR SELECT
USING (auth.uid()::text = sender_id::text);

DROP POLICY IF EXISTS "Users can create chat messages" ON chat_messages;
CREATE POLICY "Users can create chat messages"
ON chat_messages FOR INSERT
WITH CHECK (auth.uid()::text = sender_id::text);

-- Anti-vaults: Users can view anti-vaults for vaults they own
DROP POLICY IF EXISTS "Users can view anti-vaults for their vaults" ON anti_vaults;
CREATE POLICY "Users can view anti-vaults for their vaults"
ON anti_vaults FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = anti_vaults.monitored_vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
);

-- Document Fidelity: Users can view fidelity data for documents they have access to
DROP POLICY IF EXISTS "Users can view document fidelity for accessible documents" ON document_fidelity;
CREATE POLICY "Users can view document fidelity for accessible documents"
ON document_fidelity FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM documents d
        JOIN vaults v ON v.id = d.vault_id
        WHERE d.id = document_fidelity.document_id
        AND (
            v.owner_id::text = auth.uid()::text
            OR EXISTS (
                SELECT 1 FROM nominees n 
                WHERE n.vault_id = v.id 
                AND n.user_id::text = auth.uid()::text 
                AND n.status IN ('accepted', 'active')
            )
        )
    )
);

-- Dual Key Requests: Similar to other requests
DROP POLICY IF EXISTS "Users can view their dual key requests" ON dual_key_requests;
CREATE POLICY "Users can view their dual key requests"
ON dual_key_requests FOR SELECT
USING (auth.uid()::text = requester_id::text);

DROP POLICY IF EXISTS "Vault owners can view dual key requests for their vaults" ON dual_key_requests;
CREATE POLICY "Vault owners can view dual key requests for their vaults"
ON dual_key_requests FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = dual_key_requests.vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
);

-- Vault Access Requests: Similar pattern
DROP POLICY IF EXISTS "Users can view their vault access requests" ON vault_access_requests;
CREATE POLICY "Users can view their vault access requests"
ON vault_access_requests FOR SELECT
USING (auth.uid()::text = requester_id::text);

DROP POLICY IF EXISTS "Vault owners can view access requests for their vaults" ON vault_access_requests;
CREATE POLICY "Vault owners can view access requests for their vaults"
ON vault_access_requests FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM vaults 
        WHERE vaults.id = vault_access_requests.vault_id 
        AND vaults.owner_id::text = auth.uid()::text
    )
);

-- ============================================================================
-- 20. THREAT INDEX CALCULATION FUNCTION
-- ============================================================================

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

-- ============================================================================
-- 21. AUTO-UPDATE THREAT INDEX TRIGGER FUNCTION
-- ============================================================================

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

-- Create triggers
DROP TRIGGER IF EXISTS trigger_update_vault_threat_index_on_threat_events ON threat_events;
CREATE TRIGGER trigger_update_vault_threat_index_on_threat_events
AFTER INSERT OR UPDATE ON threat_events
FOR EACH ROW
EXECUTE FUNCTION update_vault_threat_index();

DROP TRIGGER IF EXISTS trigger_update_vault_threat_index_on_transfer_requests ON vault_transfer_requests;
CREATE TRIGGER trigger_update_vault_threat_index_on_transfer_requests
AFTER INSERT OR UPDATE ON vault_transfer_requests
FOR EACH ROW
EXECUTE FUNCTION update_vault_threat_index();

-- ============================================================================
-- 22. ML THREAT ASSESSMENT FUNCTION FOR TRANSFER REQUESTS
-- ============================================================================

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
    IF v_request.requested_by_user_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_threat_score
        FROM vault_transfer_requests
        WHERE requested_by_user_id = v_request.requested_by_user_id
          AND requested_at > NOW() - INTERVAL '7 days'
          AND status != 'denied'
          AND id != v_request.id;
        
        IF v_threat_score > 3 THEN
            v_threat_score := v_threat_score * 10.0;
            v_recommendation := 'deny';
        END IF;
    END IF;
    
    -- 2. Check for unusual timing (late night transfers)
    IF EXTRACT(HOUR FROM v_request.requested_at) BETWEEN 0 AND 5 THEN
        v_threat_score := v_threat_score + 15.0;
    END IF;
    
    -- 3. Check if new owner email matches existing user
    IF v_request.new_owner_email IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM users WHERE email = v_request.new_owner_email
        ) THEN
            v_threat_score := v_threat_score - 5.0; -- Lower risk if user exists
        ELSE
            v_threat_score := v_threat_score + 10.0; -- Higher risk for new users
        END IF;
    END IF;
    
    -- 4. Check vault's current threat index
    SELECT threat_index INTO v_threat_index
    FROM vaults
    WHERE id = v_request.vault_id;
    
    v_threat_score := v_threat_score + (COALESCE(v_threat_index, 0.0) * 0.3);
    
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
    v_threat_index := v_threat_score;
    
    RETURN QUERY SELECT v_threat_score, v_recommendation, v_threat_index;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 23. THREAT DASHBOARD VIEW
-- ============================================================================

CREATE OR REPLACE VIEW vault_threat_dashboard AS
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

-- ============================================================================
-- COMMIT TRANSACTION
-- ============================================================================

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Verify RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Verify indexes exist
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Verify functions exist
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- Verify triggers exist
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE event_object_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- ============================================================================
-- NOTES
-- ============================================================================
-- 1. This schema supports all three platforms (Apple, Android, Windows)
-- 2. Platform-specific user IDs are handled via separate columns (apple_user_id, google_user_id, microsoft_user_id)
-- 3. All tables have RLS enabled with appropriate policies
-- 4. Threat monitoring is integrated with automatic index calculation
-- 5. ML threat assessment functions are included
-- 6. Broadcast vaults and emergency access are fully supported
-- 7. Document versioning is implemented
-- 8. Anti-vaults and document fidelity monitoring are included

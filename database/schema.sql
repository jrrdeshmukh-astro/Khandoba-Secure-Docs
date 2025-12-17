-- Khandoba Secure Docs - Supabase Database Schema
-- Complete table definitions for migration from SwiftData/CloudKit to Supabase

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable Row-Level Security (will be configured per table)
-- RLS policies are in rls_policies.sql

-- ============================================================================
-- USERS TABLE
-- ============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apple_user_id TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    email TEXT,
    profile_picture_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    is_premium_subscriber BOOLEAN DEFAULT FALSE,
    subscription_expiry_date TIMESTAMPTZ
);

CREATE INDEX idx_users_apple_user_id ON users(apple_user_id);
CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_is_active ON users(is_active);

-- ============================================================================
-- USER ROLES TABLE
-- ============================================================================

CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_raw_value TEXT NOT NULL DEFAULT 'client',
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, role_raw_value)
);

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_is_active ON user_roles(is_active);

-- ============================================================================
-- VAULTS TABLE
-- ============================================================================

CREATE TABLE vaults (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    vault_description TEXT,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ,
    status TEXT DEFAULT 'locked', -- 'active', 'locked', 'archived'
    key_type TEXT DEFAULT 'single', -- 'single', 'dual'
    vault_type TEXT DEFAULT 'both', -- 'source', 'sink', 'both'
    is_system_vault BOOLEAN DEFAULT FALSE,
    encryption_key_data BYTEA, -- Encrypted key data
    is_encrypted BOOLEAN DEFAULT TRUE,
    is_zero_knowledge BOOLEAN DEFAULT TRUE,
    relationship_officer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_vaults_owner_id ON vaults(owner_id);
CREATE INDEX idx_vaults_status ON vaults(status);
CREATE INDEX idx_vaults_key_type ON vaults(key_type);
CREATE INDEX idx_vaults_is_system_vault ON vaults(is_system_vault);
CREATE INDEX idx_vaults_created_at ON vaults(created_at);
-- Note: is_anti_vault and monitored_vault_id indexes are created in add_fidelity_antivault_tables.sql

-- ============================================================================
-- DOCUMENTS TABLE
-- ============================================================================

CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    file_extension TEXT,
    mime_type TEXT,
    file_size BIGINT DEFAULT 0,
    storage_path TEXT, -- Path in Supabase Storage bucket
    created_at TIMESTAMPTZ DEFAULT NOW(),
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    last_modified_at TIMESTAMPTZ,
    encryption_key_data BYTEA, -- Document-specific encryption key
    is_encrypted BOOLEAN DEFAULT TRUE,
    document_type TEXT DEFAULT 'other', -- 'image', 'pdf', 'video', 'audio', 'text', 'other'
    source_sink_type TEXT, -- 'source', 'sink', 'both'
    is_archived BOOLEAN DEFAULT FALSE,
    is_redacted BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'active', -- 'active', 'archived', 'deleted'
    extracted_text TEXT,
    ai_tags TEXT[] DEFAULT '{}', -- Array of AI-generated tags
    -- Note: fidelity_tracked column is added in add_fidelity_antivault_tables.sql
    file_hash TEXT,
    metadata JSONB, -- Flexible JSON metadata
    author TEXT,
    camera_info TEXT,
    device_id TEXT,
    uploaded_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_documents_vault_id ON documents(vault_id);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_document_type ON documents(document_type);
CREATE INDEX idx_documents_created_at ON documents(created_at);
CREATE INDEX idx_documents_ai_tags ON documents USING GIN(ai_tags); -- GIN index for array search
CREATE INDEX idx_documents_metadata ON documents USING GIN(metadata); -- GIN index for JSONB

-- ============================================================================
-- DOCUMENT VERSIONS TABLE
-- ============================================================================

CREATE TABLE document_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    file_size BIGINT DEFAULT 0,
    storage_path TEXT, -- Path in Supabase Storage
    changes TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(document_id, version_number)
);

CREATE INDEX idx_document_versions_document_id ON document_versions(document_id);
CREATE INDEX idx_document_versions_version_number ON document_versions(version_number);

-- ============================================================================
-- NOMINEES TABLE (Vault Sharing)
-- ============================================================================

CREATE TABLE nominees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invited_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'revoked'
    invited_at TIMESTAMPTZ DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    declined_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    access_level TEXT DEFAULT 'read', -- 'read', 'write', 'admin'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(vault_id, user_id)
);

CREATE INDEX idx_nominees_vault_id ON nominees(vault_id);
CREATE INDEX idx_nominees_user_id ON nominees(user_id);
CREATE INDEX idx_nominees_status ON nominees(status);

-- ============================================================================
-- VAULT SESSIONS TABLE
-- ============================================================================

CREATE TABLE vault_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    was_extended BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_vault_sessions_vault_id ON vault_sessions(vault_id);
CREATE INDEX idx_vault_sessions_user_id ON vault_sessions(user_id);
CREATE INDEX idx_vault_sessions_is_active ON vault_sessions(is_active);
CREATE INDEX idx_vault_sessions_expires_at ON vault_sessions(expires_at);

-- ============================================================================
-- VAULT ACCESS LOGS TABLE (Audit Trail)
-- ============================================================================

CREATE TABLE vault_access_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    access_type TEXT DEFAULT 'viewed', -- 'opened', 'closed', 'viewed', 'modified', etc.
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    user_name TEXT,
    device_info TEXT,
    location_latitude DOUBLE PRECISION,
    location_longitude DOUBLE PRECISION,
    ip_address TEXT,
    document_id UUID REFERENCES documents(id) ON DELETE SET NULL,
    document_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_vault_access_logs_vault_id ON vault_access_logs(vault_id);
CREATE INDEX idx_vault_access_logs_user_id ON vault_access_logs(user_id);
CREATE INDEX idx_vault_access_logs_timestamp ON vault_access_logs(timestamp);
CREATE INDEX idx_vault_access_logs_access_type ON vault_access_logs(access_type);

-- ============================================================================
-- DUAL KEY REQUESTS TABLE
-- ============================================================================

CREATE TABLE dual_key_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'denied'
    reason TEXT,
    approved_at TIMESTAMPTZ,
    denied_at TIMESTAMPTZ,
    approver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    ml_score DOUBLE PRECISION, -- ML confidence score
    logical_reasoning TEXT, -- Formal logic reasoning
    decision_method TEXT, -- 'ml_auto' or 'logic_reasoning'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_dual_key_requests_vault_id ON dual_key_requests(vault_id);
CREATE INDEX idx_dual_key_requests_requester_id ON dual_key_requests(requester_id);
CREATE INDEX idx_dual_key_requests_status ON dual_key_requests(status);

-- ============================================================================
-- VAULT TRANSFER REQUESTS TABLE
-- ============================================================================

CREATE TABLE vault_transfer_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'denied', 'cancelled'
    reason TEXT,
    approved_at TIMESTAMPTZ,
    denied_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_vault_transfer_requests_vault_id ON vault_transfer_requests(vault_id);
CREATE INDEX idx_vault_transfer_requests_from_user_id ON vault_transfer_requests(from_user_id);
CREATE INDEX idx_vault_transfer_requests_to_user_id ON vault_transfer_requests(to_user_id);
CREATE INDEX idx_vault_transfer_requests_status ON vault_transfer_requests(status);

-- ============================================================================
-- VAULT ACCESS REQUESTS TABLE
-- ============================================================================

CREATE TABLE vault_access_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'denied'
    request_type TEXT DEFAULT 'request', -- 'request' or 'send'
    message TEXT,
    expires_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,
    response_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_vault_access_requests_vault_id ON vault_access_requests(vault_id);
CREATE INDEX idx_vault_access_requests_requester_id ON vault_access_requests(requester_id);
CREATE INDEX idx_vault_access_requests_status ON vault_access_requests(status);

-- ============================================================================
-- EMERGENCY ACCESS REQUESTS TABLE
-- ============================================================================

CREATE TABLE emergency_access_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vault_id UUID NOT NULL REFERENCES vaults(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    reason TEXT NOT NULL,
    urgency_level TEXT DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
    status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'denied'
    approved_at TIMESTAMPTZ,
    denied_at TIMESTAMPTZ,
    approver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_emergency_access_requests_vault_id ON emergency_access_requests(vault_id);
CREATE INDEX idx_emergency_access_requests_requester_id ON emergency_access_requests(requester_id);
CREATE INDEX idx_emergency_access_requests_status ON emergency_access_requests(status);
CREATE INDEX idx_emergency_access_requests_urgency_level ON emergency_access_requests(urgency_level);

-- ============================================================================
-- CHAT MESSAGES TABLE (LLM Support Chat)
-- ============================================================================

CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    is_from_system BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX idx_chat_messages_is_from_system ON chat_messages(is_from_system);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT TIMESTAMPS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vaults_updated_at BEFORE UPDATE ON vaults
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_document_versions_updated_at BEFORE UPDATE ON document_versions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_nominees_updated_at BEFORE UPDATE ON nominees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vault_sessions_updated_at BEFORE UPDATE ON vault_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dual_key_requests_updated_at BEFORE UPDATE ON dual_key_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vault_transfer_requests_updated_at BEFORE UPDATE ON vault_transfer_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vault_access_requests_updated_at BEFORE UPDATE ON vault_access_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emergency_access_requests_updated_at BEFORE UPDATE ON emergency_access_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_messages_updated_at BEFORE UPDATE ON chat_messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STORAGE BUCKETS (Supabase Storage)
-- ============================================================================

-- Note: Storage buckets are created via Supabase Dashboard or API
-- Buckets needed:
-- 1. encrypted-documents - For encrypted document files
-- 2. voice-memos - For voice memo audio files
-- 3. intel-reports - For Intel Report files

-- Storage policies are configured in Supabase Dashboard under Storage > Policies

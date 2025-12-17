-- Khandoba Secure Docs - Row-Level Security (RLS) Policies
-- Enforces access control at the database level for zero-knowledge architecture

-- ============================================================================
-- ENABLE ROW-LEVEL SECURITY ON ALL TABLES
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaults ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE nominees ENABLE ROW LEVEL SECURITY;
ALTER TABLE vault_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE vault_access_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE dual_key_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE vault_transfer_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE vault_access_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_access_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

-- Users can only see their own user record
CREATE POLICY "users_select_own"
ON users FOR SELECT
USING (auth.uid() = id);

-- Users can insert their own user record (during signup)
CREATE POLICY "users_insert_own"
ON users FOR INSERT
WITH CHECK (auth.uid() = id);

-- Users can update their own user record
CREATE POLICY "users_update_own"
ON users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Users cannot delete their own record (use account deletion service)
-- No DELETE policy - handled by service role

-- ============================================================================
-- USER ROLES TABLE POLICIES
-- ============================================================================

-- Users can only see their own roles
CREATE POLICY "user_roles_select_own"
ON user_roles FOR SELECT
USING (auth.uid() = user_id);

-- Users cannot insert/update/delete roles (handled by system)
-- No INSERT/UPDATE/DELETE policies - handled by service role

-- ============================================================================
-- VAULTS TABLE POLICIES
-- ============================================================================

-- Users can see vaults they own OR vaults they're nominees for
CREATE POLICY "vaults_select_accessible"
ON vaults FOR SELECT
USING (
    owner_id = auth.uid() OR
    id IN (
        SELECT vault_id FROM nominees 
        WHERE user_id = auth.uid() AND status = 'accepted'
    )
);

-- Users can only create vaults for themselves
CREATE POLICY "vaults_insert_own"
ON vaults FOR INSERT
WITH CHECK (owner_id = auth.uid());

-- Users can only update vaults they own
CREATE POLICY "vaults_update_own"
ON vaults FOR UPDATE
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

-- Users can only delete vaults they own
CREATE POLICY "vaults_delete_own"
ON vaults FOR DELETE
USING (owner_id = auth.uid());

-- ============================================================================
-- DOCUMENTS TABLE POLICIES
-- ============================================================================

-- Users can see documents in vaults they have access to
CREATE POLICY "documents_select_accessible"
ON documents FOR SELECT
USING (
    vault_id IN (
        SELECT id FROM vaults 
        WHERE owner_id = auth.uid()
        UNION
        SELECT vault_id FROM nominees 
        WHERE user_id = auth.uid() AND status = 'accepted'
    )
);

-- Users can only create documents in vaults they have access to
CREATE POLICY "documents_insert_accessible"
ON documents FOR INSERT
WITH CHECK (
    vault_id IN (
        SELECT id FROM vaults 
        WHERE owner_id = auth.uid()
        UNION
        SELECT vault_id FROM nominees 
        WHERE user_id = auth.uid() AND status = 'accepted' AND access_level IN ('write', 'admin')
    )
);

-- Users can only update documents in vaults they have write access to
CREATE POLICY "documents_update_accessible"
ON documents FOR UPDATE
USING (
    vault_id IN (
        SELECT id FROM vaults 
        WHERE owner_id = auth.uid()
        UNION
        SELECT vault_id FROM nominees 
        WHERE user_id = auth.uid() AND status = 'accepted' AND access_level IN ('write', 'admin')
    )
)
WITH CHECK (
    vault_id IN (
        SELECT id FROM vaults 
        WHERE owner_id = auth.uid()
        UNION
        SELECT vault_id FROM nominees 
        WHERE user_id = auth.uid() AND status = 'accepted' AND access_level IN ('write', 'admin')
    )
);

-- Users can only delete documents in vaults they own or have admin access to
CREATE POLICY "documents_delete_accessible"
ON documents FOR DELETE
USING (
    vault_id IN (
        SELECT id FROM vaults 
        WHERE owner_id = auth.uid()
        UNION
        SELECT vault_id FROM nominees 
        WHERE user_id = auth.uid() AND status = 'accepted' AND access_level = 'admin'
    )
);

-- ============================================================================
-- DOCUMENT VERSIONS TABLE POLICIES
-- ============================================================================

-- Users can see versions of documents they have access to
CREATE POLICY "document_versions_select_accessible"
ON document_versions FOR SELECT
USING (
    document_id IN (
        SELECT id FROM documents
        WHERE vault_id IN (
            SELECT id FROM vaults 
            WHERE owner_id = auth.uid()
            UNION
            SELECT vault_id FROM nominees 
            WHERE user_id = auth.uid() AND status = 'accepted'
        )
    )
);

-- Users can create versions for documents they have write access to
CREATE POLICY "document_versions_insert_accessible"
ON document_versions FOR INSERT
WITH CHECK (
    document_id IN (
        SELECT id FROM documents
        WHERE vault_id IN (
            SELECT id FROM vaults 
            WHERE owner_id = auth.uid()
            UNION
            SELECT vault_id FROM nominees 
            WHERE user_id = auth.uid() AND status = 'accepted' AND access_level IN ('write', 'admin')
        )
    )
);

-- ============================================================================
-- NOMINEES TABLE POLICIES
-- ============================================================================

-- Users can see nominees for vaults they own OR nominations they're part of
CREATE POLICY "nominees_select_accessible"
ON nominees FOR SELECT
USING (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    user_id = auth.uid()
);

-- Vault owners can create nominees for their vaults
CREATE POLICY "nominees_insert_owner"
ON nominees FOR INSERT
WITH CHECK (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    )
);

-- Vault owners can update nominees for their vaults
-- Nominees can update their own status (accept/decline)
CREATE POLICY "nominees_update_accessible"
ON nominees FOR UPDATE
USING (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    user_id = auth.uid()
)
WITH CHECK (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    user_id = auth.uid()
);

-- Vault owners can delete nominees for their vaults
CREATE POLICY "nominees_delete_owner"
ON nominees FOR DELETE
USING (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    )
);

-- ============================================================================
-- VAULT SESSIONS TABLE POLICIES
-- ============================================================================

-- Users can see sessions for vaults they have access to
CREATE POLICY "vault_sessions_select_accessible"
ON vault_sessions FOR SELECT
USING (
    vault_id IN (
        SELECT id FROM vaults 
        WHERE owner_id = auth.uid()
        UNION
        SELECT vault_id FROM nominees 
        WHERE user_id = auth.uid() AND status = 'accepted'
    ) OR
    user_id = auth.uid()
);

-- Users can create sessions for vaults they have access to
CREATE POLICY "vault_sessions_insert_accessible"
ON vault_sessions FOR INSERT
WITH CHECK (
    user_id = auth.uid() AND
    vault_id IN (
        SELECT id FROM vaults 
        WHERE owner_id = auth.uid()
        UNION
        SELECT vault_id FROM nominees 
        WHERE user_id = auth.uid() AND status = 'accepted'
    )
);

-- Users can update their own sessions
CREATE POLICY "vault_sessions_update_own"
ON vault_sessions FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can delete their own sessions
CREATE POLICY "vault_sessions_delete_own"
ON vault_sessions FOR DELETE
USING (user_id = auth.uid());

-- ============================================================================
-- VAULT ACCESS LOGS TABLE POLICIES
-- ============================================================================

-- Users can see access logs for vaults they own
-- (Read-only for audit trail - users cannot modify logs)
CREATE POLICY "vault_access_logs_select_owner"
ON vault_access_logs FOR SELECT
USING (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    )
);

-- System can insert access logs (handled by service role)
-- No INSERT policy for regular users - handled by service role

-- ============================================================================
-- DUAL KEY REQUESTS TABLE POLICIES
-- ============================================================================

-- Users can see dual-key requests for vaults they own or have requested
CREATE POLICY "dual_key_requests_select_accessible"
ON dual_key_requests FOR SELECT
USING (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    requester_id = auth.uid()
);

-- Users can create dual-key requests for vaults they have access to
CREATE POLICY "dual_key_requests_insert_accessible"
ON dual_key_requests FOR INSERT
WITH CHECK (
    requester_id = auth.uid() AND
    vault_id IN (
        SELECT id FROM vaults 
        WHERE owner_id = auth.uid()
        UNION
        SELECT vault_id FROM nominees 
        WHERE user_id = auth.uid() AND status = 'accepted'
    )
);

-- Vault owners can update dual-key requests for their vaults
-- Requesters can update their own requests (cancel)
CREATE POLICY "dual_key_requests_update_accessible"
ON dual_key_requests FOR UPDATE
USING (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    requester_id = auth.uid()
)
WITH CHECK (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    requester_id = auth.uid()
);

-- ============================================================================
-- VAULT TRANSFER REQUESTS TABLE POLICIES
-- ============================================================================

-- Users can see transfer requests for vaults they own or are involved in
CREATE POLICY "vault_transfer_requests_select_accessible"
ON vault_transfer_requests FOR SELECT
USING (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    from_user_id = auth.uid() OR
    to_user_id = auth.uid()
);

-- Vault owners can create transfer requests
CREATE POLICY "vault_transfer_requests_insert_owner"
ON vault_transfer_requests FOR INSERT
WITH CHECK (
    from_user_id = auth.uid() AND
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    )
);

-- Users involved in transfer can update the request
CREATE POLICY "vault_transfer_requests_update_accessible"
ON vault_transfer_requests FOR UPDATE
USING (
    from_user_id = auth.uid() OR
    to_user_id = auth.uid()
)
WITH CHECK (
    from_user_id = auth.uid() OR
    to_user_id = auth.uid()
);

-- ============================================================================
-- VAULT ACCESS REQUESTS TABLE POLICIES
-- ============================================================================

-- Users can see access requests for vaults they own or have requested
CREATE POLICY "vault_access_requests_select_accessible"
ON vault_access_requests FOR SELECT
USING (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    requester_id = auth.uid()
);

-- Users can create access requests
CREATE POLICY "vault_access_requests_insert_accessible"
ON vault_access_requests FOR INSERT
WITH CHECK (requester_id = auth.uid());

-- Vault owners can update access requests (approve/deny)
-- Requesters can update their own requests (cancel)
CREATE POLICY "vault_access_requests_update_accessible"
ON vault_access_requests FOR UPDATE
USING (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    requester_id = auth.uid()
)
WITH CHECK (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    requester_id = auth.uid()
);

-- ============================================================================
-- EMERGENCY ACCESS REQUESTS TABLE POLICIES
-- ============================================================================

-- Users can see emergency requests for vaults they own or have requested
CREATE POLICY "emergency_access_requests_select_accessible"
ON emergency_access_requests FOR SELECT
USING (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    requester_id = auth.uid()
);

-- Users can create emergency access requests
CREATE POLICY "emergency_access_requests_insert_accessible"
ON emergency_access_requests FOR INSERT
WITH CHECK (requester_id = auth.uid());

-- Vault owners can update emergency requests (approve/deny)
-- Requesters can update their own requests (cancel)
CREATE POLICY "emergency_access_requests_update_accessible"
ON emergency_access_requests FOR UPDATE
USING (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    requester_id = auth.uid()
)
WITH CHECK (
    vault_id IN (
        SELECT id FROM vaults WHERE owner_id = auth.uid()
    ) OR
    requester_id = auth.uid()
);

-- ============================================================================
-- CHAT MESSAGES TABLE POLICIES
-- ============================================================================

-- Users can see their own messages
CREATE POLICY "chat_messages_select_own"
ON chat_messages FOR SELECT
USING (sender_id = auth.uid() OR is_from_system = TRUE);

-- Users can create their own messages
CREATE POLICY "chat_messages_insert_own"
ON chat_messages FOR INSERT
WITH CHECK (sender_id = auth.uid());

-- Users can update their own messages
CREATE POLICY "chat_messages_update_own"
ON chat_messages FOR UPDATE
USING (sender_id = auth.uid())
WITH CHECK (sender_id = auth.uid());

-- Users can delete their own messages
CREATE POLICY "chat_messages_delete_own"
ON chat_messages FOR DELETE
USING (sender_id = auth.uid());

-- ============================================================================
-- NOTES
-- ============================================================================

-- 1. All policies use auth.uid() which is set by Supabase Auth
-- 2. Zero-knowledge architecture: Server cannot decrypt data, only enforce access
-- 3. Service role key is needed for:
--    - Account deletion
--    - System operations (access logs, etc.)
--    - Admin operations (if needed)
-- 4. Storage policies are configured separately in Supabase Dashboard
-- 5. Real-time subscriptions respect RLS policies automatically

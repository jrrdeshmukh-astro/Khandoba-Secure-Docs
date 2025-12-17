-- Migration: Add subset nomination fields to nominees table
-- Adds support for session-based subset nominations with time-bound access

-- Add new columns to nominees table
ALTER TABLE nominees 
ADD COLUMN IF NOT EXISTS selected_document_ids JSONB,
ADD COLUMN IF NOT EXISTS session_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS is_subset_access BOOLEAN DEFAULT FALSE;

-- Add index for session expiration queries
CREATE INDEX IF NOT EXISTS idx_nominees_session_expires_at ON nominees(session_expires_at) WHERE session_expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_nominees_is_subset_access ON nominees(is_subset_access) WHERE is_subset_access = TRUE;

-- Add comment explaining the fields
COMMENT ON COLUMN nominees.selected_document_ids IS 'JSON array of document UUIDs for subset access. NULL means access to all documents.';
COMMENT ON COLUMN nominees.session_expires_at IS 'Expiration time for subset nomination sessions. Access is automatically revoked when expired.';
COMMENT ON COLUMN nominees.is_subset_access IS 'Flag indicating if this is a subset nomination (limited to selected documents with time-bound access).';

-- Function to auto-revoke expired subset nominations
CREATE OR REPLACE FUNCTION revoke_expired_subset_nominations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE nominees
    SET status = 'revoked',
        revoked_at = NOW(),
        updated_at = NOW()
    WHERE is_subset_access = TRUE
      AND session_expires_at IS NOT NULL
      AND session_expires_at < NOW()
      AND status IN ('pending', 'accepted', 'active');
END;
$$;

-- Create a scheduled job to run revocation (requires pg_cron extension)
-- Note: This requires pg_cron extension to be enabled
-- If pg_cron is not available, the app will handle revocation client-side

-- Example: Schedule to run every minute (if pg_cron is enabled)
-- SELECT cron.schedule('revoke-expired-nominations', '* * * * *', 'SELECT revoke_expired_subset_nominations();');

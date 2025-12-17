-- Enable Real-time Subscriptions for Khandoba Secure Docs
-- Run this in Supabase SQL Editor after creating tables
--
-- Note: The supabase_realtime publication already exists in Supabase
-- You just need to add your tables to it and set REPLICA IDENTITY

-- Add tables to the supabase_realtime publication
-- This enables real-time subscriptions for these tables in your app
ALTER PUBLICATION supabase_realtime ADD TABLE vaults;
ALTER PUBLICATION supabase_realtime ADD TABLE documents;
ALTER PUBLICATION supabase_realtime ADD TABLE nominees;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE vault_sessions;

-- Set REPLICA IDENTITY FULL for proper change tracking
-- This ensures updates and deletes are properly tracked in real-time
ALTER TABLE vaults REPLICA IDENTITY FULL;
ALTER TABLE documents REPLICA IDENTITY FULL;
ALTER TABLE nominees REPLICA IDENTITY FULL;
ALTER TABLE chat_messages REPLICA IDENTITY FULL;
ALTER TABLE vault_sessions REPLICA IDENTITY FULL;

-- Verify tables are added (run this separately to check)
-- SELECT tablename 
-- FROM pg_publication_tables 
-- WHERE pubname = 'supabase_realtime'
-- ORDER BY tablename;

-- Expected output: 5 tables (vaults, documents, nominees, chat_messages, vault_sessions)

# Supabase Database Setup Instructions

## Prerequisites

1. Supabase account at [supabase.com](https://supabase.com)
2. New or existing Supabase project
3. Access to Supabase Dashboard

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Fill in:
   - **Name**: Khandoba Secure Docs (or your preferred name)
   - **Database Password**: Create a strong password (save it!)
   - **Region**: Choose closest to your users
   - **Pricing Plan**: Free tier is fine for development
4. Click "Create new project"
5. Wait 2-3 minutes for project to initialize

## Step 2: Get Project Credentials

1. In Supabase Dashboard, go to **Settings** → **API**
2. Copy the following:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJhbGci...`)
   - **service_role key** (starts with `eyJhbGci...`) - Keep this secret!

3. Update `SupabaseConfig.swift`:
   ```swift
   static let supabaseURL = "YOUR_PROJECT_URL"
   static let supabaseAnonKey = "YOUR_ANON_KEY"
   static let supabaseServiceRoleKey = "YOUR_SERVICE_ROLE_KEY"
   ```

## Step 3: Run Database Schema

1. In Supabase Dashboard, go to **SQL Editor**
2. Click **New Query**
3. Copy contents of `database/schema.sql`
4. Paste into SQL Editor
5. Click **Run** (or press Cmd+Enter)
6. Verify success message: "Success. No rows returned"

**Expected Output:**
- 13 tables created
- Indexes created
- Triggers created
- No errors

## Step 4: Apply RLS Policies

1. In Supabase Dashboard, go to **SQL Editor**
2. Click **New Query**
3. Copy contents of `database/rls_policies.sql`
4. Paste into SQL Editor
5. Click **Run**
6. Verify success message

**Expected Output:**
- RLS enabled on all tables
- Policies created for all tables
- No errors

## Step 5: Create Storage Buckets

1. In Supabase Dashboard, go to **Storage**
2. Click **New bucket**
3. Create three buckets:

### Bucket 1: encrypted-documents
- **Name**: `encrypted-documents`
- **Public**: ❌ No (Private)
- **File size limit**: 50 MB (or your preference)
- **Allowed MIME types**: Leave empty (all types allowed)

### Bucket 2: voice-memos
- **Name**: `voice-memos`
- **Public**: ❌ No (Private)
- **File size limit**: 10 MB
- **Allowed MIME types**: `audio/*`

### Bucket 3: intel-reports
- **Name**: `intel-reports`
- **Public**: ❌ No (Private)
- **File size limit**: 50 MB
- **Allowed MIME types**: Leave empty

## Step 6: Configure Storage Policies

For each bucket, set up RLS policies:

1. Go to **Storage** → Select bucket → **Policies**
2. Click **New Policy**
3. Use **For full customization** option
4. Add policies:

### Policy for encrypted-documents bucket:

**Policy Name**: `Users can upload their own files`
```sql
CREATE POLICY "Users can upload their own files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'encrypted-documents');
```

**Policy Name**: `Users can read their own files`
```sql
CREATE POLICY "Users can read their own files"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'encrypted-documents');
```

**Policy Name**: `Users can delete their own files`
```sql
CREATE POLICY "Users can delete their own files"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'encrypted-documents');
```

Repeat for `voice-memos` and `intel-reports` buckets (replace bucket name in policies).

## Step 7: Configure Apple Sign In OAuth

1. In Supabase Dashboard, go to **Authentication** → **Providers**
2. Find **Apple** and click to enable
3. You'll need:
   - **Services ID**: From Apple Developer account
   - **Team ID**: From Apple Developer account
   - **Key ID**: From Apple Developer account
   - **Private Key**: Download `.p8` file from Apple Developer

4. Follow instructions in `scripts/README_APPLE_OAUTH.md` for generating OAuth secret
5. Enter credentials in Supabase Dashboard
6. **Redirect URL**: Add your app's URL scheme (e.g., `khandoba://auth/callback`)

## Step 8: Enable Real-time (Optional but Recommended)

**Important:** The "Database → Replication" section in the Supabase Dashboard is for external data warehouses (currently in private alpha) and is **NOT** what you need for real-time subscriptions.

To enable real-time subscriptions for your tables, you need to:
1. Add them to Supabase's Realtime publication (which already exists)
2. Set REPLICA IDENTITY for proper change tracking

**Steps:**

1. In Supabase Dashboard, go to **SQL Editor**
2. Click **New Query**
3. Run this SQL to enable real-time for the required tables:

```sql
-- Add tables to the supabase_realtime publication
-- (The publication already exists - you just need to add your tables)
ALTER PUBLICATION supabase_realtime ADD TABLE vaults;
ALTER PUBLICATION supabase_realtime ADD TABLE documents;
ALTER PUBLICATION supabase_realtime ADD TABLE nominees;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE vault_sessions;

-- Set REPLICA IDENTITY FULL for proper change tracking
-- This ensures updates and deletes are properly tracked
ALTER TABLE vaults REPLICA IDENTITY FULL;
ALTER TABLE documents REPLICA IDENTITY FULL;
ALTER TABLE nominees REPLICA IDENTITY FULL;
ALTER TABLE chat_messages REPLICA IDENTITY FULL;
ALTER TABLE vault_sessions REPLICA IDENTITY FULL;
```

4. Verify the tables are added by running:

```sql
-- Check which tables are in the publication
SELECT tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;
```

**Expected Output:** You should see all 5 tables listed.

**Note:** 
- The `supabase_realtime` publication is created automatically by Supabase
- If you get an error that the publication doesn't exist, check your project settings or contact Supabase support
- REPLICA IDENTITY FULL is important for tracking updates and deletes in real-time

## Step 9: Verify Setup

Run this query in SQL Editor to verify:

```sql
-- Check tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Check storage buckets
SELECT name, public 
FROM storage.buckets;

-- Check real-time tables (if Step 8 was completed)
SELECT tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;
```

**Expected Results:**
- 13 tables listed
- All tables have `rowsecurity = true`
- 3 storage buckets listed
- 5 tables in real-time publication (if Step 8 was completed)

## Step 10: Test Connection

1. In your app, set `AppConfig.useSupabase = true`
2. Run the app
3. Check console logs for:
   - `✅ Supabase client initialized and connected`
   - `✅ Real-time subscriptions setup`

## Troubleshooting

### RLS Policy Errors

If you get "permission denied" errors:
1. Check user is authenticated: `supabaseService.currentSession != nil`
2. Verify RLS policies in `database/rls_policies.sql` were applied
3. Check Supabase logs in Dashboard → Logs

### Storage Upload Errors

If file uploads fail:
1. Verify bucket exists and is private
2. Check bucket policies allow authenticated users
3. Verify file size is under limit
4. Check Supabase logs for detailed error

### Authentication Errors

If Apple Sign In fails:
1. Verify OAuth credentials in Supabase Dashboard
2. Check redirect URL matches app URL scheme
3. Verify `.p8` key is valid and not expired
4. Check Apple Developer account status

### Real-time Subscription Errors

If real-time updates don't work:
1. Verify tables are in `supabase_realtime` publication (run the verification query in Step 9)
2. Check that `SupabaseConfig.enableRealtime = true` in your code
3. Verify REPLICA IDENTITY is set: `SELECT tablename, relreplident FROM pg_class WHERE relname IN ('vaults', 'documents', 'nominees', 'chat_messages', 'vault_sessions');` (should show 'f' for FULL)
4. Check Supabase Dashboard → Settings → API → Realtime is enabled
5. Check console logs for connection errors
6. **Note:** The "Database → Replication" section is NOT for real-time subscriptions - use SQL Editor instead
7. If publication doesn't exist, check project settings or contact Supabase support

## Next Steps

After setup is complete:
1. Test authentication flow
2. Test file upload/download
3. Test RLS policies
4. Test real-time updates
5. Enable in production when ready

## Security Notes

- ⚠️ **Never commit** service role key to git
- ⚠️ **Never expose** service role key to client
- ✅ Use anon key in app (safe for client)
- ✅ RLS policies enforce access control
- ✅ Files encrypted before upload (zero-knowledge)

## Support

- Supabase Docs: https://supabase.com/docs
- Supabase Discord: https://discord.supabase.com
- Project Issues: Check GitHub

# Update Supabase Credentials - Quick Guide

## ✅ Step 1: Get Your New Project Credentials

1. Go to: https://supabase.com/dashboard/project/uremtyiorzlapwthjsko
2. Click **Settings** → **API**
3. Copy these values:

### Project URL
```
https://uremtyiorzlapwthjsko.supabase.co
```
✅ **Already updated in code**

### Anon/Public Key
```
Copy the "anon" or "public" key (starts with eyJhbGci...)
```

### Service Role Key
```
Copy the "service_role" key (starts with eyJhbGci...)
⚠️ Keep this secret - never commit to git!
```

## ✅ Step 2: Update SupabaseConfig.swift

Open: `Khandoba Secure Docs/Config/SupabaseConfig.swift`

Replace these lines:

```swift
static let supabaseAnonKey = "YOUR_NEW_ANON_KEY_HERE"
static let supabaseServiceRoleKey = "YOUR_NEW_SERVICE_ROLE_KEY_HERE"
```

With your actual keys from Step 1.

## ✅ Step 3: Fix Apple OAuth Configuration

The error "Unacceptable audience in id_token: [com.khandoba.securedocs]" means Supabase's Apple OAuth isn't configured correctly.

### In Supabase Dashboard:

1. Go to **Authentication** → **Providers** → **Apple**
2. Enable Apple provider
3. Configure with these values:

   **Services ID**: `com.khandoba.securedocs`
   - This must match your bundle identifier exactly
   
   **Team ID**: `Q5Y8754WU4`
   - From your AppConfig.swift
   
   **Key ID**: `PR62QK662L`
   - From your AppConfig.swift
   
   **Private Key**: 
   - Upload your `.p8` file (AuthKey_PR62QK662L.p8)
   - Or generate OAuth secret using `scripts/generate_apple_oauth_secret.py`

4. **Redirect URLs**: Add `khandoba://auth/callback`

### Verify in Apple Developer Portal:

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Find Services ID: `com.khandoba.securedocs`
3. Ensure "Sign in with Apple" is enabled
4. Verify it's associated with your App ID

## ✅ Step 4: Run Database Setup

1. Go to Supabase Dashboard → **SQL Editor**
2. Run `database/schema.sql` (creates all tables)
3. Run `database/rls_policies.sql` (enables security)
4. Run `database/enable_realtime.sql` (enables real-time)

## ✅ Step 5: Create Storage Buckets

1. Go to **Storage**
2. Create these buckets:
   - `encrypted-documents` (Private)
   - `voice-memos` (Private)
   - `intel-reports` (Private)

## ✅ Step 6: Test Connection

1. Build and run the app
2. Check console for:
   ```
   ✅ Supabase client initialized and connected
   URL: https://uremtyiorzlapwthjsko.supabase.co
   ```
3. Try signing in with Apple
4. Should see:
   ```
   ✅ Supabase authentication successful
   ✅ User created/updated successfully
   ```

## Current Configuration

| Setting | Value | Status |
|---------|-------|--------|
| Project URL | `https://uremtyiorzlapwthjsko.supabase.co` | ✅ Updated |
| Anon Key | `YOUR_NEW_ANON_KEY_HERE` | ⚠️ Needs update |
| Service Role Key | `YOUR_NEW_SERVICE_ROLE_KEY_HERE` | ⚠️ Needs update |
| Bundle ID | `com.khandoba.securedocs` | ✅ Correct |
| Services ID | `com.khandoba.securedocs` | ⚠️ Needs config in Supabase |
| Team ID | `Q5Y8754WU4` | ✅ Correct |
| Key ID | `PR62QK662L` | ✅ Correct |

## Files to Update

1. ✅ `SupabaseConfig.swift` - URL updated, keys need updating
2. ⚠️ Supabase Dashboard - Apple OAuth needs configuration
3. ⚠️ Supabase Dashboard - Database schema needs to be run
4. ⚠️ Supabase Dashboard - Storage buckets need to be created

---

**Next Steps:**
1. Get credentials from Supabase Dashboard
2. Update `SupabaseConfig.swift` with new keys
3. Configure Apple OAuth in Supabase Dashboard
4. Run database setup scripts
5. Test authentication

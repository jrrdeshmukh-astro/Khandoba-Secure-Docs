# Fix: Apple OAuth "Unacceptable audience" Error

## Error Message
```
❌ Supabase authentication failed: Unacceptable audience in id_token: [com.khandoba.securedocs]
```

## Problem
The Apple ID token contains the bundle identifier (`com.khandoba.securedocs`) as the audience, but Supabase's Apple OAuth provider is configured with a different Services ID.

## Solution

### Step 1: Get Your Supabase Project Credentials

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: `uremtyiorzlapwthjsko`
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL**: `https://uremtyiorzlapwthjsko.supabase.co` ✅ (Already updated)
   - **anon/public key**: Copy this
   - **service_role key**: Copy this (keep secret!)

5. Update `SupabaseConfig.swift`:
   ```swift
   static let supabaseAnonKey = "PASTE_YOUR_ANON_KEY_HERE"
   static let supabaseServiceRoleKey = "PASTE_YOUR_SERVICE_ROLE_KEY_HERE"
   ```

### Step 2: Configure Apple OAuth in Supabase

1. In Supabase Dashboard, go to **Authentication** → **Providers**
2. Find **Apple** and click to enable/configure
3. You need to configure it with a **Services ID** that matches your app

**Important:** For iOS apps, you have two options:

#### Option A: Use Bundle Identifier as Services ID (Recommended)
- **Services ID**: `com.khandoba.securedocs` (your bundle identifier)
- This matches what Apple sends in the ID token

#### Option B: Create a Separate Services ID
1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
2. Create a new **Services ID** (e.g., `com.khandoba.securedocs.auth`)
3. Configure it for "Sign in with Apple"
4. Add this Services ID to Supabase
5. Update your app to use this Services ID (requires code changes)

**For now, use Option A** - it's simpler and matches your current setup.

### Step 3: Configure Apple OAuth in Supabase Dashboard

1. **Services ID**: `com.khandoba.securedocs`
2. **Team ID**: `Q5Y8754WU4` (from your AppConfig)
3. **Key ID**: `PR62QK662L` (from your AppConfig)
4. **Private Key**: Upload the `.p8` file (AuthKey_PR62QK662L.p8)

**To generate the OAuth secret:**
- Follow instructions in `scripts/README_APPLE_OAUTH.md`
- Or use the script: `scripts/generate_apple_oauth_secret.py`

### Step 4: Set Redirect URL

In Supabase Dashboard → Authentication → URL Configuration:
- Add redirect URL: `khandoba://auth/callback` (or your app's URL scheme)

### Step 5: Verify Configuration

After updating:
1. Restart the app
2. Try signing in with Apple
3. Check console for:
   - ✅ "Supabase authentication successful"
   - ✅ "User created/updated successfully"

## Current App Configuration

- **Bundle Identifier**: `com.khandoba.securedocs`
- **Team ID**: `Q5Y8754WU4`
- **Key ID**: `PR62QK662L`
- **Supabase Project**: `uremtyiorzlapwthjsko`

## Quick Checklist

- [ ] Updated Supabase URL in `SupabaseConfig.swift` ✅
- [ ] Updated anon key in `SupabaseConfig.swift` (get from Dashboard)
- [ ] Updated service role key in `SupabaseConfig.swift` (get from Dashboard)
- [ ] Configured Apple OAuth in Supabase Dashboard
- [ ] Services ID set to `com.khandoba.securedocs`
- [ ] Team ID, Key ID, and Private Key configured
- [ ] Redirect URL added
- [ ] Test authentication

## Troubleshooting

### Still getting "Unacceptable audience" error?
- Verify Services ID in Supabase matches bundle identifier exactly
- Check Apple Developer Portal - Services ID is enabled for "Sign in with Apple"
- Ensure the Services ID is added to your App ID's capabilities

### Authentication succeeds but user not created?
- Check RLS policies allow inserts
- Verify database schema is applied
- Check Supabase logs for errors

---

**Last Updated:** December 2024

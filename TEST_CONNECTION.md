# Test Supabase Connection - Step 10

## Quick Test Steps

### 1. Verify Configuration ✅

Check that `AppConfig.useSupabase = true`:
- File: `Khandoba Secure Docs/Config/AppConfig.swift`
- Line 32: Should be `static let useSupabase = true`

✅ **Status:** Already set to `true`

### 2. Verify Supabase Credentials

Check `SupabaseConfig.swift` has your project credentials:
- File: `Khandoba Secure Docs/Config/SupabaseConfig.swift`
- Verify `supabaseURL` matches your Supabase project URL
- Verify `supabaseAnonKey` matches your project's anon key

### 3. Run the App

1. Open the project in Xcode
2. Build and run (⌘R)
3. Watch the **Console** output (View → Debug Area → Activate Console, or ⌘⇧Y)

### 4. Expected Console Output

When the app launches, you should see these messages in order:

```
✅ Supabase client initialized and connected
✅ Supabase initialized successfully
✅ Real-time subscriptions setup for 5 channels
```

**If you see these messages:** ✅ Connection successful!

### 5. What to Look For

#### ✅ Success Messages:
- `✅ Supabase client initialized and connected`
- `✅ Supabase initialized successfully`
- `✅ Real-time subscriptions setup for 5 channels`

#### ⚠️ Warning Messages (may still work):
- `⚠️ Supabase connection check failed:` - Connection might work later
- `⚠️ Supabase initialization failed:` - Check credentials

#### ❌ Error Messages (needs fixing):
- `❌ Supabase client not initialized`
- `❌ Invalid Supabase URL`
- `❌ Authentication failed`

### 6. Test Authentication Flow

After connection is established:

1. Try signing in with Apple
2. Check console for:
   - `✅ User signed in successfully`
   - `✅ User record created/updated in Supabase`

### 7. Verify in Supabase Dashboard

1. Go to Supabase Dashboard → **Table Editor**
2. Check `users` table - should see your user record after sign-in
3. Go to **Logs** → **API Logs** - should see requests from your app

## Troubleshooting

### No Connection Messages

**Problem:** No Supabase messages appear in console

**Solutions:**
1. Verify `AppConfig.useSupabase = true`
2. Check Xcode console is visible (⌘⇧Y)
3. Check console filter isn't hiding messages
4. Clean build folder (⌘⇧K) and rebuild

### Connection Failed Error

**Problem:** `⚠️ Supabase connection check failed`

**Solutions:**
1. Check `SupabaseConfig.swift` has correct URL and keys
2. Verify internet connection
3. Check Supabase project is active (not paused)
4. Verify project URL format: `https://xxxxx.supabase.co`

### Real-time Not Working

**Problem:** No `✅ Real-time subscriptions setup` message

**Solutions:**
1. Check `SupabaseConfig.enableRealtime = true`
2. Verify tables are in `supabase_realtime` publication (run SQL from Step 8)
3. Check Supabase Dashboard → Settings → API → Realtime is enabled

### Authentication Fails

**Problem:** Apple Sign In doesn't work

**Solutions:**
1. Verify Apple OAuth configured in Supabase Dashboard
2. Check redirect URL matches app URL scheme
3. Verify `.p8` key is valid and not expired
4. Check Apple Developer account status

## Manual Connection Test

If you want to test the connection manually, you can add this temporary code to test:

```swift
// Add to ContentView or any view's .onAppear
Task {
    if AppConfig.useSupabase {
        do {
            try await supabaseService.configure()
            print("✅ Manual test: Supabase connected")
            
            // Test a simple query
            let result = try await supabaseService.query("users").execute()
            print("✅ Test query successful: \(result.count) results")
        } catch {
            print("❌ Manual test failed: \(error)")
        }
    }
}
```

## Next Steps After Successful Connection

Once you see the success messages:

1. ✅ Test authentication (sign in with Apple)
2. ✅ Test vault creation
3. ✅ Test document upload
4. ✅ Test real-time updates
5. ✅ Follow `SUPABASE_TESTING_CHECKLIST.md` for comprehensive testing

---

**Status:** Ready to test!
**Last Updated:** December 2024

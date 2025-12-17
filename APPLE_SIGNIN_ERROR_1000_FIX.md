# Fix: Apple Sign In Error 1000

## Error Message
```
The operation couldn't be completed. 
(com.apple.AuthenticationServices.AuthorizationError error 1000.)
```

## Common Causes & Solutions

### 1. ✅ Check Device iCloud Sign-In (Most Common)

**Problem:** Device must be signed into iCloud for Apple Sign In to work

**Solution:**
1. Go to **Settings** → **Sign in to your iPhone**
2. Make sure you're signed in with an Apple ID
3. Verify two-factor authentication is enabled
4. Try signing in again

**Note:** Simulators may not fully support Apple Sign In. Test on a **real device** if possible.

### 2. ✅ Verify Xcode Capabilities

**Check in Xcode:**
1. Select your project in Xcode
2. Select the **"Khandoba Secure Docs"** target
3. Go to **Signing & Capabilities** tab
4. Verify **"Sign In with Apple"** capability is added
5. If missing, click **"+ Capability"** and add it

**Verify in entitlements file:**
- File: `Khandoba_Secure_Docs.entitlements`
- Should have: `com.apple.developer.applesignin` with `Default`

✅ **Status:** Already configured correctly

### 3. ✅ Check Provisioning Profile

**In Xcode:**
1. Go to **Signing & Capabilities**
2. Check **"Automatically manage signing"** is enabled
3. Verify **Team** is set correctly: `Q5Y8754WU4`
4. Check **Bundle Identifier**: `com.khandoba.securedocs`

**If errors:**
- Clean build folder: ⌘⇧K
- Delete derived data
- Rebuild: ⌘B

### 4. ✅ Test on Real Device (Recommended)

**Why:** Simulators have limitations with Apple Sign In

**Steps:**
1. Connect your iPhone/iPad
2. Select device in Xcode
3. Build and run (⌘R)
4. Test Apple Sign In on real device

### 5. ✅ Verify Apple Developer Account

**Check:**
1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Verify your account is active
3. Check **Certificates, Identifiers & Profiles**
4. Verify App ID `com.khandoba.securedocs` exists
5. Verify "Sign in with Apple" is enabled for the App ID

### 6. ✅ Check Services ID Configuration

**In Apple Developer Portal:**
1. Go to **Identifiers** → **Services IDs**
2. Find or create Services ID: `com.khandoba.securedocs`
3. Enable **"Sign in with Apple"**
4. Configure with your app's bundle ID

### 7. ✅ Code-Level Checks

**Verify in code:**
- `SignInWithAppleButton` is properly configured
- Requested scopes: `[.fullName, .email]`
- Error handling in `handleSignIn()`

**Current implementation looks correct** ✅

## Quick Fix Checklist

- [ ] Device is signed into iCloud
- [ ] Two-factor authentication enabled on Apple ID
- [ ] Testing on real device (not simulator)
- [ ] "Sign in with Apple" capability added in Xcode
- [ ] Provisioning profile is valid
- [ ] Bundle identifier matches: `com.khandoba.securedocs`
- [ ] App ID has "Sign in with Apple" enabled
- [ ] Services ID configured (if using Supabase)

## Testing Steps

1. **On Real Device:**
   - Connect iPhone/iPad
   - Build and run
   - Tap "Sign in with Apple"
   - Should work if device is signed into iCloud

2. **On Simulator:**
   - Sign into iCloud in Simulator Settings
   - May still have limitations
   - Prefer real device testing

## If Error Persists

1. **Clean Build:**
   ```bash
   # In Xcode: Product → Clean Build Folder (⌘⇧K)
   # Then rebuild (⌘B)
   ```

2. **Reset Simulator (if using):**
   - Device → Erase All Content and Settings

3. **Check Console Logs:**
   - Look for detailed error messages
   - Check for entitlement warnings

4. **Verify Entitlements:**
   - Ensure `Khandoba_Secure_Docs.entitlements` is included in build
   - Check it's not missing from target

## Most Likely Solution

**For Simulator:**
- Error 1000 is common on simulators
- **Solution:** Test on a real device signed into iCloud

**For Real Device:**
- Ensure device is signed into iCloud
- Verify two-factor authentication is enabled
- Check provisioning profile is valid

---

**Next Steps:**
1. Test on real device (if using simulator)
2. Verify iCloud sign-in on device
3. Check Xcode capabilities
4. Try again

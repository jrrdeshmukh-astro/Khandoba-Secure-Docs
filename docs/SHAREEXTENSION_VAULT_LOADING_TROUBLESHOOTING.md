# ShareExtension Vault Loading Troubleshooting

## Issue: "No vaults available" in ShareExtension

### Root Causes

1. **App Group Not Configured**
   - App Group must be enabled in Xcode for both main app and ShareExtension
   - Both must use the same App Group identifier: `group.com.khandoba.securedocs`

2. **No Vaults Created Yet**
   - User must create at least one vault in the main app first
   - Vaults are created via `CreateVaultView` in the main app

3. **CloudKit Sync Delay**
   - CloudKit sync can take 1-5 seconds after vault creation
   - ShareExtension waits up to 3 seconds for sync

4. **Store File Location Mismatch**
   - Main app and ShareExtension must use the same store URL
   - Both should use App Group URL: `group.com.khandoba.securedocs/KhandobaSecureDocs.store`

5. **iCloud Not Signed In**
   - CloudKit requires user to be signed into iCloud
   - Check Settings → [User Name] → iCloud → iCloud Drive

## Diagnostic Steps

### 1. Check Console Logs

Look for these log messages in Xcode console:

```
📦 ShareExtension: Setting up ModelContainer
   App Group ID: group.com.khandoba.securedocs
   App Group URL: /path/to/app/group or nil
   Store file exists: true/false
```

**If App Group URL is nil:**
- App Group not properly configured in Xcode
- Check project settings → Signing & Capabilities → App Groups

**If Store file exists is false:**
- Main app hasn't created the store yet
- Create a vault in main app first
- Wait a few seconds for CloudKit sync

### 2. Verify App Group Configuration

**In Xcode:**
1. Select main app target
2. Go to Signing & Capabilities
3. Verify "App Groups" capability is added
4. Verify `group.com.khandoba.securedocs` is checked

5. Select ShareExtension target
6. Go to Signing & Capabilities
7. Verify "App Groups" capability is added
8. Verify `group.com.khandoba.securedocs` is checked

**Both targets must:**
- Use the same Team ID
- Use the same App Group identifier
- Have App Groups capability enabled

### 3. Verify Vaults Exist in Main App

1. Open main app
2. Navigate to Vaults tab
3. Verify at least one vault exists
4. If no vaults, create one using the "+" button

### 4. Test CloudKit Sync

1. Create a vault in main app
2. Wait 5 seconds
3. Open ShareExtension
4. Check console logs for vault count

### 5. Check iCloud Status

1. Settings → [Your Name] → iCloud
2. Verify iCloud Drive is enabled
3. Verify the app has iCloud access

## Solutions

### Solution 1: Ensure App Group is Configured

**In Xcode Project Settings:**
1. Select main app target → Signing & Capabilities
2. Click "+ Capability" → Add "App Groups"
3. Check `group.com.khandoba.securedocs`
4. Repeat for ShareExtension target

**Verify in entitlements files:**
- `Khandoba Secure Docs/Khandoba_Secure_Docs.entitlements` should have:
  ```xml
  <key>com.apple.security.application-groups</key>
  <array>
      <string>group.com.khandoba.securedocs</string>
  </array>
  ```

- `ShareExtension/ShareExtension.entitlements` should have:
  ```xml
  <key>com.apple.security.application-groups</key>
  <array>
      <string>group.com.khandoba.securedocs</string>
  </array>
  ```

### Solution 2: Create Vaults in Main App

1. Open main app
2. Go to Vaults tab
3. Tap "+" button
4. Create a vault with any name
5. Wait 3-5 seconds for CloudKit sync
6. Try ShareExtension again

### Solution 3: Force CloudKit Sync

If vaults still don't appear:

1. In main app, create a new vault
2. Wait 10 seconds
3. Pull down to refresh in ShareExtension (if refreshable is implemented)
4. Or close and reopen ShareExtension

### Solution 4: Check Store File Location

**Verify main app is using App Group:**

Check `Khandoba_Secure_DocsApp.swift`:
```swift
let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.khandoba.securedocs")
let modelConfiguration = ModelConfiguration(
    schema: schema,
    url: appGroupURL?.appendingPathComponent("KhandobaSecureDocs.store"),
    ...
)
```

**Verify ShareExtension is using same URL:**

Check `ShareExtensionViewController.swift` - should use the same App Group URL.

### Solution 5: Manual Store Verification

**Check if store file exists:**
```swift
let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.khandoba.securedocs")
let storeURL = appGroupURL?.appendingPathComponent("KhandobaSecureDocs.store")
print("Store exists: \(FileManager.default.fileExists(atPath: storeURL?.path ?? ""))")
```

## Expected Behavior

### When Working Correctly:

1. User creates vault in main app
2. Vault saved to App Group store
3. CloudKit syncs vault (1-5 seconds)
4. ShareExtension opens
5. ShareExtension loads same App Group store
6. Vaults appear in ShareExtension (may take 1-3 seconds)

### Console Output (Success):

```
📦 ShareExtension: Setting up ModelContainer
   App Group ID: group.com.khandoba.securedocs
   App Group URL: /private/var/mobile/Containers/Shared/AppGroup/.../group.com.khandoba.securedocs
   Store file exists: true
✅ ShareExtension: ModelContainer created successfully
   Waiting for CloudKit sync...
📦 ShareExtension: Initial fetch found 2 vault(s)
   Vault: My Vault (ID: ..., System: false)
   Vault: Test Vault (ID: ..., System: false)
📦 ShareExtension: 2 non-system vault(s) available
```

## Fallback Behavior

If App Group is not accessible, ShareExtension will:
1. Use default SwiftData location
2. Rely on CloudKit sync only
3. May take longer to sync (5-10 seconds)
4. Still work, but without local store sharing

## Testing Checklist

- [ ] App Group configured in Xcode for both targets
- [ ] App Group identifier matches: `group.com.khandoba.securedocs`
- [ ] Both targets signed with same team
- [ ] At least one vault created in main app
- [ ] User signed into iCloud
- [ ] iCloud Drive enabled
- [ ] Waited 5+ seconds after creating vault
- [ ] Checked console logs for diagnostics
- [ ] Tried pull-to-refresh in ShareExtension
- [ ] Tried closing and reopening ShareExtension

## Common Errors

### "App Group URL: nil"
**Fix:** Configure App Group in Xcode project settings

### "Store file exists: false"
**Fix:** Create a vault in main app first, then wait for CloudKit sync

### "Found 0 vault(s)"
**Possible causes:**
- No vaults created yet
- CloudKit sync not complete (wait longer)
- All vaults are system vaults (filtered out)
- iCloud not signed in

### "Failed to load vaults: [error]"
**Check:**
- CloudKit container identifier matches
- iCloud account is active
- Network connection available

## Additional Notes

- SwiftData with CloudKit automatically syncs data
- App Group enables local store sharing (faster)
- CloudKit enables cross-device sync (slower but works without App Group)
- Both methods work, but App Group is faster for same-device sharing


# ShareExtension LaunchServices Errors - Explanation & Resolution

> **Last Updated:** December 2024  
> **Status:** These errors are typically **harmless** and don't affect functionality

## Error Messages

You may see these errors in the console when using the Share Extension:

```
LaunchServices: store (null) or url (null) was nil: Error Domain=NSOSStatusErrorDomain Code=-54 "process may not map database"
Attempt to map database failed: permission was denied. This attempt will not be retried.
Failed to initialize client context with error Error Domain=NSOSStatusErrorDomain Code=-54 "process may not map database"
-[RTIInputSystemClient remoteTextInputSessionWithID:performInputOperation:] perform input operation requires a valid sessionID
Error creating the CFMessagePort needed to communicate with PPT.
[UISceneHosting-com.khandoba.securedocs:UIHostedScene-com.apple.ContactsUI.ContactsViewService-...] No scene exists for this identity (didUpdateClientSettingsWithDiff)
```

## Why These Errors Occur

These errors are **expected behavior** in iOS app extensions and system frameworks because:

1. **Sandboxed Environment**: Share Extensions run in a restricted sandbox with limited system access
2. **Launch Services Database**: Extensions don't have full access to the Launch Services database (used for app launching and registration)
3. **System Services**: Some system services (like text input system, CFMessagePort) aren't fully available to extensions
4. **Security Model**: iOS intentionally restricts extension access to prevent security issues
5. **ContactsUI Scene Warning**: When using `CNContactPickerViewController`, iOS creates a scene for the ContactsUI service. The "No scene exists" warning occurs during scene lifecycle transitions and is harmless - the contact picker still works correctly

## Are These Errors Critical?

**No.** These errors are:
- ✅ **Harmless warnings** - They don't affect Share Extension or contact picker functionality
- ✅ **Expected behavior** - iOS extensions and system frameworks are designed with these restrictions
- ✅ **Not user-visible** - Users won't see these errors
- ✅ **Common** - Most iOS extensions and apps using ContactsUI see similar warnings
- ✅ **System-level noise** - These are iOS framework internal warnings, not your app's errors

## When to Worry

You should investigate if:
- ❌ The Share Extension **doesn't work** (can't share files, crashes, etc.)
- ❌ Vaults **don't load** in the extension
- ❌ Files **don't upload** successfully
- ❌ You see **actual functional errors** (not just these warnings)

## Verification Steps

To verify the Share Extension is working correctly:

1. **Test Vault Loading:**
   - Open Share Extension from another app
   - Check if vaults appear in the list
   - Verify console logs show vaults being loaded

2. **Test File Upload:**
   - Share an image or document
   - Select a vault
   - Upload the file
   - Verify it appears in the main app

3. **Check Console Logs:**
   - Look for `✅ ShareExtension: ModelContainer created successfully`
   - Look for `📦 ShareExtension: X non-system vault(s) available`
   - These indicate successful operation despite the warnings

## Configuration Check

Your Share Extension is correctly configured:

✅ **App Groups**: `group.com.khandoba.securedocs`  
✅ **CloudKit**: `iCloud.com.khandoba.securedocs`  
✅ **Entitlements**: Properly set in `ShareExtension.entitlements`  
✅ **Info.plist**: Correctly configured with activation rules

## If Errors Persist and Affect Functionality

If the Share Extension **doesn't work** (not just showing warnings):

1. **Verify App Group Configuration:**
   ```bash
   # Check entitlements match between main app and extension
   # Both should have: group.com.khandoba.securedocs
   ```

2. **Check Code Signing:**
   - Ensure main app and extension are signed with the same team
   - Verify provisioning profiles include App Groups capability

3. **Clean Build:**
   ```bash
   # In Xcode: Product > Clean Build Folder (Shift+Cmd+K)
   # Delete DerivedData
   # Rebuild
   ```

4. **Test on Physical Device:**
   - Some extension issues only appear on simulators
   - Test on a real iOS device

5. **Check Xcode Console:**
   - Filter for actual errors (not warnings)
   - Look for SwiftData/CloudKit sync errors
   - Check for App Group access errors

## Suppressing Console Noise (Optional)

If these warnings clutter your console during development, you can:

1. **Filter Console Output:**
   - In Xcode Console, use filters to hide LaunchServices errors
   - Focus on your app's log messages (look for 📦, ✅, ❌ emojis)

2. **Use Logging Levels:**
   - Your code already uses emoji prefixes for easy filtering
   - Filter by: `📦 ShareExtension` to see only relevant logs

## Error Breakdown

### LaunchServices Errors (Code -54)
- **What**: iOS trying to access Launch Services database from extension
- **Why**: Extensions don't have full system database access (by design)
- **Impact**: None - purely informational warnings

### CFMessagePort Errors
- **What**: System trying to create inter-process communication ports
- **Why**: Some system services aren't available in extension sandbox
- **Impact**: None - system handles gracefully

### RTIInputSystemClient Errors
- **What**: Text input system trying to access remote input session
- **Why**: Extensions have limited text input system access
- **Impact**: None - text input still works normally

### ContactsUI Scene Warning
- **What**: iOS scene system warning during ContactsUI presentation
- **Why**: Scene lifecycle transitions in system frameworks
- **Impact**: None - contact picker works perfectly despite the warning

## Summary

- ✅ **These errors are normal** for iOS Share Extensions and system frameworks
- ✅ **They don't affect functionality** - your extension and contact picker work fine
- ✅ **No action needed** unless the extension actually fails to work
- ✅ **Focus on functional testing** - if vaults load, files upload, and contacts can be selected, you're good!
- ✅ **These are iOS framework warnings**, not bugs in your code

## Related Documentation

- `SHAREEXTENSION_VAULT_LOADING_TROUBLESHOOTING.md` - For actual vault loading issues
- `EXTENSION_FILES_READY.md` - Extension setup guide
- Apple Documentation: [App Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/)

---

**Bottom Line:** These are harmless system warnings. If your Share Extension works (vaults load, files upload), you can safely ignore these errors.


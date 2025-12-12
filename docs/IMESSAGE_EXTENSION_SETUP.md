# iMessage Extension Setup Guide

> **How to make Khandoba appear in Messages app**

## Where to Find It

The iMessage extension should appear in the **Messages app drawer** (the App Store icon at the bottom of the keyboard in Messages), not in the "+" menu.

## Setup Steps

### 1. Build and Run the App

First, make sure you've built and run the main app at least once:

1. Open Xcode
2. Select "Khandoba Secure Docs" scheme
3. Build and run on your device (⌘+R)
4. Let the app launch completely

This registers the iMessage extension with the system.

### 2. Enable in Settings

1. Open **Settings** app on your iPhone
2. Go to **Messages**
3. Scroll down to **Message Apps**
4. Find **"Khandoba"** in the list
5. Toggle it **ON** (if it's not already)

### 3. Add to Messages App Drawer

1. Open **Messages** app
2. Start a new conversation or open an existing one
3. Tap the **App Store icon** (📱) at the bottom left of the keyboard
4. This opens the Messages app drawer
5. Scroll through the apps or tap the **"+"** button to add apps
6. Find **"Khandoba"** in the list
7. Tap it to add it to your drawer

### 4. Access the Extension

Once added, you can access Khandoba by:
1. Opening Messages
2. Tapping the App Store icon (📱) at the bottom
3. Tapping **"Khandoba"** in your app drawer

## Troubleshooting

### Extension Not Appearing in Settings

**Problem:** "Khandoba" doesn't appear in Settings → Messages → Message Apps

**Solutions:**
1. **Rebuild the extension target:**
   ```bash
   # In Xcode, select "KhandobaSecureDocsMessageApp MessagesExtension" scheme
   # Build (⌘+B)
   ```

2. **Clean build folder:**
   - In Xcode: Product → Clean Build Folder (⇧⌘K)
   - Rebuild the project

3. **Restart device:**
   - Sometimes extensions need a device restart to register

4. **Check bundle identifier:**
   - Should be: `openstreetllc.KhandobaSecureDocsMessageApp.MessagesExtension`
   - Verify in Xcode: Target → General → Bundle Identifier

### Extension Not Appearing in Messages Drawer

**Problem:** Extension is enabled in Settings but doesn't show in Messages

**Solutions:**
1. **Force quit Messages app:**
   - Swipe up from bottom, find Messages, swipe up to close
   - Reopen Messages

2. **Restart Messages:**
   - Settings → Messages → Toggle "iMessage" OFF then ON
   - Wait a few seconds, then toggle back ON

3. **Re-add the extension:**
   - Settings → Messages → Message Apps
   - Toggle "Khandoba" OFF, then ON again
   - Restart Messages app

4. **Check display name:**
   - Should be "Khandoba" (configured in `KhandobaSecureDocsMessageApp/Info.plist`)
   - Verify: `CFBundleDisplayName = "Khandoba"`

### Extension Crashes or Doesn't Work

**Problem:** Extension appears but crashes when tapped

**Solutions:**
1. **Check console logs:**
   - Connect device to Mac
   - Open Console app
   - Filter for "Khandoba" or "MessagesExtension"
   - Look for error messages

2. **Verify entitlements:**
   - Check `KhandobaSecureDocsMessageApp.entitlements`
   - Should have App Groups: `group.com.khandoba.securedocs`
   - Should have CloudKit if needed

3. **Check dependencies:**
   - Make sure all required services are available
   - Some services are excluded from extension (see `BUILD_ERRORS_FIXED_FINAL.md`)

## Verification Checklist

- [ ] Main app builds and runs successfully
- [ ] Extension target builds without errors
- [ ] "Khandoba" appears in Settings → Messages → Message Apps
- [ ] Extension is toggled ON in Settings
- [ ] "Khandoba" appears in Messages app drawer
- [ ] Extension opens when tapped
- [ ] Can send vault invitations
- [ ] Can share files from Photos/Safari

## Expected Behavior

When you tap "Khandoba" in Messages:

1. **Main Menu** appears with options:
   - "Invite to Vault"
   - "Share File"

2. **Invite to Vault:**
   - Shows list of your vaults
   - Select vault and enter nominee name
   - Sends interactive message bubble

3. **Share File:**
   - If sharing from Photos/Safari, shows file sharing interface
   - Select vault to save file to
   - File uploads to selected vault

## Configuration Files

Key files for iMessage extension:

- `KhandobaSecureDocsMessageApp/Info.plist` - Main app configuration
- `KhandobaSecureDocsMessageApp MessagesExtension/Info.plist` - Extension configuration
- `KhandobaSecureDocsMessageApp MessagesExtension/MessagesViewController.swift` - Main controller
- `KhandobaSecureDocsMessageApp.entitlements` - App Groups, CloudKit

## Display Name

The extension appears as **"Khandoba"** (configured in):
- `CFBundleDisplayName` in main app Info.plist
- `MSMessageExtensionBundleDisplayName` in extension attributes

## Notes

- The extension uses **App Groups** (`group.com.khandoba.securedocs`) to share data with the main app
- Vault data is synced via UserDefaults in the App Group
- The extension creates interactive message bubbles (Apple Cash style)
- File sharing works when invoked from Photos/Safari share sheet

## Still Not Working?

If the extension still doesn't appear after following all steps:

1. **Check Xcode build logs** for any warnings or errors
2. **Verify the extension is embedded** in the main app:
   - Target → "Khandoba Secure Docs" → Build Phases
   - "Embed Foundation Extensions" should include the extension
3. **Check device logs** in Console app for registration errors
4. **Try on a different device** to rule out device-specific issues

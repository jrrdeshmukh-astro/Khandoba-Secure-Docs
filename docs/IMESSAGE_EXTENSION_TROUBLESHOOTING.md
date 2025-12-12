# iMessage Extension - Troubleshooting Guide

> **Last Updated:** December 2024
> 
> Guide to make the Khandoba iMessage extension appear in Messages app.

## Problem: Extension Not Appearing in Messages

If you don't see "Khandoba" in the Messages app drawer, follow these steps:

## Step 1: Build and Install the Extension

### In Xcode:

1. **Select the MessageExtension scheme**
   - In Xcode toolbar, click the scheme dropdown
   - Select "MessageExtension" (not the main app)

2. **Build and Run** (⌘+R)
   - This installs the extension on your device/simulator
   - Wait for "Build Succeeded"

3. **Switch back to main app scheme**
   - Select "Khandoba Secure Docs" scheme
   - Build and Run again (⌘+R)

**Important:** Both the main app AND the extension must be installed for the extension to appear.

## Step 2: Enable Extension in Settings

### On Your iPhone/iPad:

1. **Open Settings app**
2. **Go to:** Settings → Messages
3. **Scroll down to:** "Message Extensions" or "iMessage Apps"
4. **Find "Khandoba"** in the list
5. **Toggle it ON** (if it's off)

## Step 3: Add Extension to Messages App Drawer

### In Messages App:

1. **Open Messages app**
2. **Start or open a conversation**
3. **Tap the App Store icon** (ⓐ) in the app drawer at the bottom
4. **Tap "Manage"** (if available)
5. **Find "Khandoba"** in the list
6. **Tap the "+" button** or toggle it ON

### Alternative Method:

1. **In Messages**, tap the **App Store icon** (ⓐ)
2. **Scroll horizontally** through the app icons
3. **Look for "Khandoba"** icon
4. If you see it, tap and hold, then drag it to a visible position

## Step 4: Verify Extension is Working

### Test Steps:

1. **Open Messages app**
2. **Start a new conversation** or open existing one
3. **Tap the App Store icon** (ⓐ) in the app drawer
4. **Look for "Khandoba"** icon in the app strip
5. **Tap "Khandoba"** - it should open the extension

## Common Issues & Solutions

### Issue 1: Extension Not in Settings

**Symptoms:**
- Can't find "Khandoba" in Settings → Messages → Message Extensions

**Solutions:**
1. **Rebuild the extension:**
   - Clean Build Folder (⇧⌘K)
   - Build MessageExtension target (⌘+B)
   - Run main app (⌘+R)

2. **Check bundle identifier:**
   - Verify `MessageExtension.entitlements` matches main app
   - Should be: `com.khandoba.securedocs.MessageExtension`

3. **Restart device:**
   - Sometimes iOS needs a restart to recognize new extensions

### Issue 2: Extension Crashes on Launch

**Symptoms:**
- Extension appears but crashes when tapped

**Solutions:**
1. **Check Xcode console** for error messages
2. **Verify all dependencies are in target:**
   - UnifiedTheme.swift
   - StandardCard.swift
   - ThemeModifiers.swift
   - Models (Vault, Nominee, User)

3. **Check for missing imports:**
   - All files should have proper imports
   - No missing dependencies

### Issue 3: Extension Shows But No UI

**Symptoms:**
- Extension opens but shows blank screen

**Solutions:**
1. **Check ModelContext initialization:**
   - Extension needs access to SwiftData models
   - Verify App Group is configured correctly

2. **Check console logs:**
   - Look for SwiftData errors
   - Look for missing file errors

### Issue 4: Extension Not in App Drawer

**Symptoms:**
- Extension is enabled in Settings but doesn't appear in Messages

**Solutions:**
1. **Force quit Messages app:**
   - Swipe up from bottom, swipe away Messages
   - Reopen Messages

2. **Restart Messages:**
   - Settings → Messages → Toggle iMessage OFF
   - Wait 5 seconds
   - Toggle iMessage ON

3. **Restart device:**
   - Sometimes required for extensions to appear

## Quick Checklist

Before reporting issues, verify:

- [ ] MessageExtension target builds successfully (no errors)
- [ ] Main app builds successfully
- [ ] Both app and extension are installed on device
- [ ] Extension is enabled in Settings → Messages
- [ ] Messages app has been force-quit and reopened
- [ ] Device has been restarted (if needed)
- [ ] All dependencies are in MessageExtension target

## Debugging Steps

### 1. Check Extension is Installed

```bash
# On device, check if extension is installed
# Settings → General → iPhone Storage → Khandoba Secure Docs
# Should show both app and extension
```

### 2. Check Console Logs

In Xcode:
1. **Window → Devices and Simulators**
2. **Select your device**
3. **View Device Logs**
4. **Filter for "MessageExtension"**
5. **Look for errors or warnings**

### 3. Verify Info.plist

Check `MessageExtension/Info.plist`:
- `CFBundleDisplayName` = "Khandoba"
- `MSMessageExtensionBundleDisplayName` = "Khandoba"
- `MSMessageExtensionCategory` = "Interactive"
- `NSExtensionPointIdentifier` = "com.apple.message"

### 4. Verify Entitlements

Check `MessageExtension.entitlements`:
- App Group matches main app: `group.com.khandoba.securedocs`
- CloudKit container matches: `iCloud.com.khandoba.securedocs`

## Testing on Simulator

**Note:** iMessage extensions work better on real devices. Simulator may have limitations.

### Simulator Steps:

1. **Build MessageExtension target**
2. **Build and run main app**
3. **Open Messages in Simulator**
4. **Look for extension in app drawer**

**If it doesn't appear:**
- Try a different simulator
- Use a real device for testing

## Still Not Working?

If the extension still doesn't appear:

1. **Verify project structure:**
   - MessageExtension folder exists
   - All files are in correct location
   - Xcode project includes MessageExtension target

2. **Check Xcode project settings:**
   - MessageExtension target exists
   - Bundle identifier is correct
   - Signing is configured

3. **Clean and rebuild:**
   ```bash
   # In Xcode:
   Product → Clean Build Folder (⇧⌘K)
   Product → Build (⌘+B)
   ```

4. **Check for build errors:**
   - Fix any compilation errors
   - Fix any missing dependencies
   - Fix any signing issues

## Expected Behavior

When working correctly:

1. **Extension appears** in Messages app drawer as "Khandoba" icon
2. **Tapping icon** opens extension UI
3. **UI shows** vault selection and invitation form
4. **Sending invitation** creates interactive message
5. **Recipient can tap** message to accept/decline

## Related Documentation

- `docs/IMESSAGE_EXTENSION_APPLE_CASH_STYLE.md` - Feature documentation
- `docs/IMESSAGE_EXTENSION_DEPENDENCIES.md` - Dependency setup

## Support

If issues persist:
1. Check Xcode console for specific errors
2. Verify all files are in MessageExtension target
3. Ensure both app and extension are signed with same team
4. Try on a real device (not simulator)

---

**Status:** Troubleshooting guide ready

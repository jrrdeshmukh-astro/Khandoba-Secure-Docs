# Troubleshooting: iMessage Extension Not Appearing

## Issue
Khandoba doesn't appear in Settings → Messages → iMessage Apps

## Solutions (Try in Order)

### 1. **Full Clean Build & Reinstall**
```bash
# In Xcode:
# 1. Product → Clean Build Folder (Shift+Cmd+K)
# 2. Delete DerivedData:
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
# 3. Build and Run the main app target (not just MessageExtension)
# 4. Make sure BOTH targets build successfully:
#    - Khandoba Secure Docs (main app)
#    - MessageExtension (extension)
```

### 2. **Verify Extension is Embedded**
1. In Xcode, select **Khandoba Secure Docs** target
2. Go to **Build Phases** tab
3. Expand **Embed Foundation Extensions**
4. Verify **MessageExtension.appex** is listed
5. If missing, drag `MessageExtension.appex` from Products folder into this section

### 3. **Check Signing & Capabilities**
1. Select **MessageExtension** target
2. Go to **Signing & Capabilities**
3. Verify:
   - ✅ Team is selected
   - ✅ Bundle Identifier: `com.khandoba.securedocs.MessageExtension`
   - ✅ App Groups: `group.com.khandoba.securedocs`
   - ✅ CloudKit: `iCloud.com.khandoba.securedocs`

### 4. **Device-Side Steps**
1. **Delete the app completely** from device
2. **Restart the device** (power off/on)
3. **Reinstall** the app from Xcode
4. **Open Messages app** once
5. **Go to Settings → Messages → iMessage Apps**
6. Scroll down - Khandoba should appear under "Included With An App"

### 5. **Verify Info.plist Configuration**
Check `MessageExtension/Info.plist`:
- ✅ `NSExtensionPointIdentifier` = `com.apple.message-ui`
- ✅ `NSExtensionPrincipalClass` = `$(PRODUCT_MODULE_NAME).MessageExtensionViewController`
- ✅ `MSMessageExtensionCategory` = `Interactive`
- ✅ `MSMessageExtensionLaunchPresentationStyle` = `Expanded`
- ✅ `CFBundleDisplayName` = `Khandoba`

### 6. **Check Console Logs**
1. Connect device to Mac
2. Open **Console.app**
3. Filter for "MessageExtension" or "Khandoba"
4. Look for errors during app launch

### 7. **Manual Enable (If Extension Exists but Disabled)**
1. Open **Messages** app
2. Start a new conversation
3. Tap the **App Store icon** (left of text input)
4. Tap the **four dots** (⋯) to see all apps
5. Look for **Khandoba** in the list
6. If found, tap to enable it

### 8. **Verify Build Settings**
In Xcode, select **MessageExtension** target → **Build Settings**:
- ✅ `GENERATE_INFOPLIST_FILE` = `NO`
- ✅ `INFOPLIST_FILE` = `MessageExtension/Info.plist`
- ✅ `SWIFT_ACTIVE_COMPILATION_CONDITIONS` includes `APP_EXTENSION`
- ✅ `PRODUCT_BUNDLE_IDENTIFIER` = `com.khandoba.securedocs.MessageExtension`

## Expected Behavior After Fix

Once working:
1. Khandoba appears in **Settings → Messages → iMessage Apps**
2. Toggle is **ON** (green)
3. In Messages app, Khandoba icon appears in app drawer
4. Tapping Khandoba opens the nominee invitation interface

## Still Not Working?

If none of these work:
1. Check Xcode version (should be 26.1.1+)
2. Check iOS version (should be 17.0+)
3. Try on a different device/simulator
4. Verify the extension builds without errors
5. Check that the main app target includes MessageExtension as a dependency


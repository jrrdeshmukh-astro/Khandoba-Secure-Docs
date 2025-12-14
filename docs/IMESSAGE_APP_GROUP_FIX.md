# Fix App Group Entitlement for iMessage Extension

## Problem
The iMessage extension is showing this error:
```
container_create_or_lookup_app_group_path_by_app_group_identifier: client is not entitled
SwiftData/DataUtilities.swift:1179: Fatal error: Unable to find App Group Container in Entitlements: group.com.khandoba.securedocs
```

## Solution

The entitlements file exists and is correct, but the **App Group capability must be enabled in Xcode** for the iMessage extension target.

### Steps to Fix:

1. **Open Xcode** and select your project in the navigator

2. **Select the iMessage Extension Target:**
   - Click on the project name in the navigator
   - Select the **"KhandobaSecureDocsMessageApp MessagesExtension"** target

3. **Go to Signing & Capabilities tab**

4. **Add App Groups Capability:**
   - Click the **"+ Capability"** button at the top left
   - Search for and add **"App Groups"**
   - In the App Groups section, check the box for: `group.com.khandoba.securedocs`
   - If it doesn't exist, click the "+" button and add: `group.com.khandoba.securedocs`

5. **Verify the Entitlements File:**
   - The file `KhandobaSecureDocsMessageApp MessagesExtension/KhandobaSecureDocsMessageApp.entitlements` should contain:
   ```xml
   <key>com.apple.security.application-groups</key>
   <array>
       <string>group.com.khandoba.securedocs</string>
   </array>
   ```

6. **Clean Build Folder:**
   - Press `Shift + Command + K` (or Product → Clean Build Folder)
   - This ensures the entitlements are properly linked

7. **Rebuild:**
   - Press `Command + B` to build
   - The build should succeed

8. **Test:**
   - Run the app on a device or simulator
   - Open Messages and tap the Khandoba app in the tray
   - The App Group error should be gone

## Verification

After fixing, you should see in the console:
```
📦 App Group URL verified: /private/var/mobile/Containers/Shared/AppGroup/...
📦 VaultSelectionMessageView: Loaded X vault(s)
```

Instead of the fatal error.

## Important Notes

- **Both the main app and iMessage extension** must have the same App Group ID: `group.com.khandoba.securedocs`
- The App Group must be enabled in **both targets** in Xcode
- After adding the capability, you may need to **clean and rebuild**
- On a **physical device**, make sure your **Apple Developer account** has App Groups enabled

## If Still Not Working

1. Check that your **Apple Developer account** has App Groups enabled
2. Verify the **Team ID** is set correctly in Signing & Capabilities
3. Make sure you're testing on a **device** (not just simulator) - some entitlements require device testing
4. Check that the **entitlements file is included** in the target's "Copy Bundle Resources" build phase

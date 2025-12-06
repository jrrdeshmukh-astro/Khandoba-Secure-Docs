# Share Extension Setup Guide

> **Last Updated:** December 2024  
> Complete guide for setting up the Share Extension to import media from other apps

## Overview

The Share Extension allows users to share photos, videos, files, and URLs from other iOS apps directly into Khandoba Secure Docs vaults.

## Features

- ✅ Import images from Photos app
- ✅ Import videos from Photos app
- ✅ Import files from Files app
- ✅ Import URLs from Safari/other apps
- ✅ Select target vault
- ✅ Progress tracking
- ✅ CloudKit sync support
- ✅ Secure document encryption

## Setup Instructions

### Step 1: Add Share Extension Target in Xcode

1. Open the project in Xcode:
   ```bash
   open "Khandoba Secure Docs.xcodeproj"
   ```

2. Add Share Extension Target:
   - **File** → **New** → **Target**
   - Select **iOS** → **Share Extension**
   - Click **Next**
   - Configure:
     - **Product Name:** `ShareExtension`
     - **Bundle Identifier:** `com.khandoba.securedocs.ShareExtension`
     - **Language:** Swift
     - **Embed in Application:** Khandoba Secure Docs
   - Click **Finish**

### Step 2: Configure Share Extension Target

1. **Select ShareExtension target** in the project navigator

2. **General Tab:**
   - **Display Name:** `Khandoba`
   - **Deployment Target:** `iOS 17.0`
   - **Version:** `1.0`
   - **Build:** `19`

3. **Signing & Capabilities:**
   - **Team:** Select your development team
   - **Bundle Identifier:** `com.khandoba.securedocs.ShareExtension`
   
   - **Add App Groups:**
     - Click **+ Capability**
     - Add: `group.com.khandoba.securedocs`
     - Enable for both main app and extension
   
   - **Add CloudKit:**
     - Click **+ Capability**
     - Container: `iCloud.com.khandoba.securedocs`
     - Enable for both main app and extension

### Step 3: Replace Auto-Generated Files

1. **Delete auto-generated ShareExtensionViewController.swift:**
   - Find it in the ShareExtension folder
   - Right-click → Delete → Move to Trash

2. **Add existing ShareExtensionViewController.swift:**
   - The file already exists at: `ShareExtension/ShareExtensionViewController.swift`
   - In Xcode, right-click ShareExtension folder → **Add Files to "ShareExtension"...**
   - Select `ShareExtension/ShareExtensionViewController.swift`
   - ✅ Check "Copy items if needed"
   - ✅ Check "Add to targets: ShareExtension"
   - Click **Add**

3. **Add Info.plist:**
   - Right-click ShareExtension folder → **Add Files to "ShareExtension"...**
   - Select `ShareExtension/Info.plist`
   - ✅ Check "Copy items if needed"
   - ✅ Check "Add to targets: ShareExtension"
   - Click **Add**
   
   - In Build Settings:
     - Search for "Info.plist File"
     - Set to: `ShareExtension/Info.plist`

4. **Add Entitlements:**
   - Right-click ShareExtension folder → **Add Files to "ShareExtension"...**
   - Select `ShareExtension/ShareExtension.entitlements`
   - ✅ Check "Copy items if needed"
   - ✅ Check "Add to targets: ShareExtension"
   - Click **Add**
   
   - In Build Settings:
     - Search for "Code Signing Entitlements"
     - Set to: `ShareExtension/ShareExtension.entitlements`

### Step 4: Link Required Frameworks

1. Select **ShareExtension target**
2. Go to **Build Phases** tab
3. Expand **Link Binary With Libraries**
4. Click **+** and add:
   - `SwiftUI.framework`
   - `SwiftData.framework`
   - `UniformTypeIdentifiers.framework`
   - `MobileCoreServices.framework`

### Step 5: Share Data Models

The Share Extension needs access to your data models:

1. Select the **Models** folder in the project navigator
2. For each model file (Vault.swift, Document.swift, User.swift):
   - Select the file
   - In File Inspector (right panel)
   - Under **Target Membership**
   - ✅ Check **ShareExtension**

**Required Models:**
- `Vault.swift`
- `Document.swift`
- `User.swift`
- `DocumentVersion.swift` (if used)

### Step 6: Configure App Group

1. **Main App Target:**
   - Select main app target
   - **Signing & Capabilities**
   - **App Groups:** Ensure `group.com.khandoba.securedocs` is enabled

2. **ShareExtension Target:**
   - Select ShareExtension target
   - **Signing & Capabilities**
   - **App Groups:** Ensure `group.com.khandoba.securedocs` is enabled

### Step 7: Build and Test

1. **Select ShareExtension scheme:**
   - In Xcode toolbar, select **ShareExtension** from scheme dropdown

2. **Build:**
   - Press **Cmd+B** to build
   - Fix any compilation errors

3. **Test on Device/Simulator:**
   - Select a device/simulator
   - Press **Cmd+R** to run
   - The extension will appear in the share sheet

4. **Test Sharing:**
   - Open **Photos** app
   - Select a photo
   - Tap **Share** button
   - Look for **Khandoba** in the share sheet
   - Tap it
   - Select a vault
   - Import the photo

## Using Xcode CLI (Alternative)

If you prefer command-line setup, use the provided script:

```bash
./scripts/setup_share_extension.sh
```

This will provide detailed instructions for manual setup.

## Architecture

### Data Flow

1. **User shares from external app** (Photos, Files, Safari)
2. **Share Extension receives items** via `NSExtensionContext`
3. **Extension loads items** (images, videos, files, URLs)
4. **User selects target vault** from list
5. **Extension creates documents** in SwiftData
6. **Documents sync via CloudKit** to main app
7. **Main app processes uploads** via `ShareExtensionService`

### Key Components

- **ShareExtensionViewController.swift:** Main extension entry point
- **ShareExtensionView:** SwiftUI interface for vault selection
- **ShareExtensionService.swift:** Processes uploads in main app
- **App Group:** `group.com.khandoba.securedocs` for data sharing

## Supported File Types

- **Images:** JPEG, PNG, HEIC, GIF, WebP
- **Videos:** MP4, MOV, M4V
- **Files:** PDF, DOC, XLS, etc.
- **URLs:** Web links from Safari

## Troubleshooting

### Extension doesn't appear in share sheet

1. **Check Info.plist:**
   - Verify `NSExtensionActivationRule` is configured
   - Check file type support

2. **Check Bundle Identifier:**
   - Must be: `com.khandoba.securedocs.ShareExtension`

3. **Rebuild and reinstall:**
   - Clean build folder (Cmd+Shift+K)
   - Delete app from device
   - Rebuild and install

### "No vaults available" error

1. **Check CloudKit sync:**
   - Ensure CloudKit is enabled for both targets
   - Verify container identifier matches

2. **Check App Group:**
   - Both targets must have same App Group enabled

3. **Create a vault first:**
   - Open main app
   - Create at least one vault
   - Try sharing again

### Documents not appearing in main app

1. **Check CloudKit sync:**
   - Wait a few seconds for sync
   - Pull to refresh in main app

2. **Check vault session:**
   - Ensure vault is unlocked in main app
   - Documents only appear when vault is open

### Build errors

1. **Missing models:**
   - Ensure all model files are added to ShareExtension target

2. **Missing frameworks:**
   - Check Link Binary With Libraries
   - Add SwiftUI, SwiftData, UniformTypeIdentifiers

3. **Entitlements:**
   - Verify entitlements file is added
   - Check App Group and CloudKit capabilities

## Testing Checklist

- [ ] Extension appears in share sheet
- [ ] Can select photos from Photos app
- [ ] Can select videos from Photos app
- [ ] Can select files from Files app
- [ ] Can share URLs from Safari
- [ ] Vault list loads correctly
- [ ] Can select target vault
- [ ] Upload progress shows correctly
- [ ] Documents appear in main app
- [ ] CloudKit sync works
- [ ] Multiple items can be imported at once

## Security Notes

- All documents are encrypted before saving
- Documents are classified as "sink" (received from external source)
- Vault access rules apply (dual-key vaults require approval)
- CloudKit sync ensures data is backed up securely

## Next Steps

After setup:
1. Test with various file types
2. Test with multiple items
3. Test CloudKit sync
4. Test vault selection
5. Submit to App Store

## References

- [Apple Share Extension Documentation](https://developer.apple.com/documentation/appextensions/sharing_and_actions)
- [App Groups Documentation](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)

---

**Status:** Ready for setup  
**Last Tested:** December 2024


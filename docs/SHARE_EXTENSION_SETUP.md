# Share Extension Setup Guide

> **Last Updated:** December 2024
> 
> Complete guide for setting up the Share Extension to import media from other apps

## Overview

The Share Extension allows users to share photos, videos, files, and URLs from other apps (Photos, Safari, Files, etc.) directly into Khandoba Secure Docs vaults.

## Files Created

1. **ShareExtension/ShareViewController.swift** - Main extension entry point
2. **ShareExtension/ShareExtensionView.swift** - SwiftUI interface for selecting vault
3. **ShareExtension/Info.plist** - Extension configuration
4. **Services/ShareExtensionService.swift** - Service to handle uploads in main app

## Xcode Configuration Steps

### 1. Add Share Extension Target

1. Open your project in Xcode
2. Go to **File → New → Target**
3. Select **Share Extension** under iOS
4. Name it: **"Khandoba Secure Docs Share Extension"**
5. Bundle Identifier: `com.khandoba.securedocs.ShareExtension`
6. Language: **Swift**
7. Click **Finish**

### 2. Configure App Groups

Both the main app and extension need to share data via App Groups:

1. Select the **main app target**
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Create/select group: `group.com.khandoba.securedocs`
6. Repeat for the **Share Extension target**

### 3. Update Share Extension Files

1. Delete the default `ShareViewController.swift` created by Xcode
2. Add the files from `Khandoba Secure Docs/ShareExtension/`:
   - `ShareViewController.swift`
   - `ShareExtensionView.swift`
   - `Info.plist` (replace the default one)

### 4. Configure Info.plist

The `Info.plist` is already configured with:
- Display name: "Save to Khandoba"
- Activation rules for images, videos, files, and URLs
- Maximum counts for each type

### 5. Link Shared Code

The Share Extension needs access to:
- Models (Vault, Document, etc.)
- Services (DocumentService, etc.)
- Theme (UnifiedTheme)

**Option A: Shared Framework (Recommended)**
1. Create a shared framework target
2. Move shared code to the framework
3. Link both targets to the framework

**Option B: Direct File Reference**
1. Add shared files to both targets
2. In File Inspector, check both targets

### 6. Update Build Settings

1. Select the **Share Extension target**
2. Go to **Build Settings**
3. Set **iOS Deployment Target** to match main app (17.0+)
4. Set **Swift Language Version** to Swift 5.9+

### 7. Configure Entitlements

1. Create `ShareExtension.entitlements` file
2. Add App Groups capability:
   ```xml
   <key>com.apple.security.application-groups</key>
   <array>
       <string>group.com.khandoba.securedocs</string>
   </array>
   ```
3. Link it in the Share Extension target's **Signing & Capabilities**

## How It Works

### Flow

1. **User shares from another app** (Photos, Safari, etc.)
2. **Share Extension opens** with list of shared items
3. **User selects vault** from available vaults
4. **Items are saved** to shared UserDefaults (App Group)
5. **Main app processes** uploads when it becomes active
6. **Documents are saved** to selected vault using DocumentService

### Data Sharing

- **Vault List**: Synced from main app to extension via UserDefaults
- **Pending Uploads**: Stored in UserDefaults, processed by main app
- **Notifications**: Extension posts notification when items are saved

## Testing

1. Build and run the main app
2. Create at least one vault
3. Open Photos app
4. Select a photo
5. Tap Share button
6. Look for "Save to Khandoba" in share sheet
7. Select vault and save
8. Return to main app - document should appear in vault

## Troubleshooting

### Extension doesn't appear in share sheet
- Check Info.plist activation rules
- Verify extension target is included in build
- Check bundle identifier matches

### "No vaults available" message
- Ensure main app has synced vaults to UserDefaults
- Check App Group identifier matches in both targets
- Verify ShareExtensionService is configured in main app

### Uploads not processing
- Check notification observer is set up
- Verify App Group UserDefaults are accessible
- Check console logs for errors

### Build errors
- Ensure all shared models/services are accessible
- Check import statements
- Verify deployment targets match

## Security Notes

- All shared items are encrypted before saving
- Vault selection is required (no default vault)
- Items are classified as "sink" (received from external source)
- Full audit trail is maintained via VaultAccessLog

## Future Enhancements

- Direct SwiftData access in extension (iOS 18+)
- Background processing for large files
- Preview thumbnails in share sheet
- Batch operations for multiple items


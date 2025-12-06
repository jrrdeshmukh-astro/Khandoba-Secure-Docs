# Extension Implementation Guide

## ✅ Completed Implementation

### 1. iMessage Extension for Nominee Invitations

**Files Created:**
- `MessageExtension/MessageExtensionViewController.swift` - Main iMessage extension controller
- `MessageExtension/Info.plist` - Extension configuration
- `MessageExtension/MessageExtension.entitlements` - Extension entitlements
- `Khandoba Secure Docs/Services/MessageInvitationService.swift` - Service for sending invitations

**Features:**
- ✅ MSMessageAppViewController implementation
- ✅ Interactive message layout with vault invitation
- ✅ Deep link URL generation (`khandoba://nominee/invite?token=...`)
- ✅ Integration with NomineeService
- ✅ Fallback to SMS if Messages app unavailable

### 2. Share Extension for Media Sharing

**Files Verified:**
- `ShareExtension/ShareExtensionViewController.swift` - Share extension controller
- `ShareExtension/Info.plist` - Extension configuration (✅ CFBundleExecutable added)
- `ShareExtension/ShareExtension.entitlements` - Extension entitlements

**Features:**
- ✅ Supports images, videos, files, URLs
- ✅ SwiftUI-based interface
- ✅ Vault selection for uploads
- ✅ Progress tracking
- ✅ Error handling

## 📋 Next Steps: Add MessageExtension to Xcode

### Step 1: Create MessageExtension Target

1. Open Xcode project
2. File → New → Target
3. Select **iOS** → **iMessage Extension**
4. Click **Next**
5. Configure:
   - **Product Name:** `MessageExtension`
   - **Bundle Identifier:** `com.khandoba.securedocs.MessageExtension`
   - **Language:** Swift
   - **Include UI Extension:** ✅ (checked)
6. Click **Finish**
7. **DO NOT** activate the scheme when prompted

### Step 2: Replace Generated Files

1. Delete the auto-generated `MessageExtensionViewController.swift` in the new target
2. Copy our custom files:
   - Copy `MessageExtension/MessageExtensionViewController.swift` to the target
   - Copy `MessageExtension/Info.plist` to the target (replace the generated one)
   - Copy `MessageExtension/MessageExtension.entitlements` to the target

### Step 3: Configure Build Settings

1. Select **MessageExtension** target
2. **General Tab:**
   - **Display Name:** `Khandoba`
   - **Bundle Identifier:** `com.khandoba.securedocs.MessageExtension`
   - **Version:** Match main app version
   - **Deployment Target:** iOS 17.0+

3. **Signing & Capabilities:**
   - Enable **Automatically manage signing**
   - Add **App Groups:** `group.com.khandoba.securedocs`
   - Add **iCloud:** CloudKit container `iCloud.com.khandoba.securedocs`

4. **Build Settings:**
   - **Swift Language Version:** Swift 5.9
   - **iOS Deployment Target:** 17.0
   - Add to **Other Swift Flags:** `-APP_EXTENSION` (for Debug and Release)

### Step 4: Configure Info.plist

Ensure `MessageExtension/Info.plist` has:
- ✅ `NSExtensionPointIdentifier`: `com.apple.message-ui`
- ✅ `NSExtensionPrincipalClass`: `$(PRODUCT_MODULE_NAME).MessageExtensionViewController`
- ✅ `MSMessageExtensionCategory`: `Interactive`
- ✅ `MSMessageExtensionLaunchPresentationStyle`: `Expanded`

### Step 5: Add File System Sync (for Models Access)

1. Select **MessageExtension** target
2. **Build Phases** → **File System Synchronized Groups**
3. Add:
   - `Khandoba Secure Docs` folder (for Models, Services access)
   - `MessageExtension` folder (its own files)

4. **Exceptions:**
   - Exclude `Info.plist` from `Khandoba Secure Docs` folder sync

### Step 6: Embed Extension

1. Select **Khandoba Secure Docs** target (main app)
2. **General** → **Frameworks, Libraries, and Embedded Content**
3. Add **MessageExtension.appex** (should auto-appear)
4. Ensure it's set to **Embed & Sign**

### Step 7: Update NomineeManagementView

✅ Already updated to use `MessageInvitationService`

## 🔧 ShareExtension Configuration (Verified)

### Current Status:
- ✅ `CFBundleExecutable` added to Info.plist
- ✅ `CFBundleDisplayName` set to "Khandoba"
- ✅ Supports images, videos, files, URLs
- ✅ Properly embedded in main app
- ✅ File system sync configured for Models access
- ✅ `APP_EXTENSION` flag set for conditional compilation

### Activation Rules:
- Images: ✅
- Movies: ✅
- Files: Up to 100
- Web URLs: ✅
- Web Pages: ✅

## 🧪 Testing

### Test iMessage Extension:
1. Build and install app on device
2. Open Messages app
3. Start a conversation
4. Tap the App Store icon (next to text field)
5. Find "Khandoba" in the app drawer
6. Tap to open extension
7. Enter vault name and invite token
8. Send invitation

### Test Share Extension:
1. Open Photos app
2. Select a photo
3. Tap Share button
4. Find "Khandoba" in share sheet
5. Select vault
6. Upload should work

## 📝 Notes

- Both extensions use the same CloudKit container for data sync
- Both extensions have access to Models via file system sync
- Deep link handling: `khandoba://nominee/invite?token=...`
- Messages extension requires iOS 10.0+
- Share extension requires iOS 8.0+

## 🐛 Troubleshooting

### MessageExtension not appearing:
- Check Info.plist configuration
- Verify target is embedded in main app
- Check code signing matches main app
- Ensure deployment target matches

### ShareExtension not appearing:
- Enable in Settings → Khandoba Secure Docs → Share Extension
- Delete and reinstall app
- Check console for errors

### Models not accessible:
- Verify file system sync groups are configured
- Check exceptions exclude Info.plist
- Ensure Models folder is in sync groups


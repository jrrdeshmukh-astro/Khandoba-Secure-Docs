# Unified iMessage App - Apple Cash Style

> **Last Updated:** December 2024
> 
> Complete guide to the unified iMessage app that replaces MessageExtension and ShareExtension.

## Overview

The unified iMessage app provides **Apple Cash-style** interactive messaging for:
- **Vault Invitations** - Send secure vault access invitations
- **File Sharing** - Share files directly to vaults from other apps

All functionality is now in a single, streamlined iMessage app.

## Architecture

### Single iMessage App Target
- **Target Name:** `KhandobaSecureDocsMessageApp`
- **Type:** iMessage App Extension
- **Category:** Interactive (Apple Cash style)
- **Location:** `KhandobaSecureDocsMessageApp/`

### Key Components

#### 1. MessagesViewController.swift
Main controller that handles:
- Extension lifecycle
- Message creation and sending
- Interactive message handling (tap to accept/decline)
- File sharing from Share Sheet

#### 2. Views/
- **MainMenuMessageView.swift** - Main menu (invite or share)
- **NomineeInvitationMessageView.swift** - Invitation creation UI
- **InvitationResponseMessageView.swift** - Accept/decline UI (Apple Cash style)
- **FileSharingMessageView.swift** - File sharing UI

## Features

### ✅ Interactive Messages (Apple Cash Style)
- **Tap to Interact:** Recipients tap message bubbles to accept/decline
- **Visual Status:** Messages show "Pending", "Accepted", or "Declined"
- **In-Message Actions:** Accept/decline buttons appear when message is tapped
- **Status Updates:** Message bubble updates in real-time

### ✅ Unified Functionality
- **Single Entry Point:** One iMessage app for all sharing
- **Main Menu:** Choose between invite nominee or share file
- **Share Sheet Integration:** Automatically handles files shared from other apps
- **Deep Link Integration:** Opens main app when needed

## User Experience

### Sending Vault Invitation

1. **Open Messages app**
2. **Tap Khandoba icon** in app drawer
3. **Select "Invite to Vault"**
4. **Choose vault** and enter recipient details
5. **Tap "Send Invitation"**
6. **Interactive message sent** with tap-to-accept functionality

### Receiving Invitation

1. **Recipient receives message** in Messages
2. **Taps message bubble** (like Apple Cash)
3. **Extension opens** showing invitation details
4. **Recipient sees:**
   - Vault name
   - Sender name
   - Accept/Decline buttons
5. **Recipient taps "Accept"**
6. **Message updates** to show "Accepted" status
7. **Main app opens** to complete acceptance

### Sharing Files

1. **User shares file** from Photos/Files app
2. **Selects Khandoba** from Share Sheet
3. **iMessage app opens** with file preview
4. **User selects vault**
5. **File shared** via iMessage to recipient
6. **Recipient can save** to their vault

## Setup Instructions

### 1. Add iMessage App Target in Xcode

1. **File → New → Target**
2. **Select "iMessage App"**
3. **Product Name:** `KhandobaSecureDocsMessageApp`
4. **Language:** Swift
5. **Click "Finish"**

### 2. Replace Generated Files

Replace the generated files with our implementation:

- **Delete:** Generated `MessagesViewController.swift`
- **Copy:** `KhandobaSecureDocsMessageApp/MessagesViewController.swift`
- **Copy:** All files from `KhandobaSecureDocsMessageApp/Views/`
- **Copy:** `Info.plist` and `.entitlements`

### 3. Configure Target Membership

Add these files to the iMessage app target:

**Required Files:**
- `Theme/UnifiedTheme.swift`
- `Theme/ThemeModifiers.swift`
- `UI/Components/StandardCard.swift`
- `Models/Vault.swift`
- `Models/Nominee.swift`
- `Models/User.swift`
- `Config/AppConfig.swift`

**How to Add:**
1. Select file in Project Navigator
2. File Inspector → Target Membership
3. Check "KhandobaSecureDocsMessageApp"

### 4. Configure Info.plist

Verify `Info.plist` has:
- `MSMessageExtensionCategory` = "Interactive"
- `MSMessageExtensionLaunchPresentationStyle` = "Expanded"
- `CFBundleDisplayName` = "Khandoba"

### 5. Configure Entitlements

Verify entitlements include:
- App Group: `group.com.khandoba.securedocs`
- CloudKit Container: `iCloud.com.khandoba.securedocs`
- CloudKit Services

### 6. Build and Test

1. **Select "KhandobaSecureDocsMessageApp" scheme**
2. **Build** (⌘+B)
3. **Run** (⌘+R) - opens Messages app
4. **Test invitation flow**
5. **Test file sharing**

## Comparison: Old vs New

### Old Approach (Removed)
- ❌ **MessageExtension** - Only invitations
- ❌ **ShareExtension** - Only file sharing
- ❌ Two separate extensions
- ❌ More complex setup
- ❌ Build conflicts

### New Approach (Unified)
- ✅ **Single iMessage App** - Both features
- ✅ **Apple Cash style** - Interactive messages
- ✅ **Simpler setup** - One target
- ✅ **Better UX** - Unified experience
- ✅ **No conflicts** - Clean architecture

## Technical Details

### Message Format

**Invitation URL:**
```
khandoba://nominee/invite?token=<UUID>&vault=<Name>&status=<pending|accepted|declined>&sender=<Name>
```

**Message Layout:**
- **Caption:** "🔐 Vault Invitation"
- **Subcaption:** Vault name
- **Trailing Caption:** Status ("Tap to Accept", "Accepted", "Declined")

### Session Management

Uses `MSSession` for message updates:
- Same session = message updates in place
- Different session = new message

### Deep Link Handling

When invitation accepted:
1. Message URL updated with `status=accepted`
2. Extension opens main app via deep link
3. Main app processes invitation token
4. CloudKit share created automatically

## Troubleshooting

### Extension Not Appearing

1. **Build extension target** (not just main app)
2. **Enable in Settings** → Messages → Message Extensions
3. **Add to Messages** app drawer
4. **Restart Messages** app

### Build Errors

1. **Check target membership** for shared files
2. **Clean build folder** (⇧⌘K)
3. **Verify entitlements** match main app
4. **Check Info.plist** configuration

### Files Not Sharing

1. **Verify Share Sheet** includes Khandoba
2. **Check file types** are supported
3. **Verify vault selection** works
4. **Check console logs** for errors

## Related Files

- `KhandobaSecureDocsMessageApp/MessagesViewController.swift` - Main controller
- `KhandobaSecureDocsMessageApp/Views/` - All UI views
- `docs/IMESSAGE_EXTENSION_APPLE_CASH_STYLE.md` - Feature details (old, for reference)

## Migration Notes

### Removed Extensions
- ✅ `MessageExtension/` - Removed
- ✅ `ShareExtension/` - Removed

### New Structure
- ✅ `KhandobaSecureDocsMessageApp/` - Unified app
- ✅ All functionality in one place
- ✅ Apple Cash-style interactions

## Next Steps

1. **Add target to Xcode project** (if not done automatically)
2. **Configure target membership** for shared files
3. **Build and test** the extension
4. **Enable in Messages** app
5. **Test invitation flow**
6. **Test file sharing**

---

**Status:** ✅ Unified iMessage app ready for setup

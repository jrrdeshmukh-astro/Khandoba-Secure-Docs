# Nominee Invitation Workflow

> **Last Updated:** December 2024
> 
> Complete guide to the nominee invitation workflow using iMessage extension.

## Overview

Nominee invitations are now **exclusively** handled through the iMessage extension. The in-app invitation flow has been removed to provide a unified, streamlined experience.

## Workflow

### Step 1: Access Nominee Management

1. Open main app
2. Navigate to **Vault Detail** → **Sharing** → **Manage Nominees**
3. View current nominees and their status

### Step 2: Invite New Nominee

1. Tap the **"+"** button (top right) or **"Invite via Messages"** button
2. Main app stores vault ID in App Group UserDefaults
3. **Messages app opens automatically**
4. User must be in an active conversation (or start a new one)

### Step 3: Access iMessage Extension

1. In Messages, tap the **App Store icon (📱)** at bottom left of keyboard
2. Or tap **"+"** button → scroll to find **"Khandoba"**
3. Select **"Invite to Vault"**

### Step 4: iMessage Extension Loads

1. Extension reads vault ID from App Group UserDefaults
2. **Vault is automatically pre-selected** (the one you were managing)
3. User enters:
   - Recipient name (required)
   - Phone number (optional)
   - Email (optional)
4. Tap **"Send Invitation"**

### Step 5: Invitation Sent

1. Extension creates `Nominee` record with status `pending`
2. Generates unique `inviteToken`
3. Sends interactive message (Apple Cash style) to recipient
4. Message shows: "🔐 Vault Invitation" with vault name

### Step 6: Recipient Accepts

1. Recipient receives message in Messages
2. Taps message bubble → Extension opens
3. Sees invitation details and **Accept/Decline** buttons
4. Taps **"Accept"**
5. Message updates to "✅ Vault Access Accepted"
6. Main app opens via deep link to complete acceptance
7. Nominee status changes to `accepted`

## Technical Details

### App Group Communication

**Main App → iMessage Extension:**
- Uses App Group: `group.com.khandoba.securedocs`
- Stores vault ID: `pending_nominee_vault_id` (UUID string)
- Stores vault name: `pending_nominee_vault_name` (for reference)
- Extension reads and clears these values on load

**Code Location:**
- Main App: `NomineeManagementView.swift` → `openMessagesForNomineeInvitation()`
- Extension: `NomineeInvitationMessageView.swift` → `loadVaults()`

### Deep Link Format

When invitation is accepted:
```
khandoba://nominee/invite?token=<UUID>&vault=<Name>&status=accepted
```

Main app handles this in `ContentView.swift` → `handleDeepLink()`

## User Experience Benefits

### ✅ Unified Experience
- Single flow for all nominee invitations
- Consistent with Apple Cash-style interactions
- No confusion between different invitation methods

### ✅ Seamless Integration
- Vault automatically pre-selected when coming from main app
- No need to manually find and select vault
- Context preserved between apps

### ✅ Better UX
- Interactive messages (tap to accept/decline)
- Real-time status updates in message bubbles
- Native iOS experience

## Removed Features

### ❌ In-App Invitation Form
- `AddNomineeView` is no longer used for invitations
- Removed from `NomineeManagementView` sheet presentation
- Users are redirected to Messages app instead

### ❌ Manual Link Sharing
- Token-based invitation links still work for acceptance
- But creation is now only via iMessage extension

## Migration Notes

### For Existing Users
- Existing nominees remain unchanged
- All nominee management features still work
- Only the **creation flow** has changed

### For Developers
- `AddNomineeView.swift` still exists but is not used
- Can be removed in future cleanup if desired
- All nominee management logic remains in `NomineeService`

## Troubleshooting

### Messages App Doesn't Open
- Check that Messages app is installed
- Verify iOS version is 17.0+
- Check console for error messages

### Vault Not Pre-Selected
- Verify App Group is configured correctly
- Check that vault ID was stored in UserDefaults
- Extension will fallback to first vault if not found

### Extension Not Appearing
- See `IMESSAGE_QUICK_SETUP.md` for troubleshooting
- Ensure extension is enabled in Settings → Messages → Message Apps
- Main app must be run at least once

## Related Files

- `Views/Sharing/NomineeManagementView.swift` - Main nominee management UI
- `KhandobaSecureDocsMessageApp MessagesExtension/Views/NomineeInvitationMessageView.swift` - iMessage invitation UI
- `Services/NomineeService.swift` - Nominee business logic
- `Models/Nominee.swift` - Nominee data model

---

**Status:** ✅ Nominee invitations now exclusively use iMessage extension

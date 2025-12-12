# iMessage Extension - Apple Cash Style

> **Last Updated:** December 2024
> 
> Guide to the interactive iMessage extension for nominee invitations, similar to Apple Cash.

## Overview

The iMessage extension allows users to send and receive vault invitations directly within the Messages app, with interactive message bubbles that can be tapped to accept or decline invitations - just like Apple Cash.

## Features

### ✅ Interactive Messages (Apple Cash Style)
- **Tap to Interact**: Recipients can tap invitation messages to accept/decline
- **Visual Status**: Messages show "Pending", "Accepted", or "Declined" states
- **In-Message Actions**: Accept/decline buttons appear when message is tapped
- **Status Updates**: Message bubble updates to show acceptance/decline status

### ✅ Seamless Integration
- **Messages App**: Accessible from Messages app drawer
- **Deep Links**: Automatic app opening when invitation is accepted
- **CloudKit Sync**: Works with existing CloudKit sharing infrastructure

## How It Works

### Sending Invitation

1. **User opens Messages app**
2. **Taps Khandoba icon** in Messages app drawer
3. **Selects vault** and enters recipient details
4. **Taps "Send Invitation"**
5. **Interactive message sent** with:
   - Vault name
   - Invitation status (pending)
   - Deep link URL
   - Visual message bubble

### Receiving Invitation

1. **Recipient receives message** in Messages app
2. **Taps message bubble** (like Apple Cash)
3. **Extension opens** showing invitation details
4. **Recipient sees:**
   - Vault name
   - Sender name
   - Accept/Decline buttons
5. **Recipient taps "Accept"**
6. **Message updates** to show "Accepted" status
7. **Main app opens** to complete acceptance

## Architecture

### MessageExtensionViewController
Main controller for the iMessage extension:

- `willBecomeActive()` - Shows invitation creation UI
- `didSelect()` - Handles tapping interactive messages
- `sendNomineeInvitation()` - Creates and sends interactive message
- `handleInvitationAcceptance()` - Updates message to accepted state
- `handleInvitationDecline()` - Updates message to declined state

### Interactive Message Format

**URL Structure:**
```
khandoba://nominee/invite?token=<UUID>&vault=<Name>&status=<pending|accepted|declined>&sender=<Name>
```

**Message Layout:**
- **Caption**: "🔐 Vault Invitation"
- **Subcaption**: Vault name
- **Trailing Caption**: Status ("Tap to Accept", "Accepted", "Declined")

### Views

#### NomineeInvitationMessageView
UI for creating and sending invitations:
- Vault selection
- Recipient details
- Send invitation button

#### InvitationResponseMessageView
UI for responding to invitations (Apple Cash style):
- Vault details display
- Accept/Decline buttons
- Status messages

## Implementation Details

### Message States

1. **Pending** (Initial)
   - Shows "Tap to Accept"
   - Recipient can accept/decline
   - Message bubble is interactive

2. **Accepted**
   - Shows "✅ Accepted"
   - Message updates in conversation
   - Opens main app to complete

3. **Declined**
   - Shows "❌ Declined"
   - Message updates in conversation
   - No further action needed

### Deep Link Handling

When invitation is accepted:
1. Message URL updated with `status=accepted`
2. Extension opens main app via deep link
3. Main app processes invitation token
4. CloudKit share created automatically
5. Nominee gains access

### CloudKit Integration

- Uses same CloudKit sharing as main app
- Shares vault via `CKShare`
- Syncs across all devices
- Works with existing `NomineeService`

## User Experience Flow

### Sender Flow
```
Messages App
  → Tap Khandoba icon
  → Select vault
  → Enter recipient
  → Send
  → Interactive message appears in conversation
```

### Recipient Flow
```
Messages App
  → Receive invitation message
  → Tap message bubble
  → See invitation details
  → Tap "Accept"
  → Message updates to "Accepted"
  → Main app opens
  → Access granted
```

## Comparison with Apple Cash

| Feature | Apple Cash | Khandoba Vaults |
|---------|------------|-----------------|
| **Interactive Messages** | ✅ Yes | ✅ Yes |
| **Tap to Accept** | ✅ Yes | ✅ Yes |
| **Status Updates** | ✅ Yes | ✅ Yes |
| **In-Message Actions** | ✅ Yes | ✅ Yes |
| **Visual Feedback** | ✅ Yes | ✅ Yes |
| **Deep Link Integration** | ✅ Yes | ✅ Yes |

## Technical Requirements

### Info.plist Configuration

```xml
<key>NSExtensionAttributes</key>
<dict>
    <key>MSMessageExtensionCategory</key>
    <string>Interactive</string>
    <key>MSMessageExtensionLaunchPresentationStyle</key>
    <string>Expanded</string>
</dict>
```

### URL Scheme
- **Scheme**: `khandoba`
- **Host**: `nominee/invite` or `invite`
- **Parameters**: `token`, `vault`, `status`, `sender`

### Message Session
- Uses `MSSession` for message updates
- Allows updating message state
- Maintains conversation context

## Best Practices

### 1. **Clear Visual Design**
- Use consistent icons and colors
- Show status clearly
- Make actions obvious

### 2. **Fast Response**
- Load vaults quickly
- Minimize extension launch time
- Cache data when possible

### 3. **Error Handling**
- Handle missing tokens gracefully
- Provide clear error messages
- Allow retry on failure

### 4. **Privacy**
- Don't expose sensitive data in messages
- Use tokens, not vault IDs
- Validate all inputs

## Testing

### Test Scenarios

1. **Send Invitation**
   - Open Messages
   - Tap Khandoba icon
   - Select vault
   - Send invitation
   - Verify message appears

2. **Accept Invitation**
   - Receive message
   - Tap message bubble
   - Tap "Accept"
   - Verify message updates
   - Verify app opens

3. **Decline Invitation**
   - Receive message
   - Tap message bubble
   - Tap "Decline"
   - Verify message updates

4. **Multiple Devices**
   - Send from iPhone
   - Receive on iPad
   - Verify sync works

## Troubleshooting

### Issue: Extension doesn't appear in Messages
**Solution:**
- Check Info.plist configuration
- Verify `MSMessageExtensionCategory` is "Interactive"
- Rebuild and reinstall app

### Issue: Messages don't update status
**Solution:**
- Verify `MSSession` is used
- Check URL parameters are correct
- Ensure message is inserted into conversation

### Issue: Deep link doesn't open app
**Solution:**
- Verify URL scheme in Info.plist
- Check app is installed
- Test deep link manually

## Related Files

- `MessageExtension/MessageExtensionViewController.swift` - Main extension controller
- `MessageExtension/InvitationResponseMessageView.swift` - Interactive response UI
- `Services/MessageInvitationService.swift` - Message creation utilities
- `Services/NomineeService.swift` - Nominee management
- `Services/CloudKitSharingService.swift` - CloudKit sharing

## References

- [Messages Framework](https://developer.apple.com/documentation/messages)
- [MSMessage Documentation](https://developer.apple.com/documentation/messages/msmessage)
- [Interactive Messages Guide](https://developer.apple.com/documentation/messages/creating_interactive_message_apps)

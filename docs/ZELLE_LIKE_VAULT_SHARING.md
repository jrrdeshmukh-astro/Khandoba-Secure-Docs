# Zelle-Like Vault Sharing System

> **Last Updated:** December 2024
> 
> Complete guide to the Zelle-inspired vault sharing system for requesting and sending vault access.

## Overview

This system replicates Zelle's "Request Money" and "Send Money" functionality for vaults. Just like Zelle:
- **Vault stays with owner** (like a bank account)
- **Access is shared** (like sending/receiving money)
- **Simple, intuitive interface** (like Zelle's UI)
- **Automatic processing** (send requests are auto-accepted)

## Key Concepts

### Request Access (Like "Request Money")
- User requests access to someone else's vault
- Vault owner receives the request
- Owner can accept or decline
- If accepted, CloudKit share is created automatically

### Send Access (Like "Send Money")
- Vault owner sends access to someone
- Automatically creates CloudKit share and nominee
- Recipient gets immediate access
- No approval needed (like sending money)

## Architecture

### Models

#### `VaultAccessRequest`
Tracks all vault access requests and sends:

```swift
@Model
final class VaultAccessRequest {
    var requestType: String // "request" or "send"
    var status: String // "pending", "accepted", "declined", "expired"
    var requesterUserID: UUID?
    var recipientUserID: UUID?
    var vault: Vault?
    var message: String?
    // ... more fields
}
```

### Services

#### `VaultRequestService`
Main service for handling requests:

- `requestVaultAccess()` - Request access to a vault
- `sendVaultAccess()` - Send access to a vault (auto-accepts)
- `acceptRequest()` - Accept a pending request
- `declineRequest()` - Decline a pending request
- `loadRequests()` - Load all requests

### Views

#### `VaultRequestView`
Main interface with two tabs:
- **Request Access** - Request access to someone's vault
- **Send Access** - Send access to your vault

#### `VaultRequestsListView`
Shows pending requests:
- **Received** - Requests you've received
- **Sent** - Requests you've sent

## Usage

### Requesting Vault Access

1. Open `VaultRequestView`
2. Select "Request Access" tab
3. Choose the vault you want access to
4. Enter vault owner's email or phone
5. Add optional message
6. Tap "Request Access"

The vault owner will receive the request and can accept/decline.

### Sending Vault Access

1. Open `VaultRequestView`
2. Select "Send Access" tab
3. Choose your vault
4. Enter recipient's name and email/phone
5. Add optional message
6. Tap "Send Access"

Access is granted immediately (like sending money in Zelle).

### Viewing Requests

1. Open `VaultRequestsListView`
2. View "Received" or "Sent" requests
3. Accept/decline received requests
4. View status of sent requests

## Integration with CloudKit

### Request Flow
1. User creates `VaultAccessRequest` with type "request"
2. Request saved to SwiftData/CloudKit
3. Vault owner sees request in `VaultRequestsListView`
4. Owner accepts → `NomineeService.inviteNominee()` creates CloudKit share
5. Requester gets access via CloudKit share

### Send Flow
1. User creates `VaultAccessRequest` with type "send"
2. `processSendRequest()` automatically:
   - Creates nominee via `NomineeService`
   - Creates CloudKit share
   - Grants immediate access
3. Request marked as "accepted"

## Key Differences from Zelle

| Zelle | Vault Sharing |
|-------|---------------|
| Money transfer | Vault access sharing |
| Bank account stays | Vault stays with owner |
| Instant transfer | CloudKit share creation |
| Email/phone recipient | Email/phone recipient |
| Request/Send money | Request/Send access |

## Benefits

1. **Familiar UX**: Users understand the pattern from Zelle
2. **Vault Ownership Preserved**: Vault stays with owner (like bank account)
3. **Automatic Processing**: Send requests auto-accept (like Zelle)
4. **CloudKit Integration**: Uses existing CloudKit sharing infrastructure
5. **Simple Interface**: Clean, intuitive UI similar to Zelle

## Technical Details

### Request Expiration
- Requests expire after 7 days (configurable)
- Expired requests can't be accepted
- Status automatically updates to "expired"

### CloudKit Sync
- All requests sync via SwiftData → CloudKit
- Cross-device access to requests
- Automatic nominee creation on acceptance

### Error Handling
- Validates vault ownership
- Checks for existing access
- Handles CloudKit sync delays gracefully

## Future Enhancements

1. **Push Notifications**: Notify users of new requests
2. **Deep Links**: Open requests from notifications/links
3. **Bulk Operations**: Request/send multiple vaults
4. **Request History**: Full audit trail
5. **Custom Expiration**: User-configurable expiration times

## Related Files

- `VaultAccessRequest` model: `Models/Nominee.swift`
- `VaultRequestService`: `Services/VaultRequestService.swift`
- `VaultRequestView`: `Views/Sharing/VaultRequestView.swift`
- `VaultRequestsListView`: `Views/Sharing/VaultRequestsListView.swift`
- `CloudKitSharingService`: `Services/CloudKitSharingService.swift`
- `NomineeService`: `Services/NomineeService.swift`

## References

- [Zelle Wikipedia](https://en.wikipedia.org/wiki/Zelle)
- [CloudKit Sharing Documentation](https://developer.apple.com/documentation/cloudkit)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)

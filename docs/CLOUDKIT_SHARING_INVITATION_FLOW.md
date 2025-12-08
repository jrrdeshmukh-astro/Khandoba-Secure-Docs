# CloudKit Sharing Invitation Flow

## Current Limitation

**Problem:** When creating a nominee with only a name (no email or phone), the system cannot automatically send the invitation because there's no contact method.

## Current Flow

1. User creates nominee with just name (e.g., "Bhakti Joshi")
2. System generates:
   - CloudKit share URL (if CloudKit share exists)
   - Deep link: `khandoba://invite?token=...`
   - Invitation token
3. **User must manually:**
   - Copy the link
   - Open Messages/Email
   - Paste and send to the person

## Why This Happens

- **Name only:** No way to programmatically send (no email/phone)
- **Email/Phone provided:** Could use `MFMessageComposeViewController` or `MFMailComposeViewController`, but still requires user interaction
- **CloudKit Share:** The share URL exists, but needs to be shared manually

## Better Solution: UICloudSharingController

Apple's `UICloudSharingController` provides a native UI for sharing CloudKit records:

### Benefits:
1. **Native iOS sharing UI** - Users are familiar with it
2. **Multiple sharing options** - iMessage, Mail, Copy Link, etc.
3. **Automatic participant management** - CloudKit handles the rest
4. **Works with just a name** - User can choose how to share

### Implementation:

```swift
import UIKit
import CloudKit

func presentCloudKitSharing(for vault: Vault) {
    guard let share = try await getExistingShare(for: vault) else {
        // Create share first
        let share = try await createShare(for: vault)
    }
    
    let sharingController = UICloudSharingController { controller, completionHandler in
        // Prepare share metadata
        completionHandler(share, CKContainer.default(), nil)
    }
    
    sharingController.delegate = self
    sharingController.availablePermissions = [.allowReadWrite, .allowPrivate]
    
    // Present the sharing controller
    // User can then choose how to share (Messages, Mail, Copy Link, etc.)
}
```

## Recommended Flow

### Option 1: Require Contact Info (Current)
- **Name:** Required
- **Email OR Phone:** Required for automatic sending
- **If only name:** Show manual sharing options

### Option 2: Use UICloudSharingController (Recommended)
- **Name:** Required
- **Email/Phone:** Optional
- **Always use UICloudSharingController** for CloudKit shares
- User chooses sharing method (Messages, Mail, Copy Link, etc.)

### Option 3: Hybrid Approach
- **If email/phone provided:** Use `MFMessageComposeViewController` or `MFMailComposeViewController`
- **If only name:** Use `UICloudSharingController` or manual sharing
- **CloudKit share:** Always use `UICloudSharingController` for best UX

## For CloudKit Share Participants

When syncing CloudKit share participants to Nominees:
- **We get email from CloudKit** (`identity.lookupInfo?.emailAddress`)
- **This works because** CloudKit requires email/phone for sharing
- **So synced nominees** will have contact info

## Recommendation

**Use `UICloudSharingController`** for all CloudKit share invitations:
1. Better UX - native iOS sharing
2. Works with just a name
3. User chooses how to share
4. Automatic participant management
5. No need to manually copy/paste links

This solves the "name only" problem by letting the user choose the sharing method.


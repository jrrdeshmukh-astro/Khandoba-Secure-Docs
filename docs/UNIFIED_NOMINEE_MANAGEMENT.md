# Unified Nominee Management System

## Overview

This document describes the unified nominee management system that consolidates the previously separate "Access Control" and "Manage Nominees" flows into a single, consistent experience.

## Problem Statement

Previously, there were two separate forms for adding nominees:
1. **Access Control View** - Used `UnifiedShareView` which opened Messages app
2. **Manage Nominees View** - Used `AddNomineeView` which created nominee and showed link

This duplication caused user confusion and inconsistent experiences. Additionally, CloudKit sharing wasn't working properly because the app couldn't reliably get CloudKit record IDs from SwiftData models.

## Solution

### 1. Unified Nominee Management View

**File:** `Views/Sharing/UnifiedNomineeManagementView.swift`

A single view that combines:
- Owner information display
- Nominee list with status badges
- Add nominee functionality
- Remove nominee functionality
- Chat with active nominees
- Resend invitations for pending nominees
- Access history (for owners)

**Key Features:**
- Single source of truth for nominee management
- Consistent UI/UX across the app
- Real-time status updates
- CloudKit sharing integration

### 2. Unified Add Nominee View

**File:** `Views/Sharing/UnifiedAddNomineeView.swift`

A unified form for adding nominees that:
- Supports contact picker integration
- Creates nominee records
- Uses CloudKit sharing for invitations
- Falls back to token-based invitations if CloudKit fails
- Shows access level selection

**Key Features:**
- Contact picker for easy selection
- CloudKit sharing as primary method
- Token-based fallback for reliability
- Access level configuration

### 3. Fixed CloudKit Sharing

**Files:**
- `Views/Sharing/CloudKitSharingController.swift`
- `Services/CloudKitSharingService.swift`

**Improvements:**
- Updated `UICloudSharingController` to accept pre-created shares
- Improved `getVaultRecordID` to use SwiftData's UUID for record naming
- Better error handling and fallback mechanisms
- Support for both share creation and existing share reuse

**How It Works:**
1. When user wants to share, we try to get or create a `CKShare` for the vault
2. If successful, we present `UICloudSharingController` with the share
3. User can choose how to share (Messages, Mail, etc.) from native iOS share sheet
4. CloudKit handles the actual invitation delivery
5. If CloudKit fails, we fall back to token-based invitations

### 4. Unified Transfer Ownership

**File:** `Views/Sharing/TransferOwnershipView.swift`

Updated to use CloudKit sharing:
- Primary method: CloudKit sharing via `UICloudSharingController`
- Fallback: Token-based transfer links
- Consistent with nominee invitation flow

## Architecture

### Flow Diagram

```
User wants to add nominee
    ↓
UnifiedAddNomineeView
    ↓
User enters name/phone/email
    ↓
Create Nominee record
    ↓
Try CloudKit sharing
    ├─ Success → Present UICloudSharingController
    │              ↓
    │         User chooses sharing method
    │              ↓
    │         CloudKit sends invitation
    │
    └─ Failure → Show token-based link
                  ↓
             User copies/shares link manually
```

### Key Components

1. **UnifiedNomineeManagementView**
   - Main entry point for nominee management
   - Replaces both `VaultAccessControlView` (nominee section) and `NomineeManagementView`
   - Shows owner, nominees, and access history

2. **UnifiedAddNomineeView**
   - Single form for adding nominees
   - Replaces both `UnifiedShareView` (nominee mode) and `AddNomineeView`
   - Integrates CloudKit sharing

3. **CloudKitSharingView**
   - SwiftUI wrapper for `UICloudSharingController`
   - Handles share presentation
   - Supports both pre-created shares and automatic creation

4. **CloudKitSharingService**
   - Service for CloudKit share management
   - Handles share creation, lookup, and participant management
   - Uses SwiftData UUIDs to construct CloudKit record IDs

## Migration Guide

### For Views

**Before:**
```swift
NavigationLink {
    NomineeManagementView(vault: vault)
} label: { ... }

.sheet(isPresented: $showAddNominee) {
    UnifiedShareView(vault: vault, mode: .nominee)
}
```

**After:**
```swift
NavigationLink {
    UnifiedNomineeManagementView(vault: vault)
} label: { ... }

.sheet(isPresented: $showAddNominee) {
    UnifiedAddNomineeView(vault: vault)
}
```

### For Access Control

**Before:**
- `VaultAccessControlView` had its own nominee list and add button

**After:**
- `VaultAccessControlView` redirects to `UnifiedNomineeManagementView` for nominee management
- Access control view focuses on owner info and emergency access

## Benefits

1. **Consistency**: Single flow for adding/managing nominees
2. **Reliability**: CloudKit sharing with token-based fallback
3. **User Experience**: Native iOS share sheet integration
4. **Maintainability**: Single source of truth for nominee management
5. **Flexibility**: Works with just a name (user chooses sharing method)

## CloudKit Sharing Details

### How Notifications Work

CloudKit sharing requires email or phone number to look up users in iCloud. However, with just a name:

1. User creates nominee with name only
2. System creates CloudKit share
3. User opens native iOS share sheet (`UICloudSharingController`)
4. User chooses sharing method (Messages, Mail, etc.)
5. User manually selects recipient from their contacts
6. CloudKit sends invitation to recipient's iCloud account

This approach:
- ✅ Works with just a name (user handles contact selection)
- ✅ Uses native iOS sharing (familiar UX)
- ✅ Supports all sharing methods (Messages, Mail, AirDrop, etc.)
- ✅ Leverages CloudKit for secure sharing

### Record ID Resolution

SwiftData with CloudKit uses a naming convention for records:
- Format: `CD_<EntityName>_<UUID>`
- Example: `CD_Vault_<vault.id.uuidString>`

The `getVaultRecordID` method constructs the record ID using this convention and verifies it exists before using it.

## Testing

### Test Scenarios

1. **Add Nominee with CloudKit Sharing**
   - Create nominee with name only
   - Verify CloudKit share is created
   - Verify share sheet appears
   - Test sharing via Messages
   - Test sharing via Mail

2. **Add Nominee with Token Fallback**
   - Disable CloudKit (or simulate failure)
   - Create nominee
   - Verify token-based link is shown
   - Test copying link

3. **Manage Nominees**
   - View nominee list
   - Remove nominee
   - Resend invitation for pending nominee
   - Chat with active nominee

4. **Transfer Ownership**
   - Create transfer request
   - Verify CloudKit sharing works
   - Test fallback to token-based link

## Future Improvements

1. **Better Record ID Resolution**
   - Use SwiftData's `PersistentIdentifier` more directly
   - Explore CloudKit query improvements

2. **Share Management**
   - View all active shares
   - Revoke shares
   - Update share permissions

3. **Analytics**
   - Track sharing method usage
   - Monitor CloudKit success/failure rates
   - User feedback on sharing experience

## Related Documentation

- `docs/CLOUDKIT_SHARING_INVITATION_FLOW.md` - CloudKit sharing flow details
- `docs/UICLOUD_SHARING_CONTROLLER_IMPLEMENTATION.md` - UICloudSharingController details
- `docs/CLOUDKIT_SHARING_LIMITATIONS.md` - Known limitations


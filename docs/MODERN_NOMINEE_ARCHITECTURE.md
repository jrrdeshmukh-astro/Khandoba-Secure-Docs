# Modern Nominee Management Architecture

> **Last Updated:** December 2024  
> **Status:** Implemented in Build 22

## Overview

This document describes the modernized nominee management system that removes legacy technical debt and implements a clean, CloudKit-first architecture for concurrent vault access.

## Key Improvements

### 1. Type-Safe Status Management

**Before:**
```swift
var status: String = "pending" // Error-prone string comparisons
```

**After:**
```swift
enum NomineeStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case active = "active"
    case inactive = "inactive"
    case revoked = "revoked"
}

var statusRaw: String = NomineeStatus.pending.rawValue
var status: NomineeStatus {
    get { NomineeStatus(rawValue: statusRaw) ?? .pending }
    set { statusRaw = newValue.rawValue }
}
```

**Benefits:**
- Compile-time safety
- No typos in status strings
- Better IDE autocomplete
- Clear status transitions

### 2. CloudKit-First Sharing

**Before:**
- Token-based fallback system
- CloudKit participant sync disabled (`if false`)
- Complex dual-path invitation flow

**After:**
- CloudKit sharing is primary mechanism
- Participant sync enabled and working
- Simplified invitation flow using `UICloudSharingController`
- No token fallback (removed technical debt)

### 3. Concurrent Access Tracking (Bank Vault Model)

**New Fields:**
```swift
var isCurrentlyActive: Bool = false
var currentSessionID: UUID?
var lastActiveAt: Date?
```

**How It Works:**
- When vault owner opens a vault, all accepted nominees get concurrent access
- `isCurrentlyActive` tracks real-time access status
- `updateActiveStatus()` automatically syncs based on vault sessions
- Nominees see "Active" status when vault is unlocked

### 4. Enhanced CloudKit Integration

**New Fields:**
```swift
var cloudKitShareRecordID: String? // CKShare record ID
var cloudKitParticipantID: String? // CKShare.Participant ID
```

**Benefits:**
- Direct mapping to CloudKit share participants
- Automatic sync between CloudKit and SwiftData
- Reliable cross-device synchronization

## Architecture

### Nominee Model

```swift
@Model
final class Nominee {
    // Identity
    var id: UUID
    var name: String
    var phoneNumber: String?
    var email: String?
    
    // Type-safe status
    var statusRaw: String
    var status: NomineeStatus // Computed property
    
    // CloudKit integration
    var cloudKitShareRecordID: String?
    var cloudKitParticipantID: String?
    
    // Concurrent access tracking
    var isCurrentlyActive: Bool
    var currentSessionID: UUID?
    var lastActiveAt: Date?
    
    // Relationships
    var vault: Vault?
    var invitedByUserID: UUID?
}
```

### NomineeService Flow

1. **Load Nominees:**
   - Fetch from SwiftData (local + CloudKit synced)
   - Sync with CloudKit share participants (ENABLED)
   - Update active status based on vault sessions
   - Return nominees with real-time status

2. **Invite Nominee:**
   - Create nominee record
   - Create/get CloudKit share
   - Present `UICloudSharingController` for native sharing
   - No token fallback

3. **Remove Nominee:**
   - Remove from CloudKit share
   - Mark as revoked (soft delete)
   - Update nominee list

### CloudKit Participant Sync

**Enabled Flow:**
```swift
// Sync CloudKit share participants to Nominee records
let participants = try await sharingService.getShareParticipants(for: vault)
fetchedNominees = try await syncCloudKitParticipants(
    participants: participants,
    existingNominees: fetchedNominees,
    vault: vault,
    modelContext: modelContext
)
```

**What It Does:**
- Fetches all CloudKit share participants
- Creates Nominee records for new participants
- Updates existing nominees with CloudKit data
- Syncs acceptance status from CloudKit

## Status Transitions

```
pending → accepted → active → accepted → revoked
   ↓         ↓         ↓
(invited) (accepted) (vault open)
```

- **pending:** Invitation sent, not yet accepted
- **accepted:** Invitation accepted, waiting for vault to open
- **active:** Vault is open, nominee has concurrent access
- **inactive:** Temporarily disabled (not used for revocation)
- **revoked:** Access permanently revoked

## Usage Examples

### Checking Status

```swift
// Type-safe comparison
if nominee.status == .accepted || nominee.status == .active {
    // Show chat button
}

// Display name
Text(nominee.status.displayName) // "Pending", "Accepted", etc.

// Status color
let color = nominee.status.color // "warning", "success", etc.
```

### SwiftData Predicates

```swift
// Use statusRaw for predicates (SwiftData limitation)
let descriptor = FetchDescriptor<Nominee>(
    predicate: #Predicate { nominee in
        nominee.statusRaw == NomineeStatus.accepted.rawValue
    }
)
```

### Setting Status

```swift
// Use enum (recommended)
nominee.status = .accepted

// Automatically updates statusRaw
// nominee.statusRaw == "accepted"
```

## Migration Notes

### From String Status

**Old Code:**
```swift
if nominee.status == "accepted" {
    // ...
}
nominee.status = "inactive"
```

**New Code:**
```swift
if nominee.status == .accepted {
    // ...
}
nominee.status = .revoked // Use .revoked instead of "inactive"
```

### Predicates

**Old Code:**
```swift
predicate: #Predicate { nominee in
    nominee.status == "pending"
}
```

**New Code:**
```swift
predicate: #Predicate { nominee in
    nominee.statusRaw == NomineeStatus.pending.rawValue
}
```

## Benefits Summary

1. **Type Safety:** Compile-time checks prevent status typos
2. **CloudKit Sync:** Automatic participant synchronization
3. **Real-time Tracking:** Concurrent access status updates
4. **Cleaner Code:** Removed token fallback complexity
5. **Better UX:** Clear status indicators and transitions
6. **Maintainability:** Easier to understand and modify

## Related Documentation

- `CLOUDKIT_SHARING_INVITATION_FLOW.md` - CloudKit sharing details
- `UNIFIED_NOMINEE_MANAGEMENT.md` - UI implementation
- `SHAREEXTENSION_VAULT_LOADING_TROUBLESHOOTING.md` - Share Extension setup


# Account Deletion - Access Logs and Triage Logs Policy

## Overview

This document outlines how access logs and triage logs are handled when a user deletes their account.

## Current Data Structure

### Access Logs (VaultAccessLog)
- **Relationship**: Belongs to `Vault` (cascade delete)
- **Contains**: Timestamps, access types, userID, userName, location data, device info, document access records
- **Storage**: SwiftData (persisted, synced via CloudKit)

### Triage Logs (TriageResult)
- **Type**: Struct (not a SwiftData model)
- **Storage**: Ephemeral (in-memory only, not persisted)
- **Generated**: On-demand from vault analysis
- **Lifecycle**: Created when triage analysis runs, discarded when app closes

## Current Behavior

### When User Deletes Account:

1. **User's Own Vaults**:
   - Vaults are deleted (cascade)
   - Access logs are deleted with vaults (cascade delete rule)
   - All historical access data is permanently removed

2. **Shared Vaults (As Nominee)**:
   - Access logs are preserved with vault owner
   - Logs are marked with "(Account Deleted)" suffix
   - All historical data remains for audit trail

3. **Triage Results**:
   - Not applicable (ephemeral, not stored)
   - No action needed

## Recommended Policy Options

### Option 1: Complete Deletion (Current - Privacy-Focused) ✅ RECOMMENDED

**Approach**: Delete all access logs when user deletes account.

**Pros**:
- ✅ Maximum privacy - no data retention
- ✅ GDPR/CCPA compliant (right to be forgotten)
- ✅ Simple implementation (already working via cascade delete)
- ✅ User expectations met (complete deletion)

**Cons**:
- ❌ No audit trail for user's own vaults
- ❌ Cannot investigate security incidents after deletion
- ❌ No historical analysis possible

**Implementation**: Current behavior (no changes needed)

---

### Option 2: Anonymized Retention (Compliance-Focused)

**Approach**: Anonymize access logs before deletion, retain for security/compliance.

**Pros**:
- ✅ Maintains audit trail for security investigations
- ✅ Compliance with security regulations
- ✅ Can detect patterns after account deletion
- ✅ Privacy preserved (anonymized)

**Cons**:
- ❌ More complex implementation
- ❌ Storage overhead
- ❌ May conflict with "right to be forgotten"
- ❌ User may not expect data retention

**Implementation**:
```swift
// Before deleting vaults, anonymize access logs
for vault in user.ownedVaults {
    for log in vault.accessLogs {
        log.userID = nil
        log.userName = "Deleted User"
        log.deviceInfo = nil
        log.ipAddress = nil
        // Keep: timestamp, accessType, location (generalized), documentID
    }
}
// Then delete vaults (logs remain but anonymized)
```

---

### Option 3: Export Before Deletion (User Control)

**Approach**: Offer user to export their access logs before deletion.

**Pros**:
- ✅ User gets copy of their data
- ✅ Complete deletion after export
- ✅ User control and transparency
- ✅ GDPR compliant (data portability)

**Cons**:
- ❌ Additional UI/UX complexity
- ❌ Export format decisions needed
- ❌ User may not want to export
- ❌ Delays deletion process

**Implementation**:
```swift
// Add export option in AccountDeletionView
func exportAccessLogs(for user: User) async throws -> Data {
    // Collect all access logs from user's vaults
    // Format as JSON/CSV
    // Return exportable data
}
```

---

### Option 4: Time-Based Retention (Hybrid)

**Approach**: Delete immediately, but retain anonymized logs for X days (e.g., 30 days) for security.

**Pros**:
- ✅ Balance privacy and security
- ✅ Short retention period
- ✅ Can investigate recent incidents
- ✅ Automatic cleanup after period

**Cons**:
- ❌ Complex implementation (background cleanup)
- ❌ Storage management needed
- ❌ May still conflict with user expectations

**Implementation**:
```swift
// Mark logs for delayed deletion
log.markedForDeletion = true
log.deletionDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
// Background job deletes after 30 days
```

---

## Recommendation: Option 1 (Complete Deletion)

**Rationale**:
1. **Privacy First**: Users expect complete deletion when they delete their account
2. **GDPR Compliance**: "Right to be forgotten" requires complete data removal
3. **User Expectations**: Account deletion should mean complete removal
4. **Simplicity**: Current implementation already works correctly
5. **Shared Vaults**: Access logs in shared vaults are already preserved (handled separately)

**For Shared Vaults**: 
- Access logs remain with vault owner (already implemented)
- This satisfies audit/compliance needs for vault owners
- User's privacy is maintained (they can't access shared vaults anymore)

**For Triage Logs**:
- No action needed (ephemeral, not stored)
- If triage results were stored, they would be deleted with vaults

---

## Implementation Details

### Current Code (Already Correct)

```swift
// AccountDeletionService.swift
// 1. Delete all user-owned vaults and their contents
if let vaults = user.ownedVaults {
    for vault in vaults {
        // Access logs are automatically deleted via cascade delete
        modelContext.delete(vault)
    }
}
```

**This is correct** - SwiftData's cascade delete rule ensures:
- Vault deleted → Access logs deleted automatically
- No orphaned records
- Complete cleanup

### No Changes Needed

The current implementation is correct for Option 1 (Complete Deletion).

---

## Documentation Updates

### Terms of Service
Already updated to clarify:
- User's own vaults: All data deleted including access logs
- Shared vaults: Access logs remain with vault owner

### Privacy Policy
Already updated to clarify:
- Complete deletion of user's own data
- Retention of access logs in shared vaults

### Account Deletion UI
Already updated to show:
- What will be deleted (including access logs)
- Exception for shared vault logs

---

## Summary

**Recommended Policy**: **Option 1 - Complete Deletion**

- ✅ Delete all access logs from user's own vaults (current behavior)
- ✅ Preserve access logs in shared vaults (already implemented)
- ✅ No changes needed to triage logs (ephemeral)
- ✅ Current implementation is correct and compliant

**Rationale**: Privacy-first approach aligns with user expectations and GDPR requirements. Shared vault owners retain audit trails for their security needs.

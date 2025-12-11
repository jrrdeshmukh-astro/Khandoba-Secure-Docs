# Comprehensive System Fixes

## Overview

This document outlines comprehensive fixes for three critical systems:
1. Triage Facility Constraints
2. Share Extension Workflow
3. Nominee Management & Transfer Ownership

---

## 1. Triage Facility Constraints

### Current Issues

The triage facility can suggest/execute actions that may not be possible in the app workflow:

1. **Document Operations** (redact, restrict, delete):
   - Can be suggested even when vault is locked
   - No validation that vault has active session
   - No check if user has permission

2. **Nominee Operations** (revoke, remove):
   - Can be executed by non-owners
   - No validation of user permissions
   - Doesn't check if nominee exists

3. **Vault Operations** (lock, close):
   - Can be executed without checking ownership
   - No validation of current vault state

### Required Constraints

**Document Operations:**
- ✅ Vault must be unlocked (status != "locked")
- ✅ Vault must have active session (session.isActive && session.expiresAt > now)
- ✅ User must be owner or have document access
- ✅ Documents must exist and be accessible

**Nominee Operations:**
- ✅ User must be vault owner
- ✅ Nominee must exist
- ✅ Nominee must be in pending/accepted/active status (can't revoke already revoked)

**Vault Operations:**
- ✅ User must be vault owner (for lock/close)
- ✅ Vault must exist
- ✅ Check vault state before operation

### Implementation Plan

1. Add validation methods to `AutomaticTriageService`
2. Filter recommended actions based on constraints
3. Add validation before executing actions
4. Provide user feedback when actions can't be executed

---

## 2. Share Extension Workflow

### Current Issues

1. **Vault Selection:**
   - Only shows unlocked vaults (good)
   - But doesn't handle case where user needs to unlock vault first
   - No feedback if no vaults available

2. **Session Validation:**
   - Doesn't check if vault session is still active before upload
   - No validation that vault is accessible
   - Upload can fail silently if vault locks during upload

3. **Error Handling:**
   - Limited error messages
   - No retry mechanism
   - Doesn't handle CloudKit sync failures gracefully

4. **User Experience:**
   - No indication of upload progress per item
   - No way to cancel upload
   - Doesn't show which vault was selected clearly

### Required Fixes

**Vault Selection:**
- ✅ Show only unlocked vaults with active sessions
- ✅ Provide clear message if no vaults available
- ✅ Show vault status (locked/unlocked) clearly
- ✅ Auto-select first available vault

**Session Validation:**
- ✅ Check vault session before upload starts
- ✅ Validate session is still active during upload
- ✅ Handle session expiration during upload
- ✅ Re-check vault accessibility before each document upload

**Error Handling:**
- ✅ Clear error messages for each failure type
- ✅ Retry mechanism for transient failures
- ✅ Handle CloudKit sync delays
- ✅ Show partial success (X of Y uploaded)

**User Experience:**
- ✅ Show upload progress per item
- ✅ Allow cancel during upload
- ✅ Show selected vault clearly
- ✅ Provide feedback on completion

### Implementation Plan

1. Add session validation before upload
2. Add per-item progress tracking
3. Improve error handling and messages
4. Add cancel functionality
5. Better vault selection UI

---

## 3. Nominee Management & Transfer Ownership

### Current Issues

**Nominee Management:**
1. **CloudKit Sync:**
   - CloudKit participants may not sync properly with Nominee records
   - Status updates may not propagate correctly
   - Participant removal may not clean up Nominee records

2. **Status Management:**
   - Status transitions may not be validated
   - Active status may not update correctly
   - Concurrent access tracking may be inconsistent

3. **Removal:**
   - CloudKit participant removal may fail silently
   - Nominee records may not be properly cleaned up
   - Vault nomineeList may not be updated

**Transfer Ownership:**
1. **CloudKit Share Ownership:**
   - Transfer doesn't update CloudKit share ownership
   - New owner may not get proper CloudKit permissions
   - Previous owner may retain CloudKit access

2. **Validation:**
   - No check if user can accept transfer (e.g., already owner)
   - No validation of transfer request status
   - No check if vault exists and is accessible

3. **Cleanup:**
   - Previous owner's access may not be properly revoked
   - Nominees may not be updated with new owner
   - CloudKit share participants may not be updated

### Required Fixes

**Nominee Management:**
- ✅ Ensure CloudKit participants sync with Nominee records
- ✅ Validate status transitions
- ✅ Properly remove CloudKit participants when revoking nominees
- ✅ Update vault nomineeList correctly
- ✅ Handle concurrent access status updates

**Transfer Ownership:**
- ✅ Transfer CloudKit share ownership to new owner
- ✅ Update CloudKit share permissions
- ✅ Remove previous owner from CloudKit share
- ✅ Validate transfer request before acceptance
- ✅ Update all nominee records with new owner
- ✅ Clean up previous owner's access properly

### Implementation Plan

1. Fix CloudKit participant sync in NomineeService
2. Add proper CloudKit share ownership transfer
3. Add validation for all operations
4. Improve cleanup on removal/transfer
5. Add error handling and logging

---

## Implementation Priority

1. **High Priority:**
   - Triage constraints (security critical)
   - Share extension session validation (data integrity)
   - Transfer ownership CloudKit fix (data loss risk)

2. **Medium Priority:**
   - Nominee CloudKit sync improvements
   - Share extension UX improvements
   - Error handling enhancements

3. **Low Priority:**
   - UI polish
   - Additional logging
   - Performance optimizations

---

## Testing Checklist

### Triage Constraints
- [ ] Document operations only suggested when vault unlocked
- [ ] Nominee operations only for owners
- [ ] Vault operations validate ownership
- [ ] Actions fail gracefully with clear messages

### Share Extension
- [ ] Only unlocked vaults shown
- [ ] Session validated before upload
- [ ] Upload handles session expiration
- [ ] Clear error messages
- [ ] Progress tracking works

### Nominee & Transfer
- [ ] CloudKit participants sync correctly
- [ ] Nominee removal cleans up CloudKit
- [ ] Transfer updates CloudKit ownership
- [ ] Previous owner access revoked
- [ ] Validation prevents invalid operations

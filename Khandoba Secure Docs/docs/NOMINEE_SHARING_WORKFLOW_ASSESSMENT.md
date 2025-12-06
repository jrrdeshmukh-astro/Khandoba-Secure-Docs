# Nominee Sharing Workflow Assessment

**Date:** December 2024  
**Status:** ⚠️ **PARTIALLY WORKING** - Some gaps identified

---

## Executive Summary

The nominee sharing workflow is **mostly implemented** but has some **missing connections** that prevent it from working end-to-end.

**Overall Status:** ⚠️ **70% Complete**

**What Works:**
- ✅ Nominee invitation UI
- ✅ Nominee model and data structure
- ✅ Shared vault session service
- ✅ Message composer integration

**What's Missing:**
- ⚠️ NomineeService doesn't actually send messages (only clipboard)
- ⚠️ SharedVaultSessionService not integrated with vault opening
- ⚠️ Nominee access check missing when vault opens
- ⚠️ Deep linking for invitation acceptance

---

## Workflow Components

### 1. ✅ Nominee Invitation UI

**Files:**
- `Views/Sharing/UnifiedShareView.swift` - Main invitation interface
- `Views/Sharing/NomineeManagementView.swift` - Manage nominees
- `Views/Vaults/VaultDetailView.swift` - Entry point

**Status:** ✅ **WORKING**

**Features:**
- Contact picker integration
- Access level selection (View/Edit/Full)
- Message composer for sending invitations
- Nominee list display
- Status indicators (pending/accepted/active)

---

### 2. ✅ Nominee Data Model

**File:** `Models/Nominee.swift`

**Status:** ✅ **WORKING**

**Fields:**
- `id: UUID`
- `name: String`
- `phoneNumber: String?`
- `email: String?`
- `status: String` (pending/accepted/active/inactive)
- `invitedAt: Date`
- `acceptedAt: Date?`
- `inviteToken: String`
- `vault: Vault?` (relationship)
- `invitedByUserID: UUID?`

**Vault Relationship:**
- `Vault.nomineeList: [Nominee]?` - Cascade delete

---

### 3. ⚠️ NomineeService

**File:** `Services/NomineeService.swift`

**Status:** ⚠️ **PARTIALLY WORKING**

**What Works:**
- ✅ `loadNominees(for:)` - Loads nominees for a vault
- ✅ `inviteNominee(...)` - Creates nominee record
- ✅ `removeNominee(_:)` - Removes nominee
- ✅ `acceptInvite(token:)` - Accepts invitation by token

**What's Missing:**
- ❌ `sendInvitation(to:)` - **Only copies to clipboard, doesn't send via MessageUI**
  ```swift
  // Current implementation:
  UIPasteboard.general.string = invitationMessage
  // Should use MFMessageComposeViewController
  ```

**Issue:** The `UnifiedShareView` uses `MessageComposeView` which should work, but `NomineeService.sendInvitation()` is a fallback that only copies to clipboard.

---

### 4. ✅ Shared Vault Session Service

**File:** `Services/SharedVaultSessionService.swift`

**Status:** ✅ **IMPLEMENTED** (but not integrated)

**Features:**
- ✅ Shared session management (one session per vault for all users)
- ✅ Auto-lock after 30 minutes
- ✅ Session extension on activity
- ✅ Notifications for vault open/lock events
- ✅ Session expiry monitoring

**Issue:** ⚠️ **Not integrated with VaultService.openVault()**

The `SharedVaultSessionService.openSharedVault()` exists but is not called when a vault is opened via `VaultService.openVault()`.

---

### 5. ❌ Nominee Access Integration

**Status:** ❌ **MISSING**

**What's Needed:**
1. When vault opens, check if current user is a nominee
2. If nominee, verify status is "accepted" or "active"
3. Grant access to shared session
4. Notify nominee that vault is now accessible

**Current State:**
- No check for nominee status when vault opens
- No automatic access grant for nominees
- SharedVaultSessionService exists but not used

---

### 6. ✅ Message Composer

**File:** `Utils/ContactPickerView.swift` (MessageComposeView)

**Status:** ✅ **WORKING**

**Features:**
- Uses `MFMessageComposeViewController`
- Sends SMS/iMessage
- Handles completion callbacks
- Integrated in `UnifiedShareView`

---

## Workflow Analysis

### Current Flow (What Happens Now)

1. **Invitation:**
   - ✅ User selects contacts in `UnifiedShareView`
   - ✅ Nominee records created in database
   - ✅ Message composer opens
   - ✅ User sends invitation message
   - ✅ Nominee status: "pending"

2. **Acceptance:**
   - ⚠️ Nominee receives message (manual)
   - ❌ No deep link to app
   - ❌ Nominee must manually open app and accept
   - ⚠️ `acceptInvite(token:)` exists but no UI to call it

3. **Vault Access:**
   - ✅ Owner opens vault via `VaultService.openVault()`
   - ❌ SharedVaultSessionService not called
   - ❌ Nominees not notified
   - ❌ Nominees don't get automatic access

---

## Missing Connections

### 1. ❌ Vault Opening Integration

**Problem:** `VaultService.openVault()` doesn't call `SharedVaultSessionService.openSharedVault()`

**Fix Needed:**
```swift
// In VaultService.openVault()
// After vault is unlocked:
let sharedSessionService = SharedVaultSessionService()
sharedSessionService.configure(modelContext: modelContext, userID: currentUserID)
try await sharedSessionService.openSharedVault(vault, unlockedBy: currentUser)
```

### 2. ❌ Nominee Access Check

**Problem:** No check if current user is a nominee when vault opens

**Fix Needed:**
```swift
// Check if user is nominee for this vault
let nomineeDescriptor = FetchDescriptor<Nominee>(
    predicate: #Predicate { 
        $0.vault?.id == vault.id && 
        ($0.status == "accepted" || $0.status == "active")
    }
)
// If nominee found, grant access to shared session
```

### 3. ⚠️ Invitation Acceptance UI

**Problem:** No UI for nominee to accept invitation

**Fix Needed:**
- Deep link handler for invitation tokens
- Accept invitation view
- Update nominee status to "accepted"

### 4. ⚠️ NomineeService.sendInvitation()

**Problem:** Only copies to clipboard, doesn't send message

**Fix Needed:**
- Use `MFMessageComposeViewController` (already exists in MessageComposeView)
- Or remove this method and rely on UnifiedShareView's MessageComposeView

---

## Recommendations

### Priority 1 (Critical - Workflow Won't Work Without These)

1. **Integrate SharedVaultSessionService with VaultService**
   - Call `openSharedVault()` when vault opens
   - Call `lockSharedVault()` when vault locks

2. **Add Nominee Access Check**
   - Check nominee status when vault opens
   - Grant access if nominee status is "accepted" or "active"

3. **Create Invitation Acceptance UI**
   - Deep link handler for invitation tokens
   - Accept invitation view
   - Update nominee status

### Priority 2 (Important - Better UX)

4. **Fix NomineeService.sendInvitation()**
   - Remove clipboard fallback
   - Use MessageComposeView (already in UnifiedShareView)

5. **Add Nominee Notifications**
   - Notify nominees when vault opens
   - Notify nominees when vault locks
   - Notify owner when nominee accepts

### Priority 3 (Nice to Have)

6. **Deep Linking**
   - URL scheme for invitation acceptance
   - Universal links for better integration

7. **Access Level Enforcement**
   - Enforce view/edit/full access levels
   - Restrict actions based on access level

---

## Testing Checklist

### Invitation Flow
- [ ] Can select contacts from contact picker
- [ ] Nominee records created correctly
- [ ] Message composer opens with invitation text
- [ ] Message can be sent successfully
- [ ] Nominee status is "pending"

### Acceptance Flow
- [ ] Deep link opens app with invitation token
- [ ] Accept invitation view displays
- [ ] Nominee can accept invitation
- [ ] Nominee status changes to "accepted"
- [ ] Owner notified of acceptance

### Access Flow
- [ ] Owner opens vault
- [ ] SharedVaultSessionService creates shared session
- [ ] Nominees notified vault is open
- [ ] Nominees can access vault documents
- [ ] Nominees see same documents as owner
- [ ] Vault auto-locks after 30 minutes
- [ ] Nominees notified when vault locks

---

## Conclusion

The nominee sharing workflow is **70% complete** with good UI and data models, but **missing critical integrations**:

1. ❌ SharedVaultSessionService not called when vault opens
2. ❌ No nominee access check
3. ❌ No invitation acceptance UI

**Estimated Fix Time:** 2-3 hours for Priority 1 items

**Risk Level:** **MEDIUM** - Workflow won't work end-to-end until integrations are complete.

---

**Next Steps:**
1. Integrate SharedVaultSessionService with VaultService.openVault()
2. Add nominee access check
3. Create invitation acceptance UI
4. Test complete workflow

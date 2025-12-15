# Nominee Invitation Flow - Complete Test Plan

## Overview

This document provides a comprehensive test plan for the complete nominee invitation flow: **Contact Selection → Vault Selection → Face ID → Nominee Creation → CloudKit Share → Success**.

## Test Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User opens NomineeInvitationView                         │
│    - From UnifiedNomineeManagementView                      │
│    - Sheet presentation with Apple Pay-style UI             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Contact Selection                                        │
│    - Tap ContactSelectionCard                               │
│    - ContactPickerView (CNContactPickerViewController)      │
│    - Select contact with phone/email                        │
│    - Contact appears in card                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Vault Selection                                          │
│    - VaultRolodexView displays vaults                       │
│    - Swipe through cards (PassKit style)                    │
│    - Large vault name display (56pt)                        │
│    - Vault type indicator (Single/Dual-Key)                │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Send Invitation Button                                   │
│    - Button enabled when contact + vault selected           │
│    - Tap "Send Invitation"                                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Face ID Authentication                                   │
│    - FaceIDOverlayView appears (Apple Pay style)            │
│    - BiometricAuthService.authenticate() called            │
│    - User authenticates with Face ID/Touch ID               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Nominee Creation                                         │
│    - NomineeService.inviteNominee() called                 │
│    - Nominee record created in SwiftData                    │
│    - Nominee linked to vault                                │
│    - Status set to .pending                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. CloudKit Share Creation                                  │
│    - CloudKitSharingService.getOrCreateShare() called       │
│    - Vault synced to CloudKit (if needed)                   │
│    - CKShare created or retrieved                           │
│    - Share linked to nominee                                │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 8. CloudKit Sharing UI                                      │
│    - CloudKitSharingView presented                          │
│    - UICloudSharingController shown                        │
│    - User can share via Messages, Mail, etc.                │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 9. Success Feedback                                         │
│    - SuccessOverlayView appears                              │
│    - Checkmark animation                                    │
│    - "Invitation Sent!" message                             │
│    - Auto-dismiss after 1.5 seconds                        │
└─────────────────────────────────────────────────────────────┘
```

## Step-by-Step Test Procedure

### Prerequisites

1. **Device Setup:**
   - iOS 17.0+ device (iPhone/iPad)
   - Face ID or Touch ID enabled
   - iCloud account signed in
   - CloudKit container configured: `iCloud.com.khandoba.securedocs`

2. **App Setup:**
   - User logged in (Apple Sign In)
   - At least one vault created
   - Contacts permission granted
   - At least one contact with phone or email in Contacts app

3. **Test Data:**
   - Vault name: "Test Vault"
   - Contact name: "Test Contact"
   - Contact phone: "+1 (555) 123-4567" (or email)

### Test Steps

#### Step 1: Open Nominee Invitation View

**Action:**
1. Navigate to a vault detail view
2. Tap "Nominees" or "Add Nominee" button
3. Verify `NomineeInvitationView` appears as a sheet

**Expected Results:**
- ✅ Sheet slides up from bottom (Apple Pay style)
- ✅ Header shows "Invite to Vault" with close button (X)
- ✅ Contact selection card visible (empty state: "Select Contact")
- ✅ Vault rolodex visible (if vaults exist)
- ✅ "Send Invitation" button visible but disabled

**Code Verification:**
- `NomineeInvitationView` body renders correctly
- `ContactSelectionCard` shows placeholder
- `VaultRolodexView` displays vaults
- Button disabled: `disabled(isSending || selectedContact == nil || selectedVault == nil)`

---

#### Step 2: Select Contact

**Action:**
1. Tap the contact selection card
2. Verify `ContactPickerView` (CNContactPickerViewController) appears
3. Select a contact with phone or email
4. Verify contact picker dismisses
5. Verify contact appears in card

**Expected Results:**
- ✅ Contact picker appears (native iOS UI)
- ✅ Only contacts with phone or email are selectable
- ✅ Contact picker dismisses after selection
- ✅ Contact name appears in `ContactSelectionCard`
- ✅ Contact phone or email appears below name
- ✅ Card shows contact avatar/icon

**Code Verification:**
- `ContactPickerView.makeUIViewController()` creates `CNContactPickerViewController`
- `predicateForEnablingContact` filters contacts correctly
- `didSelect contacts` callback fires
- `selectedContact` state updates
- `ContactSelectionCard` displays contact info

**Edge Cases to Test:**
- Contact with only phone (no email) ✅
- Contact with only email (no phone) ✅
- Contact with both phone and email ✅
- Contact deleted after selection (should handle gracefully)
- No contacts permission (should request permission)

---

#### Step 3: Select Vault

**Action:**
1. Verify vault rolodex is visible
2. Swipe left/right through vault cards
3. Verify large vault name updates (56pt font)
4. Verify vault type indicator updates

**Expected Results:**
- ✅ Vault cards display in rolodex (stacked, PassKit style)
- ✅ Swipe gesture works smoothly
- ✅ Large vault name (56pt) updates on selection
- ✅ Vault type shows "Single-Key Vault" or "Dual-Key Vault"
- ✅ Selected vault card is highlighted
- ✅ Spring animations are smooth

**Code Verification:**
- `VaultRolodexView` displays vaults correctly
- `VaultCardView` renders vault info
- Swipe gesture updates `currentIndex`
- `selectedVault` binding updates
- Large name display updates: `Text(selectedVault.name).font(.system(size: 56))`

**Edge Cases to Test:**
- Single vault (no swiping needed) ✅
- Multiple vaults (swipe works) ✅
- System vaults filtered out ✅
- No vaults available (should show empty state)

---

#### Step 4: Enable Send Button

**Action:**
1. Verify both contact and vault are selected
2. Verify "Send Invitation" button is enabled
3. Verify button opacity is 1.0 (not 0.5)

**Expected Results:**
- ✅ Button enabled when contact + vault selected
- ✅ Button disabled when either missing
- ✅ Button shows "Send Invitation" text
- ✅ Button has gradient background (primary color)
- ✅ Button has shadow effect

**Code Verification:**
- Button disabled state: `.disabled(isSending || selectedContact == nil || selectedVault == nil)`
- Button opacity: `.opacity((selectedContact == nil || selectedVault == nil) ? 0.5 : 1.0)`

---

#### Step 5: Trigger Face ID

**Action:**
1. Tap "Send Invitation" button
2. Verify `authenticateAndSend()` is called
3. Verify Face ID overlay appears

**Expected Results:**
- ✅ `FaceIDOverlayView` appears with fade-in animation
- ✅ Overlay shows phone icon with Face ID indicator
- ✅ Overlay shows "Face ID" text and "Double tap to authenticate"
- ✅ Overlay has dark background with blur
- ✅ Pulse animation on outer ring
- ✅ Phone icon has subtle pulse

**Code Verification:**
- `showFaceID = true` sets overlay visible
- `FaceIDOverlayView` renders correctly
- `BiometricAuthService.authenticate()` called with reason
- Overlay animations trigger on appear

**Edge Cases to Test:**
- Face ID not available (should show error)
- Face ID cancelled (should dismiss overlay, return to view)
- Face ID failed (should show error message)
- Touch ID device (should show Touch ID icon)

---

#### Step 6: Authenticate with Face ID

**Action:**
1. Authenticate with Face ID (or Touch ID)
2. Verify authentication succeeds
3. Verify overlay dismisses

**Expected Results:**
- ✅ Face ID prompt appears (system UI)
- ✅ Authentication succeeds
- ✅ `FaceIDOverlayView` dismisses with fade-out
- ✅ Loading indicator appears ("Sending...")
- ✅ `isSending = true` (button shows progress)

**Code Verification:**
- `biometricAuth.authenticate()` returns `true`
- `showFaceID = false` after authentication
- `isSending = true` after authentication
- Button shows `ProgressView()` when sending

**Edge Cases to Test:**
- Authentication cancelled (should return to view, no nominee created)
- Authentication failed (should show error, return to view)
- Biometric locked out (should show clear error message)

---

#### Step 7: Create Nominee

**Action:**
1. Verify nominee creation starts
2. Check console logs for nominee creation
3. Verify nominee is saved to SwiftData

**Expected Results:**
- ✅ `NomineeService.inviteNominee()` called
- ✅ Nominee record created with:
  - Name from contact
  - Phone number (if available)
  - Email (if available)
  - Status: `.pending`
  - Vault relationship set
  - `invitedByUserID` set
- ✅ Nominee saved to SwiftData
- ✅ Console shows: `"✅ Nominee created: [name]"`

**Code Verification:**
- `nomineeService.inviteNominee()` called with correct parameters
- Nominee model created: `Nominee(name:contactName, phoneNumber:phoneNumber, email:email, status:.pending)`
- Nominee linked to vault: `nominee.vault = vault`
- Nominee added to vault's nomineeList
- `modelContext.insert(nominee)` and `modelContext.save()` called

**Edge Cases to Test:**
- Contact name empty (should use "Nominee" as fallback)
- Contact has no phone or email (should be caught in validation)
- Duplicate nominee (should be handled gracefully)
- ModelContext unavailable (should show error)

---

#### Step 8: Create CloudKit Share

**Action:**
1. Verify CloudKit share creation starts
2. Check console logs for share creation
3. Verify share is linked to nominee

**Expected Results:**
- ✅ `CloudKitSharingService.getOrCreateShare()` called
- ✅ Vault synced to CloudKit (if needed)
- ✅ CloudKit record ID found or created
- ✅ CKShare created or retrieved
- ✅ Share linked to nominee: `nominee.cloudKitShareRecordID = share.recordID.recordName`
- ✅ Console shows: `"✅ CloudKit share created/retrieved: [recordID]"`

**Code Verification:**
- `cloudKitSharing.getOrCreateShare(for: vault)` called
- `ensureVaultSynced()` waits for CloudKit sync
- `getVaultRecordID()` finds CloudKit record
- `getExistingShare()` checks for existing share
- New share created if needed: `CKShare(rootRecord: rootRecord)`
- Share saved to CloudKit database

**Edge Cases to Test:**
- Vault not synced to CloudKit yet (should retry with exponential backoff)
- CloudKit account not available (should show error)
- Network error (should show error, allow retry)
- Share creation fails (should show error, but nominee still created)
- Existing share found (should use existing share)

---

#### Step 9: Present CloudKit Sharing UI

**Action:**
1. Verify `CloudKitSharingView` is presented
2. Verify `UICloudSharingController` appears
3. Verify native iOS sharing UI is shown

**Expected Results:**
- ✅ `showCloudKitSharing = true` triggers sheet
- ✅ `CloudKitSharingView` wraps `UICloudSharingController`
- ✅ Native iOS sharing sheet appears
- ✅ Share options available: Messages, Mail, Copy Link, etc.
- ✅ Vault name shown in share UI
- ✅ User can select sharing method

**Code Verification:**
- `CloudKitSharingView` created with share and container
- `UICloudSharingController(share: share, container: container)` initialized
- Controller delegate set
- Sheet presentation: `.sheet(isPresented: $showCloudKitSharing)`

**Edge Cases to Test:**
- Share is nil (should use preparation handler)
- CloudKit container unavailable (should handle gracefully)
- iPad popover (should configure correctly)

---

#### Step 10: Share via Native UI

**Action:**
1. Select a sharing method (Messages, Mail, etc.)
2. Complete the share (send message, etc.)
3. Verify sharing completes

**Expected Results:**
- ✅ Native iOS sharing UI works correctly
- ✅ Share link/metadata sent via selected method
- ✅ Sharing controller dismisses
- ✅ Success overlay appears

**Code Verification:**
- `UICloudSharingControllerDelegate` methods called
- `cloudSharingController(_:failedToSaveShareWithError:)` handles errors
- Controller dismisses after sharing

**Edge Cases to Test:**
- Share cancelled (should dismiss controller, no error)
- Share failed (should show error)
- Network error during share (should handle gracefully)

---

#### Step 11: Show Success Feedback

**Action:**
1. Verify success overlay appears
2. Verify checkmark animation
3. Verify auto-dismiss

**Expected Results:**
- ✅ `SuccessOverlayView` appears with fade-in
- ✅ Green checkmark circle animates (scale + bounce)
- ✅ "Invitation Sent!" text appears
- ✅ Overlay auto-dismisses after 1.5 seconds
- ✅ Sheet dismisses after success

**Code Verification:**
- `showSuccess = true` triggers overlay
- `SuccessOverlayView` renders with animations
- Checkmark scale animation: `checkmarkScale: 0 → 1.0`
- Overlay scale animation: `scale: 0.8 → 1.0`
- Auto-dismiss: `DispatchQueue.main.asyncAfter(deadline: .now() + 1.5)`

**Edge Cases to Test:**
- Success overlay appears even if CloudKit share not available
- Overlay dismisses correctly
- Sheet dismisses after overlay

---

## Error Scenarios

### Error 1: Contact Missing Phone/Email

**Test:**
1. Select contact without phone or email
2. Tap "Send Invitation"

**Expected:**
- ✅ Error alert: "Contact must have a phone number or email address"
- ✅ No Face ID triggered
- ✅ No nominee created

**Code:**
```swift
guard hasPhone || hasEmail else {
    errorMessage = "Contact must have a phone number or email address"
    showError = true
    return
}
```

---

### Error 2: Face ID Cancelled

**Test:**
1. Select contact and vault
2. Tap "Send Invitation"
3. Cancel Face ID authentication

**Expected:**
- ✅ Face ID overlay dismisses
- ✅ Returns to invitation view
- ✅ No nominee created
- ✅ No error shown (user cancelled intentionally)

**Code:**
```swift
guard success else {
    return // User cancelled
}
```

---

### Error 3: Face ID Failed

**Test:**
1. Select contact and vault
2. Tap "Send Invitation"
3. Fail Face ID authentication (wrong face, etc.)

**Expected:**
- ✅ Face ID overlay dismisses
- ✅ Error alert: "Authentication failed: [reason]"
- ✅ No nominee created
- ✅ Returns to invitation view

**Code:**
```swift
catch let error as BiometricAuthError {
    errorMessage = error.errorDescription
    showError = true
}
```

---

### Error 4: CloudKit Share Not Available

**Test:**
1. Complete flow with vault not synced to CloudKit
2. CloudKit sync takes too long

**Expected:**
- ✅ Nominee created successfully
- ✅ CloudKit share creation fails gracefully
- ✅ Success overlay shown (nominee created, share will sync later)
- ✅ Console shows: "⚠️ CloudKit share not available yet"

**Code:**
```swift
if let share = try await cloudKitSharing.getOrCreateShare(for: vault) {
    showCloudKitSharing = true
} else {
    showSuccess = true // Nominee created, share will sync later
}
```

---

### Error 5: Network Error

**Test:**
1. Disable network connection
2. Complete flow

**Expected:**
- ✅ Face ID succeeds
- ✅ Nominee created locally
- ✅ CloudKit share creation fails
- ✅ Error shown: "Network error, please check connection"
- ✅ Nominee still created (can sync later)

---

## Success Criteria

### Functional Requirements

- ✅ **Contact Selection:** User can select contact from native picker
- ✅ **Vault Selection:** User can swipe through vaults and select one
- ✅ **Face ID:** Biometric authentication works correctly
- ✅ **Nominee Creation:** Nominee record created in SwiftData
- ✅ **CloudKit Share:** Share created or retrieved from CloudKit
- ✅ **Native Sharing:** UICloudSharingController presents correctly
- ✅ **Success Feedback:** Success overlay appears and dismisses

### UI/UX Requirements

- ✅ **Apple Pay Style:** UI matches Apple Pay design language
- ✅ **Smooth Animations:** All transitions use spring animations
- ✅ **Error Handling:** All errors show user-friendly messages
- ✅ **Loading States:** Loading indicators show during async operations
- ✅ **Accessibility:** All UI elements are accessible

### Performance Requirements

- ✅ **Response Time:** Face ID appears within 100ms
- ✅ **Nominee Creation:** Completes within 500ms
- ✅ **CloudKit Sync:** Handles sync delays gracefully (retries)
- ✅ **Animation Performance:** 60fps animations

### Edge Cases

- ✅ **No Contacts:** Handles missing contacts gracefully
- ✅ **No Vaults:** Shows empty state
- ✅ **Biometric Unavailable:** Shows appropriate error
- ✅ **CloudKit Unavailable:** Handles gracefully, creates nominee locally
- ✅ **Network Issues:** Handles network errors with retry logic

---

## Test Checklist

### Pre-Test Setup
- [ ] Device has Face ID/Touch ID enabled
- [ ] iCloud account signed in
- [ ] At least one vault created
- [ ] Contacts permission granted
- [ ] At least one contact with phone/email

### Flow Testing
- [ ] Step 1: Open Nominee Invitation View
- [ ] Step 2: Select Contact
- [ ] Step 3: Select Vault
- [ ] Step 4: Enable Send Button
- [ ] Step 5: Trigger Face ID
- [ ] Step 6: Authenticate with Face ID
- [ ] Step 7: Create Nominee
- [ ] Step 8: Create CloudKit Share
- [ ] Step 9: Present CloudKit Sharing UI
- [ ] Step 10: Share via Native UI
- [ ] Step 11: Show Success Feedback

### Error Scenarios
- [ ] Error 1: Contact Missing Phone/Email
- [ ] Error 2: Face ID Cancelled
- [ ] Error 3: Face ID Failed
- [ ] Error 4: CloudKit Share Not Available
- [ ] Error 5: Network Error

### Edge Cases
- [ ] No contacts available
- [ ] No vaults available
- [ ] Biometric unavailable
- [ ] CloudKit unavailable
- [ ] Network unavailable

### Code Verification
- [ ] All state variables update correctly
- [ ] All async operations complete
- [ ] All error cases handled
- [ ] All UI updates on main thread
- [ ] All console logs appear correctly

---

## Console Log Verification

During testing, verify these console logs appear:

```
✅ Nominee created: [Contact Name]
   Vault: [Vault Name] (ID: [UUID])
   Status: pending
   💾 Vault saved before CloudKit share creation
   ✅ CloudKit share created/retrieved: [Record ID]
   📋 Share Record ID: [Record ID]
```

If CloudKit share not available:
```
⚠️ CloudKit share not available yet
   ℹ️ This usually means the vault hasn't synced to CloudKit yet
   ℹ️ The nominee invitation will work once CloudKit sync completes
```

---

## Notes

1. **CloudKit Sync Timing:** CloudKit sync can take 5-30 seconds. The code includes retry logic with exponential backoff.

2. **Biometric Authentication:** Face ID/Touch ID requires device setup. Test on physical device, not simulator.

3. **Native Sharing:** UICloudSharingController requires iCloud account. Test with valid iCloud account.

4. **Error Handling:** All errors are user-friendly and provide actionable feedback.

5. **Success Feedback:** Success overlay appears even if CloudKit share creation fails (nominee is still created locally).

---

## Test Results Template

```
Test Date: [Date]
Tester: [Name]
Device: [Device Model, iOS Version]

Flow Test Results:
- Step 1: [PASS/FAIL] - [Notes]
- Step 2: [PASS/FAIL] - [Notes]
- Step 3: [PASS/FAIL] - [Notes]
- Step 4: [PASS/FAIL] - [Notes]
- Step 5: [PASS/FAIL] - [Notes]
- Step 6: [PASS/FAIL] - [Notes]
- Step 7: [PASS/FAIL] - [Notes]
- Step 8: [PASS/FAIL] - [Notes]
- Step 9: [PASS/FAIL] - [Notes]
- Step 10: [PASS/FAIL] - [Notes]
- Step 11: [PASS/FAIL] - [Notes]

Error Scenario Results:
- Error 1: [PASS/FAIL] - [Notes]
- Error 2: [PASS/FAIL] - [Notes]
- Error 3: [PASS/FAIL] - [Notes]
- Error 4: [PASS/FAIL] - [Notes]
- Error 5: [PASS/FAIL] - [Notes]

Overall Result: [PASS/FAIL]
Issues Found: [List any issues]
Recommendations: [Any recommendations]
```

---

**Last Updated:** December 2024  
**Test Plan Version:** 1.0  
**Status:** Ready for Testing


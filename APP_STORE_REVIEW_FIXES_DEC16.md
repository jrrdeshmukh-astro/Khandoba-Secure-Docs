# App Store Review Fixes - December 16, 2025

## Issues Addressed

### 1. Guideline 2.1 - In-App Purchase Products Not Submitted
**Problem:** App references premium features but IAP products not submitted.

**Solution:** Removed all premium/subscription references from user-facing UI since app is now a paid app (one-time purchase).

### 2. Guideline 2.3.2 - Accurate Metadata
**Problem:** App metadata refers to paid content/features but not clearly identified as requiring purchase.

**Solution:** Updated all UI text to reflect paid app model (all features included, no subscriptions).

### 3. Contact Grid Filtering
**User Request:** Limit contact cards to only people who are already app users.

**Solution:** Updated `ContactGridSelectionView` to filter and show only contacts who are registered app users.

---

## Changes Made

### 1. Contact Grid Selection (`ContactGridSelectionView.swift`)

**Filtering Logic:**
- ✅ Now only shows contacts who are already app users
- ✅ Filters using `discoveryService.isContactRegistered(contact)`
- ✅ Updated empty state message: "None of your contacts are using the app yet"

**Before:**
- Showed all contacts from device
- Mixed existing users and new invites

**After:**
- Only shows contacts who are registered app users
- Clear empty state when no app users found

---

### 2. Removed Premium References

#### `ClientOnboardingView.swift`
**Before:**
```swift
description: "Premium subscription ($5.99/month) provides unlimited vaults..."
```

**After:**
```swift
description: "All features included with your purchase: unlimited vaults..."
```

#### `BulkOperationsView.swift`
**Before:**
```swift
Text("Premium: Unlimited")
```

**After:**
```swift
Text("Unlimited")
```

#### `DocumentUploadView.swift`
**Before:**
```swift
Text("Premium: Unlimited uploads")
```

**After:**
```swift
Text("Unlimited uploads")
```

**Comment Updated:**
```swift
// Premium subscription - unlimited uploads
```
→
```swift
// All features included - unlimited uploads
```

#### `VaultDetailView.swift`
**Before:**
```swift
SecurityActionRow(
    icon: "video.fill",
    title: "Record Video",
    subtitle: "Premium",
    ...
)
```

**After:**
```swift
SecurityActionRow(
    icon: "video.fill",
    title: "Record Video",
    subtitle: "",
    ...
)
```

**Also Updated:**
- Voice Memo subtitle: "Premium" → ""

**Component Enhancement:**
- Updated `SecurityActionRow` to hide subtitle when empty

#### `TermsOfServiceView.swift`
**Major Updates:**

**Removed Subscription Section:**
- Removed entire "Subscription" section with subscription metadata
- Removed subscription information display

**Updated Service Description:**
**Before:**
```swift
"Premium subscription provides unlimited vaults..."
```

**After:**
```swift
"Khandoba Secure Docs provides unlimited vaults... All features are included with your purchase."
```

**Updated Purchase & Payment:**
**Before:**
- Subscription service description
- Auto-renewal information
- Subscription management links

**After:**
```swift
"Khandoba Secure Docs is a paid app available for purchase through the App Store. 
Payment is processed through the App Store as a one-time purchase. 
All features are included with your purchase - no subscriptions or additional 
in-app purchases required."
```

**Updated Refunds:**
**Before:**
```swift
"Cancel anytime in App Store subscriptions. Refund requests are handled by Apple..."
```

**After:**
```swift
"Refund requests are handled by Apple according to their refund policy. 
Contact Apple Support for refund requests related to your app purchase."
```

**Updated Liability:**
**Before:**
```swift
"Maximum liability limited to subscription fees paid."
```

**After:**
```swift
"Maximum liability limited to the purchase price paid for the app."
```

#### `StoreView.swift`
**Updated Header Comment:**
```swift
// NOTE: This view is not currently used in navigation (app is paid, not subscription-based)
// Kept for potential future use or reference
```

**Note:** StoreView is not in navigation, so it's not visible to users, but comment updated for clarity.

---

## Files Modified

1. ✅ `Views/Sharing/ContactGridSelectionView.swift`
   - Filtered to only show existing app users
   - Updated empty state message

2. ✅ `Views/Onboarding/ClientOnboardingView.swift`
   - Removed "Premium subscription ($5.99/month)" reference

3. ✅ `Views/Documents/BulkOperationsView.swift`
   - Changed "Premium: Unlimited" → "Unlimited"

4. ✅ `Views/Documents/DocumentUploadView.swift`
   - Changed "Premium: Unlimited uploads" → "Unlimited uploads"
   - Updated comment

5. ✅ `Views/Vaults/VaultDetailView.swift`
   - Removed "Premium" subtitles from Video and Voice Memo actions

6. ✅ `Views/Components/SecurityActionRow.swift`
   - Enhanced to hide subtitle when empty

7. ✅ `Views/Legal/TermsOfServiceView.swift`
   - Removed subscription section
   - Updated to paid app model
   - Updated refund and liability language

8. ✅ `Views/Store/StoreView.swift`
   - Updated header comment (not in navigation)

---

## Build Status

✅ **BUILD SUCCEEDED**

All changes compile successfully. No errors.

---

## Testing Checklist

- [ ] Verify contact grid only shows app users
- [ ] Verify no "Premium" labels visible in UI
- [ ] Verify onboarding text reflects paid app
- [ ] Verify Terms of Service reflects paid app model
- [ ] Verify all features accessible without subscription checks

---

## App Store Connect Actions Required

### 1. Update App Description
Remove any references to:
- "Premium subscription"
- "In-app purchases"
- "Subscription required"

Replace with:
- "One-time purchase"
- "All features included"
- "No subscriptions required"

### 2. Update Screenshots
- Remove any screenshots showing subscription UI
- Remove StoreView/Premium tab screenshots
- Update to show paid app experience

### 3. Remove In-App Purchases
- Remove all IAP products from sale
- Unlink IAP products from app version
- Verify no "In-App Purchases" label appears

### 4. Update Review Information
- Clarify app is paid (one-time purchase)
- Remove subscription-related review notes
- Update to reflect paid app model

---

## Summary

✅ **All premium/subscription references removed from user-facing UI**
✅ **Contact grid now only shows existing app users**
✅ **Terms of Service updated to paid app model**
✅ **Build successful - ready for resubmission**

**Next Steps:**
1. Update App Store Connect metadata
2. Remove IAP products from sale
3. Update screenshots
4. Submit new binary for review

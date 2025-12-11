# App Store Review Fixes - December 2025

This document outlines the fixes implemented to address App Store review feedback.

## Issues Addressed

### 1. Guideline 2.1 - In-App Purchase Products Not Submitted
**Status:** ✅ FIXED - Converted to Auto-Renewable Subscription

**Changes:**
- Removed in-app purchase products
- Implemented auto-renewable subscription ($5.99/month)
- Product ID: `com.khandoba.premium.monthly`
- Updated `SubscriptionService` to use StoreKit 2
- Updated `SubscriptionRequiredView` to show subscription details

**App Store Connect Setup Required:**
1. Create auto-renewable subscription in App Store Connect
2. Product ID: `com.khandoba.premium.monthly`
3. Price: $5.99/month
4. Subscription Group: Create new group "Khandoba Premium"
5. Localization: Add display name and description
6. Submit subscription for review along with app

### 2. Guideline 3.1.2 - Missing Subscription Metadata
**Status:** ✅ FIXED

**Required Information Added:**

#### In Binary (SubscriptionRequiredView.swift):
- ✅ Title: "Khandoba Premium" (displayed)
- ✅ Length: "Monthly (auto-renewable)" (displayed)
- ✅ Price: "$5.99 per month" (displayed)
- ✅ Functional link to Terms of Service: `https://khandoba.org/terms`
- ✅ Functional link to Privacy Policy: `https://khandoba.org/privacy`

#### In App Metadata (App Store Connect):
- ✅ Privacy Policy URL: Must be set in App Store Connect → App Privacy → Privacy Policy
- ✅ Terms of Service: Must be included in App Description or Custom EULA field

**Files Updated:**
- `SubscriptionRequiredView.swift` - Added subscription metadata display
- `TermsOfServiceView.swift` - Added subscription details and links
- `PrivacyPolicyView.swift` - Added functional links

### 3. Guideline 5.1.1(v) - Account Deletion Missing
**Status:** ✅ FIXED

**Implementation:**
- Created `AccountDeletionService.swift` - Handles account deletion
- Created `AccountDeletionView.swift` - UI for account deletion
- Added "Delete Account" option in `ProfileView.swift`

**Features:**
- ✅ Easy to find in Profile → Settings section
- ✅ Deletes entire account record and all associated data
- ✅ Includes confirmation steps to prevent accidental deletion
- ✅ Deletes all vaults, documents, chat messages, and user data
- ✅ Signs user out after deletion
- ✅ Complies with Apple's account deletion requirements

**Files Created:**
- `Services/AccountDeletionService.swift`
- `Views/Profile/AccountDeletionView.swift`

**Files Updated:**
- `Views/Profile/ProfileView.swift` - Added account deletion navigation

## App Store Connect Configuration Checklist

### Before Resubmission:

1. **Create Auto-Renewable Subscription:**
   - [ ] Go to App Store Connect → Your App → Subscriptions
   - [ ] Create new subscription group: "Khandoba Premium"
   - [ ] Create subscription:
     - Product ID: `com.khandoba.premium.monthly`
     - Display Name: "Khandoba Premium"
     - Price: $5.99/month
     - Duration: 1 month
     - Auto-renewable: Yes
   - [ ] Add localization (at least English)
   - [ ] Submit subscription for review

2. **App Privacy Settings:**
   - [ ] Go to App Store Connect → App Privacy
   - [ ] Set Privacy Policy URL: `https://khandoba.org/privacy`
   - [ ] Ensure privacy policy is accessible and functional

3. **App Information:**
   - [ ] Go to App Store Connect → App Information
   - [ ] In App Description, include link to Terms of Service:
     - Text: "Terms of Service: https://khandoba.org/terms"
   - [ ] OR provide Custom EULA in App Information → License Agreement

4. **Remove In-App Purchase Products:**
   - [ ] If any in-app purchase products exist, remove them
   - [ ] Only keep the auto-renewable subscription

## Testing Checklist

Before submitting:

- [ ] Test subscription purchase flow in sandbox
- [ ] Verify subscription metadata displays correctly:
  - Title: "Khandoba Premium"
  - Length: "Monthly (auto-renewable)"
  - Price: "$5.99 per month"
- [ ] Verify Terms of Service link works: `https://khandoba.org/terms`
- [ ] Verify Privacy Policy link works: `https://khandoba.org/privacy`
- [ ] Test account deletion flow:
  - Navigate to Profile → Delete Account
  - Verify confirmation dialog appears
  - Verify account and all data are deleted
  - Verify user is signed out after deletion
- [ ] Verify subscription can be managed in iOS Settings → Subscriptions

## Code Changes Summary

### New Files:
1. `Services/AccountDeletionService.swift` - Account deletion logic
2. `Views/Profile/AccountDeletionView.swift` - Account deletion UI

### Modified Files:
1. `Views/Profile/ProfileView.swift` - Added account deletion option
2. `Services/SubscriptionService.swift` - Updated product ID comment
3. `Views/Subscription/SubscriptionRequiredView.swift`:
   - Added subscription metadata display
   - Updated purchase flow to use real StoreKit
   - Added Terms/Privacy links
   - Configured SubscriptionService with modelContext
4. `Views/Legal/TermsOfServiceView.swift`:
   - Added subscription details (title, length, price)
   - Added functional links to Terms and Privacy
5. `Views/Legal/PrivacyPolicyView.swift`:
   - Added functional links to Privacy Policy and Terms
6. `Views/Store/StoreView.swift`:
   - Configured SubscriptionService with modelContext

## Notes

- The subscription product ID `com.khandoba.premium.monthly` must match exactly in App Store Connect
- Privacy Policy and Terms of Service URLs must be functional and accessible
- Account deletion is permanent and cannot be undone
- All user data (vaults, documents, messages) is deleted when account is deleted
- Subscription cancellation is handled through App Store Settings

## Next Steps

1. Create subscription in App Store Connect
2. Set Privacy Policy URL in App Store Connect
3. Add Terms of Service link to App Description or Custom EULA
4. Test all flows in sandbox environment
5. Submit app and subscription for review together

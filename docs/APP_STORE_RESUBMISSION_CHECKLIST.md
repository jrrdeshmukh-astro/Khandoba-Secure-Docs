# App Store Resubmission Checklist

## Review Feedback Addressed

### ✅ Issue 1: Guideline 2.1 - In-App Purchase Products Not Submitted
**Resolution:** Converted to Auto-Renewable Subscription

**What Changed:**
- Removed in-app purchase products
- Implemented auto-renewable subscription ($5.99/month)
- Product ID: `com.khandoba.premium.monthly`

**App Store Connect Action Required:**
1. Create auto-renewable subscription:
   - Product ID: `com.khandoba.premium.monthly`
   - Display Name: "Khandoba Premium"
   - Price: $5.99/month
   - Duration: 1 month
   - Auto-renewable: Yes
2. Create subscription group: "Khandoba Premium"
3. Submit subscription for review along with app

### ✅ Issue 2: Guideline 3.1.2 - Missing Subscription Metadata
**Resolution:** Added all required subscription information

**In Binary (SubscriptionRequiredView.swift):**
- ✅ Title: "Khandoba Premium" (clearly displayed)
- ✅ Length: "Monthly (auto-renewable)" (clearly displayed)
- ✅ Price: "$5.99 per month" (clearly displayed)
- ✅ Functional Terms of Service link: `https://khandoba.org/terms`
- ✅ Functional Privacy Policy link: `https://khandoba.org/privacy`

**App Store Connect Action Required:**
1. Set Privacy Policy URL:
   - Go to App Store Connect → Your App → App Privacy
   - Privacy Policy URL: `https://khandoba.org/privacy`
   - Verify link is accessible and functional

2. Add Terms of Service:
   - Option A: Add to App Description:
     - "Terms of Service: https://khandoba.org/terms"
   - Option B: Provide Custom EULA:
     - Go to App Store Connect → App Information → License Agreement
     - Select "Apply a custom EULA"
     - Enter terms text or link

### ✅ Issue 3: Guideline 5.1.1(v) - Account Deletion Missing
**Resolution:** Implemented complete account deletion feature

**Implementation:**
- ✅ Account deletion option in Profile → Settings
- ✅ Easy to find (clearly labeled "Delete Account")
- ✅ Deletes entire account and all associated data
- ✅ Includes confirmation steps to prevent accidental deletion
- ✅ No customer service flow required (not highly regulated)

**User Flow:**
1. Profile → Delete Account
2. View what will be deleted
3. Tap "Delete My Account"
4. Final confirmation dialog
5. Account and all data permanently deleted
6. User signed out automatically

## Code Changes Summary

### New Files Created:
1. `Services/AccountDeletionService.swift` - Account deletion logic
2. `Views/Profile/AccountDeletionView.swift` - Account deletion UI
3. `docs/APP_STORE_REVIEW_FIXES.md` - Detailed documentation

### Files Modified:
1. `Views/Profile/ProfileView.swift` - Added account deletion option
2. `Services/SubscriptionService.swift` - Updated product ID comment
3. `Views/Subscription/SubscriptionRequiredView.swift`:
   - Added subscription metadata (title, length, price)
   - Added Terms/Privacy links
   - Updated to use real StoreKit purchases
   - Configured SubscriptionService with modelContext
4. `Views/Legal/TermsOfServiceView.swift`:
   - Added subscription details
   - Added functional links
5. `Views/Legal/PrivacyPolicyView.swift`:
   - Added functional links to Privacy Policy and Terms
6. `Views/Store/StoreView.swift`:
   - Configured SubscriptionService with modelContext

## Pre-Submission Checklist

### App Store Connect Setup:
- [ ] Create auto-renewable subscription:
  - Product ID: `com.khandoba.premium.monthly`
  - Price: $5.99/month
  - Duration: 1 month
  - Auto-renewable: Yes
- [ ] Set Privacy Policy URL: `https://khandoba.org/privacy`
- [ ] Add Terms of Service link to App Description OR provide Custom EULA
- [ ] Remove any existing in-app purchase products
- [ ] Submit subscription for review

### Testing:
- [ ] Test subscription purchase in sandbox
- [ ] Verify subscription metadata displays:
  - Title: "Khandoba Premium"
  - Length: "Monthly (auto-renewable)"
  - Price: "$5.99 per month"
- [ ] Verify Terms link works: `https://khandoba.org/terms`
- [ ] Verify Privacy link works: `https://khandoba.org/privacy`
- [ ] Test account deletion:
  - Navigate to Profile → Delete Account
  - Verify confirmation appears
  - Verify account is deleted
  - Verify user is signed out
- [ ] Verify subscription can be managed in Settings → Subscriptions

### Code Verification:
- [ ] No build errors
- [ ] All imports correct
- [ ] SubscriptionService configured with modelContext
- [ ] AccountDeletionService configured with modelContext
- [ ] All links are functional

## Submission Notes

1. **Submit Together:**
   - Submit the app binary
   - Submit the subscription product
   - Both must be reviewed together

2. **Review Notes:**
   - Mention that subscription is auto-renewable
   - Mention that account deletion is available in Profile → Delete Account
   - Mention that Terms and Privacy links are functional

3. **Test Account:**
   - Use sandbox test account for subscription testing
   - Verify subscription activates correctly
   - Verify subscription status updates in app

## Important URLs

- Privacy Policy: `https://khandoba.org/privacy`
- Terms of Service: `https://khandoba.org/terms`
- Subscription Management: `https://apps.apple.com/account/subscriptions`
- App Store Connect: https://appstoreconnect.apple.com

## Product ID

**Subscription Product ID:** `com.khandoba.premium.monthly`

This must match exactly in:
- App Store Connect subscription configuration
- `SubscriptionService.swift` productIDs array

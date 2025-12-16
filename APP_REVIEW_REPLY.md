# App Review Reply - Submission ID: 8a62a0a0-afe6-4d31-8d71-030e390a818c

**Date:** December 16, 2025  
**Version:** 1.0.0  
**Submission ID:** 8a62a0a0-afe6-4d31-8d71-030e390a818c

---

## Response to Review Feedback

Thank you for your review. We have addressed all three issues identified in your feedback. Below is a detailed response to each guideline:

---

## ✅ Issue 1: Guideline 2.1 - Performance - App Completeness

**Issue:** In-app purchase products have not been submitted for review.

**Status:** ✅ **RESOLVED**

**Action Taken:**
1. Created auto-renewable subscription products in App Store Connect:
   - **Product ID:** `com.khandoba.premium.monthly`
   - **Title:** Khandoba Premium
   - **Type:** Auto-renewable subscription
   - **Price:** $5.99/month
   - **Subscription Group:** Khandoba Premium

2. Added App Review screenshot for subscription products in App Store Connect

3. Submitted in-app purchases for review alongside the app binary

**Location in App Store Connect:**
- App Store Connect → My Apps → Khandoba Secure Docs → Features → In-App Purchases
- All subscription products are now submitted and pending review

**Next Steps:**
- The in-app purchases are now submitted for review
- We will ensure the subscription products are approved before the app review proceeds

---

## ✅ Issue 2: Guideline 3.1.2 - Business - Payments - Subscriptions

**Issue:** Missing required subscription information:
- Functional link to Terms of Use (EULA)
- Functional link to Privacy Policy

**Status:** ✅ **RESOLVED**

### A. Terms of Use (EULA) Link

**EULA Type:** We are using the **standard Apple Terms of Use (EULA)**. A link to Apple's standard Terms of Use is included in the App Description in App Store Connect.

**Terms of Service Link (Additional):**
1. **Store View (Primary):** 
   - Navigate to: Store Tab → Premium section
   - Direct links to Terms of Service and Privacy Policy are displayed below subscription information
   - Links: "Terms of Service" and "Privacy Policy" (both functional)

2. **Subscription Required View:**
   - Appears when premium features are accessed
   - Displays subscription details with functional links to Terms and Privacy Policy
   - Location: Bottom of subscription screen

3. **Profile View:**
   - Navigate to: Profile Tab → Settings → Terms of Service
   - Full Terms of Service view with functional link to: `https://khandoba.org/terms`

4. **Terms of Service View:**
   - In-app view accessible from Profile → Terms of Service
   - Contains full subscription information:
     - Title: Khandoba Premium
     - Length: Monthly (auto-renewable)
     - Price: $5.99 per month
   - Functional link to full Terms: `https://khandoba.org/terms`
   - Functional link to Privacy Policy: `https://khandoba.org/privacy`

### B. Privacy Policy Link

**Location in App:**
1. **Store View:**
   - Direct link displayed below subscription information
   - Link: "Privacy Policy" → `https://khandoba.org/privacy`

2. **Subscription Required View:**
   - Functional link displayed at bottom of screen
   - Link: "Privacy Policy" → `https://khandoba.org/privacy`

3. **Profile View:**
   - Navigate to: Profile Tab → Settings → Privacy Policy
   - Full Privacy Policy view with functional link to: `https://khandoba.org/privacy`

4. **Privacy Policy View:**
   - In-app view accessible from Profile → Privacy Policy
   - Functional link to full Privacy Policy: `https://khandoba.org/privacy`
   - Functional link to Terms of Service: `https://khandoba.org/terms`

### C. Subscription Information Displayed in App

**Required Information (All Present):**
- ✅ **Title:** "Khandoba Premium" (displayed in StoreView, SubscriptionRequiredView, TermsOfServiceView)
- ✅ **Length:** "Monthly (auto-renewable)" (displayed in all subscription views)
- ✅ **Price:** "$5.99 per month" (displayed in all subscription views)
- ✅ **Terms Link:** Functional link to `https://khandoba.org/terms` (displayed in StoreView, SubscriptionRequiredView, TermsOfServiceView, PrivacyPolicyView)
- ✅ **Privacy Link:** Functional link to `https://khandoba.org/privacy` (displayed in StoreView, SubscriptionRequiredView, TermsOfServiceView, PrivacyPolicyView)

**App Store Connect Metadata:**
- ✅ Privacy Policy URL set: `https://khandoba.org/privacy`
- ✅ Standard Apple Terms of Use (EULA) - link included in App Description
- ✅ Terms of Service link (`https://khandoba.org/terms`) included in App Description

**Website URLs (Verified Functional):**
- Terms of Service: `https://khandoba.org/terms`
- Privacy Policy: `https://khandoba.org/privacy`

**EULA:**
- Using standard Apple Terms of Use (EULA) - link provided in App Description per App Store requirements

---

## ✅ Issue 3: Guideline 5.1.1(v) - Data Collection and Storage

**Issue:** App supports account creation but does not include an option to initiate account deletion.

**Status:** ✅ **RESOLVED**

### Account Deletion Feature Location

**Primary Access Path:**
1. Open the app
2. Navigate to: **Profile Tab** (bottom tab bar, 4th tab)
3. Scroll to: **"Delete Account"** section (located at bottom of Profile view, above Sign Out)
4. Tap: **"Delete Account"** (red text with trash icon)
5. Navigate to: **AccountDeletionView**
6. Review deletion information
7. Tap: **"Delete My Account"** button (red button at bottom)
8. Confirm: **"Delete Forever"** in confirmation alert

**Visual Indicators:**
- Red trash icon (trash.fill)
- Red text color (error color)
- Clear label: "Delete Account"
- Footer text: "Deleting your account will permanently remove all your data, vaults, and documents. This action cannot be undone."

### Account Deletion Functionality

**What Gets Deleted:**
1. ✅ User account record (permanent deletion)
2. ✅ All user-owned vaults and documents (cascade delete)
3. ✅ All access logs from user's own vaults
4. ✅ All chat messages and conversations
5. ✅ All encryption keys (data cannot be recovered)
6. ✅ User profile and account information
7. ✅ Nominee access to shared vaults (terminated immediately)

**Deletion Process:**
1. User taps "Delete Account" in Profile
2. User reviews what will be deleted
3. User taps "Delete My Account" button
4. Confirmation alert appears: "Are you absolutely sure? This will permanently delete your account and all data. This action cannot be undone."
5. User confirms "Delete Forever"
6. Account and all associated data are permanently deleted
7. User is signed out automatically

**Compliance Features:**
- ✅ Permanent deletion (not temporary deactivation)
- ✅ No website visit required (deletion happens entirely in-app)
- ✅ Confirmation steps to prevent accidental deletion
- ✅ Clear explanation of what will be deleted
- ✅ No customer service call or email required

**Code Implementation:**
- Service: `AccountDeletionService.swift`
- View: `AccountDeletionView.swift`
- Accessible from: `ProfileView.swift` → Delete Account section

**Testing Instructions:**
1. Sign in to the app
2. Navigate to Profile tab (bottom navigation)
3. Scroll to bottom
4. Tap "Delete Account" (red, with trash icon)
5. Review the deletion information
6. Tap "Delete My Account" button
7. Confirm deletion in alert
8. Verify account is deleted and user is signed out

---

## Summary

All three issues have been resolved:

1. ✅ **In-App Purchases:** Subscription products created and submitted for review in App Store Connect
2. ✅ **Subscription Metadata:** All required information (title, length, price) and functional links (Terms, Privacy) displayed in app and App Store Connect
3. ✅ **Account Deletion:** Fully functional account deletion feature accessible from Profile → Delete Account

**New Binary:**
A new binary has been uploaded with all fixes included. The app now fully complies with all three guidelines.

**Thank you for your review. We look forward to approval.**

---

## Additional Information

**Contact:**
- Developer: Open Street LLC
- Email: support@khandoba.org
- Website: https://khandoba.org

**Subscription Products:**
- Product ID: `com.khandoba.premium.monthly`
- Price: $5.99/month
- Type: Auto-renewable subscription

**Legal Links:**
- Terms of Service: https://khandoba.org/terms
- Privacy Policy: https://khandoba.org/privacy
- EULA: Standard Apple Terms of Use (link in App Description)

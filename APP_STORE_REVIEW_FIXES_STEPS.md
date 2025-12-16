# App Store Review Fixes - Step-by-Step Guide

**Submission ID:** 9ee22f99-2ef7-4119-b4d9-e6b3306732c8  
**Review Date:** December 16, 2025  
**Version:** 1.0.0

---

## Issue 1: Guideline 2.1 - In-App Purchase Products Not Submitted

### Problem
The app references premium features, but the in-app purchase products haven't been submitted for review in App Store Connect.

### Solution Steps

#### Step 1: Create In-App Purchase Product in App Store Connect

1. **Log in to App Store Connect**
   - Go to: https://appstoreconnect.apple.com
   - Sign in with your Apple Developer account

2. **Navigate to Your App**
   - Click "My Apps"
   - Select "Khandoba Secure Docs"

3. **Go to In-App Purchases**
   - Click on "Features" tab (top navigation)
   - Click on "In-App Purchases" in the left sidebar
   - Click the "+" button (blue button) to create a new product

4. **Select Product Type**
   - Choose: **"Auto-Renewable Subscription"**
   - Click "Create"

5. **Fill in Product Information**
   - **Reference Name:** `Khandoba Premium Monthly`
   - **Product ID:** `com.khandoba.premium.monthly`
   - **Subscription Group:** Create new group "Khandoba Premium" (or select existing)
   - Click "Create"

6. **Configure Subscription Details**
   - **Subscription Duration:** Monthly
   - **Price:** $5.99 (or your local equivalent)
   - **Display Name:** `Khandoba Premium`
   - **Description:** 
     ```
     Khandoba Premium provides unlimited vaults, unlimited document storage, AI-powered Intel Reports, advanced threat monitoring, and secure collaboration features.
     ```

7. **Add Localization (Required)**
   - Click "Add Localization"
   - Select "English (U.S.)"
   - **Display Name:** `Khandoba Premium`
   - **Description:** 
     ```
     Get unlimited vaults, unlimited storage, AI intelligence features, threat monitoring, and secure collaboration tools.
     ```
   - Click "Save"

8. **Add App Review Information (CRITICAL)**
   - Scroll to "App Review Information" section
   - **Review Notes:** 
     ```
     This is a monthly auto-renewable subscription for premium features. The subscription provides unlimited vaults, unlimited storage, AI-powered Intel Reports, and advanced security features.
     ```
   - **Screenshot (REQUIRED):** 
     - Take a screenshot of your app's Store/Subscription screen showing the subscription option
     - The screenshot should show:
       - Subscription title: "Khandoba Premium"
       - Price: "$5.99 per month"
       - Subscription details (title, length, price)
       - Links to Terms of Service and Privacy Policy
     - Upload the screenshot (must be at least 640x920 pixels)
   - Click "Save"

9. **Submit for Review**
   - Scroll to top of page
   - Click "Submit for Review" button
   - Confirm submission

#### Step 2: Verify Product Status

1. **Check Product Status**
   - Go back to In-App Purchases list
   - Verify product shows status: **"Waiting for Review"** or **"In Review"**
   - If it shows "Ready to Submit", click "Submit for Review" again

#### Step 3: Link Product to App Version

1. **Go to App Version**
   - Navigate to: App Store → [Your Version] (1.0.0)
   - Scroll to "In-App Purchases" section

2. **Add Product**
   - Click "+" next to "In-App Purchases"
   - Select your product: `com.khandoba.premium.monthly`
   - Click "Add"

3. **Save Changes**
   - Click "Save" at top right

---

## Issue 2: Guideline 2.3.2 - Metadata Doesn't Indicate Paid Content

### Problem
The app description doesn't clearly state that premium features require a purchase.

### Solution Steps

#### Step 1: Update App Description

1. **Navigate to App Information**
   - In App Store Connect, go to: App Store → App Information
   - Or: App Store → [Your Version] → App Store Listing

2. **Edit App Description**
   - Find the "Description" field
   - **Add clear statement at the beginning or end:**
   
   **Option A (Add at Beginning):**
   ```
   Khandoba Secure Docs is a secure document management platform with free and premium features.
   
   FREE FEATURES:
   - Secure document storage
   - Basic vault management
   - Document encryption
   
   PREMIUM FEATURES (Requires Subscription - $5.99/month):
   - Unlimited vaults
   - Unlimited document storage
   - AI-powered Intel Reports
   - Advanced threat monitoring
   - Secure collaboration tools
   
   [Your existing description continues here...]
   ```
   
   **Option B (Add at End):**
   ```
   [Your existing description...]
   
   SUBSCRIPTION INFORMATION:
   Khandoba Premium is an optional monthly subscription ($5.99/month) that unlocks advanced features including unlimited vaults, unlimited storage, AI intelligence, and threat monitoring. Subscription auto-renews unless cancelled 24 hours before the end of the period. Manage subscriptions in iOS Settings → Subscriptions.
   
   Terms of Service: https://khandoba.org/terms
   Privacy Policy: https://khandoba.org/privacy
   ```

3. **Save Changes**
   - Click "Save" at top right

#### Step 2: Update What's New (Release Notes) - Optional but Recommended

1. **Go to Version Information**
   - Navigate to: App Store → [Your Version] → What's New in This Version

2. **Add Clear Statement**
   ```
   This version includes premium subscription features. Premium features require a monthly subscription ($5.99/month) and include unlimited vaults, unlimited storage, AI intelligence, and advanced security features.
   ```

3. **Save Changes**

#### Step 3: Update Promotional Text (If Used)

1. **Check Promotional Text**
   - Go to: App Store → [Your Version] → Promotional Text
   - If you have promotional text, ensure it mentions premium features require purchase
   - Example: "Premium features available via subscription ($5.99/month)"

4. **Save Changes**

#### Step 4: Verify Screenshots

1. **Check Screenshots**
   - Go to: App Store → [Your Version] → App Preview and Screenshots
   - Ensure screenshots don't mislead users about what's free vs paid
   - If screenshots show premium features, add text overlay: "Premium Feature" or "Requires Subscription"

---

## Complete Checklist

### For Issue 1 (IAP Products):
- [ ] Created auto-renewable subscription product in App Store Connect
- [ ] Product ID: `com.khandoba.premium.monthly`
- [ ] Set price: $5.99/month
- [ ] Added display name and description
- [ ] Added localization (English)
- [ ] **Added App Review screenshot (REQUIRED)**
- [ ] Added review notes
- [ ] Submitted product for review
- [ ] Product status shows "Waiting for Review" or "In Review"
- [ ] Linked product to app version (1.0.0)

### For Issue 2 (Metadata):
- [ ] Updated App Description to clearly state:
  - [ ] What features are free
  - [ ] What features require premium subscription
  - [ ] Subscription price ($5.99/month)
  - [ ] How to manage subscriptions
- [ ] Updated "What's New" section (if applicable)
- [ ] Updated Promotional Text (if used)
- [ ] Verified screenshots don't mislead about free vs paid features
- [ ] Added Terms of Service link in description
- [ ] Added Privacy Policy link in description

---

## After Completing All Steps

1. **Verify Everything**
   - Double-check all information is accurate
   - Ensure IAP product is submitted and linked to app version
   - Ensure app description clearly indicates paid content

2. **Submit New Binary (If Needed)**
   - If you made code changes, build and upload new binary
   - If only metadata changes, you may not need a new binary
   - Check App Store Connect to see if binary resubmission is required

3. **Reply to App Review**
   - Go to: App Store Connect → App Review → Resolution Center
   - Reply to the review message
   - State that you've:
     - Submitted the in-app purchase product for review
     - Updated the app description to clearly indicate premium features require purchase
   - Reference the submission ID: 9ee22f99-2ef7-4119-b4d9-e6b3306732c8

---

## Important Notes

### App Review Screenshot Requirements:
- **Minimum size:** 640x920 pixels
- **Must show:** Subscription screen with price, terms, and privacy links
- **Format:** PNG or JPEG
- **Content:** Must match what reviewers will see in the app

### App Description Best Practices:
- Be transparent about what's free vs paid
- Clearly state subscription price
- Explain how to cancel subscriptions
- Include links to Terms and Privacy Policy

### Timeline:
- IAP product review: Usually 24-48 hours
- App review: Usually 24-48 hours after IAP is approved
- Total: Expect 2-4 business days for complete review

---

## Sample App Review Reply

```
Thank you for your review. We have addressed both issues:

1. In-App Purchase Product:
   - Created and submitted auto-renewable subscription product (Product ID: com.khandoba.premium.monthly)
   - Added App Review screenshot showing subscription details
   - Product is now submitted for review and linked to app version 1.0.0

2. App Description:
   - Updated app description to clearly indicate which features are free and which require premium subscription ($5.99/month)
   - Added subscription information including price and cancellation instructions
   - Added links to Terms of Service and Privacy Policy

All issues have been resolved. We look forward to approval.
```

---

## Troubleshooting

### If IAP Product Shows "Ready to Submit":
- Make sure you've added the App Review screenshot
- Make sure you've filled in all required fields (display name, description, localization)
- Click "Submit for Review" button

### If IAP Product Shows "Missing Metadata":
- Check that you've added at least one localization (English)
- Check that display name and description are filled in
- Check that App Review screenshot is uploaded

### If App Description Changes Don't Save:
- Make sure you're editing the correct version (1.0.0)
- Make sure you click "Save" at the top right
- Wait a few minutes and refresh the page

---

**Last Updated:** December 16, 2025

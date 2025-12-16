# Paid App Conversion Guide

## Overview

This guide explains how to convert Khandoba Secure Docs from a free app with in-app purchases to a **paid app** (one-time purchase) like the examples shown (HotSchedules, Shadowrocket, Procreate Pocket).

---

## ✅ Code Changes Completed

### 1. ContentView.swift
- ✅ Removed subscription service
- ✅ Removed subscription check from navigation flow
- ✅ Removed `needsSubscription` computed property
- ✅ Removed all subscription blocking logic
- ✅ App now allows full access without subscription

### 2. App Flow
**New Flow:**
1. Authentication
2. Permissions Setup (if needed)
3. Account Setup (if needed)
4. **Main App** (full access - no subscription required)

**Removed:**
- SubscriptionRequiredView blocking
- Subscription status checks
- StoreKit subscription logic

---

## 📱 App Store Connect Configuration

### Step 1: Change App Pricing

1. **Log in to App Store Connect**
   - Go to: https://appstoreconnect.apple.com
   - Navigate to: My Apps → Khandoba Secure Docs

2. **Go to Pricing and Availability**
   - Click on "Pricing and Availability" in left sidebar
   - Or: App Store → Pricing and Availability

3. **Set App Price**
   - **Price Schedule:** Select a price tier
   - **Recommended:** $4.99 or $5.99 (one-time purchase)
   - **Price Tiers:**
     - Tier 1: $0.99
     - Tier 2: $1.99
     - Tier 3: $2.99
     - Tier 4: $3.99
     - Tier 5: $4.99
     - Tier 6: $5.99 ← **Recommended**
     - Tier 7: $6.99
     - etc.

4. **Save Changes**

### Step 2: Remove In-App Purchases

1. **Go to In-App Purchases**
   - Navigate to: Features → In-App Purchases

2. **Delete or Remove Products**
   - If products are "Ready to Submit" or "Waiting for Review":
     - Click on the product
     - Scroll to bottom
     - Click "Remove from Sale" or delete the product
   - If products are "In Review":
     - Wait for review to complete, then remove
   - If products are "Approved":
     - Click "Remove from Sale" (they'll remain in your account but won't be available)

3. **Unlink from App Version**
   - Go to: App Store → [Your Version] (1.0.0)
   - Scroll to "In-App Purchases" section
   - Remove any linked products

### Step 3: Update App Description

**New App Description Template:**

```
Khandoba Secure Docs - Professional Secure Document Management

A one-time purchase app for enterprise-grade secure document management with ML-based threat monitoring, dual-key approvals, and comprehensive security features.

FEATURES:
• Unlimited secure vaults
• Unlimited document storage
• AI-powered Intel Reports
• Advanced threat monitoring
• Secure collaboration tools
• Military-grade AES-256 encryption
• Zero-knowledge architecture
• CloudKit sync across devices
• Biometric authentication
• Complete audit trails

SECURITY:
• Military-grade encryption (AES-256-GCM)
• Zero-knowledge architecture
• Dual-key vault approvals
• Geographic anomaly detection
• ML-powered threat analysis
• Complete access logging

PRICING:
One-time purchase - no subscriptions, no in-app purchases.

Terms of Service: https://khandoba.org/terms
Privacy Policy: https://khandoba.org/privacy
```

### Step 4: Update App Review Information

**App Review Notes:**

```
This is a paid app (one-time purchase) with no in-app purchases or subscriptions. All features are included with the purchase price. The app provides secure document management with encryption, vaults, and AI-powered threat monitoring.
```

### Step 5: Update Screenshots

1. **Remove Subscription Screenshots**
   - Remove any screenshots showing subscription options
   - Remove StoreView screenshots

2. **Update Screenshots**
   - Show main app features
   - Show vault management
   - Show document security
   - Make it clear it's a paid app (price will show in App Store)

### Step 6: Update What's New

**Version 1.0.0 Release Notes:**

```
Khandoba Secure Docs is now available as a one-time purchase app. All features are included - no subscriptions, no in-app purchases. Enjoy unlimited vaults, unlimited storage, AI intelligence, and advanced security features with a single purchase.
```

---

## 🔍 Verification Checklist

### App Store Connect:
- [ ] App price set (e.g., $5.99)
- [ ] In-app purchases removed from sale
- [ ] In-app purchases unlinked from app version
- [ ] App description updated (no mention of subscriptions)
- [ ] App Review notes updated
- [ ] Screenshots updated (no subscription UI)
- [ ] What's New section updated

### Code:
- [ ] Subscription checks removed from ContentView
- [ ] SubscriptionRequiredView no longer blocks access
- [ ] StoreView removed from navigation (if it was there)
- [ ] App builds successfully
- [ ] App allows full access without subscription

### Testing:
- [ ] App launches without subscription screen
- [ ] All features accessible
- [ ] No subscription-related UI visible
- [ ] App works as expected

---

## 📋 Important Notes

### 1. User Model Fields
- **Keep subscription fields in User model** for backward compatibility
- Fields like `isPremiumSubscriber` and `subscriptionExpiryDate` can remain
- They just won't be used or checked anymore

### 2. Existing Users
- Users who already have the app installed will continue to work
- No migration needed - app will just ignore subscription status

### 3. App Store Display
- App will show price (e.g., "$5.99") on download button
- **No "In-App Purchases" label** will appear
- Matches the examples: HotSchedules ($2.99), Shadowrocket ($2.99), Procreate Pocket ($5.99)

### 4. Revenue Model
- **One-time purchase:** User pays once, owns forever
- **No recurring revenue:** No monthly subscriptions
- **Simpler model:** Easier to manage, no subscription tracking

---

## 🚀 Next Steps

1. **Build New Binary**
   - Increment build number
   - Build and export IPA
   - Upload to App Store Connect

2. **Update App Store Connect**
   - Set app price
   - Remove in-app purchases
   - Update description
   - Update screenshots

3. **Submit for Review**
   - Submit new binary
   - App will show as paid app
   - No subscription review needed

4. **Monitor**
   - Check App Store listing shows price correctly
   - Verify no "In-App Purchases" label appears
   - Test purchase flow

---

## 📊 Comparison

### Before (Free with IAP):
- App shows "Get" button
- "In-App Purchases" label below
- Subscription required to use
- Monthly recurring revenue

### After (Paid App):
- App shows price (e.g., "$5.99") button
- **No "In-App Purchases" label**
- One-time purchase
- All features included
- No subscription management needed

---

## 🎯 Result

Your app will appear in the App Store like:
- **HotSchedules** - Shows "$2.99" with no IAP label
- **Shadowrocket** - Shows "$2.99" with no IAP label  
- **Procreate Pocket** - Shows "$5.99" with no IAP label

**Your app:** Shows "$5.99" (or your chosen price) with no IAP label ✅

---

**Last Updated:** December 16, 2025

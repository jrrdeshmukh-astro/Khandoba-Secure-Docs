# Subscription System

**Status:** ✅ Implemented  
**Type:** StoreKit 2 Monthly Subscription

---

## Overview

Khandoba Secure Docs uses a simple, transparent subscription model:

- **Price:** $5.99/month
- **Billing:** Through App Store (auto-renewable)
- **Features:** Everything included, unlimited
- **Family Sharing:** Up to 6 people
- **Free Trial:** None

---

## Features Included

### With Premium Subscription:

1. **Unlimited Vaults**
   - Create as many vaults as needed
   - Single-key or dual-key vaults
   - Source, Sink, or Mixed types

2. **Unlimited Storage**
   - No caps on document size
   - No caps on number of documents
   - All file types supported

3. **AI Intelligence**
   - Auto-naming with NLP
   - Document tagging
   - Intel Reports generation
   - Source/Sink classification

4. **Security Features**
   - Threat monitoring
   - Access maps with geolocation
   - Geofencing alerts
   - Anomaly detection

5. **HIPAA Compliance**
   - Document redaction
   - Version history
   - Audit trails
   - Secure sharing

6. **Media Capture**
   - Video recording
   - Voice memos
   - Document scanning
   - Bulk uploads

7. **Family Sharing**
   - Share with up to 6 family members
   - Each gets their own vaults
   - Managed through App Store

---

## Implementation

### StoreKit Configuration

**Product ID:** `com.khandoba.premium.monthly`  
**Type:** Auto-renewable subscription  
**Duration:** 1 month (renews automatically)

### Service: `SubscriptionService.swift`

```swift
@MainActor
final class SubscriptionService: ObservableObject {
    @Published var isSubscribed = false
    @Published var products: [Product] = []
    
    func requestProducts() async
    func purchase() async throws
    func restorePurchases() async
    func manageSubscription() async
}
```

### View: `StoreView.swift`

- Shows subscription status
- Lists premium features
- Subscribe/Manage button
- Restore purchases

---

## User Flow

### New User:
1. Sign in with Apple
2. Browse app (limited to viewing)
3. See "Premium" tab
4. View features
5. Subscribe for $5.99/month
6. Full access immediately

### Existing User:
1. Subscription renews automatically
2. Manage in iOS Settings → Subscriptions
3. Cancel anytime (no refund for current period)
4. Access continues until period ends

---

## App Store Connect Setup

### Required Steps:

1. **Create Subscription Group:**
   - Name: "Premium Features"
   - Reference: premium_features

2. **Create Subscription:**
   - Product ID: com.khandoba.premium.monthly
   - Display Name: Premium Subscription
   - Description: (see App Store metadata)
   - Duration: 1 month
   - Price: $5.99

3. **Set Availability:**
   - All territories
   - Family Sharing: Enabled

4. **Review Information:**
   - Screenshot: Optional (skip if upload fails)
   - Review notes: Describe premium features

---

## Revenue

### App Store Economics:

**First Year (85% → 70%):**
- Gross: $5.99
- Apple: -$1.80 (30%)
- Net: $4.19/month

**After Year 1 (85% → 85%):**
- Gross: $5.99
- Apple: -$0.90 (15%)
- Net: $5.09/month

**Retained subscriber value:**
- Year 1: $50.28
- Year 2+: $61.08/year

---

## Testing

### StoreKit Configuration File:

`Configuration.storekit` includes:
- Product ID
- Display name
- Price
- Duration

### Testing in Simulator:
1. Build & Run
2. Go to "Premium" tab
3. Tap "Subscribe Now"
4. Sandbox purchase (no charge)
5. Verify features unlock

### Testing on Device:
1. Use Sandbox tester account
2. Sign out of real App Store
3. Run from Xcode
4. Make test purchase
5. Verify subscription active

---

## Migration from Credit System

**OLD (Removed):**
- ❌ Credit purchases
- ❌ Per-action costs
- ❌ Balance tracking
- ❌ Credit deductions
- ❌ Purchase flow

**NEW (Current):**
- ✅ Simple subscription
- ✅ Everything unlimited
- ✅ Transparent pricing
- ✅ Family Sharing
- ✅ App Store managed

**All credit references removed from:**
- Models (deleted PaymentModels.swift)
- Services (deleted PaymentService.swift)
- Views (updated all UI)
- Documentation (this file)

---

## Support

### Common Questions:

**Q: Why can't I see subscription options?**
- Ensure you've created the subscription in App Store Connect
- Check that the product ID matches exactly
- Verify StoreKit configuration file

**Q: How do I cancel?**
- iOS Settings → [Your Name] → Subscriptions
- Select Khandoba Secure Docs
- Tap "Cancel Subscription"

**Q: Can I get a refund?**
- Subscriptions are non-refundable
- Contact Apple Support for exceptions

**Q: What happens if I cancel?**
- Access continues until period ends
- No partial refunds
- Can resubscribe anytime

---

## Future Enhancements

Potential additions:
- Annual plan (10-month price)
- Lifetime unlock option
- Business/team plans
- Additional tiers

---

**Last Updated:** December 2025  
**Version:** 1.0


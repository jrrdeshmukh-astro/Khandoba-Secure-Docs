# Subscriptions Feature

> Documentation for premium subscription system across platforms

---

## Overview

Khandoba Secure Docs offers premium subscriptions with family sharing, providing access to advanced features.

---

## Subscription Tiers

### Free Tier

**Included:**
- Basic vault management
- Document storage (limited)
- Basic encryption
- Core features

### Premium Tier

**Additional Features:**
- Unlimited storage
- Advanced AI features
- Intel Reports (Apple only)
- Priority support
- Family sharing

---

## Platform Implementation

### Apple (StoreKit 2)

**Implementation:**
- StoreKit 2 framework
- Subscription management
- Receipt validation
- Family sharing support

**Service:**
- `SubscriptionService.swift`
- Handles StoreKit subscriptions
- Validates receipts
- Manages subscription status

**Features:**
- Auto-renewable subscriptions
- Family sharing
- Promotional offers
- Subscription status sync

### Android (Play Billing)

**Implementation:**
- Play Billing Library
- Subscription management
- Purchase validation

**Service:**
- `SubscriptionService.kt`
- Handles Play Billing
- Validates purchases
- Manages subscription status

**Features:**
- Auto-renewable subscriptions
- Family library support
- Promotional pricing

### Windows (Microsoft Store)

**Status:** 🚧 In Development

**Implementation:**
- Microsoft Store APIs
- Subscription management

**Planned Features:**
- Auto-renewable subscriptions
- Family sharing

---

## Subscription Flow

### Purchase Flow

```
User selects subscription
    ↓
Platform Store (App Store / Play Store / Microsoft Store)
    ↓
Payment processing
    ↓
Receipt/Purchase validation
    ↓
Update subscription status in Supabase
    ↓
Enable premium features
```

### Validation Flow

```
App checks subscription status
    ↓
Query platform store (receipt validation)
    ↓
Update local status
    ↓
Sync with Supabase backend
    ↓
Enable/disable premium features
```

---

## Subscription Status

### Status Types

- **active** - Subscription is active
- **expired** - Subscription has expired
- **cancelled** - User cancelled
- **pending** - Purchase pending
- **trial** - In trial period

### Status Checking

**All Platforms:**
```swift/kotlin/csharp
subscriptionStatus == .active  // or equivalent
```

---

## Family Sharing

### Apple

**Implementation:**
- StoreKit family sharing
- Share across family members
- Automatic family member detection

### Android

**Implementation:**
- Google Play Family Library
- Share with family group
- Family member access

### Windows

**Status:** Planned for future

---

## Premium Features

### Available to Premium Users

1. **Unlimited Storage**
   - No storage limits
   - Unlimited documents

2. **Advanced AI Features**
   - Intel Reports (Apple)
   - Advanced document analysis
   - Enhanced ML capabilities

3. **Priority Support**
   - Faster response times
   - Priority assistance

4. **Family Sharing**
   - Share with family members
   - Family vaults

---

## Subscription Management

### User Actions

- **Subscribe** - Purchase subscription
- **Cancel** - Cancel auto-renewal
- **Restore** - Restore previous purchases
- **Upgrade/Downgrade** - Change subscription tier

### Service Actions

- **Validate** - Verify subscription status
- **Sync** - Sync with backend
- **Update** - Update subscription info

---

## Backend Integration

### Supabase Database

**User Table:**
- `is_premium_subscriber` - Boolean flag
- `subscription_expiry_date` - Expiry date

**Subscription Sync:**
- Subscription status stored in user profile
- Updated on validation
- Used for feature gating

---

## Feature Gating

### Implementation

```swift
// Apple
if subscriptionStatus == .active {
    // Enable premium features
}

// Android
if (subscriptionStatus == SubscriptionStatus.ACTIVE) {
    // Enable premium features
}

// Windows
if (subscriptionStatus == SubscriptionStatus.Active) {
    // Enable premium features
}
```

### Gated Features

- Intel Reports
- Advanced AI features
- Unlimited storage
- Family sharing

---

## Testing

### Sandbox Testing

**Apple:**
- StoreKit sandbox accounts
- Test subscriptions
- Sandbox receipt validation

**Android:**
- Google Play test accounts
- Test purchases
- License testing

**Windows:**
- Microsoft Store sandbox
- Test subscriptions

---

## Error Handling

### Common Issues

1. **Network errors** - Retry validation
2. **Invalid receipt** - Re-validate
3. **Expired subscription** - Show renewal prompt
4. **Payment issues** - Platform handles

### Fallback Behavior

- Grace period for expired subscriptions
- Cached status for offline mode
- Re-validation on app launch

---

**Last Updated:** December 2024

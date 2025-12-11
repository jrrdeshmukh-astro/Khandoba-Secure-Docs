# Restore Purchases Implementation

## Problem

After deleting an account and signing in again, users see the subscription screen even though their App Store subscription is still active. This happens because:

1. **Account deletion** removes the local user record (including subscription status)
2. **App Store subscription** remains active (tied to Apple ID, not app account)
3. **New user record** doesn't have subscription status set
4. **User needs a way** to restore their existing subscription

## Solution

### Added "Restore Purchases" Button

**Location**: `SubscriptionRequiredView.swift`

**Features**:
- Secondary button style (outlined, not filled)
- Calls `SubscriptionService.restorePurchases()`
- Syncs with App Store to find active subscriptions
- Updates user's subscription status in database
- Shows success/error messages
- Automatically refreshes view when subscription is restored

### Implementation Details

#### 1. UI Addition

```swift
// Restore Purchases Button
Button {
    restorePurchases()
} label: {
    if isRestoring {
        HStack {
            ProgressView()
                .tint(colors.textSecondary)
            Text("Restoring...")
        }
    } else {
        HStack {
            Image(systemName: "arrow.clockwise")
            Text("Restore Purchases")
        }
    }
}
.buttonStyle(SecondaryButtonStyle())
.disabled(isPurchasing || isRestoring)
```

#### 2. Restore Function

```swift
private func restorePurchases() {
    // 1. Call App Store sync
    try await subscriptionService.restorePurchases()
    
    // 2. Update purchased products
    await subscriptionService.updatePurchasedProducts()
    
    // 3. Check if subscription was found
    if subscriptionService.subscriptionStatus == .active {
        // 4. Notify view to refresh
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
        
        // 5. Show success message
        showRestoreSuccess = true
    }
}
```

#### 3. SubscriptionService.restorePurchases()

```swift
func restorePurchases() async throws {
    // Sync with App Store
    try await AppStore.sync()
    
    // Update purchased products from App Store
    await updatePurchasedProducts()
}
```

#### 4. Automatic Status Update

When `updatePurchasedProducts()` finds an active subscription:
- Updates `user.isPremiumSubscriber = true`
- Sets `user.subscriptionExpiryDate`
- Saves to database
- Posts `subscriptionStatusChanged` notification
- View automatically refreshes

## User Flow

### Scenario: Account Deleted, Subscription Still Active

1. **User deletes account** → Local data deleted
2. **User signs in again** → New user created
3. **App shows subscription screen** → Because new user has no subscription status
4. **User taps "Restore Purchases"** → Calls App Store sync
5. **App Store returns active subscription** → Subscription detected
6. **User's subscription status updated** → `isPremiumSubscriber = true`
7. **View refreshes** → Subscription screen disappears, main app appears
8. **Success message shown** → "Your subscription has been restored"

## Testing

### Manual Test Steps

1. **Purchase subscription** (through App Store or in-app)
2. **Delete account** (Profile → Delete Account)
3. **Sign in again** with same Apple ID
4. **See subscription screen** (expected)
5. **Tap "Restore Purchases"**
6. **Expected**: 
   - Loading indicator shows "Restoring..."
   - Success alert appears
   - Subscription screen disappears
   - Main app appears
7. **Check console logs**:
   - `✅ Subscription restored successfully`
   - `Subscription status: active`
   - `Purchased products: ["com.khandoba.premium.monthly"]`

### Edge Cases

1. **No active subscription**:
   - Shows error: "No active subscription found"
   - User can still purchase new subscription

2. **Network error**:
   - Shows error: "Failed to restore purchases: [error]"
   - User can retry

3. **Multiple subscriptions**:
   - Finds all active subscriptions
   - Updates status based on most recent/active one

## Benefits

✅ **User-friendly**: Easy way to restore existing subscription
✅ **App Store compliant**: Required for subscription apps
✅ **Automatic**: View refreshes automatically after restore
✅ **Clear feedback**: Success/error messages guide user
✅ **Handles edge cases**: Network errors, no subscription, etc.

## Status

✅ **IMPLEMENTED**

- Restore Purchases button added to subscription screen
- Restore function implemented
- Success/error handling added
- View refresh on successful restore
- App Store sync integration

## Related Files

- `SubscriptionRequiredView.swift` - UI and restore function
- `SubscriptionService.swift` - Restore purchases logic
- `ContentView.swift` - Subscription status checking
- `Khandoba_Secure_DocsApp.swift` - Notification names

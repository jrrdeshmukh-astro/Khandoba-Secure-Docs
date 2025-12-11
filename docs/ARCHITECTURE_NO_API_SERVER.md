# Architecture: No Custom API Server Required

## Overview

Khandoba Secure Docs is designed to work **entirely client-side** using Apple's cloud services. **No custom backend API server is needed.**

## Architecture

### Data Sync: CloudKit
- **SwiftData** with CloudKit integration handles all data persistence
- Automatic sync across devices via Apple's CloudKit
- No custom API endpoints required
- Zero-knowledge architecture maintained client-side

### Authentication: Apple Sign In
- Uses Apple's native authentication
- No custom authentication server needed
- User credentials managed by Apple

### Subscriptions: StoreKit
- Auto-renewable subscriptions handled by Apple
- Payment processing via App Store
- No custom billing API needed

### Push Notifications: APNs
- Apple Push Notification Service (APNs)
- No custom notification server needed

## Why No API Server?

1. **CloudKit provides all sync functionality**
   - Automatic data synchronization
   - Conflict resolution
   - Background sync
   - Cross-device access

2. **Apple services handle infrastructure**
   - Authentication (Apple Sign In)
   - Payments (StoreKit)
   - Notifications (APNs)
   - Cloud storage (CloudKit)

3. **Zero-knowledge architecture**
   - All encryption happens client-side
   - Server (CloudKit) never sees unencrypted data
   - No need for custom encryption endpoints

4. **Simplified architecture**
   - No server maintenance
   - No API versioning
   - No server scaling concerns
   - Lower operational costs

## AppConfig.apiBaseURL

The `apiBaseURL` in `AppConfig.swift` is **not used** and can be safely ignored or removed. It was likely added as a placeholder for future features that were never implemented.

## When Would You Need an API Server?

You would only need a custom API server if you wanted to:

1. **Custom analytics** (beyond Apple's analytics)
2. **Custom authentication** (beyond Apple Sign In)
3. **Custom billing** (beyond StoreKit)
4. **Server-side processing** (ML models, document analysis)
5. **Third-party integrations** (webhooks, external APIs)

For the current architecture, **none of these are required.**

## Current Data Flow

```
User Device
    ↓
SwiftData (Local Storage)
    ↓
CloudKit (Apple's Cloud Sync)
    ↓
Other User Devices (via CloudKit)
```

**No custom API server in the path.**

## Benefits

✅ **No server costs** - Apple handles infrastructure  
✅ **No server maintenance** - No updates, patches, or monitoring  
✅ **Automatic scaling** - CloudKit scales automatically  
✅ **Better privacy** - Data stays within Apple's ecosystem  
✅ **Simpler architecture** - Less code, fewer failure points  
✅ **Faster development** - No backend development needed  

## Conclusion

**You do not need a production server.** The app is fully functional using only Apple's cloud services. The `apiBaseURL` configuration is unused and can be removed or left as-is for potential future use.

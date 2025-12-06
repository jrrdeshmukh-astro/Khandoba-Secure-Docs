# CloudKit API Implementation Guide

> **Last Updated:** December 2024
> 
> Complete guide to CloudKit integration using CloudKit Framework API

## Overview

The app uses **two complementary CloudKit approaches**:

1. **SwiftData with CloudKit** (Automatic Sync)
   - Automatic sync via `ModelConfiguration(cloudKitDatabase: .automatic)`
   - No code needed - SwiftData handles everything
   - Works seamlessly with `@Model` classes

2. **CloudKit Framework API** (Direct Operations)
   - `CloudKitAPIService` for direct CloudKit operations
   - Sync status monitoring
   - Token verification
   - Health diagnostics

## Architecture

### SwiftData + CloudKit (Primary)

**How It Works:**
- SwiftData models automatically sync to CloudKit
- No manual sync calls needed
- Uses user's iCloud account for authentication
- Handles conflicts automatically

**Configuration:**
```swift
let modelConfiguration = ModelConfiguration(
    schema: schema,
    cloudKitDatabase: .automatic  // Enables CloudKit sync
)
```

### CloudKit Framework API (Monitoring)

**Purpose:**
- Verify sync status
- Monitor CloudKit health
- Query records directly when needed
- Provide diagnostics

**Service:** `CloudKitAPIService.swift`

## Implementation Details

### CloudKitAPIService Features

1. **Sync Status Monitoring**
   ```swift
   await cloudKitAPI.checkSyncStatus()
   // Returns: .syncing, .synced, or .error
   ```

2. **Token Verification**
   ```swift
   let isValid = try await cloudKitAPI.verifyNomineeToken(token)
   // Verifies nominee invitation token exists in CloudKit
   ```

3. **Health Monitoring**
   ```swift
   let health = await cloudKitAPI.monitorSyncHealth()
   // Returns: SyncHealthReport with account status, sync info
   ```

4. **Direct Record Access**
   ```swift
   let nominee = try await cloudKitAPI.getNomineeByToken(token)
   // Gets nominee record directly from CloudKit
   ```

### Integration with NomineeService

The `NomineeService` now integrates with `CloudKitAPIService`:

1. **When loading invitations:**
   - First checks local SwiftData (fast)
   - If not found, verifies with CloudKit API
   - Waits for SwiftData sync if token exists in CloudKit

2. **Benefits:**
   - Faster local lookups
   - Fallback verification via CloudKit API
   - Better error messages

## Configuration

### AppConfig Settings

```swift
static let cloudKitContainer = "iCloud.com.khandoba.securedocs"
static let cloudKitKeyID = "PR62QK662L"  // For reference (not used in framework)
static let cloudKitTeamID = "YOUR_TEAM_ID"  // Set your Apple Developer Team ID
```

### Environment Detection

- **Development**: Used in DEBUG builds and TestFlight
- **Production**: Used in App Store releases

```swift
#if DEBUG
self.environment = .development
#else
self.environment = .production
#endif
```

## Authentication

### Client-Side (CloudKit Framework)

- **Automatic**: Uses user's iCloud account
- **No API keys needed**: CloudKit framework handles auth
- **Secure**: Managed by iOS system

### Server-Side (REST API - Not Implemented)

If you need server-side CloudKit operations:
- Would require CloudKit REST API
- Uses JWT tokens with .p8 key
- For webhooks, server-to-server operations
- **Note**: Not needed for iOS app - CloudKit framework is sufficient

## Testing in TestFlight

### Prerequisites

1. **CloudKit Container Created**
   - App Store Connect → CloudKit Dashboard
   - Container: `iCloud.com.khandoba.securedocs`

2. **Same iCloud Account**
   - Both devices must use same iCloud account
   - iCloud Drive must be enabled

3. **Internet Connection**
   - Required for CloudKit sync

### Test Flow

1. **Device A (Owner):**
   ```
   Create nominee → SwiftData saves locally
   → CloudKit syncs automatically
   → CloudKitAPIService can verify
   ```

2. **Device B (Nominee):**
   ```
   Receive invitation → Load token
   → NomineeService checks local SwiftData
   → If not found, CloudKitAPIService verifies
   → SwiftData syncs from CloudKit
   → Invitation found
   ```

### Monitoring

**Console Output:**
```
✅ ModelContainer created successfully with CloudKit sync enabled
✅ Nominee created: [Name]
📤 CloudKit sync: Nominee record will sync automatically
🔍 Loading invitation with token: [UUID]
   🔄 Not found locally, verifying with CloudKit API...
   ✅ Token verified in CloudKit, waiting for SwiftData sync...
✅ Invitation found: [Name]
```

## Error Handling

### Common Issues

1. **Container Not Available**
   - Check entitlements file
   - Verify container ID matches App Store Connect

2. **Account Status Issues**
   - No iCloud account → User must sign in
   - Restricted account → Check iCloud settings
   - Temporarily unavailable → Retry later

3. **Sync Delays**
   - Normal: 10-30 seconds
   - Network issues → Check connectivity
   - CloudKit quota → Check dashboard

## Best Practices

1. **Primary: Use SwiftData**
   - Let SwiftData handle sync automatically
   - Only use CloudKit API for verification/monitoring

2. **Fallback Verification**
   - Use CloudKit API when local lookup fails
   - Provides better user experience

3. **Health Monitoring**
   - Check sync health periodically
   - Log sync status for debugging

4. **Error Messages**
   - Provide clear error messages
   - Suggest solutions (wait, check iCloud, etc.)

## Production Checklist

- [x] CloudKit enabled in ModelConfiguration
- [x] CloudKitAPIService implemented
- [x] NomineeService integration
- [x] Enhanced logging
- [ ] CloudKit container created in App Store Connect
- [ ] Team ID configured in AppConfig
- [ ] TestFlight testing completed
- [ ] Sync latency verified
- [ ] Error handling tested

## Related Documentation

- [CloudKit Framework Documentation](https://developer.apple.com/documentation/cloudkit)
- [SwiftData with CloudKit](https://developer.apple.com/documentation/swiftdata)
- [CloudKit Dashboard Guide](https://developer.apple.com/cloudkit/)

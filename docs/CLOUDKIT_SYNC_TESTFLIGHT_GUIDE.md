# CloudKit Sync TestFlight Testing Guide

> **Last Updated:** December 2024
> 
> Complete guide for testing CloudKit sync of nominee invitations in TestFlight

## ✅ CloudKit Configuration

### What Was Enabled

1. **ModelConfiguration**: Changed from `.none` to `.automatic`
   - Location: `Khandoba_Secure_DocsApp.swift`
   - Enables automatic CloudKit sync for all SwiftData models

2. **Nominee Model Updates**:
   - Added `@Attribute(.unique)` to `id` and `inviteToken`
   - Ensures CloudKit can properly sync and deduplicate records

3. **CloudKit Container**: Already configured
   - Container ID: `iCloud.com.khandoba.securedocs`
   - Location: `Khandoba_Secure_Docs.entitlements`

4. **CloudKit API Service**: New service for direct CloudKit operations
   - Location: `CloudKitAPIService.swift`
   - Provides sync status monitoring
   - Token verification via CloudKit API
   - Health monitoring and diagnostics

5. **Enhanced Logging**: Added CloudKit sync status logging
   - Tracks when nominees are created
   - Logs when invitations are loaded
   - Shows sync status in console
   - Integrates with CloudKit API for verification

## 🧪 TestFlight Testing Steps

### Prerequisites

1. **Both devices must:**
   - Be signed into the same iCloud account
   - Have iCloud Drive enabled
   - Have the app installed from TestFlight
   - Be connected to the internet

2. **CloudKit Setup:**
   - CloudKit container must be configured in App Store Connect
   - Container ID: `iCloud.com.khandoba.securedocs`

### Test Scenario 1: Basic Nominee Invitation Flow

**Device A (Owner):**
1. Open app → Sign in with Apple
2. Create or open a vault
3. Go to Sharing → Invite Nominees
4. Select a contact
5. Send invitation via iMessage
6. **Check console logs:**
   ```
   ✅ Nominee created: [Name]
   Token: [UUID]
   📤 CloudKit sync: Nominee record will sync automatically
   ```

**Device B (Nominee):**
1. Receive iMessage invitation
2. Tap deep link: `khandoba://invite?token=[UUID]`
3. OR manually enter token via Profile → Accept Invitation
4. App should open and show invitation details
5. Tap "Accept Invitation"
6. **Check console logs:**
   ```
   🔍 Loading invitation with token: [UUID]
   📥 Checking local database and CloudKit sync...
   ✅ Invitation found: [Name]
   ✅ Invitation accepted
   📤 CloudKit sync: Status update will sync to owner's device
   ```

**Device A (Owner - Verification):**
1. Wait 10-30 seconds for CloudKit sync
2. Go to Vault → Sharing → Manage Nominees
3. Nominee should show status: "accepted"
4. Open vault → Nominee should have access

### Test Scenario 2: Manual Token Entry (TestFlight Fallback)

**Device A (Owner):**
1. Send invitation via iMessage
2. Copy the token from the message

**Device B (Nominee):**
1. Open app → Profile tab
2. Tap "Accept Invitation" in Settings
3. Paste token manually
4. Tap "Load Invitation"
5. Should see invitation details
6. Accept invitation

### Test Scenario 3: Cross-Device Sync Verification

**Device A (Owner):**
1. Create nominee invitation
2. Wait for CloudKit sync (check console)
3. Close app completely
4. Reopen app
5. Check nominee status (should persist)

**Device B (Nominee):**
1. Accept invitation
2. Wait for CloudKit sync
3. Close app
4. Reopen app
5. Check vault access (should persist)

## 🔍 Troubleshooting

### Issue: "Invalid or expired invitation token"

**Possible Causes:**
1. CloudKit sync hasn't completed yet
   - **Solution**: Wait 10-30 seconds and try again
   - Check internet connection on both devices

2. Different iCloud accounts
   - **Solution**: Both devices must use the same iCloud account
   - Check Settings → [Your Name] → iCloud

3. CloudKit container not configured
   - **Solution**: Verify container ID in App Store Connect
   - Check entitlements file has correct container ID

4. iCloud Drive disabled
   - **Solution**: Enable iCloud Drive in Settings → [Your Name] → iCloud → iCloud Drive

### Issue: Nominee not appearing on owner's device

**Possible Causes:**
1. CloudKit sync delay
   - **Solution**: Wait up to 1 minute for sync
   - Pull to refresh the nominees list

2. Network connectivity
   - **Solution**: Ensure both devices have internet
   - Check iCloud status in Settings

3. CloudKit quota exceeded
   - **Solution**: Check CloudKit dashboard in App Store Connect
   - Free tier: 1GB storage, 2GB transfer/day

### Issue: Deep link doesn't work in TestFlight

**Solution**: Use manual token entry
1. Profile → Accept Invitation
2. Paste token from iMessage
3. Load invitation

## 📊 CloudKit Sync Monitoring

### Console Logs to Watch For

**Successful Sync:**
```
✅ ModelContainer created successfully with CloudKit sync enabled
   CloudKit Container: iCloud.com.khandoba.securedocs
✅ Nominee created: [Name]
📤 CloudKit sync: Nominee record will sync automatically
🔍 Loading invitation with token: [UUID]
📥 Checking local database and CloudKit sync...
✅ Invitation found: [Name]
```

**CloudKit API Verification:**
```
🔍 Loading invitation with token: [UUID]
   🔄 Not found locally, verifying with CloudKit API...
   ✅ Token verified in CloudKit, waiting for SwiftData sync...
```

**Sync Issues:**
```
⚠️ Falling back to local-only storage (CloudKit sync disabled)
❌ Invitation not found with token: [UUID]
💡 If this is a new invitation, wait a few seconds for CloudKit sync
⚠️ CloudKit API verification failed: [error]
```

### Using CloudKitAPIService

The new `CloudKitAPIService` provides:
- **Sync Status Monitoring**: Check CloudKit sync health
- **Token Verification**: Verify nominee tokens directly in CloudKit
- **Health Reports**: Get detailed sync status and account information

**Example Usage:**
```swift
let cloudKitAPI = CloudKitAPIService()

// Check sync status
await cloudKitAPI.checkSyncStatus()

// Verify token
let isValid = try await cloudKitAPI.verifyNomineeToken(token)

// Get health report
let health = await cloudKitAPI.monitorSyncHealth()
```

### CloudKit Dashboard

Monitor sync status in:
- App Store Connect → CloudKit Dashboard
- Check record counts
- Monitor sync errors
- View sync latency

## ✅ Success Criteria

The test is successful when:

1. ✅ Owner creates nominee → Record appears in CloudKit
2. ✅ Nominee receives invitation → Can load invitation details
3. ✅ Nominee accepts → Status updates sync to owner's device
4. ✅ Owner sees nominee as "accepted" → Within 30 seconds
5. ✅ Nominee can access vault → When owner unlocks it
6. ✅ Data persists → After app restart on both devices

## 🚀 Production Readiness Checklist

- [x] CloudKit enabled in ModelConfiguration
- [x] Unique attributes on Nominee model
- [x] CloudKit container configured in entitlements
- [x] Enhanced logging for sync status
- [x] Manual token entry fallback
- [ ] CloudKit container created in App Store Connect
- [ ] TestFlight build with CloudKit enabled
- [ ] Cross-device testing completed
- [ ] Sync latency verified (< 30 seconds)
- [ ] Error handling tested

## 📝 Notes

- CloudKit sync is automatic - no manual sync calls needed
- Sync typically happens within 10-30 seconds
- Both devices must be online for sync to work
- Same iCloud account required for cross-device sync
- CloudKit uses iCloud Drive for data transfer
- Free tier: 1GB storage, 2GB transfer/day (usually sufficient)

## 🔗 Related Documentation

- [Apple CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [SwiftData with CloudKit](https://developer.apple.com/documentation/swiftdata)
- [CloudKit Dashboard Guide](https://developer.apple.com/cloudkit/)

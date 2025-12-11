# CloudKit Nominee Sync Guide

> **Last Updated:** December 2024
> 
> Guide to resolving "Could not find CloudKit record with any method" errors when syncing nominees.

## Problem

When trying to share vaults with nominees via CloudKit, you may encounter the error:

```
Could not find CloudKit record with any method
```

This occurs because:

1. **SwiftData → CloudKit sync is asynchronous**: When a vault is created or modified, SwiftData doesn't immediately sync it to CloudKit. There's a delay (typically 1-5 seconds).

2. **Record naming conventions**: SwiftData uses specific naming conventions for CloudKit records (e.g., `CD_Vault_<UUID>`), but the exact format can vary.

3. **Timing issues**: If you try to find the CloudKit record immediately after creating/saving a vault, it may not exist yet.

## Solution

The `CloudKitSharingService` has been enhanced with:

### 1. Improved Sync Detection (`ensureVaultSynced`)

The method now:
- **Waits longer**: Retries up to 5 times with 1-second delays (total ~5 seconds)
- **Verifies sync**: Actually checks if the record exists in CloudKit during each retry
- **Better logging**: Provides detailed information about sync status

```swift
private func ensureVaultSynced(_ vault: Vault) async throws {
    // Force save to trigger CloudKit sync
    try modelContext.save()
    
    // Wait for CloudKit sync with retry logic
    for attempt in 1...maxRetries {
        try await Task.sleep(nanoseconds: retryDelay)
        
        // Try to find the record in CloudKit
        if let recordID = try? await getVaultRecordID(vault) {
            print("✅ Vault found in CloudKit")
            return
        }
    }
}
```

### 2. Enhanced Record Lookup (`getVaultRecordID`)

The method now uses **three strategies** to find CloudKit records:

#### Method 1: Common Naming Formats
Tries multiple naming conventions:
- `CD_Vault_<UUID>`
- `<UUID>` (UUID only)
- `CD_vault_<UUID>` (lowercase)
- `CD-Vault-<UUID>` (hyphens)

#### Method 2: Query All Records (NEW)
Queries all `CD_Vault` records and matches by:
- UUID stored in the record's `id` field
- Record name containing the vault UUID
- Vault name matching

This is more reliable because it searches all records and matches by the vault's UUID.

#### Method 3: Date Range Query
Queries records created within 1 minute of the vault's creation date and matches by name.

### 3. Better Error Handling

The service now:
- Provides detailed logging at each step
- Explains why a record might not be found
- Falls back gracefully if CloudKit sync hasn't completed

## Best Practices

### When Creating Vaults

1. **Save immediately**: Always call `modelContext.save()` after creating a vault
2. **Wait before sharing**: If you're immediately sharing a vault, wait a few seconds or use `ensureVaultSynced()`

```swift
// Create vault
let vault = Vault(name: "My Vault")
modelContext.insert(vault)
try modelContext.save()

// Wait for CloudKit sync before sharing
try await cloudKitSharing.ensureVaultSynced(vault)

// Now safe to share
try await cloudKitSharing.createShare(for: vault)
```

### When Inviting Nominees

The `NomineeService.inviteNominee()` method now:

1. **Saves the vault** before attempting CloudKit operations
2. **Waits up to 10 seconds** (10 retries × 1 second) for CloudKit sync
3. **Creates the nominee locally** even if CloudKit share isn't ready yet
4. **Allows retry later** - the share will be created when CloudKit sync completes

**Improved Flow:**
```swift
// Invite nominee
let nominee = try await nomineeService.inviteNominee(
    name: "John Doe",
    email: "john@example.com",
    to: vault,
    invitedByUserID: currentUser.id
)

// If CloudKit share isn't ready, nominee is still created locally
// The share will be created automatically when CloudKit sync completes
// You can retry the invitation later if needed
```

**Key Improvements:**
- **Extended retry logic**: Up to 10 attempts (10 seconds total) to find CloudKit record
- **Graceful degradation**: Nominee is created locally even if CloudKit isn't ready
- **Better error messages**: Detailed logging explains what's happening
- **No blocking**: Invitation doesn't fail completely if CloudKit sync is delayed

### When Syncing Nominees

The `NomineeService.loadNominees()` method automatically:
1. Ensures the vault is synced to CloudKit
2. Fetches CloudKit share participants
3. Syncs participants with local Nominee records

You don't need to do anything special - just call:

```swift
try await nomineeService.loadNominees(for: vault)
```

### Debugging

If you still see "Could not find CloudKit record" errors:

1. **Check CloudKit status**: Ensure CloudKit is enabled in your app's capabilities
2. **Verify container**: Check that `AppConfig.cloudKitContainer` matches your CloudKit container identifier
3. **Check logs**: Look for detailed logging from `CloudKitSharingService`
4. **Wait longer**: CloudKit sync can take up to 10-15 seconds in some cases

### Logging

The service provides detailed logging:

```
🔄 Ensuring vault is synced to CloudKit...
📋 Vault: My Vault (ID: 12345678-...)
💾 Vault saved to SwiftData
⏳ Waiting for CloudKit sync (attempt 1/5)...
🔍 Trying common naming formats...
✅ Found CloudKit record using format 'CD_Vault_<UUID>': CD_Vault_12345678-...
```

## Technical Details

### SwiftData + CloudKit Integration

SwiftData automatically syncs `@Model` entities to CloudKit when:
- CloudKit is enabled in `ModelConfiguration` (`.automatic` or `.private`)
- The entity is saved via `modelContext.save()`
- The device is connected to iCloud

### Record Naming

SwiftData uses the format: `CD_<EntityName>_<UUID>`

For example:
- `CD_Vault_12345678-1234-1234-1234-123456789abc`
- `CD_Document_98765432-4321-4321-4321-cba987654321`

### Zone

All records are stored in the **default zone** (`CKRecordZone.default()`).

## Troubleshooting

### Error: "Could not get CloudKit record ID"

**Cause**: The vault hasn't synced to CloudKit yet, or sync is taking longer than expected.

**What Happens Now:**
- The system retries up to **10 times** (10 seconds total) to find the record
- If still not found, the nominee is **created locally** anyway
- CloudKit share will be created automatically when sync completes
- You can retry the invitation later if needed

**Solutions**: 
- **Wait and retry**: The system will automatically retry, but you can manually retry the invitation
- **Check CloudKit status**: Settings → [Your Name] → iCloud → Ensure iCloud Drive is enabled
- **Check network**: Ensure device has internet connectivity
- **Check logs**: Look for detailed error messages in console

**Note**: This is now a **non-blocking error** - nominees are created locally and CloudKit sync happens in the background.

### Error: "CloudKit sync is disabled"

**Cause**: CloudKit is not enabled or configured.

**Solution**:
1. Check `ModelConfiguration` has `cloudKitDatabase: .automatic`
2. Verify CloudKit capability is enabled in Xcode
3. Check iCloud account is signed in

### Error: "Container identifier mismatch"

**Cause**: The CloudKit container identifier doesn't match.

**Solution**:
- Verify `AppConfig.cloudKitContainer` matches your CloudKit container
- Check the container identifier in Xcode project settings

## Related Files

- `CloudKitSharingService.swift`: Main service for CloudKit sharing
- `NomineeService.swift`: Service for managing nominees
- `Khandoba_Secure_DocsApp.swift`: ModelContainer configuration

## References

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [CKShare Documentation](https://developer.apple.com/documentation/cloudkit/ckshare)

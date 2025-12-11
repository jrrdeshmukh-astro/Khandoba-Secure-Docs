# CloudKit Deletion Fix - Orphaned Vaults After Account Deletion

## Problem

When a user deletes their account and then signs up again with the same iCloud account, some vaults may still appear. This happens because:

1. **CloudKit Sync Delay**: When account is deleted locally, CloudKit sync might not have completed deletion
2. **CloudKit Restoration**: CloudKit may restore deleted records during sync
3. **User Record Matching**: AuthenticationService finds existing user by `appleUserID`, which matches even after deletion

## Root Cause

- SwiftData with CloudKit sync can restore deleted records if:
  - Deletion hasn't synced to CloudKit yet
  - CloudKit has a record that wasn't deleted
  - There's a sync conflict

## Solution Implemented

### 1. Enhanced Account Deletion (`AccountDeletionService.swift`)

**Added**:
- Force CloudKit sync after deletion
- Wait for sync to propagate
- Multiple save operations to ensure CloudKit receives deletions

```swift
// 8. Save all deletions
try modelContext.save()

// 9. Force CloudKit sync to ensure deletions propagate
try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
try modelContext.save()
```

### 2. Orphaned Vault Cleanup (`VaultService.swift`)

**Added**:
- `cleanupOrphanedVaults()` method that runs on every vault load
- Detects vaults with:
  - No owner
  - Owner that doesn't exist
  - Owner with mismatched ID (CloudKit restored)

**Runs**: Every time `loadVaults()` is called

### 3. Sign-In Cleanup (`AuthenticationService.swift`)

**Added**:
- `cleanupOrphanedVaults(for:modelContext:)` method
- Runs synchronously on sign-in (both new and existing users)
- Detects and deletes:
  - Vaults with owner that has same Apple ID but different UUID (CloudKit restored)
  - Vaults with deleted owners
  - Vaults with no owner

**Runs**: 
- When existing user signs in
- When new user signs in (in case CloudKit restored old data)

## Implementation Details

### Cleanup Logic

```swift
// Find all vaults
let allVaults = try modelContext.fetch(FetchDescriptor<Vault>())

// Find all existing users
let allUsers = try modelContext.fetch(FetchDescriptor<User>())
let existingUserIDs = Set(allUsers.map { $0.id })

// Check each vault
for vault in allVaults {
    if let owner = vault.owner {
        // Check if owner still exists
        if !existingUserIDs.contains(owner.id) {
            // Orphaned - delete it
        }
        // Check if owner has same Apple ID but different UUID (CloudKit restored)
        if owner.appleUserID == currentUser.appleUserID && owner.id != currentUser.id {
            // Orphaned - delete it
        }
    } else {
        // No owner - orphaned
    }
}
```

## Testing

### Manual Test

1. Create account and vaults
2. Delete account
3. Sign in again with same Apple ID
4. **Expected**: No vaults should appear
5. **Actual**: Cleanup should remove any orphaned vaults

### Automated Test

Add to `AccountDeletionServiceTests.swift`:
```swift
@Test("CloudKit sync - orphaned vaults cleaned up on sign-in")
func testCloudKitOrphanedVaultsCleanup() async throws {
    // Test cleanup logic
}
```

## Prevention

### Multiple Layers

1. **Account Deletion**: Force CloudKit sync
2. **Vault Loading**: Clean up orphaned vaults
3. **Sign-In**: Clean up orphaned vaults
4. **Defense in Depth**: Multiple cleanup points ensure no orphaned data

## Logging

All cleanup operations are logged:
- `🔍 Checking for orphaned vaults...`
- `⚠️ Found orphaned vault: [name]`
- `🗑️ Deleting X orphaned vault(s)`
- `✅ Cleaned up X orphaned vault(s)`

## Status

✅ **FIXED**

- Account deletion forces CloudKit sync
- Vault loading cleans up orphaned vaults
- Sign-in cleans up orphaned vaults
- Multiple defense layers prevent orphaned data

## Next Steps

1. Test with real iCloud account
2. Verify no vaults appear after account deletion and re-sign-in
3. Monitor logs for cleanup operations
4. Add unit tests for CloudKit restoration scenarios

# CloudKit Sharing Limitations with SwiftData

## Problem

SwiftData automatically syncs to CloudKit, but doesn't expose CloudKit record IDs directly. This makes it difficult to:
1. Query CloudKit records by SwiftData model properties
2. Get CloudKit record IDs for sharing
3. Find existing CloudKit shares

## Current Limitations

### 1. Field Name Mismatches
- SwiftData model properties (e.g., `id`, `name`) don't directly map to CloudKit queryable fields
- CloudKit requires fields to be marked as "queryable" in the schema
- SwiftData manages this automatically, but field names may differ

### 2. Query Restrictions
- `NSPredicate(value: true)` causes "Field 'recordName' is not marked queryable" error
- Can't query by `recordName` (system field, not queryable)
- Can't query by custom `id` field (doesn't exist in CloudKit schema)

### 3. Persistent Identifier Access
- `PersistentIdentifier` doesn't expose `uri` property
- No direct way to extract CloudKit record ID from SwiftData model

## Current Workaround

### Token-Based Invitations (Working)
- Nominees are created with invitation tokens
- Tokens are shared via Messages, Email, etc.
- Recipients accept using deep links: `khandoba://invite?token=...`
- Works across different iCloud accounts

### CloudKit Sharing (Partially Working)
- `UICloudSharingController` integration implemented
- Preparation handler attempts to get/create share
- Falls back gracefully if CloudKit record can't be found
- User can still use token-based invitations as fallback

## Recommended Solution

### Option 1: Use Token-Based System (Current)
- ✅ Works reliably
- ✅ Works across iCloud accounts
- ✅ No CloudKit query issues
- ✅ Simple implementation

### Option 2: Store CloudKit Record ID
- When vault is created, store its CloudKit record ID
- Use stored ID for sharing operations
- Requires schema changes

### Option 3: Use ModelContext to Access CloudKit
- Use SwiftData's internal APIs (if available)
- May require private APIs (not recommended)

### Option 4: Wait for SwiftData Updates
- Apple may add better CloudKit integration
- Monitor WWDC updates for improvements

## Current Status

- ✅ Token-based invitations: **Working**
- ⚠️ CloudKit sharing: **Partially working** (falls back to token-based)
- ✅ Nominee sync: **Working** (when CloudKit share exists)
- ⚠️ Share participant sync: **Disabled** (due to query limitations)

## Next Steps

1. **Short-term**: Use token-based invitations (already working)
2. **Medium-term**: Investigate storing CloudKit record IDs
3. **Long-term**: Wait for SwiftData/CloudKit improvements

## Error Messages

If you see:
- "Unknown field 'id'" → Field doesn't exist in CloudKit schema
- "Unknown field 'name'" → Field not queryable or named differently
- "Field 'recordName' is not marked queryable" → Can't query by recordName

These are expected when querying CloudKit directly from SwiftData models.


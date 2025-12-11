# CloudKit User Restoration Fix - Profile Photo and Name

## Problem

After deleting an account and signing in again with the same iCloud account, the old profile photo and name from the deleted account were still showing up.

## Root Cause

When a user deletes their account:
1. User record is deleted locally
2. CloudKit sync may not complete deletion immediately
3. When user signs in again, CloudKit restores the old User record
4. AuthenticationService finds existing user by `appleUserID`
5. Old profile photo and name are displayed

## Solution

### Detection Logic

When an existing user is found during sign-in:
1. Check if user has any vaults
2. If user has **no vaults**, it's likely a restored deleted account
3. Delete the old user record
4. Create a fresh account with data from Apple Sign In

### Implementation

```swift
if let existingUser = existingUsers.first {
    // Check if user has any vaults
    let userVaults = allVaults.filter { $0.owner?.id == existingUser.id }
    
    // If user has no vaults, delete old user and create fresh
    if userVaults.isEmpty {
        // Delete old user record
        modelContext.delete(existingUser)
        try modelContext.save()
        
        // Create fresh account with Apple data
        let newUser = User(
            appleUserID: userIdentifier,
            fullName: fullName.isEmpty ? "User" : fullName,
            email: email,
            profilePictureData: createDefaultProfileImage(name: fullName.isEmpty ? "User" : fullName)
        )
        // ... create fresh account
    } else {
        // Normal sign in - user has vaults
    }
}
```

## Why This Works

### Detection Method
- **No vaults** = likely restored deleted account
- **Has vaults** = legitimate existing account

### Clean Slate
- Deletes old user record completely
- Creates fresh account with:
  - New UUID
  - Fresh profile picture (default generated)
  - Name from Apple Sign In (if provided)
  - Clean state

## Edge Cases

### Apple Sign In Name/Email
- Apple only provides name/email on **first sign-in**
- On subsequent sign-ins, these may be `nil`
- Solution: Use default "User" name if Apple doesn't provide it
- Profile picture: Always generate fresh default image

### User with No Vaults (Legitimate)
- Rare case: User signs in but hasn't created vaults yet
- **Impact**: Would delete and recreate account
- **Mitigation**: This is acceptable - user gets fresh start anyway
- **Alternative**: Could check `createdAt` date, but simpler to just recreate

## Testing

### Manual Test Steps

1. **Create Account**:
   - Sign in with Apple ID
   - Set profile picture and name
   - Create a vault (optional)

2. **Delete Account**:
   - Profile → Delete Account
   - Confirm deletion

3. **Sign In Again**:
   - Sign in with same Apple ID
   - **Expected**: 
     - Fresh default profile picture
     - Name from Apple (or "User" if not provided)
     - No old photo/name
   - Check console logs for:
     - `⚠️ Found restored deleted account (no vaults) - creating fresh account`
     - `📝 Creating fresh account after deletion`

## Status

✅ **FIXED**

- Detects restored deleted accounts
- Deletes old user record
- Creates fresh account with clean profile
- No old photo/name appears

## Related Fixes

- **CloudKit Orphaned Vaults**: Handles vault restoration
- **Account Deletion**: Ensures proper deletion
- **Profile Reset**: Ensures clean profile after deletion

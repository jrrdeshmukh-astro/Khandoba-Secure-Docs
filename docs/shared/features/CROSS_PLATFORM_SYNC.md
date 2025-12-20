# Cross-Platform Synchronization

> Documentation for cross-platform data synchronization

---

## Overview

Khandoba Secure Docs uses Supabase as a shared backend, enabling real-time synchronization across iOS, Android, and Windows platforms.

---

## Architecture

### Shared Backend

```
┌─────────────┐
│  Supabase   │
│  Backend    │
│             │
│  PostgreSQL │
│  + Storage  │
│  + Realtime │
└──────┬──────┘
       │
   ┌───┴───┬─────────┬─────────┐
   │       │         │         │
┌──▼──┐ ┌──▼──┐  ┌──▼──┐  ┌──▼──┐
│Apple│ │Android│ │Windows│ │Web │
│     │ │       │ │      │ │     │
└─────┘ └───────┘ └──────┘ └─────┘
```

---

## Synchronization Components

### Database (PostgreSQL)

**Shared Tables:**
- `users` - User accounts
- `vaults` - Vault definitions
- `documents` - Document metadata
- `vault_sessions` - Active sessions
- `vault_access_logs` - Access logs
- `nominees` - Nominee relationships
- `dual_key_requests` - Dual-key requests
- `chat_messages` - User messages

**Row-Level Security (RLS):**
- Users can only access their own data
- Vault owners control access
- Nominees have limited access

### Storage (Supabase Storage)

**Shared Buckets:**
- `encrypted-documents` - Document files
- `profile-pictures` - User profile pictures
- `voice-memos` - Audio files (if applicable)
- `intel-reports` - Intel report data (if applicable)

### Real-Time (Supabase Realtime)

**Channels:**
- `vaults` - Vault changes
- `documents` - Document changes
- `nominees` - Nominee updates
- `chat_messages` - Message updates
- `vault_sessions` - Session updates

---

## Sync Flow

### Write Flow

```
Platform A: User Action (Create/Update/Delete)
    ↓
Local Database Update
    ↓
Supabase API Call
    ↓
Supabase Database Update
    ↓
Real-time Event Broadcast
    ↓
Platform B: Receives Event
    ↓
Local Database Update
    ↓
UI Refresh
```

### Read Flow

```
User Action (View/List)
    ↓
Check Local Database
    ↓
If stale or missing: Fetch from Supabase
    ↓
Update Local Database
    ↓
Display to User
```

---

## Conflict Resolution

### Last-Write-Wins

- Most recent update wins
- Timestamp-based resolution
- Access logs prevent conflicts

### Optimistic Updates

- Update UI immediately
- Sync in background
- Rollback on failure

---

## Real-Time Updates

### Subscription Setup

**All Platforms:**
```swift/kotlin/csharp
// Subscribe to vaults channel
client.realtime.createChannel("vaults") {
    on("postgres_changes") { event ->
        // Handle change
    }
}
```

### Event Types

- **INSERT** - New record created
- **UPDATE** - Record updated
- **DELETE** - Record deleted

### Event Handling

**Example - Vault Update:**
1. Vault updated on Platform A
2. Supabase database updated
3. Real-time event broadcast
4. Platform B receives event
5. Local database updated
6. UI refreshes

---

## Offline Support

### Local Storage

**Each Platform:**
- Local database (SwiftData/Room/EF Core)
- Encrypted local storage
- Offline queue for operations

### Offline Queue

**Operations Queued:**
- Document uploads
- Vault creation
- Updates to metadata

**Sync on Reconnect:**
- Process queued operations
- Resolve conflicts
- Update UI

---

## Authentication Sync

### Platform Providers → Supabase

**Flow:**
```
Platform Sign In (Apple/Google/Microsoft)
    ↓
Get ID Token
    ↓
Supabase Auth (OAuth)
    ↓
Create/Update User in Database
    ↓
Session Established
    ↓
Sync Enabled
```

### User Identity

- **Apple:** `apple_user_id` in database
- **Android:** `google_user_id` in database
- **Windows:** `microsoft_user_id` in database

**Shared:**
- Same user can sign in from multiple platforms
- User ID from Supabase Auth is consistent
- Cross-platform user profile

---

## Data Consistency

### Guarantees

1. **Eventual Consistency** - All platforms will sync
2. **Real-time Updates** - Changes propagate quickly
3. **Conflict Resolution** - Last-write-wins
4. **Audit Trail** - All changes logged

### Consistency Checks

- Timestamp-based ordering
- Version tracking (where applicable)
- Access log timestamps
- Database constraints

---

## Performance

### Optimization

1. **Local Caching** - Reduce API calls
2. **Batch Operations** - Group updates
3. **Incremental Sync** - Only sync changes
4. **Pagination** - Load data in chunks

### Bandwidth

- Only metadata synced in real-time
- Files uploaded/downloaded on-demand
- Compressed data where possible

---

## Error Handling

### Network Errors

- Retry with exponential backoff
- Queue operations for later
- Show user-friendly error messages

### Sync Failures

- Log errors for debugging
- Retry sync automatically
- Manual refresh option

### Conflict Resolution

- Last-write-wins for metadata
- User notification for conflicts
- Manual resolution if needed

---

## Testing Cross-Platform Sync

### Test Scenarios

1. **Create vault on iOS → Check Android**
2. **Upload document on Android → Check iOS**
3. **Update vault on Windows → Check other platforms**
4. **Delete document → Verify deletion across platforms**

### Verification

- Check Supabase database directly
- Verify real-time events received
- Confirm local databases updated
- Validate UI reflects changes

---

## Platform-Specific Notes

### Apple

- CloudKit available as fallback (iOS-only)
- Real-time subscriptions via Supabase
- Background sync support

### Android

- Real-time subscriptions via Supabase Kotlin client
- Background sync via WorkManager (if implemented)
- Network state monitoring

### Windows

- Real-time subscriptions via Supabase C# client
- Background sync (planned)
- Network state handling

---

## Security Considerations

### Encryption

- All data encrypted before sync
- Encryption keys never synced
- Zero-knowledge architecture maintained

### Authentication

- Platform-specific providers
- Supabase Auth as bridge
- Secure token storage

### Access Control

- RLS policies enforce access
- User can only access authorized data
- Vault-level access control

---

**Last Updated:** December 2024

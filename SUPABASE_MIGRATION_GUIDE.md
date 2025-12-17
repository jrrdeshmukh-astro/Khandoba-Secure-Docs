# Supabase Migration Guide

## Overview

This guide provides step-by-step instructions for migrating from SwiftData/CloudKit to Supabase. The migration is feature-flagged via `AppConfig.useSupabase` to allow gradual rollout.

## Prerequisites

1. Supabase project created at [supabase.com](https://supabase.com)
2. Supabase URL and anon key added to `SupabaseConfig.swift`
3. Database schema and RLS policies applied (see `database/` folder)

## Migration Steps

### Step 1: Database Setup

1. **Create Supabase Project**
   - Go to [supabase.com](https://supabase.com)
   - Create new project
   - Note your project URL and anon key

2. **Apply Database Schema**
   ```bash
   # In Supabase Dashboard > SQL Editor, run:
   database/schema.sql
   ```

3. **Apply RLS Policies**
   ```bash
   # In Supabase Dashboard > SQL Editor, run:
   database/rls_policies.sql
   ```

4. **Create Storage Buckets**
   - Go to Storage in Supabase Dashboard
   - Create buckets:
     - `encrypted-documents` (private)
     - `voice-memos` (private)
     - `intel-reports` (private)
   - Configure bucket policies (users can only access their own files)

5. **Configure Apple Sign In OAuth**
   - Go to Authentication > Providers in Supabase Dashboard
   - Enable Apple provider
   - Add your Apple OAuth credentials (see `scripts/README_APPLE_OAUTH.md`)

### Step 2: Update Configuration

1. **Update SupabaseConfig.swift**
   - Replace placeholder URL and keys with your actual Supabase credentials
   - Verify environment configuration

2. **Enable Supabase in AppConfig**
   ```swift
   static let useSupabase = true // Enable Supabase migration
   ```

### Step 3: Update App Entry Point

The app entry point (`Khandoba_Secure_DocsApp.swift`) has been updated to:
- Conditionally initialize Supabase when `AppConfig.useSupabase == true`
- Keep SwiftData/CloudKit as fallback for gradual migration
- Initialize `SupabaseService` as environment object

### Step 4: Update Services

Services need to be updated to use Supabase instead of SwiftData. Here's the pattern:

#### AuthenticationService Migration

**Before (SwiftData):**
```swift
let descriptor = FetchDescriptor<User>(
    predicate: #Predicate { $0.appleUserID == userIdentifier }
)
let existingUsers = try modelContext.fetch(descriptor)
```

**After (Supabase):**
```swift
// Sign in with Apple via Supabase Auth
let session = try await supabaseService.signInWithApple(
    idToken: idToken,
    nonce: nonce
)

// Fetch user from Supabase
let user: SupabaseUser = try await supabaseService.fetch(
    "users",
    id: session.user.id
)
```

#### VaultService Migration

**Before (SwiftData):**
```swift
let descriptor = FetchDescriptor<Vault>(
    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
)
let vaults = try modelContext.fetch(descriptor)
```

**After (Supabase):**
```swift
// RLS automatically filters vaults user has access to
let vaults: [SupabaseVault] = try await supabaseService.fetchAll(
    "vaults",
    filters: nil // RLS handles filtering
)
```

#### DocumentService Migration

**Before (SwiftData):**
```swift
document.encryptedFileData = data
modelContext.insert(document)
try modelContext.save()
```

**After (Supabase):**
```swift
// Upload encrypted file to Supabase Storage
let storagePath = "\(vaultID)/\(documentID)"
try await supabaseService.uploadFile(
    bucket: "encrypted-documents",
    path: storagePath,
    data: encryptedData
)

// Create document record
let supabaseDoc = SupabaseDocument(
    vaultID: vaultID,
    name: name,
    storagePath: storagePath,
    // ... other fields
)
let created: SupabaseDocument = try await supabaseService.insert(
    "documents",
    values: supabaseDoc
)
```

### Step 5: Update Views

Views that use `@Environment(\.modelContext)` need to be updated:

**Before:**
```swift
@Environment(\.modelContext) private var modelContext
```

**After:**
```swift
@EnvironmentObject var supabaseService: SupabaseService
```

### Step 6: Real-time Updates

Supabase real-time automatically notifies when data changes:

```swift
// Listen for vault updates
NotificationCenter.default.addObserver(
    forName: .supabaseRealtimeUpdate,
    object: nil,
    queue: .main
) { notification in
    if let channel = notification.userInfo?["channel"] as? String,
       channel == "vaults" {
        // Refresh vaults
        Task {
            try? await vaultService.loadVaults()
        }
    }
}
```

## Migration Checklist

### Phase 1: Setup ✅
- [x] Create Supabase project
- [x] Apply database schema
- [x] Apply RLS policies
- [x] Create storage buckets
- [x] Configure Apple Sign In OAuth
- [x] Update SupabaseConfig.swift
- [x] Create Supabase models
- [x] Create SupabaseService

### Phase 2: Core Services
- [ ] Update AuthenticationService
- [ ] Update VaultService
- [ ] Update DocumentService
- [ ] Update NomineeService
- [ ] Update ChatService

### Phase 3: Supporting Services
- [ ] Update DualKeyApprovalService
- [ ] Update EmergencyApprovalService
- [ ] Update SharedVaultSessionService
- [ ] Update IntelReportService
- [ ] Update VoiceMemoService

### Phase 4: Views
- [ ] Update ContentView
- [ ] Update ClientMainView
- [ ] Update VaultListView
- [ ] Update VaultDetailView
- [ ] Update DocumentListView
- [ ] Update all other views using ModelContext

### Phase 5: Testing
- [ ] Test authentication flow
- [ ] Test vault CRUD operations
- [ ] Test document upload/download
- [ ] Test nominee sharing
- [ ] Test dual-key approval
- [ ] Test real-time updates
- [ ] Test offline handling

### Phase 6: Cleanup
- [ ] Remove SwiftData models (or archive)
- [ ] Remove CloudKit dependencies
- [ ] Remove ModelContext usage
- [ ] Update documentation

## Key Differences

### Data Access

**SwiftData:**
- Direct model access via `@Model` classes
- Relationships via `@Relationship`
- Automatic CloudKit sync

**Supabase:**
- Codable structs (no `@Model`)
- Foreign keys for relationships
- Real-time subscriptions for sync
- RLS enforces access control

### File Storage

**SwiftData/CloudKit:**
- Files stored in `encryptedFileData` property
- Synced via CloudKit

**Supabase:**
- Files stored in Supabase Storage buckets
- `storagePath` references file location
- Encrypted before upload

### Authentication

**SwiftData:**
- User stored in local database
- No server-side auth

**Supabase:**
- Supabase Auth handles authentication
- JWT tokens for API access
- RLS uses `auth.uid()` for access control

## Troubleshooting

### RLS Policy Errors

If you get "permission denied" errors:
1. Check RLS policies in `database/rls_policies.sql`
2. Verify user is authenticated: `supabaseService.currentSession != nil`
3. Check Supabase logs in Dashboard

### Storage Upload Errors

If file uploads fail:
1. Verify bucket exists and is private
2. Check bucket policies allow user uploads
3. Verify file size limits (default 50MB)

### Real-time Not Working

If real-time updates don't appear:
1. Check `SupabaseConfig.enableRealtime == true`
2. Verify channel subscriptions in `SupabaseService.setupRealtimeSubscriptions()`
3. Check Supabase Dashboard > Realtime for connection status

## Rollback Plan

If migration issues occur:
1. Set `AppConfig.useSupabase = false`
2. App will use SwiftData/CloudKit as before
3. Fix issues and re-enable Supabase

## Next Steps

1. Complete Phase 2 (Core Services)
2. Test thoroughly with real data
3. Gradually migrate users
4. Monitor Supabase dashboard for errors
5. Complete Phase 3-6

## Support

- Supabase Docs: https://supabase.com/docs
- Supabase Swift SDK: https://github.com/supabase/supabase-swift
- Project Issues: Check GitHub issues

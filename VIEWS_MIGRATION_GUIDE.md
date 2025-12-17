# Views Migration Guide for Supabase

## Overview

This guide provides patterns for updating views to support Supabase. Most views use services (VaultService, DocumentService, etc.) which have already been updated. Views primarily need to:

1. Add `@EnvironmentObject var supabaseService: SupabaseService`
2. Update service configuration calls to use Supabase when enabled
3. Remove direct `modelContext` usage where possible

## Migration Pattern

### Step 1: Add SupabaseService to Environment

```swift
@EnvironmentObject var supabaseService: SupabaseService
```

### Step 2: Update Service Configuration

**Before:**
```swift
nomineeService.configure(modelContext: modelContext, currentUserID: userID)
```

**After:**
```swift
if AppConfig.useSupabase {
    nomineeService.configure(supabaseService: supabaseService, currentUserID: userID)
} else {
    nomineeService.configure(modelContext: modelContext, currentUserID: userID)
}
```

### Step 3: Use ServiceConfigurationHelper (Optional)

For cleaner code, use the helper utility:

```swift
ServiceConfigurationHelper.configureNomineeService(
    nomineeService,
    modelContext: modelContext,
    supabaseService: supabaseService,
    userID: userID
)
```

## Views Updated ✅

1. ✅ **ContentView** - Added SupabaseService, updated shared vault finding
2. ✅ **ClientMainView** - Updated service configuration
3. ✅ **VaultListView** - Updated NomineeService configuration
4. ✅ **VaultDetailView** - Added SupabaseService, updated session saving
5. ✅ **NomineeManagementView** - Updated NomineeService and ChatService configuration

## Views Remaining

The following views configure NomineeService and may need updates:

- `UnifiedNomineeManagementView.swift`
- `VaultRequestView.swift`
- `AcceptNomineeInvitationView.swift`
- `VaultRequestsListView.swift`
- `ManualInviteTokenView.swift`
- `UnifiedAddNomineeView.swift`
- `UnifiedShareView.swift`
- `AddNomineeView.swift`
- `NomineeInvitationView.swift`

## Helper Utility

A `ServiceConfigurationHelper` has been created in `Config/ServiceConfigurationHelper.swift` to simplify service configuration across views.

## Key Points

1. **Services handle data operations** - Views don't need to change much
2. **Configuration is the main change** - Update how services are configured
3. **Feature flag controls mode** - `AppConfig.useSupabase` determines backend
4. **Backward compatible** - SwiftData/CloudKit still works when flag is false

## Testing Checklist

- [ ] Test authentication flow
- [ ] Test vault loading
- [ ] Test document upload/download
- [ ] Test nominee invitations
- [ ] Test chat messaging
- [ ] Test real-time updates
- [ ] Test with `AppConfig.useSupabase = false` (fallback)

# iMessage App Info.plist Conflict Fix

> **Date:** December 2024  
> **Status:** ✅ Fixed

## Problem

Build error:
```
Multiple commands produce '/Users/.../KhandobaSecureDocsMessageApp.app/Info.plist'
```

## Root Cause

The `KhandobaSecureDocsMessageApp` target uses `PBXFileSystemSynchronizedRootGroup` which automatically includes all files in the `KhandobaSecureDocsMessageApp` folder, including `Info.plist`. However, the build settings also specify `INFOPLIST_FILE = KhandobaSecureDocsMessageApp/Info.plist`, causing Xcode to process the Info.plist twice:
1. Once from the file system synchronized group (automatic inclusion)
2. Once from the explicit `INFOPLIST_FILE` build setting

## Solution

Created a `PBXFileSystemSynchronizedBuildFileExceptionSet` to exclude `Info.plist` from being automatically included in build phases for the `KhandobaSecureDocsMessageApp` target.

### Changes Made

1. **Created exception set** (UUID: `24807B8C2EEB52F2008E3E1F`):
   ```xml
   24807B8C2EEB52F2008E3E1F /* Exceptions for "KhandobaSecureDocsMessageApp" folder in "KhandobaSecureDocsMessageApp" target */ = {
       isa = PBXFileSystemSynchronizedBuildFileExceptionSet;
       membershipExceptions = (
           Info.plist,
       );
       target = 24807B742EEB52EF008E3E1E /* KhandobaSecureDocsMessageApp */;
   };
   ```

2. **Added exception to root group**:
   ```xml
   24807B762EEB52EF008E3E1E /* KhandobaSecureDocsMessageApp */ = {
       isa = PBXFileSystemSynchronizedRootGroup;
       exceptions = (
           24807B8C2EEB52F2008E3E1F /* Exceptions for "KhandobaSecureDocsMessageApp" folder in "KhandobaSecureDocsMessageApp" target */,
       );
       path = KhandobaSecureDocsMessageApp;
       sourceTree = "<group>";
   };
   ```

## Build Configuration

The target correctly uses:
- `GENERATE_INFOPLIST_FILE = NO`
- `INFOPLIST_FILE = KhandobaSecureDocsMessageApp/Info.plist`

This ensures the Info.plist is processed only once via the explicit build setting, not from the file system synchronized group.

## Verification

✅ **Info.plist conflict resolved** - No more "Multiple commands produce" error  
✅ **Build configuration correct** - Info.plist processed once via build setting

## Related Fixes

Similar fixes were applied to:
- `ShareExtension` target
- `KhandobaSecureDocsMessageApp MessagesExtension` target

See:
- `docs/SHAREEXTENSION_INFOPLIST_DUPLICATE_FIXED.md`
- `docs/INFOPLIST_CONFLICT_FIXED.md`

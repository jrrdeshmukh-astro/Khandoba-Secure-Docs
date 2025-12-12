# ShareExtension Info.plist Duplicate Fixed

## Issue

**Error:**
```
Multiple commands produce '/Users/.../ShareExtension.appex/Info.plist'
warning: The Copy Bundle Resources build phase contains this target's Info.plist file
warning: duplicate output file on task: ProcessInfoPlistFile
```

## Root Cause

ShareExtension's Info.plist was being:
1. **Processed as Info.plist** (via `INFOPLIST_FILE` setting)
2. **Copied as a Resource** (via `fileSystemSynchronizedGroups` automatically adding it to Resources)

This created a duplicate - the same file was being processed twice, causing the conflict.

## Solution

Added an exception set for ShareExtension's own folder to exclude Info.plist from being copied to Resources:

**Exception Created:**
- UUID: `245C559E2EE4C09600270A38`
- Target: ShareExtension
- Excludes: `Info.plist` from ShareExtension folder

**Configuration:**
```pbxproj
245C55842EE4B66400270A37 /* ShareExtension */ = {
    isa = PBXFileSystemSynchronizedRootGroup;
    exceptions = (
        245C559E2EE4C09600270A38 /* Exceptions for "ShareExtension" folder in "ShareExtension" target */,
    );
    path = ShareExtension;
};
```

This ensures that:
- Info.plist is processed as the Info.plist file (via `INFOPLIST_FILE`)
- Info.plist is NOT copied as a resource (excluded by exception)

## Files Modified

- `Khandoba Secure Docs.xcodeproj/project.pbxproj`
  - Added exception set for ShareExtension folder
  - Added exception reference to ShareExtension's fileSystemSynchronizedGroups

## Verification

**Build ShareExtension:**
```bash
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -target "ShareExtension" \
  -configuration Debug
```

**Expected:** No "Multiple commands produce" or "Copy Bundle Resources" warnings

## Next Steps

1. **Clean build folder:**
   ```bash
   rm -rf build
   rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
   ```

2. **In Xcode:**
   - Clean build folder (⇧⌘K)
   - Build (⌘+B)
   - Error should be resolved

---

**Status:** ✅ ShareExtension Info.plist duplicate fixed

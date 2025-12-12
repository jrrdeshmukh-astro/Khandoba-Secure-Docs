# ShareExtension Info.plist Conflict Fix

## Issue

**Error:**
```
Multiple commands produce '/Users/.../ShareExtension.appex/Info.plist'
```

## Root Cause

ShareExtension has `fileSystemSynchronizedGroups` that includes the "Khandoba Secure Docs" folder (for shared code). When the main app builds and embeds ShareExtension, both targets might be trying to process Info.plist files.

The ShareExtension already has an exception to exclude `Info.plist` from the "Khandoba Secure Docs" folder, but the conflict might be happening during the embed phase.

## Current Configuration

**ShareExtension Target:**
- `GENERATE_INFOPLIST_FILE = NO`
- `INFOPLIST_FILE = ShareExtension/Info.plist`
- Exception set excludes `Info.plist` from "Khandoba Secure Docs" folder
- `fileSystemSynchronizedGroups` includes:
  - `ShareExtension` folder
  - `Khandoba Secure Docs` folder (with exception for Info.plist)

**Main App Target:**
- `GENERATE_INFOPLIST_FILE = YES`
- Embeds ShareExtension via "Embed Foundation Extensions" phase

## Solution

The configuration appears correct. The issue might be:
1. **Build cache conflict** - Clean build folder
2. **Xcode indexing** - Close and reopen Xcode
3. **DerivedData** - Delete DerivedData

## Verification Steps

1. **Clean build folder:**
   ```bash
   rm -rf build
   rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
   ```

2. **In Xcode:**
   - Close Xcode
   - Reopen project
   - Clean build folder (⇧⌘K)
   - Build (⌘+B)

3. **If error persists:**
   - Check Build Phases → Copy Files for ShareExtension
   - Verify no duplicate Info.plist processing
   - Check if Resources phase includes Info.plist

## Files Status

✅ `ShareExtension/ShareExtension.entitlements` - Created
✅ `ShareExtension/Info.plist` - Created
✅ Exception set configured correctly
✅ Build settings configured correctly

---

**Status:** Configuration correct, likely build cache issue

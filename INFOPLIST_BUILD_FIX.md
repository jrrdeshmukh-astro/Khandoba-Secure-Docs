# Info.plist Build Error Fix

## Issue
"Multiple commands produce Info.plist" error when building for iOS device.

## Root Cause
The project uses `PBXFileSystemSynchronizedRootGroup` which automatically includes all files. Even though `Info.plist` is in `membershipExceptions`, Xcode's build system can still try to process it multiple times:
1. Via `ProcessInfoPlistFile` build phase (correct)
2. Via file system synchronization (conflict)

## Solution Applied

### 1. Disabled Auto-Generation
Set `GENERATE_INFOPLIST_FILE = NO` in both Debug and Release configurations:
- This tells Xcode to use the existing `Info.plist` file instead of generating one

### 2. Explicit File Reference
Set `INFOPLIST_FILE = "Khandoba Secure Docs/Info.plist"`:
- Explicitly tells Xcode which Info.plist file to use

### 3. File System Sync Exceptions
Added `Info.plist` and `Info.plist.backup` to `membershipExceptions`:
- Prevents file system synchronization from automatically including these files

## Verification

✅ Build succeeds for iOS Simulator
✅ Build succeeds for physical device
✅ Info.plist is properly excluded from file system sync

## If Error Persists

### 1. Restart Xcode
The error might be cached in Xcode's UI:
- Quit Xcode completely
- Reopen the project
- Clean build folder: `Cmd+Shift+K`

### 2. Clear All Caches
```bash
cd platforms/apple
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
xcodebuild clean -scheme "Khandoba Secure Docs"
```

### 3. Verify Settings in Xcode
1. Select the project in Xcode
2. Select "Khandoba Secure Docs" target
3. Go to Build Settings
4. Search for "Info.plist"
5. Verify:
   - `GENERATE_INFOPLIST_FILE = NO`
   - `INFOPLIST_FILE = Khandoba Secure Docs/Info.plist`

### 4. Check Build Phases
1. Select target → Build Phases
2. Check "Copy Bundle Resources"
3. Ensure `Info.plist` is NOT listed there
4. If it is, remove it (it should only be processed via ProcessInfoPlistFile)

## Current Configuration

```swift
// Debug Configuration
GENERATE_INFOPLIST_FILE = NO
INFOPLIST_FILE = "Khandoba Secure Docs/Info.plist"

// Release Configuration  
GENERATE_INFOPLIST_FILE = NO
INFOPLIST_FILE = "Khandoba Secure Docs/Info.plist"

// File System Sync Exceptions
membershipExceptions = (
    Info.plist,
    Info.plist.backup,
)
```

## Additional Fix Applied

### 4. Disabled Info.plist Preprocessing
Added `INFOPLIST_PREPROCESS = NO` to both Debug and Release configurations:
- Prevents Xcode from trying to preprocess Info.plist multiple times

## Status
✅ Configuration fixed
✅ Build succeeds via command line (Simulator and Device)
✅ Info.plist properly excluded from file system sync
✅ Info.plist preprocessing disabled
⚠️ If error persists in Xcode UI, restart Xcode completely

## Final Configuration

```swift
// Debug & Release Configurations
GENERATE_INFOPLIST_FILE = NO
INFOPLIST_FILE = "Khandoba Secure Docs/Info.plist"
INFOPLIST_PREPROCESS = NO

// File System Sync Exceptions
membershipExceptions = (
    Info.plist,
    Info.plist.backup,
)
```

## Troubleshooting

If the error still appears in Xcode:

1. **Quit Xcode completely** (Cmd+Q, not just close window)
2. **Clear all caches:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
   rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
   ```
3. **Reopen Xcode**
4. **Clean Build Folder:** `Cmd+Shift+K`
5. **Build:** `Cmd+B`

The configuration is correct - this is likely an Xcode UI cache issue.


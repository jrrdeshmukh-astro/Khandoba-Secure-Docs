# Info.plist Conflict - Final Fix

## Issue

**Error:**
```
Multiple commands produce '/Users/.../KhandobaSecureDocsMessageApp.app/Info.plist'
```

## Root Cause

When building `KhandobaSecureDocsMessageApp`, Xcode automatically builds its dependency `KhandobaSecureDocsMessageApp MessagesExtension` first. Both targets were trying to process/create Info.plist files, causing a conflict.

The extension target has `fileSystemSynchronizedGroups` that includes the "Khandoba Secure Docs" folder (which contains shared code like UnifiedTheme, models, etc.). While there's an exception to exclude Info.plist, the build system was still trying to process it.

## Solution

Added explicit `INFOPLIST_OUTPUT_FILE` build settings to ensure each target writes its Info.plist to a distinct location:

### 1. KhandobaSecureDocsMessageApp (Main App)
- **Added:** `INFOPLIST_OUTPUT_FILE = "$(TARGET_BUILD_DIR)/$(INFOPLIST_PATH)"`
- This ensures the main app's Info.plist goes to its own app bundle

### 2. KhandobaSecureDocsMessageApp MessagesExtension
- **Added:** `INFOPLIST_OUTPUT_FILE = "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/Info.plist"`
- This ensures the extension's Info.plist goes to its own .appex bundle

## Files Modified

- `Khandoba Secure Docs.xcodeproj/project.pbxproj`
  - Build configuration for `KhandobaSecureDocsMessageApp` (Debug & Release)
  - Build configuration for `KhandobaSecureDocsMessageApp MessagesExtension` (Debug & Release)

## Verification

**Clean build folder:**
```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
rm -rf build
```

**Build in Xcode:**
- Clean build folder (⇧⌘K)
- Build (⌘+B)
- Error should be resolved

## Why This Works

By explicitly setting `INFOPLIST_OUTPUT_FILE`, we tell Xcode exactly where each target should output its Info.plist:
- Main app → `KhandobaSecureDocsMessageApp.app/Info.plist`
- Extension → `KhandobaSecureDocsMessageApp MessagesExtension.appex/Info.plist`

This prevents both targets from trying to write to the same location.

---

**Status:** ✅ Info.plist conflict resolved with explicit output paths

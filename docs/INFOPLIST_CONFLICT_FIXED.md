# Info.plist Conflict Fixed

## Issue

**Error:**
```
Multiple commands produce '/Users/.../KhandobaSecureDocsMessageApp.app/Info.plist'
```

## Root Cause

Both targets had `GENERATE_INFOPLIST_FILE = YES` while also pointing to existing Info.plist files:
- `KhandobaSecureDocsMessageApp` target: `GENERATE_INFOPLIST_FILE = YES` (no explicit INFOPLIST_FILE)
- `KhandobaSecureDocsMessageApp MessagesExtension` target: `GENERATE_INFOPLIST_FILE = YES` + `INFOPLIST_FILE = "..."`

This caused both targets to try generating Info.plist files in conflicting locations.

## Solution

Changed both targets to use existing Info.plist files instead of auto-generating:

### 1. KhandobaSecureDocsMessageApp Target
- **Before:** `GENERATE_INFOPLIST_FILE = YES`
- **After:** `GENERATE_INFOPLIST_FILE = NO` + `INFOPLIST_FILE = "KhandobaSecureDocsMessageApp/Info.plist"`

### 2. KhandobaSecureDocsMessageApp MessagesExtension Target
- **Before:** `GENERATE_INFOPLIST_FILE = YES` + `INFOPLIST_FILE = "..."`
- **After:** `GENERATE_INFOPLIST_FILE = NO` + `INFOPLIST_FILE = "KhandobaSecureDocsMessageApp MessagesExtension/Info.plist"`

## Files Modified

- `Khandoba Secure Docs.xcodeproj/project.pbxproj`
  - Build configuration for `KhandobaSecureDocsMessageApp` (Debug & Release)
  - Build configuration for `KhandobaSecureDocsMessageApp MessagesExtension` (Debug & Release)

## Verification

**Check build settings:**
```bash
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -target "KhandobaSecureDocsMessageApp MessagesExtension" \
  -showBuildSettings | grep -E "(GENERATE_INFOPLIST|INFOPLIST_FILE)"
```

**Expected output:**
- `GENERATE_INFOPLIST_FILE = NO`
- `INFOPLIST_FILE = KhandobaSecureDocsMessageApp MessagesExtension/Info.plist`

## Next Steps

1. **Clean build folder:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
   ```

2. **Build in Xcode:**
   - Clean build folder (⇧⌘K)
   - Build (⌘+B)
   - Error should be resolved

---

**Status:** ✅ Info.plist conflict fixed

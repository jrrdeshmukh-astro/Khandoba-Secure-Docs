# Clean Build Fix - iMessage Extension

> **If you're seeing build errors that should be fixed, clean your build folder**

## Quick Fix

If you're seeing errors like:
- `Cannot find 'PushNotificationService' in scope`
- `Cannot find 'SharedVaultSessionService' in scope`
- `Cannot find 'VaultService' in scope`

**Even though the files are excluded**, this is usually a **cached build** issue.

## Solution

### Option 1: Clean in Xcode (Recommended)

1. Open Xcode
2. **Product → Clean Build Folder** (⇧⌘K)
3. Wait for cleanup to complete
4. Build again (⌘+B)

### Option 2: Clean via Terminal

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Clean build folder
xcodebuild clean -project "Khandoba Secure Docs.xcodeproj" -target "KhandobaSecureDocsMessageApp MessagesExtension"

# Remove DerivedData (more thorough)
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*

# Rebuild
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -target "KhandobaSecureDocsMessageApp MessagesExtension" \
  -configuration Debug \
  -sdk iphoneos \
  build
```

### Option 3: Clean All Targets

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Clean all
xcodebuild clean -project "Khandoba Secure Docs.xcodeproj" -alltargets

# Remove DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*

# Rebuild
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -configuration Debug \
  -sdk iphoneos \
  build
```

## Verification

After cleaning, the build should succeed:

```bash
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -target "KhandobaSecureDocsMessageApp MessagesExtension" \
  -configuration Debug \
  -sdk iphoneos \
  build 2>&1 | grep -E "(BUILD SUCCEEDED|BUILD FAILED)"
```

Expected output: `** BUILD SUCCEEDED **`

## Why This Happens

Xcode caches compiled files in `DerivedData`. When you exclude files from a target:
1. The exclusion is added to `project.pbxproj`
2. But old compiled artifacts may still exist in DerivedData
3. Xcode might use cached files instead of respecting the exclusion
4. Cleaning forces Xcode to rebuild from scratch with the new exclusions

## Files Excluded from Extension

The following files are excluded from `KhandobaSecureDocsMessageApp MessagesExtension`:

**Services:**
- `Services/SharedVaultSessionService.swift` ✅
- `Services/PushNotificationService.swift` ✅
- `Services/VaultService.swift` ✅
- `Services/AuthenticationService.swift` ✅
- And 7 more service files

**Views:**
- All 61 view files in `Views/` directory ✅

**Other:**
- `Khandoba_Secure_DocsApp.swift` ✅
- `ContentView.swift` ✅
- `Theme/AnimationStyles.swift` ✅

See `docs/IMESSAGE_EXTENSION_BUILD_FIX.md` for complete list.

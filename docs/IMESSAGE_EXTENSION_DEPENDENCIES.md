# iMessage Extension - Dependency Configuration

> **Last Updated:** December 2024
> 
> Guide to configuring dependencies for the iMessage extension.

## Overview

The iMessage extension needs access to shared files from the main app. This document outlines what needs to be configured in Xcode.

## Required Dependencies

### ✅ Files That Must Be Added to MessageExtension Target

The following files need to be included in the **MessageExtension** target in Xcode:

#### 1. **New File**
- `MessageExtension/InvitationResponseMessageView.swift` - **MUST BE ADDED** (new file)

#### 2. **Theme Files** (Required for UI)
- `Khandoba Secure Docs/Theme/UnifiedTheme.swift`
- `Khandoba Secure Docs/Theme/ThemeModifiers.swift` (contains `PrimaryButtonStyle`)

#### 3. **UI Components** (Required for UI)
- `Khandoba Secure Docs/UI/Components/StandardCard.swift`

#### 4. **Models** (Required for SwiftData)
- `Khandoba Secure Docs/Models/Vault.swift`
- `Khandoba Secure Docs/Models/Nominee.swift`
- `Khandoba Secure Docs/Models/User.swift`

#### 5. **Config** (Required for CloudKit)
- `Khandoba Secure Docs/Config/AppConfig.swift` (for CloudKit container identifier)

## How to Add Files to MessageExtension Target

### Method 1: Using Xcode File Inspector (Recommended)

1. **Open Xcode**
2. **Select the file** in the Project Navigator
3. **Open File Inspector** (right panel, first tab)
4. **Under "Target Membership"**, check the box for **"MessageExtension"**
5. **Repeat for all files listed above**

### Method 2: Using Xcode Project Settings

1. **Select the project** in Project Navigator
2. **Select "MessageExtension" target**
3. **Go to "Build Phases" tab**
4. **Expand "Compile Sources"**
5. **Click "+" button**
6. **Add all required files**

## Files Already Configured

Based on the project structure, these files are likely already included:
- ✅ `MessageExtension/MessageExtensionViewController.swift` (already in target)
- ✅ `MessageExtension/Info.plist` (already in target)
- ✅ `MessageExtension/MessageExtension.entitlements` (already in target)

## Verification Checklist

After adding files, verify:

- [ ] `InvitationResponseMessageView.swift` compiles in MessageExtension target
- [ ] `UnifiedTheme` is accessible
- [ ] `StandardCard` is accessible
- [ ] `PrimaryButtonStyle` is accessible
- [ ] SwiftData models (Vault, Nominee, User) are accessible
- [ ] `AppConfig` is accessible (if used)

## Build Errors to Watch For

If you see these errors, the file is not in the target:

```
❌ Cannot find 'UnifiedTheme' in scope
❌ Cannot find 'StandardCard' in scope
❌ Cannot find 'PrimaryButtonStyle' in scope
❌ Cannot find type 'Vault' in scope
❌ Cannot find type 'Nominee' in scope
❌ Cannot find type 'User' in scope
```

**Solution:** Add the missing file to MessageExtension target using Method 1 or 2 above.

## App Group Configuration

The MessageExtension uses the same App Group as the main app for shared data:

```swift
let appGroupIdentifier = "group.com.khandoba.securedocs"
```

**Verify:**
- [ ] MessageExtension.entitlements includes App Group
- [ ] Main app entitlements include same App Group
- [ ] Both use same CloudKit container

## CloudKit Configuration

Both targets should use the same CloudKit container:

```swift
let container = CKContainer(identifier: AppConfig.cloudKitContainer)
```

**Verify:**
- [ ] `AppConfig.swift` is accessible to MessageExtension
- [ ] CloudKit container identifier matches in both targets
- [ ] Entitlements include CloudKit capability

## Quick Setup Script

If you prefer command line, you can verify file membership:

```bash
# Check if file is in MessageExtension target
grep -r "InvitationResponseMessageView.swift" "Khandoba Secure Docs.xcodeproj/project.pbxproj"
```

## Testing

After adding dependencies:

1. **Build MessageExtension target** (⌘+B)
2. **Check for compilation errors**
3. **Test in Messages app:**
   - Open Messages
   - Tap Khandoba icon
   - Verify UI loads correctly
   - Send test invitation

## Common Issues

### Issue: "Cannot find type in scope"
**Solution:** File is not in MessageExtension target. Add it using File Inspector.

### Issue: "Module not found"
**Solution:** Check that shared files are included in both targets, or create a shared framework.

### Issue: "App Group not found"
**Solution:** Verify entitlements match between main app and extension.

## Related Files

- `MessageExtension/MessageExtensionViewController.swift` - Main extension controller
- `MessageExtension/InvitationResponseMessageView.swift` - Interactive response UI
- `docs/IMESSAGE_EXTENSION_APPLE_CASH_STYLE.md` - Feature documentation

## Summary

**Action Required:**
1. ✅ Add `InvitationResponseMessageView.swift` to MessageExtension target
2. ✅ Verify shared files (UnifiedTheme, StandardCard, etc.) are in target
3. ✅ Verify models (Vault, Nominee, User) are in target
4. ✅ Build and test

**Time Estimate:** 5-10 minutes

---

**Status:** Ready for configuration in Xcode

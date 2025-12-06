# Fix: Multiple Commands Produce Info.plist Error

## Problem
```
Multiple commands produce '/Users/.../Khandoba Secure Docs.app/Info.plist'
```

This error occurs when Xcode tries to both auto-generate and use a manual Info.plist file.

## Solution

### Step 1: Main App Target (Already Fixed)
✅ Changed `GENERATE_INFOPLIST_FILE = YES` to `NO` in project.pbxproj

### Step 2: Configure Share Extension Target in Xcode

1. **Open Xcode** and select your project
2. **Add Share Extension Target** (if not already added):
   - File → New → Target
   - iOS → Share Extension
   - Name: "Khandoba Secure Docs Share Extension"
   - Bundle ID: `com.khandoba.securedocs.ShareExtension`

3. **Configure Share Extension Build Settings**:
   - Select the **Share Extension target**
   - Go to **Build Settings**
   - Search for "Generate Info.plist"
   - Set `GENERATE_INFOPLIST_FILE` to **NO**
   - Search for "Info.plist File"
   - Set `INFOPLIST_FILE` to: `Khandoba Secure Docs/ShareExtension/Info.plist`

4. **Add Share Extension Files**:
   - Right-click on "ShareExtension" folder in Project Navigator
   - Select "Add Files to 'Khandoba Secure Docs'"
   - Select:
     - `ShareViewController.swift`
     - `ShareExtensionView.swift`
     - `Info.plist`
   - Make sure "Copy items if needed" is checked
   - **Target Membership**: Check only "Khandoba Secure Docs Share Extension"

5. **Verify File Membership**:
   - Select `Khandoba Secure Docs/Info.plist`
   - In File Inspector, check only "Khandoba Secure Docs" target
   - Select `ShareExtension/Info.plist`
   - In File Inspector, check only "Khandoba Secure Docs Share Extension" target

### Step 3: Clean Build Folder
1. Product → Clean Build Folder (Shift+Cmd+K)
2. Close Xcode
3. Delete DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
   ```
4. Reopen Xcode and build

## Alternative: If Share Extension Not Yet Added

If you haven't added the Share Extension target yet, the error might be from duplicate Info.plist references. Check:

1. **Project Navigator** - Make sure `Info.plist` appears only once
2. **Build Phases** → **Copy Bundle Resources**:
   - Remove any duplicate `Info.plist` entries
   - Main app should only have: `Khandoba Secure Docs/Info.plist`

## Verification

After fixing, you should see:
- ✅ Main app target: `GENERATE_INFOPLIST_FILE = NO`, uses `Khandoba Secure Docs/Info.plist`
- ✅ Share Extension target: `GENERATE_INFOPLIST_FILE = NO`, uses `ShareExtension/Info.plist`
- ✅ No duplicate Info.plist files in Copy Bundle Resources

## Quick Fix Script

If the error persists, run this in Terminal:

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
# Reopen Xcode
open "Khandoba Secure Docs.xcodeproj"
```

Then in Xcode:
1. Product → Clean Build Folder
2. Build again


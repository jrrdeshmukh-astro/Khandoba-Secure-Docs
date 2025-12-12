# CLI Setup Guide - iMessage Extension

> **Last Updated:** December 2024
> 
> Execute Steps 2 & 3 using command line tools.

## Quick Start

Run these commands in order:

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Step 2: Replace files and copy Views
./scripts/setup_imessage_extension.sh

# Step 3: Add target membership (automated)
python3 scripts/add_target_membership.py

# Verify setup
xcodebuild -project "Khandoba Secure Docs.xcodeproj" -target "KhandobaSecureDocsMessageApp MessagesExtension" -showBuildSettings | grep PRODUCT_NAME
```

## Detailed Steps

### Step 2: Replace Generated Files

**Script:** `scripts/setup_imessage_extension.sh`

**What it does:**
1. ✅ Replaces `MessagesViewController.swift` with full implementation
2. ✅ Copies all 4 files from `Views/` folder
3. ✅ Copies entitlements file
4. ✅ Creates Views directory if needed

**Run:**
```bash
./scripts/setup_imessage_extension.sh
```

**Output:**
```
🚀 Setting up iMessage Extension...

📝 Step 2.1: Replacing MessagesViewController.swift...
✅ MessagesViewController.swift replaced

📁 Step 2.2: Copying Views folder...
✅ Views folder copied (4 files)

🔐 Step 2.3: Copying entitlements file...
✅ Entitlements file copied

✅ Step 2 Complete!
```

### Step 3: Configure Target Membership

**Script:** `scripts/add_target_membership.py`

**What it does:**
1. ✅ Finds extension target in project.pbxproj
2. ✅ Locates file references for shared files
3. ✅ Adds files to Compile Sources phase
4. ✅ Creates backup of project.pbxproj

**Run:**
```bash
python3 scripts/add_target_membership.py
```

**Output:**
```
🔧 Adding target membership for shared files...

✅ Found target: KhandobaSecureDocsMessageApp MessagesExtension
✅ Found Sources phase: [UUID]

Processing: UnifiedTheme.swift...
   ✅ Found file reference: [UUID]
   ✅ Added to Compile Sources

Processing: ThemeModifiers.swift...
   ✅ Found file reference: [UUID]
   ✅ Added to Compile Sources

...

✅ Successfully added 7 file(s) to target
```

## Verification

### Check Files Were Added

```bash
# List files in extension target
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -target "KhandobaSecureDocsMessageApp MessagesExtension" \
  -showBuildSettings 2>/dev/null | grep -i "product_name\|bundle_identifier"
```

### Build Extension Target

```bash
# Clean build folder
xcodebuild clean -project "Khandoba Secure Docs.xcodeproj" \
  -target "KhandobaSecureDocsMessageApp MessagesExtension"

# Build extension
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -target "KhandobaSecureDocsMessageApp MessagesExtension" \
  -configuration Debug \
  -sdk iphoneos \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

### Check for Errors

```bash
# Build and capture errors
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -target "KhandobaSecureDocsMessageApp MessagesExtension" \
  -configuration Debug 2>&1 | grep -i "error\|warning" | head -20
```

## Manual Verification in Xcode

After running scripts:

1. **Open Xcode**
2. **Select target:** `KhandobaSecureDocsMessageApp MessagesExtension`
3. **Go to:** Build Phases → Compile Sources
4. **Verify these files appear:**
   - `UnifiedTheme.swift`
   - `ThemeModifiers.swift`
   - `StandardCard.swift`
   - `Vault.swift`
   - `Nominee.swift`
   - `User.swift`
   - `AppConfig.swift`
   - `MessagesViewController.swift`
   - All 4 view files

## Troubleshooting

### Script Fails: "Permission denied"

```bash
chmod +x scripts/setup_imessage_extension.sh
chmod +x scripts/add_target_membership.py
```

### Python Script Fails: "File reference not found"

The Python script uses pattern matching to find files. If it fails:

1. **Check file paths** in `FILES_TO_ADD` array
2. **Verify files exist** in project
3. **Manual alternative:** Use Xcode File Inspector (see manual guide)

### Build Errors: "Cannot find 'UnifiedTheme'"

**Cause:** File not in target membership

**Fix:**
1. Run Python script again
2. Or manually add in Xcode (File Inspector → Target Membership)

### Project File Corrupted

**Restore backup:**
```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
cp "Khandoba Secure Docs.xcodeproj/project.pbxproj.backup" \
   "Khandoba Secure Docs.xcodeproj/project.pbxproj"
```

## Alternative: Manual Xcode Method

If scripts don't work, use Xcode:

1. **Select file** in Project Navigator
2. **File Inspector** (⌥⌘1)
3. **Target Membership** section
4. **Check** `KhandobaSecureDocsMessageApp MessagesExtension`

## Files Modified

### Created/Modified:
- `KhandobaSecureDocsMessageApp MessagesExtension/MessagesViewController.swift` (replaced)
- `KhandobaSecureDocsMessageApp MessagesExtension/Views/` (4 files copied)
- `KhandobaSecureDocsMessageApp MessagesExtension/KhandobaSecureDocsMessageApp.entitlements` (copied)
- `Khandoba Secure Docs.xcodeproj/project.pbxproj` (target membership added)

### Backup Created:
- `Khandoba Secure Docs.xcodeproj/project.pbxproj.backup`

## Next Steps

After running scripts:

1. **Open Xcode**
2. **Verify files** in Project Navigator
3. **Build extension** (⌘+B)
4. **Test in Messages app**

---

**Status:** Ready to execute via CLI

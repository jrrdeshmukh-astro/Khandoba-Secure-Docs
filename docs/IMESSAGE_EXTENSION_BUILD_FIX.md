# Fix: Multiple Commands Produce Error

> **Issue:** "Multiple commands produce" error when building MessageExtension
> 
> **Cause:** Shared files compiled in both targets generate conflicting intermediate build artifacts

## Quick Fix (3 Steps)

### Step 1: Clean Build Folder

**In Xcode:**
1. **Product → Clean Build Folder** (⇧⌘K)
2. Wait for cleanup to complete

**Or via Terminal:**
```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
```

### Step 2: Verify File Membership (Important!)

**For each of these files:**
- `AppConfig.swift`
- `Nominee.swift`
- `User.swift`
- `Vault.swift`
- `StandardCard.swift`
- `ThemeModifiers.swift`
- `UnifiedTheme.swift`

**Do this:**
1. Select the file in Project Navigator
2. Open File Inspector (right panel)
3. Under "Target Membership":
   - ✅ Check "Khandoba Secure Docs" (main app)
   - ✅ Check "MessageExtension"
   - ⚠️ **Make sure each is checked ONLY ONCE**

### Step 3: Check Build Phases

**For MessageExtension target:**
1. Select **MessageExtension** target
2. Go to **Build Phases** tab
3. Expand **Compile Sources**
4. **Look for duplicates:**
   - Same file listed twice = problem!
   - Remove duplicate entries
5. **Verify files are listed:**
   - AppConfig.swift (once)
   - Nominee.swift (once)
   - User.swift (once)
   - Vault.swift (once)
   - StandardCard.swift (once)
   - ThemeModifiers.swift (once)
   - UnifiedTheme.swift (once)

## Alternative Fix: Remove and Re-add Files

If Step 2 doesn't work:

1. **Select file** (e.g., `AppConfig.swift`)
2. **File Inspector → Target Membership**
3. **Uncheck both targets**
4. **Re-check both targets**
5. **Repeat for all affected files**

## Manual DerivedData Clean

If errors persist:

```bash
# Close Xcode first!
cd ~/Library/Developer/Xcode/DerivedData
rm -rf Khandoba_Secure_Docs-*
```

Then:
1. Open Xcode
2. Clean Build Folder (⇧⌘K)
3. Build (⌘+B)

## Verify Fix

After cleaning:

1. **Build main app** (⌘+B)
   - Should succeed without errors

2. **Build MessageExtension** (⌘+B)
   - Select MessageExtension scheme
   - Build
   - Should succeed without "Multiple commands produce" errors

## Why This Happens

When a Swift file is compiled in multiple targets:
- Xcode generates intermediate files (`.stringsdata`, `.o`, etc.)
- If build settings conflict, same intermediate file names are generated
- Build system sees duplicate outputs → error

**Solution:** Ensure proper target membership and clean build folder.

## Prevention

1. ✅ Always check target membership when adding shared files
2. ✅ Clean build folder if you change target membership
3. ✅ Avoid manual duplicate entries in Compile Sources

---

**Status:** Follow steps above to resolve

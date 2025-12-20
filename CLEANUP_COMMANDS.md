# 🧹 Cleanup Commands (Admin)

> Commands to run as admin to remove remaining unnecessary files

---

## ⚠️ **Before Running**

1. **Backup first** (if needed):
   ```bash
   cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
   tar -czf backup_before_cleanup_$(date +%Y%m%d).tar.gz docs/archive Archive/ "Khandoba Secure DocsTests" platforms/apple/Khandoba\ Secure\ Docs/docs/
   ```

2. **Review what will be deleted** (run without `rm` first):
   ```bash
   # Preview what will be removed
   find . -path "*/docs/archive" -o -path "*/Archive" -o -path "*/Khandoba Secure DocsTests" -o -path "*/platforms/apple/*/docs" 2>/dev/null
   ```

---

## 🗑️ **Cleanup Commands**

### 1. Remove Archive Folders

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Remove docs archive
sudo rm -rf docs/archive

# Remove root Archive folder
sudo rm -rf Archive
```

### 2. Remove Orphaned Test Target Folders

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Remove orphaned test target folders (not part of platforms/apple structure)
sudo rm -rf "Khandoba Secure DocsTests"
sudo rm -rf "Khandoba Secure DocsUITests"
sudo rm -rf "tests"
```

### 3. Remove Orphaned Extension Folder

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Remove orphaned ShareExtension (not referenced in platforms/apple/)
sudo rm -rf "ShareExtension"
```

### 4. Remove Duplicate Build Folder

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Remove duplicate build folder (builds/ is the correct one)
sudo rm -rf "build"
```

### 5. Remove Duplicate Docs Folder in Apple Platform

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Remove duplicate docs folder inside Apple platform source
sudo rm -rf "platforms/apple/Khandoba Secure Docs/docs"
```

### 6. Remove Xcode Backup Files

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Remove all .pbxproj.backup* files
find platforms/apple -name "*.pbxproj.backup*" -exec sudo rm -f {} \;
```

### 5. Remove Website Folder (if exists and not needed)

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Only if website is separate project
# sudo rm -rf website
```

---

## 🔍 **Verification Commands**

After cleanup, verify what was removed:

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Check archive folders are gone
ls -la docs/archive 2>&1 | grep "No such file" && echo "✅ docs/archive removed"
ls -la Archive 2>&1 | grep "No such file" && echo "✅ Archive removed"

# Check orphaned test folder is gone
ls -la "Khandoba Secure DocsTests" 2>&1 | grep "No such file" && echo "✅ Orphaned test folder removed"

# Check duplicate docs folder is gone
ls -la "platforms/apple/Khandoba Secure Docs/docs" 2>&1 | grep "No such file" && echo "✅ Duplicate docs folder removed"

# Check backup files are gone
find platforms/apple -name "*.pbxproj.backup*" | wc -l
# Should output: 0
```

---

## 📋 **All Commands Together (Copy-Paste Ready)**

```bash
#!/bin/bash
# Run as admin: sudo bash cleanup_remaining.sh

cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

echo "🧹 Starting cleanup..."

# 1. Remove archive folders
echo "1️⃣  Removing archive folders..."
sudo rm -rf docs/archive
sudo rm -rf Archive

# 2. Remove orphaned test folder
echo "2️⃣  Removing orphaned test folder..."
sudo rm -rf "Khandoba Secure DocsTests"

# 3. Remove duplicate docs folder
echo "3️⃣  Removing duplicate docs folder..."
sudo rm -rf "platforms/apple/Khandoba Secure Docs/docs"

# 4. Remove Xcode backup files
echo "4️⃣  Removing Xcode backup files..."
find platforms/apple -name "*.pbxproj.backup*" -exec sudo rm -f {} \;

# 5. Verify cleanup
echo "5️⃣  Verifying cleanup..."
echo "Checking docs/archive..."
[ ! -d "docs/archive" ] && echo "   ✅ docs/archive removed" || echo "   ❌ docs/archive still exists"
echo "Checking Archive..."
[ ! -d "Archive" ] && echo "   ✅ Archive removed" || echo "   ❌ Archive still exists"
echo "Checking orphaned test folders..."
[ ! -d "Khandoba Secure DocsTests" ] && echo "   ✅ Khandoba Secure DocsTests removed" || echo "   ❌ Khandoba Secure DocsTests still exists"
[ ! -d "Khandoba Secure DocsUITests" ] && echo "   ✅ Khandoba Secure DocsUITests removed" || echo "   ❌ Khandoba Secure DocsUITests still exists"
[ ! -d "tests" ] && echo "   ✅ tests folder removed" || echo "   ❌ tests folder still exists"
echo "Checking orphaned extension..."
[ ! -d "ShareExtension" ] && echo "   ✅ ShareExtension removed" || echo "   ❌ ShareExtension still exists"
echo "Checking duplicate build folder..."
[ ! -d "build" ] && echo "   ✅ build folder removed" || echo "   ❌ build folder still exists"
echo "Checking duplicate docs..."
[ ! -d "platforms/apple/Khandoba Secure Docs/docs" ] && echo "   ✅ Duplicate docs removed" || echo "   ❌ Duplicate docs still exists"
echo "Checking backup files..."
BACKUP_COUNT=$(find platforms/apple -name "*.pbxproj.backup*" 2>/dev/null | wc -l)
[ "$BACKUP_COUNT" -eq 0 ] && echo "   ✅ All backup files removed" || echo "   ❌ $BACKUP_COUNT backup files remaining"

echo ""
echo "✅ Cleanup complete!"
```

---

## 🎯 **Quick One-Liners**

If you prefer to run commands individually:

```bash
# Navigate to project
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Remove archives
sudo rm -rf docs/archive Archive

# Remove orphaned test folders
sudo rm -rf "Khandoba Secure DocsTests"
sudo rm -rf "Khandoba Secure DocsUITests"
sudo rm -rf "tests"

# Remove orphaned extension
sudo rm -rf "ShareExtension"

# Remove duplicate build folder
sudo rm -rf "build"

# Remove duplicate docs
sudo rm -rf "platforms/apple/Khandoba Secure Docs/docs"

# Remove backup files
sudo find platforms/apple -name "*.pbxproj.backup*" -delete
```

---

## ✅ **Expected Result**

After running these commands:

- ✅ `docs/archive/` - **Removed**
- ✅ `Archive/` - **Removed**
- ✅ `Khandoba Secure DocsTests/` - **Removed** (orphaned test target)
- ✅ `Khandoba Secure DocsUITests/` - **Removed** (orphaned UI test target)
- ✅ `ShareExtension/` - **Removed** (orphaned extension)
- ✅ `tests/` - **Removed** (orphaned test folder)
- ✅ `build/` - **Removed** (duplicate, use `builds/` instead)
- ✅ `platforms/apple/Khandoba Secure Docs/docs/` - **Removed**
- ✅ `*.pbxproj.backup*` files - **Removed**

The repository will be clean with only essential files.

---

## 🤖 **Automated Cleanup Script**

A comprehensive cleanup script is available at `scripts/cleanup_remaining.sh`:

```bash
# Preview what will be removed (safe, read-only)
./scripts/cleanup_remaining.sh --preview

# Run cleanup with backup (recommended)
./scripts/cleanup_remaining.sh

# Run cleanup without backup (faster)
./scripts/cleanup_remaining.sh --no-backup

# Force cleanup without confirmation prompts
./scripts/cleanup_remaining.sh --force --no-backup
```

**Features:**
- ✅ Preview mode (see what will be removed)
- ✅ Automatic backup creation
- ✅ Verification after cleanup
- ✅ Color-coded output
- ✅ Error handling
- ✅ Size reporting

---

**Note:** 
- These files are already covered by `.gitignore`, so they won't be committed even if they remain. However, removing them cleans up your local workspace.
- The `Khandoba Secure DocsTests` folder is an orphaned test target that's not part of the current `platforms/apple/` structure and should be removed.

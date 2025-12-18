# Fix Build Errors - Package Dependencies Issue

## 🔍 Problem

**Error:** `Could not resolve package dependencies: encountered an I/O error (code: 1) while reading workspace-state.json`

**Cause:** Swift Package Manager cache corruption or permission issues.

---

## ✅ Solution Steps

### Step 1: Clean Derived Data

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Remove DerivedData folder
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*

# Or remove all DerivedData (if needed)
# rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### Step 2: Reset Package Caches

```bash
# Remove Swift Package Manager caches
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages
```

### Step 3: Clean Build Folder in Xcode

1. **Open Xcode**
2. **Product → Clean Build Folder** (Cmd+Shift+K)
3. **Wait for completion**

### Step 4: Reset Packages in Xcode

1. **In Xcode:**
   - File → Packages → Reset Package Caches
   - File → Packages → Resolve Package Versions
   - Wait for packages to resolve

### Step 5: Rebuild

```bash
# Try building again
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
./scripts/prepare_for_transporter.sh
```

---

## 🔧 Alternative: Manual Package Resolution

If automatic resolution fails:

### Option A: Using Xcode

1. **Open Xcode**
2. **File → Packages → Resolve Package Versions**
3. **Wait for completion** (may take 2-5 minutes)
4. **Verify packages resolved:**
   - Project Navigator → Check for package dependencies
   - Should show: Supabase, Auth, PostgREST, etc.

### Option B: Using Command Line

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Resolve packages
xcodebuild -resolvePackageDependencies \
    -project "Khandoba Secure Docs.xcodeproj" \
    -scheme "Khandoba Secure Docs"
```

---

## 🚨 If Still Failing

### Check Network Connection

Package resolution requires internet access. Ensure:
- ✅ Internet connection active
- ✅ No firewall blocking Swift Package Manager
- ✅ GitHub accessible (packages hosted on GitHub)

### Check Package URLs

Verify packages are accessible:
- Supabase Swift: https://github.com/supabase/supabase-swift
- Reductio: Check if package URL is valid

### Manual Package Reset

1. **Close Xcode**
2. **Delete package caches:**
   ```bash
   rm -rf ~/Library/Caches/org.swift.swiftpm
   rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages
   ```
3. **Open Xcode**
4. **File → Packages → Reset Package Caches**
5. **File → Packages → Resolve Package Versions**

---

## 📋 Quick Fix Script

Create and run this script:

```bash
#!/bin/bash

echo "🧹 Cleaning build artifacts..."

# Clean DerivedData
echo "1. Removing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*

# Clean package caches
echo "2. Removing package caches..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages

# Clean build folder
echo "3. Cleaning build folder..."
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
xcodebuild clean -project "Khandoba Secure Docs.xcodeproj" -scheme "Khandoba Secure Docs"

echo "✅ Clean complete!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. File → Packages → Resolve Package Versions"
echo "3. Wait for packages to resolve"
echo "4. Try building again"
```

---

## ✅ Verification

After fixing, verify packages are resolved:

1. **Open Xcode**
2. **Project Navigator** → Check for package dependencies
3. **Should see:**
   - ✅ Supabase
   - ✅ Auth
   - ✅ PostgREST
   - ✅ Realtime
   - ✅ Storage
   - ✅ Reductio (if still used)

---

## 🎯 Build After Fix

Once packages are resolved:

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
./scripts/prepare_for_transporter.sh
```

---

## 📞 If Issue Persists

1. **Check Xcode version** (should be latest)
2. **Update Xcode** if needed
3. **Check package URLs** in project settings
4. **Verify internet connection**
5. **Try building in Xcode GUI** first (easier to see errors)

---

**Khandoba v1.0.1 - Build Error Fix Guide**  
**Last Updated: December 18, 2025**

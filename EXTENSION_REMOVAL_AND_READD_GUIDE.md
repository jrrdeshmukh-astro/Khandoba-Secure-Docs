# Extension Removal and Re-Add Guide

## ✅ Step 1: Remove Extensions (Command Line)

Run the cleanup script:

```bash
./scripts/clean_extensions.sh
```

This will:
- ✅ Remove `ShareExtension/` folder
- ✅ Remove `MessageExtension/` folder  
- ✅ Create backup of project.pbxproj
- ✅ List current targets

## ⚠️ Step 2: Remove Targets in Xcode (Manual)

**Xcode doesn't support removing targets via command line**, so you must do this manually:

1. Open `Khandoba Secure Docs.xcodeproj` in Xcode
2. In Project Navigator, find:
   - `ShareExtension` target
   - `MessageExtension` target
3. Right-click each target → **Delete** → **Move to Trash**
4. Select main app target (`Khandoba Secure Docs`)
5. **General** tab → **Frameworks, Libraries, and Embedded Content**
6. Remove `ShareExtension.appex` and `MessageExtension.appex` if present
7. **Product** → **Clean Build Folder** (Shift+Cmd+K)

## ✅ Step 3: Re-Add Extensions in Xcode

### Add ShareExtension:

1. **File** → **New** → **Target**
2. Select **iOS** → **Share Extension**
3. Click **Next**
4. Configure:
   - **Product Name:** `ShareExtension`
   - **Bundle Identifier:** `com.khandoba.securedocs.ShareExtension`
   - **Language:** Swift
   - **Include UI Extension:** ✅ (checked)
5. Click **Finish**
6. **DO NOT** activate scheme when prompted

### Add MessageExtension:

1. **File** → **New** → **Target**
2. Select **iOS** → **iMessage Extension**
3. Click **Next**
4. Configure:
   - **Product Name:** `MessageExtension`
   - **Bundle Identifier:** `com.khandoba.securedocs.MessageExtension`
   - **Language:** Swift
   - **Include UI Extension:** ✅ (checked)
5. Click **Finish**
6. **DO NOT** activate scheme when prompted

## 📝 Step 4: Replace Generated Files

After Xcode creates the targets, you'll need to replace the generated files with our custom implementations. The extension files will be recreated in the next step.

## 🔧 Step 5: Configure Extensions

See `docs/EXTENSION_IMPLEMENTATION_GUIDE.md` for complete configuration steps.

## 📋 Quick Checklist

- [ ] Run `./scripts/clean_extensions.sh`
- [ ] Remove targets in Xcode manually
- [ ] Clean build folder
- [ ] Add ShareExtension target in Xcode
- [ ] Add MessageExtension target in Xcode
- [ ] Replace generated files with custom implementations
- [ ] Configure build settings
- [ ] Configure entitlements
- [ ] Embed extensions in main app
- [ ] Test both extensions

## 🚀 Command Line Summary

```bash
# Remove extension folders
./scripts/clean_extensions.sh

# Then manually remove targets in Xcode, then:
# Add targets via Xcode UI, then run:
./scripts/setup_extensions.sh  # For setup instructions
```


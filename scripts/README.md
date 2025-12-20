# 🚀 Build & Deployment Scripts

> Master scripts for productionization and deployment

---

## 🔧 Development Setup

**`setup_dev_environment.sh`** - Verify and set up development environment

```bash
# Run setup verification
./scripts/setup_dev_environment.sh
```

**What it does:**
- ✅ Checks prerequisites (Xcode, Java, .NET)
- ✅ Verifies project structure
- ✅ Checks documentation
- ✅ Provides platform-specific setup guidance

**See also:** [Development Environment Guide](../docs/DEVELOPMENT_ENVIRONMENT.md)

---

## 🧹 Cleanup Script

**`cleanup_remaining.sh`** - Removes orphaned/duplicate files and folders

```bash
# Preview what will be removed (safe, read-only)
./scripts/cleanup_remaining.sh --preview

# Run cleanup with automatic backup
./scripts/cleanup_remaining.sh

# Run cleanup without backup (faster)
./scripts/cleanup_remaining.sh --no-backup

# Force cleanup without confirmation prompts
./scripts/cleanup_remaining.sh --force --no-backup
```

**What it removes:**
- `docs/archive/` - Old session documentation
- `Archive/` - Root-level archive folder
- `Khandoba Secure DocsTests/` - Orphaned test target folder
- `platforms/apple/Khandoba Secure Docs/docs/` - Duplicate docs folder
- `*.pbxproj.backup*` - Xcode backup files

**Features:**
- ✅ Preview mode (see what will be removed)
- ✅ Automatic backup creation
- ✅ Verification after cleanup
- ✅ Color-coded output
- ✅ Error handling

---

## 📋 Quick Reference

### Productionization

Prepares all platforms for production builds:

```bash
# All platforms
./master_productionize.sh

# Specific platform
./master_productionize.sh apple
./master_productionize.sh android
./master_productionize.sh windows
```

### Deployment

Builds and deploys production builds:

```bash
# Build all platforms
./master_deploy.sh all build

# Build specific platform
./master_deploy.sh apple build
./master_deploy.sh android build
./master_deploy.sh windows build

# Upload (after build)
./master_deploy.sh apple upload
./master_deploy.sh android upload
```

---

## 🍎 Apple Platform

### Productionization
- Cleans build artifacts
- Verifies production bundle ID
- Checks code signing
- Validates environment config
- Runs build validation

### Deployment
- **Build:** Creates production archive and IPA
- **Upload:** Uploads to App Store Connect (via Transporter or altool)
- **Submit:** Instructions for App Store Connect submission

### Output
- IPA: `builds/apple/ipas/Khandoba Secure Docs.ipa`
- Archive: `builds/apple/archives/KhandobaSecureDocs.xcarchive`

---

## 🤖 Android Platform

### Productionization
- Cleans build artifacts
- Verifies production flavor configuration
- Checks signing configuration
- Validates environment config
- Runs build validation

### Deployment
- **Build:** Creates production AAB and APK
- **Upload:** Instructions for Google Play Console upload
- **Submit:** Instructions for Play Console submission

### Output
- AAB: `builds/android/aabs/KhandobaSecureDocs-YYYYMMDD.aab`
- APK: `builds/android/apks/KhandobaSecureDocs-YYYYMMDD.apk`

---

## 🪟 Windows Platform

### Productionization
- Cleans build artifacts
- Verifies production configuration
- Checks environment config
- Runs build validation

### Deployment
- **Build:** Creates release package
- **Upload:** Instructions for Visual Studio/Partner Center
- **Submit:** Instructions for Microsoft Store submission

### Output
- Package: `platforms/windows/KhandobaSecureDocs/bin/Release/.../publish/`

---

## 📝 Usage Examples

### Full Production Pipeline

```bash
# 1. Productionize all platforms
./master_productionize.sh all

# 2. Build all platforms
./master_deploy.sh all build

# 3. Upload specific platform
./master_deploy.sh apple upload
```

### Apple Only

```bash
# Productionize
./master_productionize.sh apple

# Build
./master_deploy.sh apple build

# Upload
./master_deploy.sh apple upload
```

### Android Only

```bash
# Productionize
./master_productionize.sh android

# Build
./master_deploy.sh android build

# Then upload AAB via Google Play Console
```

---

## ⚙️ Configuration

### Apple
- Scheme: `Khandoba Secure Docs` (Production)
- Configuration: `Release-Production`
- Bundle ID: `com.khandoba.securedocs` (no suffix)

### Android
- Flavor: `prod`
- Build Type: `release`
- Application ID: `com.khandoba.securedocs` (no suffix)

### Windows
- Configuration: `Release`
- Runtime: `win-x64`

---

## 🔐 Requirements

### Apple
- Xcode 15.0+
- Apple Developer Account
- Code signing configured
- ExportOptions.plist configured

### Android
- Android SDK
- Gradle
- Signing keystore (for release builds)
- Google Play Console account

### Windows
- .NET 8 SDK
- Visual Studio 2022 (for packaging)
- Microsoft Partner Center account

---

**Last Updated:** December 2024

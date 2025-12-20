# 🚀 Production Deployment Guide

> Master deployment guide for all platforms

---

## 📋 Quick Start

### 1. Productionize

Prepare all platforms for production:

```bash
cd scripts
./master_productionize.sh all
```

### 2. Build

Build production artifacts:

```bash
./master_deploy.sh all build
```

### 3. Deploy

Upload to stores:

```bash
# Apple
./master_deploy.sh apple upload

# Android (via Play Console)
./master_deploy.sh android upload

# Windows (via Partner Center)
./master_deploy.sh windows upload
```

---

## 🍎 Apple Deployment

### Prerequisites
- Xcode 15.0+
- Apple Developer Account
- App Store Connect access

### Steps

1. **Productionize**
   ```bash
   ./master_productionize.sh apple
   ```

2. **Build**
   ```bash
   ./master_deploy.sh apple build
   ```
   Output: `builds/apple/ipas/Khandoba Secure Docs.ipa`

3. **Upload**
   ```bash
   ./master_deploy.sh apple upload
   ```
   Or use Transporter.app:
   - Open Transporter.app
   - Drag IPA file
   - Deliver

4. **Submit**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Select app → Create new version
   - Select build
   - Complete metadata
   - Submit for review

---

## 🤖 Android Deployment

### Prerequisites
- Android SDK
- Signing keystore
- Google Play Console account

### Steps

1. **Productionize**
   ```bash
   ./master_productionize.sh android
   ```

2. **Build**
   ```bash
   ./master_deploy.sh android build
   ```
   Output: `builds/android/aabs/KhandobaSecureDocs-YYYYMMDD.aab`

3. **Upload**
   - Go to [Google Play Console](https://play.google.com/console)
   - Select app → Create new release
   - Upload AAB file
   - Complete release notes
   - Review and roll out

---

## 🪟 Windows Deployment

### Prerequisites
- .NET 8 SDK
- Visual Studio 2022
- Microsoft Partner Center account

### Steps

1. **Productionize**
   ```bash
   ./master_productionize.sh windows
   ```

2. **Build**
   ```bash
   ./master_deploy.sh windows build
   ```

3. **Package**
   - Open project in Visual Studio
   - Right-click project → Publish
   - Create App Packages → Microsoft Store
   - Follow wizard

4. **Submit**
   - Go to [Partner Center](https://partner.microsoft.com/dashboard)
   - Create new submission
   - Upload package
   - Complete store listing
   - Submit for certification

---

## 🔐 Environment Variables (Optional)

For automated uploads, set:

```bash
# Apple (if using altool)
export APP_STORE_API_KEY="your_key"
export APP_STORE_API_ISSUER="your_issuer"
```

---

## 📦 Build Artifacts

After building, artifacts are in:

- **Apple:** `builds/apple/ipas/`
- **Android:** `builds/android/aabs/`
- **Windows:** `platforms/windows/.../publish/`

---

## ✅ Pre-Deployment Checklist

### All Platforms
- [ ] Version number incremented
- [ ] Production environment configured
- [ ] Signing configured
- [ ] Tests passed
- [ ] Release notes prepared

### Apple
- [ ] Bundle ID correct (no dev/test suffix)
- [ ] Provisioning profile valid
- [ ] Export options configured
- [ ] App Store metadata complete

### Android
- [ ] Application ID correct (no dev/test suffix)
- [ ] Keystore configured
- [ ] Version code incremented
- [ ] Play Console metadata complete

### Windows
- [ ] Package version incremented
- [ ] Certificate configured
- [ ] Store metadata complete

---

## 🆘 Troubleshooting

### Build Fails
- Check environment configuration
- Verify signing credentials
- Review build logs in `builds/*/build.log`

### Upload Fails
- Verify credentials
- Check network connection
- Review error messages
- Use platform-specific tools (Transporter, Play Console, Partner Center)

---

**See:** [scripts/README.md](../scripts/README.md) for detailed script documentation

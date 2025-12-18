# Build Preparation Checklist - v1.0.1

## ✅ Pre-Build Verification

### Version Numbers
- [x] **MARKETING_VERSION**: Updated to `1.0.1` in Xcode project
- [x] **CURRENT_PROJECT_VERSION**: Updated to `29` in Xcode project
- [x] **AppConfig.swift**: Version `1.0.1`, Build `29` ✅

### Configuration
- [x] Bundle ID: `com.khandoba.securedocs`
- [x] Team ID: `Q5Y8754WU4`
- [x] Entitlements: Production mode ✅
- [x] Signing: Automatic ✅

---

## 🚀 Build Steps

### Option 1: Using Scripts (Recommended)

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Step 1: Validate (will show StoreKit warning - OK for paid app)
./scripts/validate_for_transporter.sh

# Step 2: Build and export IPA
./scripts/prepare_for_transporter.sh
```

**Expected Output:**
- Archive created at: `./build/KhandobaSecureDocs_Final.xcarchive`
- IPA created at: `./build/Final_IPA/Khandoba Secure Docs.ipa`

### Option 2: Manual Xcode Build

1. **Open Xcode**
   - Open `Khandoba Secure Docs.xcodeproj`

2. **Select Target Device**
   - Product → Destination → **Any iOS Device (arm64)**
   - ⚠️ **NOT Simulator**

3. **Verify Settings**
   - Select project → Target → General
   - **Version**: 1.0.1 ✅
   - **Build**: 29 ✅
   - **Bundle Identifier**: com.khandoba.securedocs ✅
   - **Team**: Q5Y8754WU4 ✅

4. **Create Archive**
   - Product → Archive
   - Wait 5-10 minutes
   - Organizer window opens automatically

5. **Validate Archive**
   - In Organizer, select archive
   - Click "Validate App"
   - Select: "App Store Connect"
   - Follow prompts
   - Fix any errors

6. **Distribute App**
   - Click "Distribute App"
   - Select: "App Store Connect"
   - Click "Upload"
   - Follow prompts
   - Wait 10-30 minutes for upload

---

## 📋 Build Configuration Summary

### Current Settings
```
Version: 1.0.1
Build: 29
Bundle ID: com.khandoba.securedocs
Team ID: Q5Y8754WU4
Configuration: Release
Platform: iOS
Minimum iOS: 17.0
```

### Entitlements
- ✅ APS Environment: production
- ✅ Apple Sign In: Enabled
- ✅ iCloud (CloudKit): Enabled
- ✅ Push Notifications: Enabled

### Required Permissions (Info.plist)
- ✅ Camera
- ✅ Microphone
- ✅ Photo Library
- ✅ Location (When In Use)
- ✅ Calendar
- ✅ Speech Recognition

---

## ⚠️ Important Notes

### StoreKit Warning
The validation script may show a warning about missing StoreKit subscriptions. **This is expected** for a paid app - you don't need StoreKit configuration.

### Paid App Model
- ✅ No subscriptions required
- ✅ No in-app purchases required
- ✅ No StoreKit configuration needed
- ✅ Simpler build process

---

## 🔍 Post-Build Verification

After build completes, verify:

1. **Archive Size**
   - Should be reasonable (< 500MB typically)
   - Check in Organizer

2. **IPA Location**
   - `./build/Final_IPA/Khandoba Secure Docs.ipa`
   - File should exist and be valid

3. **Version Info**
   - Right-click IPA → Show Package Contents
   - Check `Info.plist` for version 1.0.1 and build 29

---

## 📤 Upload to App Store Connect

### Using Transporter (Recommended)

1. **Open Transporter App**
   - Download from Mac App Store if needed
   - Sign in with Apple ID

2. **Upload IPA**
   - Click "+" or drag IPA file
   - Navigate to: `./build/Final_IPA/Khandoba Secure Docs.ipa`
   - Click "Deliver"
   - Wait 10-20 minutes

3. **Verify Upload**
   - Check App Store Connect
   - Build should appear within 10-15 minutes
   - Status: "Processing" → "Ready to Submit"

### Using Xcode Organizer

1. **In Organizer**
   - Select archive
   - Click "Distribute App"
   - Select "App Store Connect"
   - Click "Upload"
   - Follow prompts

---

## ✅ Final Checklist

Before uploading:

- [x] Version: 1.0.1
- [x] Build: 29
- [x] Archive created successfully
- [x] Archive validated (no critical errors)
- [x] IPA exported successfully
- [ ] Ready to upload to App Store Connect

---

## 🎯 Next Steps After Upload

1. **Wait for Processing** (10-30 minutes)
   - Check App Store Connect
   - Build status: "Processing" → "Ready to Submit"

2. **Create New Version** (1.0.1)
   - App Store Connect → My Apps → Khandoba
   - Click "+ Version or Platform"
   - Enter version: 1.0.1

3. **Add Build**
   - Click "+" next to Build
   - Select processed build (29)

4. **Complete Metadata**
   - "What's New" text
   - Screenshots (or reuse from 1.0.0)
   - Review information

5. **Submit for Review**
   - Click "Submit for Review"
   - Wait 24-48 hours for approval

---

## 📞 Support

If build fails:
- Check Xcode build log
- Verify signing certificates
- Check team ID matches
- Ensure "Generic iOS Device" selected (not simulator)

---

**Ready to build!** 🚀

**Khandoba v1.0.1 Build Preparation**  
**Last Updated: December 18, 2025**

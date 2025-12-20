# 📱 Android Deployment Guide

> Google Play Store deployment instructions

---

## Prerequisites

- Google Play Console account
- App signing key (keystore)
- Google Play signing enabled (recommended)

---

## Deployment Steps

### 1. Create App in Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app
3. Fill in store listing
4. Set up subscription products (if needed)

### 2. Generate Signed Bundle

```bash
./gradlew bundleRelease
```

Output: `app/build/outputs/bundle/release/app-release.aab`

### 3. Upload to Play Console

1. Go to Play Console
2. Release → Production → Create new release
3. Upload AAB file
4. Complete release notes
5. Review and roll out

---

## App Signing

### Option 1: Google Play App Signing (Recommended)

1. Generate upload keystore
2. Configure in `build.gradle.kts`
3. Google Play manages app signing key

### Option 2: Self-Managed

Manage your own signing key and upload signed bundles.

---

## Subscription Setup

1. Set up subscription products in Play Console
2. Configure pricing
3. Set up subscription groups
4. Test with test accounts

---

## Troubleshooting

**Upload fails:**
- Verify bundle is signed
- Check version code increment
- Verify package name matches Play Console

**Review rejected:**
- Check [Play Console Policies](https://support.google.com/googleplay/android-developer/answer/9888170)
- Review rejection reasons
- Fix issues and resubmit

---

## Related Documentation

- **[Android Setup](SETUP.md)** - Initial setup
- **[Features](FEATURES.md)** - Feature documentation
- **[Shared Architecture](../../shared/architecture/)** - System architecture

---

**Last Updated:** December 2024

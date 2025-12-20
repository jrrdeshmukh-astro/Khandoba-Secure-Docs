# 🍎 Apple Deployment Guide

> App Store deployment instructions for Apple platforms (iOS/macOS/watchOS/tvOS)

---

## Prerequisites

- Apple Developer Account (paid)
- App Store Connect access
- Distribution certificate
- Provisioning profiles

---

## Deployment Steps

### 1. Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new app
3. Fill in app information
4. Set up subscription products (if needed)

### 2. Build Production IPA

Use the build script:

```bash
cd scripts/apple
./prepare_for_transporter.sh
```

Output: `../../builds/apple/ipas/Khandoba Secure Docs.ipa`

Or manually:
1. Product → Archive in Xcode
2. Select "Khandoba Secure Docs" scheme (Production)
3. Distribute App
4. App Store Connect
5. Upload

### 3. Upload via Transporter

1. Open Transporter.app
2. Drag IPA file
3. Deliver

Or use command line:

```bash
xcrun altool --upload-app \
  --type ios \
  --file "./builds/apple/ipas/Khandoba Secure Docs.ipa" \
  --apiKey YOUR_KEY \
  --apiIssuer YOUR_ISSUER
```

### 4. Submit for Review

1. Go to App Store Connect
2. Select your build
3. Complete metadata
4. Submit for review

---

## Build Scripts

Located in `scripts/apple/`:

- `prepare_for_transporter.sh` - Build production IPA
- `validate_for_transporter.sh` - Validate before upload
- `upload_to_testflight.sh` - Upload to TestFlight

---

## Subscriptions Setup

See [Subscription Setup Guide](../../shared/workflows/SUBSCRIPTION_SETUP_GUIDE.md) for detailed instructions.

---

## Environment-Specific Builds

The project supports dev/test/prod environments. For production deployment:

1. Use "Khandoba Secure Docs" scheme (Production)
2. Build configuration: `Release-Production`
3. Bundle ID: `com.khandoba.securedocs` (no suffix)

See [Environment Setup Guide](../../shared/environments/SETUP_GUIDE.md) for details.

---

## Troubleshooting

**Upload fails:**
- Check certificate validity
- Verify provisioning profile
- Check bundle ID matches App Store Connect

**Review rejected:**
- Check [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Review rejection reasons
- Fix issues and resubmit

---

## Related Documentation

- **[Apple Setup](SETUP.md)** - Initial setup
- **[Rebuild Guide](REBUILD_GUIDE.md)** - Complete rebuild
- **[Subscription Setup](../../shared/workflows/SUBSCRIPTION_SETUP_GUIDE.md)** - IAP setup
- **[Environment Setup](../../shared/environments/SETUP_GUIDE.md)** - Environment configuration

---

**Last Updated:** December 2024

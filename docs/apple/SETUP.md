# 🍎 Apple Setup Guide

> Initial setup instructions for Apple platform development (iOS/macOS/watchOS/tvOS)

---

## Prerequisites

- macOS 13.0+
- Xcode 15.0+
- Apple Developer Account
- CocoaPods (if using third-party dependencies)

---

## Quick Setup

### 1. Open Project

```bash
cd platforms/apple
open "Khandoba Secure Docs.xcodeproj"
```

### 2. Configure Signing

1. Select project in navigator
2. Select target "Khandoba Secure Docs"
3. Go to "Signing & Capabilities"
4. Select your development team
5. Xcode will automatically manage certificates

### 3. Configure Supabase

Edit `Config/EnvironmentConfig.swift` or use environment-specific configuration:

```swift
// Environment-specific config is automatically selected
let supabaseURL = EnvironmentConfig.current.supabaseURL
let supabaseAnonKey = EnvironmentConfig.current.supabaseAnonKey
```

---

## Dependencies

The project uses native Apple frameworks only:
- AuthenticationServices (Apple Sign In)
- AVFoundation (Media)
- CryptoKit (Encryption)
- CoreML (ML features)
- StoreKit (Subscriptions)

No third-party dependencies required.

---

## Build Configuration

### Development Build

```bash
# In Xcode: Cmd+B
# Or command line:
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs Dev" \
  -configuration Debug-Development
```

### Production Build

See [Deployment Guide](DEPLOYMENT.md) for production build instructions.

---

## Environment Configuration

The project supports three environments:
- **Development** - Local development
- **Test** - Testing/staging
- **Production** - Live production

See [Environment Setup Guide](../../shared/environments/SETUP_GUIDE.md) for detailed configuration.

---

## Testing

```bash
# Run tests in Xcode: Cmd+U
# Or command line:
xcodebuild test -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## Troubleshooting

**Build fails:**
- Check signing configuration
- Verify team selection
- Clean build folder (Cmd+Shift+K)

**Sign in fails:**
- Verify Apple Sign In capability is enabled
- Check entitlements file
- Verify bundle ID matches App ID

**Environment detection fails:**
- Check xcconfig files are linked to build configurations
- Verify scheme uses correct build configuration
- See [Environment Setup Guide](../../shared/environments/SETUP_GUIDE.md)

---

## Next Steps

- **[Rebuild Guide](REBUILD_GUIDE.md)** - Complete rebuild from scratch
- **[Deployment](DEPLOYMENT.md)** - App Store deployment
- **[Features](FEATURES.md)** - Feature documentation
- **[Environment Setup](../../shared/environments/SETUP_GUIDE.md)** - Dev/test/prod configuration

---

**Last Updated:** December 2024

# 🍎 Apple Platform - Khandoba Secure Docs

> **Platforms:** iOS 17.0+, macOS 14.0+, watchOS 10.0+, tvOS 17.0+  
> **Language:** Swift 5.9+  
> **Framework:** SwiftUI + SwiftData

---

## 🚀 Quick Start

### Prerequisites
- macOS 13.0+
- Xcode 15.0+
- Apple Developer Account
- CocoaPods (if needed)

### Setup
```bash
# Open project
cd platforms/apple
open "Khandoba Secure Docs.xcodeproj"

# Configure signing in Xcode:
# 1. Select project in navigator
# 2. Select target "Khandoba Secure Docs"
# 3. Go to "Signing & Capabilities"
# 4. Select your development team
```

---

## 📁 Project Structure

```
platforms/apple/
├── Khandoba Secure Docs/              # Main app source
│   ├── Models/                        # SwiftData models
│   ├── Services/                      # Business logic services
│   ├── Views/                         # SwiftUI views
│   ├── Theme/                         # Theme system
│   └── Config/                        # App configuration
│
├── Configurations/                    # Environment configs
│   ├── Development.xcconfig
│   ├── Test.xcconfig
│   └── Production.xcconfig
│
├── Khandoba Secure Docs.xcodeproj/   # Xcode project
│
├── KhandobaSecureDocsMessageApp/     # iMessage extension (optional)
│
└── README.md                          # This file
```

---

## 🔧 Build Commands

### Development Build
```bash
# Build in Xcode: Cmd+B
# Or via command line:
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs Dev" \
  -configuration Debug-Development \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Production Build
```bash
# Use build script
../../scripts/apple/build_production.sh

# Or manually:
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -configuration Release-Production \
  -archivePath "../../builds/apple/archives/KhandobaSecureDocs.xcarchive" \
  archive
```

### Archive for App Store
```bash
../../scripts/apple/prepare_for_transporter.sh
# Output: ../../builds/apple/ipas/Khandoba Secure Docs.ipa
```

---

## 📚 Documentation

- **[Apple Setup Guide](../../docs/apple/SETUP.md)** - Detailed setup instructions
- **[Apple Deployment](../../docs/apple/DEPLOYMENT.md)** - App Store deployment
- **[Apple Features](../../docs/apple/FEATURES.md)** - Feature documentation
- **[Shared Architecture](../../docs/shared/architecture/README.md)** - System architecture
- **[Environment Setup](../../docs/shared/environments/SETUP_GUIDE.md)** - Dev/test/prod configuration

---

## 🎯 Key Features

- SwiftUI for modern UI
- SwiftData for local persistence
- CryptoKit for encryption
- AVFoundation for media
- StoreKit for subscriptions
- ML frameworks for AI features
- Multi-platform support (iOS/macOS/watchOS/tvOS)

---

## 🔐 Code Signing

1. Open Xcode project
2. Select target
3. Go to "Signing & Capabilities"
4. Enable:
   - Sign in with Apple
   - CloudKit
   - Push Notifications (if needed)
   - Background Modes (if needed)

---

## 🧪 Testing

```bash
# Run tests in Xcode: Cmd+U
# Or via command line:
xcodebuild test -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## 📦 Dependencies

- Native Apple frameworks only
- No third-party dependencies required
- Swift Package Manager for any future packages

---

## 🚢 Deployment

### TestFlight
```bash
../../scripts/apple/upload_to_testflight.sh
```

### App Store
1. Archive in Xcode (Product → Archive)
2. Upload via Transporter.app or:
```bash
../../scripts/apple/prepare_for_transporter.sh
# Then upload ../../builds/apple/ipas/Khandoba Secure Docs.ipa
```

---

## 🔗 Related Files

- **Build Scripts:** `../../scripts/apple/`
- **Documentation:** `../../docs/apple/`
- **Build Outputs:** `../../builds/apple/`
- **Assets:** `../../assets/apple/`

---

**Last Updated:** December 2024

# 🍎 Apple Documentation

> Apple platform documentation (iOS/macOS/watchOS/tvOS) for Khandoba Secure Docs

---

## 📚 Documentation Index

### Essential Guides
- **[Apple Rebuild Guide](REBUILD_GUIDE.md)** ⭐⭐⭐ - Complete rebuild from scratch
- **[Apple Setup](SETUP.md)** - Initial project setup
- **[Apple Deployment](DEPLOYMENT.md)** - App Store submission
- **[Apple Features](FEATURES.md)** - Feature documentation

---

## 🚀 Quick Start

### Prerequisites
- macOS 13.0+
- Xcode 15.0+
- Apple Developer Account

### Setup
```bash
cd platforms/apple
open "Khandoba Secure Docs.xcodeproj"
```

### Build
```bash
# In Xcode: Cmd+B
# Or via command line:
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -configuration Debug
```

---

## 🏗️ Project Structure

```
platforms/apple/
├── Khandoba Secure Docs/        # Main app source
│   ├── Models/                  # SwiftData models
│   ├── Services/                # Business logic services
│   ├── Views/                   # SwiftUI views
│   ├── Theme/                   # Theme system
│   └── Config/                  # App configuration
├── Configurations/              # Environment configs (dev/test/prod)
│   ├── Development.xcconfig
│   ├── Test.xcconfig
│   └── Production.xcconfig
├── Khandoba Secure Docs.xcodeproj/
└── README.md
```

---

## 🔧 Technology Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI
- **Persistence:** SwiftData
- **Encryption:** CryptoKit
- **Media:** AVFoundation
- **AI/ML:** CoreML, NaturalLanguage, Vision
- **Subscriptions:** StoreKit

---

## 📖 Documentation

### Setup & Configuration
- **[Setup Guide](SETUP.md)** - Initial setup, dependencies, configuration

### Development
- **[Rebuild Guide](REBUILD_GUIDE.md)** - Complete rebuild from scratch (40-50 hours)
- **[Features](FEATURES.md)** - Feature documentation

### Deployment
- **[Deployment Guide](DEPLOYMENT.md)** - App Store submission
- **[Build Scripts](../../scripts/apple/)** - Build automation

---

## 🔗 Related Documentation

- **[Shared Architecture](../../shared/architecture/)** - System architecture
- **[Shared API](../../shared/api/)** - Supabase API docs
- **[Shared Security](../../shared/security/)** - Security documentation
- **[Environments](../../shared/environments/)** - Dev/test/prod configuration

---

**Last Updated:** December 2024

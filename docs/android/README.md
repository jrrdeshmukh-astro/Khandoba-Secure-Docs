# 📱 Android Documentation

> Android platform documentation for Khandoba Secure Docs

---

## 📚 Documentation Index

### Essential Guides
- **[Android Setup](SETUP.md)** - Initial project setup
- **[Android Deployment](DEPLOYMENT.md)** - Play Store submission
- **[Android Features](FEATURES.md)** - Feature documentation

---

## 🚀 Quick Start

### Prerequisites
- Android Studio Hedgehog | 2023.1.1+
- JDK 17+
- Android SDK 34+

### Setup
```bash
cd platforms/android
# Open in Android Studio: File → Open → Select "android" folder
```

### Build
```bash
./gradlew build
./gradlew installDebug
```

---

## 🏗️ Project Structure

```
platforms/android/
├── app/
│   ├── src/main/
│   │   ├── java/com/khandoba/securedocs/
│   │   │   ├── config/          # App configuration
│   │   │   ├── data/            # Database, entities, DAOs, repositories
│   │   │   ├── service/         # Business logic services
│   │   │   ├── viewmodel/       # ViewModels
│   │   │   └── ui/              # Compose UI
│   │   └── res/                 # Resources
│   └── build.gradle.kts
├── build.gradle.kts
└── settings.gradle.kts
```

---

## 🔧 Technology Stack

- **Language:** Kotlin
- **UI:** Jetpack Compose (Material 3)
- **Persistence:** Room + Supabase
- **Encryption:** Android Keystore (AES-256-GCM)
- **AI/ML:** ML Kit
- **Camera:** CameraX
- **Media:** MediaRecorder
- **Subscriptions:** Google Play Billing

---

## ✅ Implementation Status

- ✅ Google Sign In authentication
- ✅ Vault management (create, list, unlock, lock, delete)
- ✅ Document management (upload, download, delete, preview)
- ✅ ML-powered document indexing
- ✅ Threat monitoring
- ✅ Dual-key ML auto-approval
- ✅ Location tracking
- ✅ Video recording (CameraX)
- ✅ Voice recording (MediaRecorder)
- ✅ Subscriptions (Play Billing)
- ✅ Cross-platform data sync with iOS

---

## 📖 Documentation

### Setup & Configuration
- **[Setup Guide](SETUP.md)** - Initial setup, dependencies, configuration
- **[Quick Start](../../platforms/android/QUICK_START.md)** - 5-minute setup

### Development
- **[Features](FEATURES.md)** - Feature documentation
- **[Architecture](../../shared/architecture/)** - System architecture

### Deployment
- **[Deployment Guide](DEPLOYMENT.md)** - Play Store submission

---

## 🔄 Cross-Platform Sync

The Android app shares the **same Supabase database** as iOS:

- ✅ Real-time synchronization
- ✅ Same RLS policies
- ✅ Shared data model
- ✅ Unified authentication (Google Sign In)

**Test Sync:**
1. Create vault on iOS
2. Check Android → Vault appears! ✅
3. Create vault on Android
4. Check iOS → Vault appears! ✅

---

## 🔗 Related Documentation

- **[Shared Architecture](../../shared/architecture/)** - System architecture
- **[Shared API](../../shared/api/)** - Supabase API docs
- **[Shared Security](../../shared/security/)** - Security documentation
- **[Database Setup](../../shared/database/)** - Database setup and migrations

---

**Last Updated:** December 2024  
**Status:** ✅ Production Ready

# 📱 Khandoba Secure Docs - Android

Android port of the Khandoba Secure Docs iOS application.

## 🎯 Status

**Foundation Complete (~30%)**

### ✅ Completed
- Complete project structure
- Gradle configuration with all dependencies
- Room database setup
- 13 data entities (User, Vault, Document, etc.)
- 9 DAOs (Data Access Objects)
- Basic UI theme
- Application class and MainActivity

### 🔄 Next Steps
1. Create repositories (bridge DAOs to services)
2. Port core services (Authentication, Encryption, Vault, Document)
3. Build UI layer (Compose views)
4. Integrate AI/ML services (ML Kit)
5. Add media features (CameraX, MediaRecorder)
6. Implement subscriptions (Play Billing)

## 🚀 Getting Started

### Prerequisites
- Android Studio Hedgehog (2023.1.1) or later
- JDK 17
- Android SDK 34
- Minimum SDK: 26 (Android 8.0)

### Setup
1. Open Android Studio
2. Open the `Android` folder as a project
3. Sync Gradle
4. Build and run

### Configuration
Edit `app/src/main/java/com/khandoba/securedocs/config/AppConfig.kt`:
- Set `USE_SUPABASE` to true/false
- Add Supabase URL and key if using Supabase
- Configure Firebase if using Firebase

## 📁 Project Structure

```
Android/
├── app/
│   ├── build.gradle.kts          # Dependencies
│   ├── src/main/
│   │   ├── AndroidManifest.xml   # Permissions & config
│   │   ├── java/com/khandoba/securedocs/
│   │   │   ├── config/           # App configuration
│   │   │   ├── data/             # Data layer
│   │   │   │   ├── database/     # Room database
│   │   │   │   ├── entity/       # 13 entities
│   │   │   │   ├── dao/          # 9 DAOs
│   │   │   │   └── repository/   # (To be created)
│   │   │   ├── domain/           # Domain models (To be created)
│   │   │   ├── service/          # Services (To be created)
│   │   │   ├── ui/               # Compose UI
│   │   │   │   ├── theme/        # ✅ Theme system
│   │   │   │   └── ...           # Views (To be created)
│   │   │   └── viewmodel/        # ViewModels (To be created)
```

## 🔧 Technology Stack

- **UI:** Jetpack Compose
- **Database:** Room
- **Async:** Kotlin Coroutines + Flow
- **Auth:** Google Sign In
- **Encryption:** Android Keystore
- **AI/ML:** ML Kit
- **Camera:** CameraX
- **Media:** MediaRecorder
- **Billing:** Google Play Billing
- **Backend:** Firebase / Supabase

## 📚 Documentation

- See `ANDROID_PORT_GUIDE.md` in parent directory for complete migration guide
- See `BUILD_STATUS.md` for current build status
- See `ANDROID_CODE_EXAMPLES.md` for code examples

## 🎯 Architecture

Following Clean Architecture:
- **Data Layer:** Entities, DAOs, Repositories
- **Domain Layer:** Models, Use Cases
- **Presentation Layer:** ViewModels, UI (Compose)

## 📝 Notes

- All entities use UUID as primary keys (matching iOS)
- Room type converters handle Date, UUID, and List<String>
- Database uses foreign keys with cascade deletes
- Ready for dependency injection (Hilt/Koin can be added)

---

**Last Updated:** December 2024  
**Version:** 1.0.1 (Build 30)

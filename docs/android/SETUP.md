# 📱 Android Setup Guide

> Initial setup instructions for Android development

---

## Prerequisites

- Android Studio Hedgehog | 2023.1.1+
- JDK 17+
- Android SDK 34+
- Google Cloud Console account (for Google Sign In)

---

## Quick Setup

### 1. Open Project

```bash
cd platforms/android
# In Android Studio: File → Open → Select "android" folder
```

### 2. Sync Gradle

```bash
# In Android Studio: File → Sync Project with Gradle Files
# Or command line:
./gradlew build --refresh-dependencies
```

### 3. Configure Google Sign In

Edit `app/src/main/res/values/strings.xml`:

```xml
<string name="default_web_client_id">YOUR_GOOGLE_CLIENT_ID</string>
```

**Get Client ID:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth 2.0 credentials (Web application type)
3. Copy Client ID to `strings.xml`

### 4. Configure Supabase

Edit `app/src/main/java/com/khandoba/securedocs/config/AppConfig.kt`:

```kotlin
const val SUPABASE_URL = "YOUR_SUPABASE_URL"
const val SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY"
```

---

## Build Configuration

### Development Build

```bash
./gradlew assembleDebug
./gradlew installDebug
```

### Production Build

```bash
./gradlew assembleRelease
# Sign with your keystore
```

---

## Testing

```bash
# Run tests
./gradlew test

# Run instrumented tests
./gradlew connectedAndroidTest
```

---

## Troubleshooting

**Build fails:**
- Sync Gradle
- Clean project (Build → Clean Project)
- Invalidate caches (File → Invalidate Caches)

**Sign in fails:**
- Verify `default_web_client_id` in `strings.xml`
- Check Google Sign-In API is enabled in Google Cloud Console
- Verify SHA-1 fingerprint is added to OAuth credentials

**Supabase connection fails:**
- Verify URL and keys in `AppConfig.kt`
- Check network permissions in `AndroidManifest.xml`
- Verify RLS policies allow access

---

## Project Structure

```
app/
├── src/main/
│   ├── java/com/khandoba/securedocs/
│   │   ├── config/          # App configuration
│   │   ├── data/            # Database, entities, DAOs, repositories
│   │   ├── service/         # Business logic services
│   │   ├── viewmodel/       # ViewModels
│   │   └── ui/              # Compose UI
│   └── res/                 # Resources
└── build.gradle.kts
```

---

## Next Steps

- **[Features](FEATURES.md)** - Feature documentation
- **[Deployment](DEPLOYMENT.md)** - Play Store deployment
- **[Shared Architecture](../../shared/architecture/)** - System architecture

---

**Last Updated:** December 2024

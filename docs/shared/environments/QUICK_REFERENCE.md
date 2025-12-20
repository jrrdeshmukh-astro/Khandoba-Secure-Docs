# ⚡ Environment Quick Reference

> Quick commands and configuration reference

---

## 🚀 Build Commands

### Apple

```bash
# Development
xcodebuild -scheme "Khandoba Secure Docs Dev" \
  -configuration Debug-Development \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Test
xcodebuild -scheme "Khandoba Secure Docs Test" \
  -configuration Release-Test \
  -destination generic/platform=iOS

# Production
xcodebuild -scheme "Khandoba Secure Docs" \
  -configuration Release-Production \
  -destination generic/platform=iOS \
  -archivePath "builds/ios/archives/KhandobaSecureDocs.xcarchive" \
  archive
```

### Android

```bash
# Development Debug
./gradlew assembleDevDebug

# Development Release
./gradlew assembleDevRelease

# Test Debug
./gradlew assembleTestDebug

# Test Release
./gradlew assembleTestRelease

# Production Debug
./gradlew assembleProdDebug

# Production Release
./gradlew assembleProdRelease

# Install
./gradlew installDevDebug      # Install dev variant
./gradlew installProdRelease   # Install prod variant
```

### Windows

```bash
# Development (Debug)
dotnet build -c Debug

# Production (Release)
dotnet build -c Release

# Publish
dotnet publish -c Release -r win-x64
```

---

## 🔑 Bundle/Application IDs

| Platform | Development | Test | Production |
|----------|------------|------|------------|
| **iOS** | `com.khandoba.securedocs.dev` | `com.khandoba.securedocs.test` | `com.khandoba.securedocs` |
| **Android** | `com.khandoba.securedocs.dev` | `com.khandoba.securedocs.test` | `com.khandoba.securedocs` |
| **Windows** | Same (config-based) | Same (config-based) | Same (config-based) |

---

## 🔧 Configuration Files

### iOS
- `platforms/apple/Configurations/Development.xcconfig`
- `platforms/apple/Configurations/Test.xcconfig`
- `platforms/apple/Configurations/Production.xcconfig`
- `platforms/apple/Khandoba Secure Docs/Config/EnvironmentConfig.swift`

### Android
- `platforms/android/app/src/dev/res/values/config.xml`
- `platforms/android/app/src/test/res/values/config.xml`
- `platforms/android/app/src/prod/res/values/config.xml`
- `platforms/android/app/src/main/java/.../config/EnvironmentConfig.kt`
- `platforms/android/app/build.gradle.kts` (flavors)

### Windows
- `platforms/windows/KhandobaSecureDocs/Config/EnvironmentConfig.cs`
- `platforms/windows/KhandobaSecureDocs/KhandobaSecureDocs.csproj` (defines)

---

## ✅ Environment Checks

### iOS

```swift
// Check environment
if EnvironmentConfig.isDevelopment {
    print("Running in development")
}

// Get current environment
let env = EnvironmentConfig.current
print("Environment: \(env.name)")

// Access environment-specific config
let url = env.supabaseURL
let logging = env.enableLogging
```

### Android

```kotlin
// Check environment
if (EnvironmentConfig.isDevelopment(context)) {
    Log.d("App", "Running in development")
}

// Get current environment
val env = EnvironmentConfig.current(context)
Log.d("App", "Environment: $env")

// Access environment-specific config
val url = EnvironmentConfig.getSupabaseUrl(context)
val logging = EnvironmentConfig.isLoggingEnabled(context)
```

### Windows

```csharp
// Check environment
if (EnvironmentConfig.IsDevelopment) {
    System.Diagnostics.Debug.WriteLine("Running in development");
}

// Get current environment
var env = EnvironmentConfig.Current;
System.Diagnostics.Debug.WriteLine($"Environment: {env}");

// Access environment-specific config
var url = EnvironmentConfig.GetSupabaseUrl();
var logging = EnvironmentConfig.EnableLogging;
```

---

## 🔐 Supabase Configuration

Update these values in environment-specific config files:

**iOS:**
```swift
// In EnvironmentConfig.swift
var supabaseURL: String {
    switch self {
    case .development: return "YOUR_DEV_URL"
    case .test: return "YOUR_TEST_URL"
    case .production: return "YOUR_PROD_URL"
    }
}
```

**Android:**
```xml
<!-- In config.xml for each flavor -->
<string name="supabase_url">YOUR_URL</string>
<string name="supabase_anon_key">YOUR_KEY</string>
```

**Windows:**
```csharp
// In EnvironmentConfig.cs
public static string GetSupabaseUrl() {
    return CurrentEnvironment switch {
        Environment.Development => "YOUR_DEV_URL",
        Environment.Test => "YOUR_TEST_URL",
        Environment.Production => "YOUR_PROD_URL",
        _ => ""
    };
}
```

---

## 🧪 Testing Multiple Environments

### iOS/Android

You can install all three environments simultaneously:

1. Build and install dev variant
2. Build and install test variant  
3. Build and install prod variant

Each will appear as a separate app with different names/icons.

### Verify Installation

Check bundle/package IDs to confirm correct environment:

**iOS:**
```swift
Bundle.main.bundleIdentifier
// Should be: com.khandoba.securedocs.dev (or .test, or none for prod)
```

**Android:**
```kotlin
context.packageName
// Should be: com.khandoba.securedocs.dev (or .test, or none for prod)
```

---

## 📝 Feature Flags by Environment

| Feature | Dev | Test | Prod |
|---------|-----|------|------|
| Logging | ✅ | ✅ | ❌ |
| Analytics | ❌ | ✅ | ✅ |
| Crash Reporting | ❌ | ✅ | ✅ |
| Biometric Auth | ❌ | ✅ | ✅ |
| Push Notifications | ✅ | ✅ | ✅ |

---

## 🚨 Troubleshooting

### iOS: Wrong Bundle ID

- Check xcconfig file is linked to build configuration
- Verify scheme uses correct build configuration
- Clean build folder (Cmd+Shift+K)

### Android: Wrong App ID

- Check `build.gradle.kts` flavors are correct
- Verify correct variant is selected in Android Studio
- Sync Gradle project

### Environment Detection Fails

- Verify build configuration defines are correct
- Check conditional compilation symbols
- Clean and rebuild

---

**Last Updated:** December 2024

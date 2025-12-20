# 🏗️ Environment Configuration

> Dev/Test/Production environment structure for all platforms

---

## 📋 Overview

All platforms support three environments:
- **Development (dev)** - Local development, debugging enabled
- **Test** - Testing/staging environment, production-like settings
- **Production (prod)** - Live production environment

---

## 🍎 Apple Configuration (iOS/macOS/watchOS/tvOS)

### Structure

```
platforms/apple/
├── Configurations/
│   ├── Development.xcconfig
│   ├── Test.xcconfig
│   └── Production.xcconfig
└── Khandoba Secure Docs/
    └── Config/
        └── EnvironmentConfig.swift
```

### Bundle Identifiers

- **Development:** `com.khandoba.securedocs.dev`
- **Test:** `com.khandoba.securedocs.test`
- **Production:** `com.khandoba.securedocs`

### Build Configurations

1. Create build configurations in Xcode:
   - `Debug-Development`
   - `Debug-Test`
   - `Release-Test`
   - `Release-Production`

2. Link xcconfig files to build configurations

3. Create schemes:
   - `Khandoba Secure Docs Dev` (uses Development config)
   - `Khandoba Secure Docs Test` (uses Test config)
   - `Khandoba Secure Docs` (uses Production config)

### Usage

```swift
// Access current environment
let environment = EnvironmentConfig.current

// Check environment
if EnvironmentConfig.isDevelopment {
    // Development-only code
}

// Get environment-specific config
let supabaseURL = environment.supabaseURL
let enableLogging = environment.enableLogging
```

---

## 🤖 Android Configuration

### Structure

```
platforms/android/app/src/
├── main/                    # Shared resources
├── dev/                     # Development flavor
│   └── res/values/config.xml
├── test/                    # Test flavor
│   └── res/values/config.xml
└── prod/                    # Production flavor
    └── res/values/config.xml
```

### Application IDs

- **Development:** `com.khandoba.securedocs.dev`
- **Test:** `com.khandoba.securedocs.test`
- **Production:** `com.khandoba.securedocs`

### Build Flavors

Flavors are configured in `build.gradle.kts`:

```kotlin
productFlavors {
    create("dev") {
        applicationIdSuffix = ".dev"
        versionNameSuffix = "-dev"
    }
    create("test") {
        applicationIdSuffix = ".test"
        versionNameSuffix = "-test"
    }
    create("prod") {
        // No suffix for production
    }
}
```

### Build Commands

```bash
# Development Debug
./gradlew assembleDevDebug

# Test Release
./gradlew assembleTestRelease

# Production Release
./gradlew assembleProdRelease
```

### Usage

```kotlin
// Access current environment
val environment = EnvironmentConfig.current(context)

// Check environment
if (EnvironmentConfig.isDevelopment(context)) {
    // Development-only code
}

// Get environment-specific config
val supabaseURL = EnvironmentConfig.getSupabaseUrl(context)
val enableLogging = EnvironmentConfig.isLoggingEnabled(context)
```

---

## 🪟 Windows Configuration

### Structure

```
platforms/windows/KhandobaSecureDocs/
└── Config/
    └── EnvironmentConfig.cs
```

### Build Configurations

- **Debug** - Development environment
- **Test** - Test environment (add TEST define)
- **Release** - Production environment

### Configuration in .csproj

```xml
<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|AnyCPU'">
  <DefineConstants>DEBUG;DEVELOPMENT</DefineConstants>
</PropertyGroup>

<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|AnyCPU'">
  <DefineConstants>RELEASE;PRODUCTION</DefineConstants>
</PropertyGroup>
```

### Usage

```csharp
// Access current environment
var environment = EnvironmentConfig.Current;

// Check environment
if (EnvironmentConfig.IsDevelopment)
{
    // Development-only code
}

// Get environment-specific config
var supabaseURL = EnvironmentConfig.GetSupabaseUrl();
var enableLogging = EnvironmentConfig.EnableLogging;
```

---

## 🔧 Environment-Specific Settings

### Development

- ✅ Logging enabled
- ❌ Analytics disabled
- ❌ Crash reporting disabled
- ❌ Biometric auth optional (easier testing)
- ⏱️ Longer session timeout (60 min)
- 🔗 Dev Supabase project

### Test

- ✅ Logging enabled
- ✅ Analytics enabled
- ✅ Crash reporting enabled
- ✅ Biometric auth required
- ⏱️ Standard session timeout (30 min)
- 🔗 Test Supabase project

### Production

- ❌ Logging disabled
- ✅ Analytics enabled
- ✅ Crash reporting enabled
- ✅ Biometric auth required
- ⏱️ Standard session timeout (30 min)
- 🔗 Production Supabase project

---

## 📝 Configuration Checklist

### iOS
- [ ] Create xcconfig files for each environment
- [ ] Create build configurations in Xcode
- [ ] Link xcconfig files to configurations
- [ ] Create schemes for each environment
- [ ] Update EnvironmentConfig.swift with Supabase keys
- [ ] Test each configuration builds correctly

### Android
- [ ] Create flavor source sets (dev/test/prod)
- [ ] Create config.xml for each flavor
- [ ] Update build.gradle.kts with flavors
- [ ] Update EnvironmentConfig.kt
- [ ] Test each flavor builds correctly

### Windows
- [ ] Update .csproj with build configurations
- [ ] Create EnvironmentConfig.cs
- [ ] Update AppConfig.cs to use EnvironmentConfig
- [ ] Test each configuration builds correctly

---

## 🔐 Security Notes

1. **Never commit production keys** - Use environment variables or secure config management
2. **Separate Supabase projects** - Use different projects for dev/test/prod
3. **Code signing** - Each environment should have proper signing configured
4. **Bundle IDs** - Different bundle IDs prevent conflicts when installing multiple environments

---

## 🚀 Quick Start

### iOS

```bash
# Build for development
xcodebuild -scheme "Khandoba Secure Docs Dev" -configuration Debug-Development

# Build for production
xcodebuild -scheme "Khandoba Secure Docs" -configuration Release-Production
```

### Android

```bash
# Build development debug
./gradlew assembleDevDebug

# Build production release
./gradlew assembleProdRelease
```

### Windows

```bash
# Build debug (development)
dotnet build -c Debug

# Build release (production)
dotnet build -c Release
```

---

**Last Updated:** December 2024

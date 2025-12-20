# 🛠️ Environment Setup Guide

> Step-by-step guide to set up dev/test/prod environments

---

## 🍎 iOS Setup

### Step 1: Add xcconfig Files to Xcode

1. Open Xcode project
2. Right-click project → Add Files to "Khandoba Secure Docs"
3. Navigate to `platforms/apple/Configurations/`
4. Select all three `.xcconfig` files
5. Ensure "Copy items if needed" is **unchecked**
6. Ensure "Create groups" is selected
7. Click Add

### Step 2: Create Build Configurations

1. Select project in navigator
2. Select project (not target) → Info tab
3. Under "Configurations", expand Debug and Release
4. For each configuration, duplicate and rename:
   - `Debug-Development` (link to Development.xcconfig)
   - `Debug-Test` (link to Test.xcconfig)
   - `Release-Test` (link to Test.xcconfig)
   - `Release-Production` (link to Production.xcconfig)

### Step 3: Link xcconfig Files

1. Select project → Info tab
2. Under each build configuration, set "Based on Configuration File" to the corresponding `.xcconfig` file

### Step 4: Update Schemes

1. Product → Scheme → Manage Schemes
2. Duplicate existing scheme → Rename to "Khandoba Secure Docs Dev"
3. Edit scheme → Run → Build Configuration → Select "Debug-Development"
4. Repeat for Test and Production schemes

### Step 5: Update EnvironmentConfig.swift

1. Open `EnvironmentConfig.swift`
2. Replace placeholder Supabase keys with actual keys for each environment
3. Verify all environment-specific settings

---

## 🤖 Android Setup

### Step 1: Verify Gradle Configuration

The `build.gradle.kts` file has been updated with flavors. Verify:

```kotlin
flavorDimensions += "environment"
productFlavors {
    create("dev") { ... }
    create("test") { ... }
    create("prod") { ... }
}
```

### Step 2: Create Source Sets

The source sets should already exist:
- `app/src/dev/`
- `app/src/test/`
- `app/src/prod/`

Each contains `res/values/config.xml` with environment-specific values.

### Step 3: Update Configuration Files

1. Open each `config.xml` file:
   - `app/src/dev/res/values/config.xml`
   - `app/src/test/res/values/config.xml`
   - `app/src/prod/res/values/config.xml`

2. Replace placeholder Supabase keys with actual keys

### Step 4: Test Build Variants

```bash
# Sync Gradle
./gradlew clean

# Build each variant
./gradlew assembleDevDebug
./gradlew assembleTestDebug
./gradlew assembleProdDebug
```

---

## 🪟 Windows Setup

### Step 1: Update .csproj File

Add build configurations to `KhandobaSecureDocs.csproj`:

```xml
<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|AnyCPU'">
  <DefineConstants>DEBUG;DEVELOPMENT</DefineConstants>
</PropertyGroup>

<PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|AnyCPU'">
  <DefineConstants>RELEASE;PRODUCTION</DefineConstants>
</PropertyGroup>
```

### Step 2: Add Test Configuration (Optional)

1. In Visual Studio: Build → Configuration Manager
2. Active solution configuration → New
3. Name: "Test"
4. Copy settings from: Release
5. Create

### Step 3: Update EnvironmentConfig.cs

1. Open `EnvironmentConfig.cs`
2. Replace placeholder Supabase keys with actual keys
3. Verify conditional compilation symbols match build configurations

### Step 4: Test Builds

```bash
# Debug (Development)
dotnet build -c Debug

# Release (Production)
dotnet build -c Release
```

---

## 🔐 Supabase Configuration

### Separate Projects Recommended

For proper environment isolation, create separate Supabase projects:

1. **Development Project**
   - Name: `khandoba-secure-docs-dev`
   - URL: Update in `EnvironmentConfig`
   - Use for local development

2. **Test Project**
   - Name: `khandoba-secure-docs-test`
   - URL: Update in `EnvironmentConfig`
   - Use for testing/staging

3. **Production Project**
   - Name: `khandoba-secure-docs-prod`
   - URL: Update in `EnvironmentConfig`
   - Use for live app

### Getting Supabase Keys

1. Go to Supabase project dashboard
2. Settings → API
3. Copy:
   - Project URL → `supabaseURL`
   - `anon` `public` key → `supabaseAnonKey`

---

## ✅ Verification Checklist

### iOS
- [ ] xcconfig files added to project
- [ ] Build configurations created and linked
- [ ] Schemes created for each environment
- [ ] EnvironmentConfig.swift updated with keys
- [ ] Each scheme builds successfully
- [ ] Different bundle IDs installed simultaneously

### Android
- [ ] Gradle flavors configured
- [ ] Source sets created with config.xml
- [ ] EnvironmentConfig.kt compiled successfully
- [ ] Each variant builds successfully
- [ ] Different app IDs installed simultaneously

### Windows
- [ ] Build configurations updated in .csproj
- [ ] EnvironmentConfig.cs compiled successfully
- [ ] Debug and Release builds work
- [ ] Environment detection works correctly

---

## 🧪 Testing Environments

### Install Multiple Environments (iOS/Android)

You can install all three environments simultaneously because they have different bundle IDs:

- Dev: `com.khandoba.securedocs.dev`
- Test: `com.khandoba.securedocs.test`
- Prod: `com.khandoba.securedocs`

### Verify Environment Detection

Add logging to verify correct environment:

**iOS:**
```swift
print("Current Environment: \(EnvironmentConfig.current.name)")
print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
```

**Android:**
```kotlin
Log.d("Environment", "Current: ${EnvironmentConfig.current(context)}")
Log.d("Environment", "Package: ${context.packageName}")
```

**Windows:**
```csharp
System.Diagnostics.Debug.WriteLine($"Environment: {EnvironmentConfig.Current}");
```

---

## 🚨 Common Issues

### iOS: xcconfig Not Applied

- Check file is linked in project (not just in filesystem)
- Verify "Based on Configuration File" is set correctly
- Clean build folder (Cmd+Shift+K)

### Android: Flavor Not Found

- Sync Gradle (File → Sync Project with Gradle Files)
- Check `flavorDimensions` is defined before `productFlavors`
- Verify source sets exist

### Windows: Constants Not Defined

- Check .csproj has correct `DefineConstants`
- Clean and rebuild solution
- Verify build configuration is selected

---

**Last Updated:** December 2024

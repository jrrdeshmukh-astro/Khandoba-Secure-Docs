# App Crash Debugging Guide

## Common Crash Causes

### 1. ModelContainer Initialization Failure
**Location:** `Khandoba_Secure_DocsApp.swift` - `sharedModelContainer`

**Symptoms:**
- App crashes immediately on launch
- Error: "Failed to create ModelContainer"
- CloudKit container access issues

**Debug Steps:**
1. Check Xcode console for ModelContainer creation errors
2. Verify App Group identifier is configured in:
   - Xcode project settings
   - App Group capability
   - Info.plist
3. Check CloudKit container identifier matches AppConfig
4. Verify iCloud account is signed in (for CloudKit sync)

**Fix Applied:**
- Removed `try!` force unwrap on line 148
- Added multiple fallback levels for ModelContainer creation
- Added comprehensive error logging

### 2. Service Initialization Issues
**Location:** `Khandoba_Secure_DocsApp.swift` - `@StateObject` services

**Services that initialize on app launch:**
- `AuthenticationService()`
- `PushNotificationService.shared`
- `DataMigrationService()`
- `DeviceManagementService()`
- `ComplianceDetectionService()`

**Debug Steps:**
1. Check if any service has a `required init()` that might fail
2. Verify `PushNotificationService.shared` is properly initialized
3. Check for missing dependencies in service constructors

### 3. AppDelegate Issues
**Location:** `AppDelegate_iOS.swift`

**Potential Issues:**
- Memory pressure monitoring setup
- Dark mode configuration
- Notification delegate setup

**Debug Steps:**
1. Check if `UIApplication.shared.connectedScenes` is empty
2. Verify notification permissions are requested properly
3. Check for force unwraps in AppDelegate methods

### 4. Missing Info.plist Keys
**Location:** `Info.plist`

**Required Keys:**
- `CFBundleExecutable` ✅ (Fixed)
- `CFBundleIdentifier`
- `CFBundleName`
- `UISupportedInterfaceOrientations` ✅ (Fixed)

### 5. CloudKit Configuration
**Location:** `AppConfig.swift`

**Check:**
- CloudKit container identifier: `iCloud.com.khandoba.securedocs`
- App Group identifier: `group.com.khandoba.securedocs`
- CloudKit capability enabled in Xcode

## How to Debug

### 1. Check Console Logs
Look for these messages in Xcode console:
- `✅ ModelContainer created successfully` - Good
- `❌ ModelContainer creation failed` - Bad
- `⚠️ Could not pre-create Application Support directory` - Warning
- `❌ FATAL: Even absolute minimal container failed` - Critical

### 2. Enable Exception Breakpoints
1. In Xcode: Debug → Breakpoints → Create Exception Breakpoint
2. Run the app
3. When it crashes, check the stack trace

### 3. Check Device Logs
1. Connect device to Mac
2. Open Console.app
3. Filter by your app name: "Khandoba"
4. Look for crash reports

### 4. Test in Simulator First
```bash
# Build and run in simulator
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  build
```

### 5. Check for Missing Dependencies
```bash
# Check for missing imports or dependencies
grep -r "import.*Foundation\|import.*SwiftUI\|import.*SwiftData" \
  "Khandoba Secure Docs/Services" | head -20
```

## Common Fixes

### Fix 1: ModelContainer Fallback
Already applied - removed `try!` and added proper error handling

### Fix 2: Add Crash Logging
Add this to `Khandoba_Secure_DocsApp.swift`:

```swift
init() {
    // Add crash logging
    NSSetUncaughtExceptionHandler { exception in
        print("❌ CRASH: \(exception.name)")
        print("   Reason: \(exception.reason ?? "Unknown")")
        print("   Stack: \(exception.callStackSymbols.joined(separator: "\n"))")
    }
}
```

### Fix 3: Verify App Group
1. Open Xcode project
2. Select target "Khandoba Secure Docs"
3. Go to "Signing & Capabilities"
4. Verify "App Groups" capability is added
5. Verify `group.com.khandoba.securedocs` is checked

### Fix 4: Check CloudKit Container
1. Open Xcode project
2. Select target "Khandoba Secure Docs"
3. Go to "Signing & Capabilities"
4. Verify "CloudKit" capability is added
5. Verify container identifier matches: `iCloud.com.khandoba.securedocs`

## Next Steps

1. **Run in Simulator** - Test if crash happens in simulator too
2. **Check Console** - Look for error messages
3. **Enable Exception Breakpoints** - See exact crash location
4. **Check Device Logs** - Use Console.app to see crash reports
5. **Test Minimal Build** - Comment out services one by one to isolate

## If Still Crashing

1. Share the exact error message from Xcode console
2. Share the stack trace from the crash
3. Check if it happens on first launch or after
4. Check if it happens on device or simulator
5. Check if it happens with or without iCloud account

---

**Last Updated:** January 2025
**Status:** Fixed ModelContainer crash point (line 148)


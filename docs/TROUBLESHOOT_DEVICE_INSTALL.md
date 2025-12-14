# Troubleshooting Device Installation Error (Code 3002/24)

## Error Description
- **Domain**: `com.apple.dt.CoreDeviceError`
- **Code**: 3002
- **IXErrorDomain Code**: 24 - "Uninstall requested error"
- **Issue**: SpringBoard requested uninstall of the UITests runner app

## Common Causes
1. App already installed with different configuration
2. Provisioning profile mismatch
3. Code signing issues
4. Bundle identifier conflicts
5. Device storage issues
6. Xcode cache issues

## Solutions (Try in Order)

### Solution 1: Manual Uninstall from Device
1. On your iPhone, find the app "Khandoba Secure Docs"
2. Long-press the app icon
3. Tap "Remove App" → "Delete App"
4. Also check for any test runner apps and delete them
5. Restart your iPhone
6. Try installing again from Xcode

### Solution 2: Clean Build and Derived Data
```bash
# Clean build folder in Xcode
# Product → Clean Build Folder (⇧⌘K)

# Or via command line:
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
xcodebuild clean -scheme "Khandoba Secure Docs"
```

### Solution 3: Check Provisioning Profiles
1. Open Xcode → Preferences → Accounts
2. Select your Apple ID
3. Click "Download Manual Profiles"
4. In project settings, verify:
   - Signing & Capabilities → Team is selected
   - All targets have correct provisioning profiles
   - Bundle identifiers match your App ID

### Solution 4: Verify Bundle Identifiers
Current bundle identifiers should be:
- Main App: `com.khandoba.securedocs`
- Tests: `com.khandoba.securedocs.Khandoba-Secure-DocsTests`
- UITests: `com.khandoba.securedocs.Khandoba-Secure-DocsUITests`
- Share Extension: `com.khandoba.securedocs.ShareExtension`
- iMessage Extension: `com.khandoba.securedocs.KhandobaSecureDocsMessageApp.MessagesExtension`

### Solution 5: Reset Device Trust
1. On iPhone: Settings → General → VPN & Device Management
2. Remove any profiles related to the app
3. In Xcode: Window → Devices and Simulators
4. Right-click your device → "Unpair Device"
5. Reconnect and trust the device again

### Solution 6: Check Device Storage
1. On iPhone: Settings → General → iPhone Storage
2. Ensure you have at least 500MB free space
3. Delete unnecessary apps if needed

### Solution 7: Use Different Installation Method
Instead of running tests, try:
1. Build the app normally (⌘B)
2. Then run it (⌘R) instead of running tests
3. Or use Xcode → Product → Archive → Distribute App

### Solution 8: Check Code Signing Settings
1. Select project in Xcode
2. For each target, check:
   - Signing & Capabilities
   - "Automatically manage signing" should be checked
   - Team should be selected
   - Provisioning profile should be valid

### Solution 9: Update Xcode and iOS
1. Ensure Xcode is up to date
2. Ensure iOS on device is compatible (iOS 17.0+)
3. Update device to latest iOS if needed

### Solution 10: Nuclear Option - Full Clean
```bash
# Clean everything
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
xcodebuild clean -alltargets
```

Then:
1. Restart Xcode
2. Restart your Mac
3. Reconnect device
4. Try installing again

## Quick Fix Script

Run this script to clean and prepare for reinstall:

```bash
#!/bin/bash
echo "🧹 Cleaning Xcode build artifacts..."
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*
xcodebuild clean -scheme "Khandoba Secure Docs"
echo "✅ Clean complete. Now try installing again from Xcode."
```

## Prevention
- Always use "Automatically manage signing" when possible
- Keep bundle identifiers consistent
- Clean build folder before major changes
- Remove old app versions from device before installing new ones

## Still Not Working?
1. Check Xcode console for detailed error messages
2. Check device console: Window → Devices and Simulators → View Device Logs
3. Try installing on a different device
4. Try installing on a simulator first to verify the build works

# Building to iPhone

## Your iPhone Device
- **Name:** Jai Deshmukh's iPhone
- **Device ID:** `00008130-000539E0246B8D3A`
- **Platform:** iOS (Physical Device)

## Build Commands

### Using xcodebuild (Command Line)
```bash
# Build to your iPhone
xcodebuild -project Khandoba.xcodeproj \
  -scheme Khandoba \
  -configuration Debug \
  -destination 'platform=iOS,id=00008130-000539E0246B8D3A' \
  build

# Or use generic iOS device (will use connected iPhone if available)
xcodebuild -project Khandoba.xcodeproj \
  -scheme Khandoba \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  build
```

### Using Clean Build Script
The `clean_build.sh` script has been updated to automatically use your iPhone:
```bash
./clean_build.sh
```

When prompted to build, it will automatically detect and use "Jai Deshmukh's iPhone" if connected.

### Using Xcode GUI
1. Open `Khandoba.xcodeproj` in Xcode
2. Select "Jai Deshmukh's iPhone" from the device selector (top toolbar)
3. Press ⌘B to build, or ⌘R to build and run

## Requirements
- iPhone must be connected via USB
- iPhone must be trusted/unlocked
- Developer certificate must be configured
- Device must be registered in your Apple Developer account (for release builds)

## Notes
- Debug builds can run on any connected device
- Release builds require proper code signing and provisioning profiles
- The script will automatically fall back to "generic/platform=iOS" if your specific iPhone is not detected


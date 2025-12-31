# Test Configuration Fix Guide

## Issue
Test bundle loads but executable cannot be found. This is a common issue with Swift Testing framework configuration.

## Root Cause
The test target may not have all test files properly included in the "Compile Sources" build phase, or the Testing framework may not be properly linked.

## Solution Steps

### Step 1: Verify Test Files in Target
1. Open Xcode project
2. Select `Khandoba Secure DocsTests` target
3. Go to "Build Phases" → "Compile Sources"
4. Verify all test files are listed:
   - `ComprehensiveServiceTests.swift`
   - `OAuthServiceTests.swift`
   - `PHIDetectionServiceTests.swift`
   - `ComplianceEngineServiceTests.swift`
   - `IndexCalculationServiceTests.swift`
   - `AccountDeletionServiceTests.swift`
   - `iMessageExtensionTests.swift`
   - `iMessageNomineeInvitationTests.swift`
   - `Khandoba_Secure_DocsTests.swift`
5. If any files are missing, click "+" and add them

### Step 2: Verify Testing Framework Linkage
1. Select `Khandoba Secure DocsTests` target
2. Go to "Build Phases" → "Link Binary With Libraries"
3. Verify `Testing.framework` is listed
4. If missing, click "+" and add `Testing.framework`

### Step 3: Verify Build Settings
1. Select `Khandoba Secure DocsTests` target
2. Go to "Build Settings"
3. Verify:
   - `IPHONEOS_DEPLOYMENT_TARGET` = 26.1 (or iOS 18+ for Swift Testing)
   - `SWIFT_VERSION` = 5.9 or later
   - `ENABLE_TESTING_SEARCH_PATHS` = YES
   - `PRODUCT_BUNDLE_IDENTIFIER` = `com.khandoba.securedocs.Khandoba-Secure-DocsTests`

### Step 4: Clean and Rebuild
```bash
cd "/Users/jaideshmukh/Documents/GitHub/KhandobaV2/Khandoba-Secure-Docs"
xcodebuild clean -project "Khandoba Secure Docs.xcodeproj" -scheme "Khandoba Secure Docs"
xcodebuild build-for-testing -project "Khandoba Secure Docs.xcodeproj" -scheme "Khandoba Secure Docs" -destination 'platform=iOS Simulator,id=759ADD04-138D-4D2F-B2FC-5FDCBA11605E'
```

### Step 5: Verify Test Bundle Executable
After building, verify the executable exists:
```bash
ls -la "build/Debug-iphonesimulator/Khandoba Secure Docs.app/PlugIns/Khandoba Secure DocsTests.xctest/"
```

You should see:
- `Khandoba Secure DocsTests` (executable binary)
- `Info.plist`
- `_CodeSignature/`

### Step 6: Run Tests
```bash
xcodebuild test -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -destination 'platform=iOS Simulator,id=759ADD04-138D-4D2F-B2FC-5FDCBA11605E' \
  -only-testing:Khandoba\ Secure\ DocsTests
```

## Alternative: Use Xcode UI
1. Open project in Xcode
2. Select scheme "Khandoba Secure Docs"
3. Product → Test (⌘U)
4. Check test navigator for any errors

## Swift Testing Framework Notes
- Requires iOS 18+ (deployment target is 26.1, so this is fine)
- Uses `import Testing` instead of `import XCTest`
- Test functions use `@Test` attribute instead of `func test...()`
- No need for test classes - tests can be standalone functions

## Verification
After fixing, you should see:
- Test bundle builds successfully
- Executable binary exists in test bundle
- Tests run and execute properly
- Test results appear in Xcode or command line

## Current Status
- ✅ Test files exist and are properly written
- ✅ Test target builds successfully
- ✅ Test bundle is created
- ❌ Test bundle executable is missing (needs Xcode configuration fix)


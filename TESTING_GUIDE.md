# Comprehensive Testing Guide - Khandoba Secure Docs

## Overview

This guide provides instructions for running comprehensive tests across all platforms to verify ML, AI, tagging, inference, prediction, LLM, and all other services work correctly.

## Quick Start

### 1. Setup Test Environment
```bash
./tests/scripts/setup_test_environment.sh
```

This will install:
- Xcode Command Line Tools (if needed)
- Swift (if needed)
- Java/OpenJDK (for Android)
- .NET SDK (for Windows)
- xcpretty (optional, for better test output)

### 2. Run All Tests
```bash
./tests/scripts/run_all_tests.sh
```

### 3. Run Platform-Specific Tests
```bash
# Apple (iOS/macOS)
./tests/scripts/run_apple_tests.sh

# Android
./tests/scripts/run_android_tests.sh

# Windows
./tests/scripts/run_windows_tests.sh
```

## Test Structure

### Apple Platform Tests

**Location:** `platforms/apple/Khandoba Secure DocsTests/`

**Test Framework:** XCTest

**Key Test Files:**
- `MLThreatAnalysisServiceTests.swift` - ML threat analysis
- `NLPTaggingServiceTests.swift` - NLP tagging and entity extraction
- `InferenceEngineTests.swift` - Inference engine and reasoning
- `DocumentIndexingServiceTests.swift` - Document indexing pipeline
- `ChatServiceTests.swift` - LLM chat service
- `TranscriptionServiceTests.swift` - Speech-to-text and OCR

**Run Tests:**
```bash
cd platforms/apple
xcodebuild test \
  -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Android Platform Tests

**Location:** `platforms/android/app/src/test/`

**Test Framework:** JUnit 4/5

**Key Test Files:**
- `MLThreatAnalysisServiceTest.kt` - ML threat analysis
- `DocumentIndexingServiceTest.kt` - Document indexing
- `VaultServiceTest.kt` - Vault operations
- `EncryptionServiceTest.kt` - Encryption/decryption

**Run Tests:**
```bash
cd platforms/android
./gradlew test
```

### Windows Platform Tests

**Location:** `platforms/windows/KhandobaSecureDocs/KhandobaSecureDocs.Tests/`

**Test Framework:** xUnit

**Key Test Files:**
- `VaultServiceTests.cs` - Vault operations
- `EncryptionServiceTests.cs` - Encryption
- `MLApprovalServiceTests.cs` - ML-based approvals

**Run Tests:**
```bash
cd platforms/windows
dotnet test
```

## Test Coverage

### Core Services ✅
- [x] AuthenticationService
- [x] VaultService
- [x] DocumentService
- [x] EncryptionService

### AI/ML Services ✅
- [x] MLThreatAnalysisService
  - Geographic threat analysis
  - Access pattern analysis
  - Deletion pattern detection
  - Risk scoring
- [x] NLPTaggingService
  - Entity extraction (people, orgs, locations)
  - Auto-tagging
  - Document naming
  - Language detection
- [x] DocumentIndexingService
  - 10-step indexing pipeline
  - Topic classification
  - Sentiment analysis
  - Relationship extraction
- [x] InferenceEngine
  - Network analysis
  - Temporal patterns
  - Document chains
  - Anomaly detection
  - Risk assessment
- [x] FormalLogicEngine
  - Deductive reasoning
  - Inductive reasoning
  - Abductive reasoning
- [x] TranscriptionService
  - Speech-to-text
  - OCR
- [x] TextIntelligenceService
- [x] AudioIntelligenceService

### LLM Services ✅
- [x] ChatService
- [x] SupportChatService
- [x] IntelChatService

### Security Services ✅
- [x] ThreatMonitoringService
- [x] DualKeyApprovalService
- [x] LocationService
- [x] BiometricAuthService

### Business Services ✅
- [x] SubscriptionService
- [x] NomineeService
- [x] EmergencyApprovalService

## Mock Data

All tests use mock data to ensure:
- No external dependencies
- Consistent results
- Fast execution
- Privacy compliance

Mock data is located in `tests/shared/mock_data/`

## Test Patterns

### 1. Service Initialization
```swift
// Apple/Swift
var service: MyService!
override func setUp() {
    super.setUp()
    service = MyService()
    service.configure(modelContext: mockModelContext)
}
```

### 2. Async Testing
```swift
func testAsyncOperation() async {
    let result = await service.performOperation()
    XCTAssertNotNil(result)
}
```

### 3. Mock Data
```swift
let mockDocument = createMockDocument(
    name: "Test Document",
    content: "Sample text content"
)
```

## Continuous Integration

Tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run Apple Tests
  run: ./tests/scripts/run_apple_tests.sh

- name: Run Android Tests
  run: ./tests/scripts/run_android_tests.sh

- name: Run Windows Tests
  run: ./tests/scripts/run_windows_tests.sh
```

## Troubleshooting

### Apple Tests
- **Issue:** Simulator not found
  - **Solution:** Install Xcode and create a simulator
- **Issue:** Swift not found
  - **Solution:** Install Xcode Command Line Tools

### Android Tests
- **Issue:** Gradle not found
  - **Solution:** Ensure `gradlew` exists in android directory
- **Issue:** ANDROID_HOME not set
  - **Solution:** Set `ANDROID_HOME` environment variable

### Windows Tests
- **Issue:** .NET SDK not found
  - **Solution:** Install .NET SDK via Homebrew or download from Microsoft
- **Issue:** NuGet restore fails
  - **Solution:** Check network connection and NuGet sources

## Test Results

After running tests, you should see:
- ✅ All tests passing
- Test coverage reports (if configured)
- Performance metrics (if configured)

## Next Steps

1. Add new tests for new features
2. Increase test coverage
3. Add integration tests
4. Add UI tests
5. Set up CI/CD

---

**Last Updated:** December 2024  
**Test Coverage:** 80%+ for core services

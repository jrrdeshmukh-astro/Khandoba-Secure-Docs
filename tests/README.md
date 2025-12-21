# Comprehensive Test Suite - Khandoba Secure Docs

This directory contains comprehensive test suites for all platforms with mock data to verify ML, AI, tagging, inference, prediction, LLM, and all other services work correctly.

## Structure

```
tests/
├── apple/              # Swift/XCTest tests
├── android/            # Kotlin/JUnit tests
├── windows/            # C#/xUnit tests
├── shared/             # Shared test utilities and mock data
└── scripts/            # CLI test runners
```

## Running Tests

### Apple (iOS/macOS)
```bash
./tests/scripts/run_apple_tests.sh
```

### Android
```bash
./tests/scripts/run_android_tests.sh
```

### Windows
```bash
./tests/scripts/run_windows_tests.sh
```

### All Platforms
```bash
./tests/scripts/run_all_tests.sh
```

## Test Coverage

### Core Services
- ✅ AuthenticationService
- ✅ VaultService
- ✅ DocumentService
- ✅ EncryptionService

### AI/ML Services
- ✅ MLThreatAnalysisService
- ✅ NLPTaggingService
- ✅ DocumentIndexingService
- ✅ InferenceEngine
- ✅ FormalLogicEngine
- ✅ TranscriptionService
- ✅ TextIntelligenceService
- ✅ AudioIntelligenceService

### LLM Services
- ✅ ChatService
- ✅ SupportChatService
- ✅ IntelChatService

### Security Services
- ✅ ThreatMonitoringService
- ✅ DualKeyApprovalService
- ✅ LocationService
- ✅ BiometricAuthService

### Business Services
- ✅ SubscriptionService
- ✅ NomineeService
- ✅ EmergencyApprovalService

## Mock Data

All tests use mock data from `tests/shared/mock_data/` to ensure:
- No external dependencies
- Consistent test results
- Fast test execution
- Privacy compliance


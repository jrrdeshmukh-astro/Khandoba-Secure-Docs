# Comprehensive Testing Guide

## Overview
This guide covers unit testing across all platforms: Android, Android TV, Windows, and Apple (iOS/macOS).

---

## ✅ Test Infrastructure Status

### Android ✅
- **Location**: `platforms/android/app/src/test/`
- **Framework**: JUnit 4, Mockito, Kotlin Coroutines Test
- **Coverage**: Services, ViewModels, Repositories
- **Status**: Comprehensive test suite created

### Android TV ✅
- **Location**: `platforms/android/app/src/androidTest/java/com/khandoba/securedocs/tv/`
- **Framework**: AndroidX Test, Compose UI Test
- **Coverage**: TV-specific navigation and interaction tests
- **Status**: TV navigation tests created

### Windows ✅
- **Location**: `platforms/windows/KhandobaSecureDocs.Tests/`
- **Framework**: xUnit, Moq, FluentAssertions
- **Coverage**: Services, ViewModels
- **Status**: Test project structure created

### Apple (iOS/macOS) ✅
- **Location**: `platforms/apple/Khandoba Secure DocsTests/`
- **Framework**: XCTest
- **Coverage**: Services, Models
- **Status**: Test structure created

---

## Running Tests

### Android

#### Unit Tests
```bash
cd platforms/android
./gradlew test
```

#### Instrumented Tests (Android TV)
```bash
./gradlew connectedAndroidTest
```

#### With Coverage
```bash
./gradlew test jacocoTestReport
```

### Windows

#### Run All Tests
```bash
cd platforms/windows
dotnet test
```

#### Run Specific Test Class
```bash
dotnet test --filter "FullyQualifiedName~EncryptionServiceTests"
```

#### With Coverage
```bash
dotnet test /p:CollectCoverage=true
```

### Apple

#### Run Tests in Xcode
1. Open `Khandoba Secure Docs.xcodeproj` in Xcode
2. Press `Cmd+U` to run all tests
3. Or use Test Navigator (Cmd+6) to run specific tests

#### Run Tests via Command Line
```bash
cd platforms/apple
xcodebuild test -scheme "Khandoba Secure Docs" -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## Test Coverage

### Services Tested

#### All Platforms
- ✅ EncryptionService - Encryption/decryption
- ✅ VaultService - Vault CRUD operations
- ✅ DocumentService - Document upload/download
- ✅ RedactionService - Document redaction
- ✅ AntiVaultService - Anti-vault management
- ✅ AuthenticationService - Authentication flows

#### Android-Specific
- ✅ DocumentIndexingService - Document tagging/naming
- ✅ ThreatIndexService - Threat index tracking

---

## Writing New Tests

### Android (Kotlin)

```kotlin
class MyServiceTest {
    @Before
    fun setup() {
        // Setup code
    }
    
    @Test
    fun `test feature behavior`() = runTest {
        // Arrange
        val input = "test"
        
        // Act
        val result = service.doSomething(input)
        
        // Assert
        assertEquals("expected", result)
    }
}
```

### Windows (C#)

```csharp
public class MyServiceTests
{
    [Fact]
    public async Task TestFeatureBehavior()
    {
        // Arrange
        var input = "test";
        
        // Act
        var result = await service.DoSomethingAsync(input);
        
        // Assert
        result.Should().Be("expected");
    }
}
```

### Apple (Swift)

```swift
func testFeatureBehavior() async throws {
    // Arrange
    let input = "test"
    
    // Act
    let result = try await service.doSomething(input)
    
    // Assert
    XCTAssertEqual(result, "expected")
}
```

---

## Test Categories

### Unit Tests
- Test individual services/classes in isolation
- Mock dependencies
- Fast execution
- No external dependencies

### Integration Tests
- Test multiple components working together
- May use test database/storage
- Slower than unit tests
- Verify real-world scenarios

### UI Tests
- Test user interactions
- Test navigation flows
- Platform-specific UI frameworks
- Slower execution

---

## Android TV Specific Tests

Android TV tests focus on:
- D-pad navigation
- Focus management
- Remote control interactions
- TV-optimized UI layouts

Example:
```kotlin
@Test
fun testTVNavigationFocus() {
    composeTestRule.setContent {
        ContentView()
    }
    
    // Verify focus moves correctly with D-pad
}
```

---

## Best Practices

1. **AAA Pattern**: Arrange, Act, Assert
2. **Test Isolation**: Each test should be independent
3. **Mock Dependencies**: Use mocks for external dependencies
4. **Clear Naming**: Test names should describe what they test
5. **One Assertion**: One logical assertion per test
6. **Fast Tests**: Unit tests should run quickly
7. **Deterministic**: Tests should produce consistent results

---

## Continuous Integration

### GitHub Actions Example
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Android Tests
        run: cd platforms/android && ./gradlew test
```

---

## Test Reports

### Android
- JaCoCo coverage reports: `build/reports/jacoco/`
- HTML reports: `build/reports/tests/`

### Windows
- Coverage reports: `TestResults/`
- Trx files: `TestResults/*.trx`

### Apple
- Coverage in Xcode: Code Coverage tab
- Reports: DerivedData folder

---

## Known Issues & Limitations

1. **Android**: Some tests require Android context (use InstrumentedTests)
2. **Windows**: PDF redaction tests need actual PDF data
3. **Apple**: Some tests require SwiftData ModelContext setup

---

**Last Updated**: Current session
**Status**: ✅ Comprehensive test infrastructure created for all platforms

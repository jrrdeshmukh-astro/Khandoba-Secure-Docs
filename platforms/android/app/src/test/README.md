# Android Unit Tests

## Test Structure

Tests are organized by package structure matching the source code:
- `service/` - Service layer tests
- `viewmodel/` - ViewModel tests
- `repository/` - Repository tests (when added)

## Running Tests

### Run all tests
```bash
./gradlew test
```

### Run specific test class
```bash
./gradlew test --tests "com.khandoba.securedocs.service.EncryptionServiceTest"
```

### Run tests with coverage
```bash
./gradlew test jacocoTestReport
```

## Test Coverage

Current test coverage includes:

### Services
- ✅ EncryptionServiceTest - Encryption/decryption functionality
- ✅ AuthenticationServiceTest - Authentication flows
- ✅ VaultServiceTest - Vault CRUD operations
- ✅ DocumentServiceTest - Document upload/download
- ✅ RedactionServiceTest - Document redaction
- ✅ AntiVaultServiceTest - Anti-vault management
- ✅ DocumentIndexingServiceTest - Document tagging/naming
- ✅ ThreatIndexServiceTest - Threat index tracking

### ViewModels
- ✅ VaultViewModelTest - Vault operations

## Test Dependencies

- JUnit 4.13.2
- Mockito 5.5.0
- Mockito Kotlin 5.1.0
- Kotlin Coroutines Test 1.7.3
- Turbine 1.0.0 (for Flow testing)

## Writing New Tests

1. Create test class matching source structure
2. Use `@Before` for setup
3. Use `runTest { }` for coroutine tests
4. Mock dependencies with MockK
5. Assert expected behavior

Example:
```kotlin
@Test
fun `test feature behavior`() = runTest {
    // Arrange
    val input = "test"
    
    // Act
    val result = service.doSomething(input)
    
    // Assert
    assertEquals("expected", result)
}
```

# Test Utilities Guide

## Common Test Patterns

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

```kotlin
// Android/Kotlin
lateinit var service: MyService
@Before
fun setUp() {
    service = MyService()
    service.configure(mockContext)
}
```

```csharp
// Windows/C#
private MyService service;
[SetUp]
public void SetUp()
{
    service = new MyService();
    service.Configure(mockContext);
}
```

### 2. Mock Data Creation
- Use factory methods for creating test data
- Ensure data is realistic but not sensitive
- Use consistent IDs for predictable tests

### 3. Async Testing
- Use platform-specific async test helpers
- Set appropriate timeouts
- Clean up async resources in tearDown

### 4. Assertions
- Test both success and failure cases
- Verify error messages
- Check side effects (database updates, etc.)


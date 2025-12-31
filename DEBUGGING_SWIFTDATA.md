# Debugging SwiftData with LLDB

## Known Issue: Predicate Type Inspection

When debugging SwiftData code in Xcode's debugger (LLDB), you may encounter errors like:

```
<LLDB error: Could not find reflection metadata for type
no TypeInfo for field type: (bound_generic_enum Swift.Optional
  (bound_generic_struct Foundation.Predicate
    (pack
      (class Khandoba_Secure_Docs.User))))
```

## What This Means

**This is NOT a code error** - it's a limitation of the LLDB debugger when inspecting SwiftData's `Predicate` macro types. Your code works correctly at runtime.

## Why It Happens

SwiftData uses Swift macros (`#Predicate`) to create type-safe queries. LLDB's reflection system cannot inspect these macro-generated types, so it shows this error when you try to:

- Inspect a `FetchDescriptor` variable that contains a `Predicate`
- View the predicate in the Variables view
- Use `po` command on a descriptor with a predicate

## Workarounds

### 1. Inspect the Results Instead

Instead of inspecting the `FetchDescriptor`, fetch the results and inspect those:

```swift
// ❌ This will show LLDB error
let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == userID })
// Inspecting 'descriptor' in debugger fails

// ✅ Do this instead
let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == userID })
let users = try modelContext.fetch(descriptor)
// Inspect 'users' - this works fine
```

### 2. Use Helper Functions

Use the test utilities helper functions that avoid predicate inspection:

```swift
// In debugger, use:
po TestUtilities.debugFetchDescriptor(descriptor, context: modelContext)
```

### 3. Print Instead of Inspect

Add print statements to see what's happening:

```swift
let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == userID })
let users = try modelContext.fetch(descriptor)
print("Found \(users.count) users")
print("User IDs: \(users.map { $0.id })")
```

### 4. Break After Fetch

Set breakpoints **after** the fetch operation, not on the descriptor:

```swift
let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.id == userID })
let users = try modelContext.fetch(descriptor) // ← Set breakpoint here
// Now inspect 'users' - works perfectly
```

## Common Patterns

### Fetching by ID

```swift
// Pattern used throughout the codebase
let userDescriptor = FetchDescriptor<User>(
    predicate: #Predicate { $0.id == userID }
)
let user = try modelContext.fetch(userDescriptor).first
```

### Fetching All (No Predicate)

```swift
// This works fine in debugger (no predicate)
let descriptor = FetchDescriptor<User>()
let users = try modelContext.fetch(descriptor)
```

### Complex Predicates

```swift
// Complex predicates also can't be inspected
let descriptor = FetchDescriptor<Vault>(
    predicate: #Predicate { vault in
        vault.owner?.id == userID && vault.status == "active"
    }
)
// Inspect results, not descriptor
let vaults = try modelContext.fetch(descriptor)
```

## Testing

In unit tests, this limitation doesn't affect functionality:

```swift
func testFetchUser() throws {
    let userID = UUID()
    let user = TestUtilities.createMockUser(id: userID)
    modelContext.insert(user)
    try modelContext.save()
    
    // This works fine - predicate inspection error is debugger-only
    let descriptor = FetchDescriptor<User>(
        predicate: #Predicate { $0.id == userID }
    )
    let fetched = try modelContext.fetch(descriptor)
    
    XCTAssertEqual(fetched.count, 1)
    XCTAssertEqual(fetched.first?.id, userID)
}
```

## Best Practices

1. **Don't worry about the LLDB error** - it's cosmetic, not functional
2. **Inspect results, not descriptors** - fetch first, then inspect
3. **Use print statements** for debugging predicate logic
4. **Set breakpoints after fetch** operations
5. **Test your code** - if tests pass, the predicates work correctly

## Related Files

- `TestUtilities.swift` - Contains debugging helpers
- `AuthenticationService.swift` - Example of FetchDescriptor usage
- `VaultService.swift` - Complex predicate examples

## Apple's Response

This is a known limitation documented in:
- SwiftData documentation
- Xcode release notes
- Apple Developer Forums

There's no fix available yet, but it doesn't affect runtime behavior.

---

**Summary:** The LLDB error is harmless - your SwiftData code works correctly. Inspect fetched results instead of descriptors.


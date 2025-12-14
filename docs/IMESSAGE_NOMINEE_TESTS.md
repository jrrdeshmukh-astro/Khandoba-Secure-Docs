# iMessage Nominee Invitation Tests

## Overview

Comprehensive unit tests for the iMessage nominee invitation and acceptance flow, covering the complete journey from invitation creation to vault access.

## Test Coverage

### 1. Invitation URL Creation Tests
- ✅ **testInvitationURLCreation**: Creates invitation URL with all parameters (token, vault, status, sender)
- ✅ **testInvitationURLMinimalParameters**: Creates URL with minimal required parameters
- ✅ **testInvitationURLSpecialCharacters**: Handles special characters in vault names (URL encoding)

### 2. Invitation URL Parsing Tests
- ✅ **testParseInvitationURL**: Parses complete invitation URL with all parameters
- ✅ **testParseInvitationURLMissingParameters**: Handles missing optional parameters with defaults

### 3. Nominee Creation Tests
- ✅ **testCreateNomineeWithToken**: Creates nominee record with invitation token
- ✅ **testNomineeTokenUniqueness**: Ensures each nominee has a unique token

### 4. Invitation Acceptance Tests
- ✅ **testAcceptInvitationStatusUpdate**: Updates nominee status from pending to accepted
- ✅ **testAcceptInvitationFindByToken**: Finds nominee by token and updates status
- ✅ **testAcceptInvitationInvalidToken**: Handles invalid/non-existent tokens gracefully

### 5. Deep Link Generation Tests
- ✅ **testDeepLinkURLGeneration**: Generates deep link URL for main app
- ✅ **testDeepLinkUserDefaultsFallback**: Tests UserDefaults storage for token fallback

### 6. Status Transition Tests
- ✅ **testStatusTransitionPendingToAccepted**: Tests pending → accepted transition
- ✅ **testStatusTransitionAcceptedToActive**: Tests accepted → active transition
- ✅ **testStatusDisplayNames**: Verifies all status display names

### 7. Vault Access Verification Tests
- ✅ **testAcceptedNomineeVaultAccess**: Verifies accepted nominee has vault access
- ✅ **testMultipleNomineesSameVault**: Tests multiple nominees for same vault

### 8. Complete Flow Test
- ✅ **testCompleteInvitationFlow**: End-to-end test covering:
  1. Owner and vault creation
  2. Invitation creation with token
  3. URL generation
  4. URL parsing
  5. Invitation acceptance
  6. Vault access verification
  7. Deep link generation

### 9. Error Handling Tests
- ✅ **testHandleMissingToken**: Handles missing token gracefully
- ✅ **testHandleInvalidURL**: Validates URL format handling

## Test Flow Diagram

```
1. Owner creates invitation
   ↓
2. Nominee record created with token
   ↓
3. Invitation URL generated: khandoba://nominee/invite?token=...&vault=...
   ↓
4. URL sent via iMessage
   ↓
5. Recipient taps message
   ↓
6. URL parsed, nominee found by token
   ↓
7. Nominee status updated: pending → accepted
   ↓
8. Deep link generated for main app
   ↓
9. Main app opens, processes invitation
   ↓
10. Nominee has vault access
```

## Running the Tests

### In Xcode:
1. Open the project
2. Press `⌘ + U` to run all tests
3. Or select `iMessageNomineeInvitationTests` and run specific tests

### Command Line:
```bash
xcodebuild test -scheme "Khandoba Secure Docs" -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.1' -only-testing:Khandoba_Secure_DocsTests/iMessageNomineeInvitationTests
```

## Test Structure

Each test follows this pattern:
1. **Setup**: Create test data (users, vaults, nominees)
2. **Action**: Perform the operation being tested
3. **Verification**: Assert expected outcomes

## Key Test Scenarios

### Happy Path
- ✅ Complete invitation → acceptance → vault access flow
- ✅ All status transitions work correctly
- ✅ Deep links generated properly

### Edge Cases
- ✅ Missing optional parameters
- ✅ Invalid tokens
- ✅ Special characters in vault names
- ✅ Multiple nominees for same vault

### Error Handling
- ✅ Missing tokens
- ✅ Invalid URLs
- ✅ Non-existent nominees

## Integration Points

The tests verify integration with:
- **SwiftData**: Nominee persistence
- **URL Scheme**: Deep link handling (`khandoba://`)
- **UserDefaults**: Token fallback storage
- **Status Management**: NomineeStatus enum transitions

## Expected Test Results

All tests should pass, verifying:
- ✅ Invitation URLs are created correctly
- ✅ URLs are parsed correctly
- ✅ Nominees are created with proper tokens
- ✅ Invitations are accepted and status updated
- ✅ Accepted nominees have vault access
- ✅ Deep links are generated for main app
- ✅ Error cases are handled gracefully

## Notes

- Tests use in-memory ModelContainer for isolation
- Tests don't require actual iMessage framework (MSMessage, MSConversation)
- Tests focus on business logic, not UI interactions
- All async operations are properly awaited

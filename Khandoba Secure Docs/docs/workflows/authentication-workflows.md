# Authentication Workflows

> **Last Updated:** December 2024
> 
> Comprehensive documentation of authentication and onboarding workflows.

## Table of Contents

1. [Initial Launch](#initial-launch)
2. [Sign In with Apple](#sign-in-with-apple)
3. [Account Setup](#account-setup)
4. [Role Selection](#role-selection)
5. [Session Management](#session-management)
6. [Account Switching](#account-switching)
7. [Sign Out](#sign-out)

---

## Initial Launch

### App Launch Flow

1. **App Starts:**
   - Check authentication state
   - Show `StandardLoadingView` during check
   - Determine next screen

2. **Authentication Check:**
   - Check for valid Apple Sign In session
   - Check for stored user data
   - Check for role assignments

3. **Routing:**
   - **Not Authenticated:** → `WelcomeView`
   - **Authenticated:** → Role-based main view
     - Client → `ClientMainView`
     - Admin → `AdminMainView`

---

## Sign In with Apple

### Sign In Flow

1. **Welcome View:**
   - Display app branding
   - "Sign In with Apple" button
   - Privacy messaging

2. **Apple Authentication:**
   - Tap "Sign In with Apple"
   - Haptic feedback (medium)
   - Apple authentication sheet appears
   - User authenticates:
     - Face ID
     - Touch ID
     - Password

3. **Authentication Result:**
   - Success → Check account setup status
   - Failure → Show error message
   - Cancel → Return to welcome view

4. **Post-Authentication:**
   - If first time → `AccountSetupView`
   - If existing user → Check role → Navigate to main view

---

## Account Setup

### First Time User Setup

**Required Information:**
1. **Full Name:**
   - Text input field
   - Required validation
   - Minimum length check
   - Character validation

2. **Profile Picture:**
   - Camera access request
   - Photo library access request
   - Capture selfie
   - Preview image
   - Confirm or retake

**Setup Flow:**
1. Display `AccountSetupView`
2. User enters name
3. User captures/selects profile picture
4. Preview and confirm
5. Submit setup
6. Save to user profile
7. Proceed to role selection

**Validation:**
- Name cannot be empty
- Name must meet minimum length
- Profile picture must be provided
- Image format validation

**Error Handling:**
- Camera permission denied → Show instructions
- Photo library permission denied → Show instructions
- Invalid image format → Show error
- Save failure → Retry mechanism

---

## Role Selection

### Role Selection Flow

**Trigger:**
- After account setup completion
- If user has no roles assigned

**Role Options:**
1. **Client** (Default):
   - Always available
   - Selected by default
   - Icon: `person.fill`
   - Description: "Standard user access"
   - Auto-assigned to all new users

2. **Admin** (Restricted):
   - Only available if admin assignment exists
   - Disabled for regular signup
   - Icon: `crown.fill`
   - Description: "Full system access"
   - Note: "Admin role must be assigned separately"

**Selection Process:**
1. Display `RoleSelectionView`
2. Show available roles
3. User selects or confirms role
4. System assigns role
5. Navigate to appropriate main view

**Role Assignment:**
- Client role: Auto-assigned
- Admin role: Must be assigned by existing admin
- Single admin per system
- Role assignment tracked in `UserRoleService`

---

## Session Management

### Session Persistence

**Apple Sign In Session:**
- Managed by Apple
- Persists across app launches
- Automatic renewal

**User Session:**
- Stored in CoreData
- Synced via CloudKit
- Available across devices

**Session Validation:**
- Check on app launch
- Validate token expiration
- Refresh if needed
- Handle expired sessions

### Session Expiration

**Handling:**
- Detect expired session
- Show re-authentication prompt
- Redirect to welcome view
- Clear cached data

---

## Account Switching

### Role Switching Flow

**Access:**
- Profile tab → Account Switcher section
- Tap "Switch Account"

**Available Roles:**
- Display all roles user has access to
- Show current role indicator
- Role descriptions

**Switch Process:**
1. Display `AccountSwitcherView`
2. Show available roles
3. User selects role
4. Haptic feedback
5. Switch role in `AccountSwitchService`
6. Update `AuthenticationService.userRole`
7. Navigate to role-specific view
8. Dismiss switcher

**Smooth Transitions:**
- Animated role switch
- Preserve navigation state where possible
- Clear role-specific data if needed

---

## Sign Out

### Sign Out Flow

1. **Access:**
   - Profile tab → Sign Out button

2. **Confirmation:**
   - Alert dialog
   - "Are you sure you want to sign out?"
   - Cancel / Sign Out buttons

3. **Sign Out Process:**
   - Clear user session
   - Clear cached data
   - Sign out from Apple Sign In
   - Navigate to welcome view

4. **Post Sign Out:**
   - All data cleared
   - User must sign in again
   - Onboarding shown if needed

---

## Error Handling

### Authentication Errors

1. **Network Errors:**
   - Retry mechanism
   - Offline mode handling
   - Error messages

2. **Apple Sign In Errors:**
   - Handle cancellation
   - Handle failures
   - Show appropriate messages

3. **Account Setup Errors:**
   - Validation errors
   - Save failures
   - Permission errors

4. **Role Assignment Errors:**
   - Invalid role assignment
   - Permission denied
   - System errors

---

## Security Considerations

### Data Protection

- Profile pictures encrypted
- User data encrypted at rest
- Secure token storage
- Zero-knowledge architecture

### Privacy

- Minimal data collection
- User consent for profile picture
- Privacy policy compliance
- Data retention policies

---

## Accessibility

- VoiceOver labels on all buttons
- Dynamic Type support
- Haptic feedback for interactions
- Clear error messages
- Accessible form inputs


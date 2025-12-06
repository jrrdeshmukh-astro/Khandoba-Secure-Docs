# Push Notifications Setup Guide

> **Last Updated:** December 2024
> 
> Complete guide for push notification implementation and configuration

## ✅ Implementation Complete

### What Was Implemented

1. **PushNotificationService** (`PushNotificationService.swift`)
   - Request authorization
   - Register device tokens
   - Handle incoming notifications
   - Send local notifications
   - Support for multiple notification types

2. **AppDelegate Integration**
   - Device token registration
   - Remote notification handling
   - Background notification support

3. **Permissions Setup**
   - Updated `PermissionsSetupView` to request notification permissions
   - Integrated with onboarding flow

4. **Service Integration**
   - `NomineeService` - Sends notifications for invitations
   - `SharedVaultSessionService` - Uses PushNotificationService for vault notifications

## 📱 Notification Types

### 1. Nominee Invitations
- **Trigger**: When owner invites a nominee
- **Content**: "You've been invited to access vault: [Vault Name]"
- **Action**: Opens invitation acceptance view

### 2. Vault Access
- **Trigger**: When vault is opened or locked
- **Content**: "[User] opened/locked [Vault Name]"
- **Action**: Shows vault status

### 3. Nominee Acceptance
- **Trigger**: When nominee accepts invitation
- **Content**: "[Nominee] accepted invitation to [Vault Name]"
- **Action**: Updates nominee list

### 4. Security Alerts
- **Trigger**: Suspicious activity detected
- **Content**: Security alert details
- **Action**: Opens security dashboard

## 🔧 Configuration

### Entitlements

**Current Setting:**
```xml
<key>aps-environment</key>
<string>development</string>
```

**For Production:**
- Change to `production` before App Store submission
- Development: Used for TestFlight and development builds
- Production: Used for App Store releases

### Info.plist

Already configured:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### APNsConfig

```swift
static let keyID = "PR62QK662L"
static let teamID = "Q5Y8754WU4"
static let bundleID = "com.khandoba.securedocs"
```

## 🚀 Setup Steps

### 1. App Store Connect

1. Go to App Store Connect → Your App
2. Navigate to **App Information** → **App Store Connect API**
3. Ensure APNs key is configured:
   - Key ID: `PR62QK662L`
   - Team ID: `Q5Y8754WU4`

### 2. Xcode Project

1. **Signing & Capabilities:**
   - Add "Push Notifications" capability
   - Add "Background Modes" → "Remote notifications"

2. **Provisioning Profile:**
   - Ensure profile includes push notification entitlement
   - Regenerate if needed

### 3. APNs Certificate/Key

**Option A: APNs Auth Key (Recommended)**
- Already configured: `AuthKey_PR62QK662L.p8`
- Works for all apps under your team
- No expiration

**Option B: APNs Certificate**
- Create in Apple Developer Portal
- App-specific
- Expires annually

## 📊 How It Works

### Registration Flow

1. **App Launch:**
   ```
   App starts → PushNotificationService.shared initializes
   → Requests authorization on first launch
   → Registers for remote notifications
   ```

2. **Device Token:**
   ```
   APNs assigns device token
   → AppDelegate receives token
   → PushNotificationService stores token
   → TODO: Send token to backend server
   ```

3. **Notification Delivery:**
   ```
   Backend sends push via APNs
   → APNs delivers to device
   → AppDelegate receives notification
   → PushNotificationService handles
   → UI updates accordingly
   ```

### Notification Handling

**Foreground:**
- Notification shown as banner
- User can tap to open app
- `userNotificationCenter(_:willPresent:)` handles

**Background:**
- Notification appears in notification center
- User taps → App opens
- `userNotificationCenter(_:didReceive:)` handles

**Terminated:**
- Notification appears in notification center
- User taps → App launches
- `application(_:didReceiveRemoteNotification:)` handles

## 🧪 Testing

### TestFlight Testing

1. **Build with Push Notifications:**
   - Ensure entitlements include push notifications
   - Build and upload to TestFlight

2. **Test Notification Flow:**
   - Install app on test device
   - Grant notification permission
   - Check device token is registered (console logs)
   - Send test notification from backend

3. **Verify Delivery:**
   - Check notification appears
   - Tap notification → App opens
   - Verify correct view is shown

### Local Testing

**Send Test Notification:**
```swift
// In PushNotificationService
PushNotificationService.shared.sendNomineeInvitationNotification(
    token: "test-token",
    vaultName: "Test Vault"
)
```

### Backend Integration (TODO)

To send push notifications from your backend:

1. **Store Device Tokens:**
   - When device token is registered, send to your backend
   - Associate with user account/phone number

2. **Send Notifications:**
   - When nominee is invited, backend looks up nominee's device token
   - Sends push notification via APNs
   - Includes invitation token in payload

3. **APNs Payload Format:**
```json
{
  "aps": {
    "alert": {
      "title": "Vault Invitation",
      "body": "You've been invited to access vault: [Name]"
    },
    "sound": "default",
    "badge": 1
  },
  "type": "nominee_invitation",
  "inviteToken": "[UUID]",
  "vaultName": "[Vault Name]"
}
```

## 🔐 Security Considerations

1. **Device Token Storage:**
   - Store securely on backend
   - Associate with user account
   - Invalidate on logout

2. **Notification Payload:**
   - Don't include sensitive data
   - Use tokens/IDs, not actual content
   - Fetch details after app opens

3. **User Privacy:**
   - Request permission clearly
   - Explain why notifications are needed
   - Allow users to disable in Settings

## 📝 Notification Payload Examples

### Nominee Invitation
```json
{
  "aps": {
    "alert": "You've been invited to access vault: Medical Records",
    "sound": "default"
  },
  "type": "nominee_invitation",
  "inviteToken": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
  "vaultName": "Medical Records"
}
```

### Vault Opened
```json
{
  "aps": {
    "alert": "John Doe opened Medical Records",
    "sound": "default"
  },
  "type": "vault_opened",
  "vaultID": "[UUID]",
  "vaultName": "Medical Records",
  "openedBy": "John Doe"
}
```

### Nominee Accepted
```json
{
  "aps": {
    "alert": "Jane Smith accepted invitation to Medical Records",
    "sound": "default"
  },
  "type": "nominee_accepted",
  "nomineeID": "[UUID]",
  "nomineeName": "Jane Smith",
  "vaultName": "Medical Records"
}
```

## ✅ Production Checklist

- [x] PushNotificationService implemented
- [x] AppDelegate integration
- [x] Permissions request in onboarding
- [x] Entitlements configured
- [x] Info.plist background modes set
- [ ] APNs key configured in App Store Connect
- [ ] Backend API for sending notifications
- [ ] Device token storage on backend
- [ ] TestFlight testing completed
- [ ] Production environment set in entitlements
- [ ] Notification payloads tested

## 🔗 Related Documentation

- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [APNs Overview](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/)
- [UserNotifications Framework](https://developer.apple.com/documentation/usernotifications)

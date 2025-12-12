# Testing Guide - Khandoba Secure Docs

> **Last Updated:** December 2024
> 
> Comprehensive guide for testing all features of the app

## Quick Start

### 1. Build Project

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Clean build folder
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*

# Build all targets
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -configuration Debug \
  -sdk iphonesimulator \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO
```

### 2. Run in Xcode

1. **Open Xcode:**
   ```bash
   open "Khandoba Secure Docs.xcodeproj"
   ```

2. **Select scheme:**
   - Choose "Khandoba Secure Docs" from scheme selector

3. **Select destination:**
   - iOS Simulator (iPhone 15 Pro, iOS 26.1+)
   - Or physical device (connected via USB)

4. **Build & Run:**
   - Press ⌘+R or click Run button
   - Wait for app to launch

---

## Testing Scenarios

### 1. Main App Testing

#### Authentication Flow

**Test Cases:**
1. ✅ First launch → Welcome screen
2. ✅ Sign in with Apple ID
3. ✅ Account setup (name capture)
4. ✅ Permissions setup
5. ✅ Navigate to main dashboard

**Steps:**
1. Launch app
2. Tap "Sign in with Apple"
3. Complete Apple Sign In flow
4. Enter name (first launch only)
5. Grant permissions (Camera, Photos, Location, Microphone)
6. Verify dashboard loads

**Expected Results:**
- User account created in SwiftData
- User profile shows correct name
- All permissions granted

#### Vault Management

**Test Cases:**
1. ✅ Create new vault
2. ✅ Open vault (with password/biometric)
3. ✅ Vault session timeout
4. ✅ View vault documents
5. ✅ Delete vault

**Steps:**
1. Navigate to Vaults tab
2. Tap "Create Vault"
3. Enter vault name and password
4. Select vault type (Single-key or Dual-key)
5. Tap "Create"
6. Tap vault to open (enter password/use Face ID)
7. Wait 5 minutes → Verify session expires
8. Open vault again

**Expected Results:**
- Vault created successfully
- Password/biometric authentication works
- Session timer counts down
- Session expires after timeout
- Can reopen vault with password

#### Document Management

**Test Cases:**
1. ✅ Upload document (photo)
2. ✅ Upload document (PDF)
3. ✅ View document preview
4. ✅ Search documents
5. ✅ Filter documents
6. ✅ Delete document

**Steps:**
1. Open a vault
2. Tap "Upload Document"
3. Select photo from library
4. Wait for encryption & upload
5. Tap document → View preview
6. Use search bar → Find document
7. Tap filter icon → Filter by type/date
8. Swipe left on document → Delete

**Expected Results:**
- Documents encrypt before upload
- Preview shows correctly
- Search finds documents
- Filters work
- Deletion removes document

#### Media Capture

**Test Cases:**
1. ✅ Record video
2. ✅ Capture photo
3. ✅ Record voice memo
4. ✅ Play voice memo

**Steps:**
1. Open vault
2. Tap "Record Video"
3. Record 10-second video
4. Preview video
5. Save to vault
6. Tap "Record Voice Memo"
7. Record 30-second memo
8. Play back memo

**Expected Results:**
- Video records and previews correctly
- Photo captures correctly
- Voice memo records audio
- Playback works correctly

---

### 2. iMessage Extension Testing

#### Setup

**Prerequisites:**
1. Build the extension target:
   ```bash
   xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
     -target "KhandobaSecureDocsMessageApp MessagesExtension" \
     -configuration Debug \
     -sdk iphonesimulator
   ```

2. **Enable extension in Settings:**
   - Settings → Messages → Message Apps
   - Find "Khandoba" in list
   - Toggle ON

3. **Add to Messages drawer:**
   - Open Messages app
   - Tap App Store icon (drawer)
   - Tap "+" to add apps
   - Find "Khandoba" and add it

#### Test Nominee Invitation Flow

**Test Cases:**
1. ✅ Send vault invitation via iMessage
2. ✅ Receive invitation in Messages
3. ✅ Tap invitation bubble
4. ✅ Accept invitation
5. ✅ Verify vault access granted

**Steps:**
1. **Sender:**
   - Open Messages app
   - Start new conversation
   - Tap "Khandoba" app icon
   - Select "Invite to Vault"
   - Choose vault
   - Enter recipient name
   - Tap "Send Invitation"
   - Verify interactive bubble sent

2. **Receiver:**
   - Receive message
   - Tap invitation bubble
   - View invitation details
   - Tap "Accept"
   - Verify main app opens
   - Verify vault appears in shared vaults

**Expected Results:**
- Interactive bubble shows in conversation
- Bubble updates when accepted/declined
- Main app opens on acceptance
- Vault access granted automatically

#### Test File Sharing Flow

**Test Cases:**
1. ✅ Share file from Photos to iMessage app
2. ✅ Select vault in extension
3. ✅ Share file to vault
4. ✅ Verify file appears in vault

**Steps:**
1. Open Photos app
2. Select a photo
3. Tap Share button
4. Scroll to "Khandoba" in share sheet
5. Tap "Khandoba"
6. iMessage extension opens
7. Select target vault
8. Tap "Share"
9. Verify file uploads

**Expected Results:**
- Extension appears in share sheet
- File selection works
- Vault picker shows available vaults
- File uploads successfully

---

### 3. Share Extension Testing

#### Setup

**Prerequisites:**
1. Build ShareExtension target:
   ```bash
   xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
     -target "ShareExtension" \
     -configuration Debug \
     -sdk iphonesimulator
   ```

2. Extension automatically available in share sheets

#### Test File Sharing

**Test Cases:**
1. ✅ Share file from Safari
2. ✅ Share file from Photos
3. ✅ Share file from Files app
4. ✅ Select vault in extension
5. ✅ Verify file uploads

**Steps:**
1. Open Photos app (or Safari, Files, etc.)
2. Select file/image
3. Tap Share button
4. Find "Khandoba Secure Docs" in share sheet
5. Tap extension
6. Select vault (if multiple)
7. Tap "Upload"
8. Open main app → Verify file in vault

**Expected Results:**
- Extension appears in share sheet
- File selection works
- Vault selection works
- File encrypts and uploads
- File appears in selected vault

---

## Testing Commands

### Build All Targets

```bash
# Main app
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -target "Khandoba Secure Docs" \
  -configuration Debug

# ShareExtension
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -target "ShareExtension" \
  -configuration Debug

# iMessage Extension
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -target "KhandobaSecureDocsMessageApp MessagesExtension" \
  -configuration Debug
```

### Run on Simulator

```bash
# List available simulators
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "iPhone 15 Pro"

# Install app
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  install
```

### Run Tests

```bash
# Run unit tests
xcodebuild test -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## Feature-Specific Testing

### 1. Subscription Testing

**Test Cases:**
- ✅ View subscription options
- ✅ Purchase subscription
- ✅ Restore purchases
- ✅ Verify premium features unlock
- ✅ Test subscription expiry

**Steps:**
1. Navigate to Store tab
2. View subscription options
3. Tap "Subscribe" ($5.99/month)
4. Complete purchase flow
5. Verify premium features enabled
6. Test "Restore Purchases"

**Expected Results:**
- Subscription options display
- Purchase flow works
- Premium features unlock
- Status persists after app restart

### 2. CloudKit Sync Testing

**Test Cases:**
- ✅ Create vault on Device A
- ✅ Verify vault appears on Device B
- ✅ Invite nominee
- ✅ Accept invitation
- ✅ Verify sync across devices

**Steps:**
1. Create vault on iPhone
2. Wait for CloudKit sync
3. Open app on iPad (same iCloud account)
4. Verify vault appears
5. Invite nominee from iPhone
6. Accept invitation on iPad
7. Verify nominee appears on both devices

**Expected Results:**
- Vaults sync across devices
- Nominee invitations sync
- Access grants sync
- All data consistent

### 3. Security Features Testing

**Test Cases:**
- ✅ Threat monitoring
- ✅ Access logs
- ✅ Dual-key approval
- ✅ Session management
- ✅ Encryption verification

**Steps:**
1. Open Security tab
2. View threat dashboard
3. Check access logs
4. Create dual-key vault
5. Request access
6. Verify ML auto-approval (or manual approval)
7. Check session timer

**Expected Results:**
- Threats detected and displayed
- Access logs accurate
- Dual-key workflow works
- Sessions timeout correctly

---

## Common Issues & Solutions

### Extension Not Appearing

**Problem:** iMessage extension doesn't appear in Messages app

**Solution:**
1. Check Settings → Messages → Message Apps → Khandoba is ON
2. Restart Messages app
3. Clean build folder
4. Rebuild extension target
5. Restart device/simulator

### Share Extension Not Working

**Problem:** Share extension doesn't appear in share sheet

**Solution:**
1. Verify extension built successfully
2. Check entitlements configured
3. Restart device/simulator
4. Try different source apps (Photos, Safari, Files)

### Build Errors

**Problem:** Build fails with errors

**Solution:**
```bash
# Clean everything
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*

# Reopen Xcode
# Clean build folder (⇧⌘K)
# Build again (⌘+B)
```

### CloudKit Sync Issues

**Problem:** Data not syncing across devices

**Solution:**
1. Verify iCloud signed in
2. Check CloudKit container configuration
3. Check network connectivity
4. Wait for sync (can take 30-60 seconds)
5. Force quit and restart app

---

## Testing Checklist

### Main App
- [ ] Authentication (Apple Sign In)
- [ ] Vault creation
- [ ] Vault access (password/biometric)
- [ ] Document upload
- [ ] Document preview
- [ ] Document search/filter
- [ ] Video recording
- [ ] Photo capture
- [ ] Voice memo recording
- [ ] Subscription purchase
- [ ] Premium features

### iMessage Extension
- [ ] Extension appears in Messages
- [ ] Send vault invitation
- [ ] Receive invitation
- [ ] Accept invitation
- [ ] Decline invitation
- [ ] Share file from Photos
- [ ] Share file from Safari
- [ ] Select vault in extension

### Share Extension
- [ ] Extension appears in share sheet
- [ ] Share from Photos
- [ ] Share from Safari
- [ ] Share from Files
- [ ] File uploads to vault
- [ ] Encryption works

### Security
- [ ] Threat monitoring
- [ ] Access logs
- [ ] Dual-key approval
- [ ] Session timeout
- [ ] Encryption verification

### CloudKit Sync
- [ ] Vault sync across devices
- [ ] Nominee invitation sync
- [ ] Access grants sync
- [ ] Document sync

---

## Debug Tips

### Enable Logging

Check console output for:
- `✅` Success messages
- `❌` Error messages
- `📊` Analytics/status messages

### Test on Physical Device

For best results:
1. Connect iPhone via USB
2. Select device in Xcode
3. Build & Run
4. Test with real Messages app
5. Test with real share sheet

### Simulator Limitations

Some features work better on device:
- iMessage extension (requires Messages app)
- Face ID/Touch ID
- Camera/Photos access
- Share extensions

---

## Performance Testing

### Memory Usage

Monitor memory in Xcode:
1. Run app
2. Debug → Memory Graph
3. Check for leaks
4. Verify memory releases correctly

### Network Performance

Test upload speeds:
1. Upload large file (100MB+)
2. Monitor progress
3. Check completion time
4. Verify encryption doesn't block UI

---

## Status

✅ **Main App:** Ready for testing  
✅ **iMessage Extension:** Ready for testing  
✅ **Share Extension:** Ready for testing  

All targets build successfully and are ready for comprehensive testing.

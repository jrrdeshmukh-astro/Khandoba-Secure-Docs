# Quick Test Guide - Khandoba Secure Docs

> **Quick reference for testing the app**

## 🚀 Quick Start

### Option 1: Xcode (Recommended)

1. **Open Project:**
   ```bash
   open "Khandoba Secure Docs.xcodeproj"
   ```

2. **Select Scheme & Device:**
   - Scheme: `Khandoba Secure Docs`
   - Device: `iPhone 15 Pro (iOS 26.1+)` (or physical device)

3. **Run:**
   - Press **⌘+R** or click Run button
   - App launches in simulator/device

### Option 2: Command Line

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Run automated test script
./scripts/test_project.sh

# Or build manually
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

---

## 🧪 Testing Checklist

### Main App Features

- [ ] **Authentication**
  - Sign in with Apple ID
  - Account setup completes
  - Permissions granted

- [ ] **Vault Management**
  - Create vault (Single-key)
  - Create vault (Dual-key)
  - Open vault (password/biometric)
  - Session timeout works

- [ ] **Documents**
  - Upload photo
  - Upload PDF
  - View preview
  - Search documents
  - Delete document

- [ ] **Media**
  - Record video
  - Capture photo
  - Record voice memo
  - Play voice memo

- [ ] **Subscriptions**
  - View store
  - Purchase subscription
  - Restore purchases
  - Premium features unlock

### iMessage Extension

- [ ] **Setup**
  - Extension appears in Messages
  - Can access from Messages drawer

- [ ] **Invitations**
  - Send vault invitation
  - Receive invitation
  - Accept invitation
  - Decline invitation

- [ ] **File Sharing**
  - Share from Photos
  - Share from Safari
  - Select vault
  - File uploads

### Share Extension

- [ ] **Sharing**
  - Appears in share sheet
  - Share from Photos
  - Share from Safari
  - Share from Files
  - File uploads to vault

---

## 🔧 Testing Commands

### Build All Targets
```bash
./scripts/test_project.sh
```

### Build Individual Target
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

### Run on Specific Simulator
```bash
# List available simulators
xcrun simctl list devices available

# Boot simulator
xcrun simctl boot "iPhone 15 Pro"

# Run app
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  run
```

---

## 📱 Testing iMessage Extension

### Setup (First Time Only)

1. **Build extension:**
   - Build "KhandobaSecureDocsMessageApp MessagesExtension" target

2. **Enable in Settings:**
   - Settings → Messages → Message Apps
   - Find "Khandoba"
   - Toggle ON

3. **Add to Messages:**
   - Open Messages app
   - Tap App Store icon (bottom)
   - Tap "+" to add apps
   - Find "Khandoba" and add

### Test Flow

1. **Send Invitation:**
   - Open Messages
   - Start conversation
   - Tap "Khandoba" app icon
   - Select "Invite to Vault"
   - Choose vault & send

2. **Receive Invitation:**
   - Tap invitation bubble
   - View details
   - Accept or Decline
   - Verify main app opens

---

## 📤 Testing Share Extension

### Setup

1. Build ShareExtension target
2. Extension automatically available

### Test Flow

1. **Share File:**
   - Open Photos (or Safari, Files)
   - Select file/image
   - Tap Share button
   - Find "Khandoba Secure Docs"
   - Tap extension
   - Select vault
   - Upload

2. **Verify:**
   - Open main app
   - Go to vault
   - Verify file appears

---

## 🐛 Troubleshooting

### Build Errors

```bash
# Clean everything
rm -rf build
rm -rf ~/Library/Developer/Xcode/DerivedData/Khandoba_Secure_Docs-*

# In Xcode
# Clean build folder: ⇧⌘K
# Build: ⌘+B
```

### Extension Not Appearing

1. Check Settings → Messages → Message Apps
2. Restart Messages app
3. Restart device/simulator
4. Rebuild extension target

### CloudKit Sync Issues

1. Verify iCloud signed in
2. Check network
3. Wait 30-60 seconds for sync
4. Force quit and restart app

---

## 📊 Testing Priorities

### Critical (Must Test)
1. ✅ Authentication (Apple Sign In)
2. ✅ Vault creation & access
3. ✅ Document upload
4. ✅ Encryption works
5. ✅ Subscription purchase

### Important
1. ✅ iMessage extension
2. ✅ Share extension
3. ✅ CloudKit sync
4. ✅ Nominee invitations

### Nice to Have
1. ✅ Voice memos
2. ✅ Intel reports
3. ✅ Threat monitoring
4. ✅ Advanced features

---

**Full Testing Guide:** See `docs/TESTING_GUIDE.md`

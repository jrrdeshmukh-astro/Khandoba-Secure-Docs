# Quick Setup: Make Khandoba Appear in Messages

## Where to Find It

**NOT in the "+" menu** - Look for the **App Store icon (📱)** at the bottom left of the Messages keyboard.

## Step-by-Step

### 1. Run the Main App First
- Build and run "Khandoba Secure Docs" in Xcode (⌘+R)
- This registers the extension with iOS

### 2. Enable in Settings
1. Open **Settings** app
2. Go to **Messages**
3. Scroll to **Message Apps**
4. Find **"Khandoba"** and toggle it **ON**

### 3. Add to Messages
1. Open **Messages** app
2. Start/open a conversation
3. Tap the **App Store icon (📱)** at bottom left (NOT the "+")
4. This opens the Messages app drawer
5. Scroll or tap **"+"** to add apps
6. Find **"Khandoba"** and tap it

### 4. Use It
- Tap the App Store icon (📱) in Messages
- Tap **"Khandoba"** from your drawer
- Choose "Invite to Vault" or "Share File"

## Troubleshooting

**Not showing in Settings?**
- Clean build folder (⇧⌘K) and rebuild
- Restart your device

**Not showing in Messages drawer?**
- Force quit Messages app and reopen
- Toggle "Khandoba" OFF then ON in Settings → Messages → Message Apps

**Still not working?**
- Check that the main app has been run at least once
- Verify bundle identifier: `openstreetllc.KhandobaSecureDocsMessageApp.MessagesExtension`

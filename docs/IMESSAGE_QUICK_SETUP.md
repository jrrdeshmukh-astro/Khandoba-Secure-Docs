# Quick Setup: Make Khandoba Appear in Messages

## Where to Find It

The **App Store icon (📱)** appears at the bottom left of the Messages keyboard when you're in an active conversation. If you don't see it, follow the troubleshooting steps below.

## Step-by-Step

### 1. Run the Main App First
- Build and run "Khandoba Secure Docs" in Xcode (⌘+R)
- **Important:** The main app MUST be installed and run at least once before the extension will appear
- This registers the extension with iOS

### 2. Enable in Settings
1. Open **Settings** app on your iPhone
2. Scroll down and tap **Messages**
3. Scroll to **Message Apps** section (under "iMessage Apps")
4. Look for **"Khandoba"** in the list
5. Toggle it **ON** (green switch)

**If "Khandoba" doesn't appear in Settings:**
- Make sure the main app is installed on your device
- Clean build folder (⇧⌘K) and rebuild
- Delete the app from device, then reinstall
- Restart your iPhone

### 3. Access in Messages
1. Open **Messages** app
2. **Start or open an existing conversation** (you must be IN a conversation, not just the Messages list)
3. Look for the **App Store icon (📱)** at the bottom left of the keyboard area
4. If you don't see it:
   - Tap the **"+"** button (next to the text field)
   - Scroll down to find **"Khandoba"**
   - Or swipe left on the app icons row

### 4. Alternative Access Methods

**Method 1: Through the "+" Menu**
1. In a conversation, tap the **"+"** button
2. Scroll down to find **"Khandoba"**
3. Tap it to open

**Method 2: Long-press on Text Field**
1. Long-press the text input field
2. Look for app options

**Method 3: Swipe on App Icons**
1. If you see app icons above the keyboard
2. Swipe left/right to find "Khandoba"

### 5. Use It
- Once opened, choose "Invite to Vault" or "Share File"
- For file sharing: Share files from Photos/Files app, then select Messages, then tap "Khandoba"

## Troubleshooting

### App Store Icon Not Showing?

**Check 1: Are you in a conversation?**
- The App Store icon only appears when you're IN an active conversation
- It won't show in the main Messages list

**Check 2: Is the extension enabled?**
- Settings → Messages → Message Apps → "Khandoba" should be ON (green)

**Check 3: Is the main app installed?**
- The main "Khandoba Secure Docs" app must be installed on your device
- Run it at least once from Xcode

**Check 4: Force refresh**
1. Force quit Messages app (swipe up from bottom, swipe up on Messages)
2. Restart your iPhone
3. Open Messages again and go to a conversation

**Check 5: Re-enable extension**
1. Settings → Messages → Message Apps
2. Toggle "Khandoba" OFF
3. Wait 2 seconds
4. Toggle it back ON

### Not Showing in Settings?

**Solution 1: Clean Rebuild**
1. In Xcode: Product → Clean Build Folder (⇧⌘K)
2. Delete app from device
3. Rebuild and run (⌘R)

**Solution 2: Check Bundle Identifiers**
- Main app: `com.khandoba.securedocs`
- Extension: `com.khandoba.securedocs.KhandobaSecureDocsMessageApp.MessagesExtension`
- Verify these match in Xcode project settings

**Solution 3: Restart Device**
- Sometimes iOS needs a restart to recognize new extensions

### Extension Shows But Doesn't Work?

**Check Info.plist:**
- Verify `NSExtensionActivationRule` is present
- Verify `CFBundleDisplayName` is set to "Khandoba"
- Verify all required keys are present

**Check Build:**
- Make sure extension target builds successfully
- Check for any build errors or warnings

## Verification Checklist

Before troubleshooting, verify:
- [ ] Main app is installed on device
- [ ] Main app has been run at least once
- [ ] Extension appears in Settings → Messages → Message Apps
- [ ] Extension is toggled ON in Settings
- [ ] You're in an active conversation (not just Messages list)
- [ ] Device has been restarted after installing extension
- [ ] No build errors in Xcode

## Still Not Working?

If none of the above works:
1. Check Xcode console for errors when running the app
2. Verify the extension is embedded in the main app (Build Phases → Embed Foundation Extensions)
3. Check that bundle identifiers are correct and match
4. Try creating a new test conversation
5. Verify iOS version is 17.0+ (required for the app)

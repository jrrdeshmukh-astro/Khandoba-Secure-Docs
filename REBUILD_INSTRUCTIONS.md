# Rebuild Instructions for Apple Cash-Style iMessage Extension

## To See the New Design:

1. **Clean Build Folder in Xcode:**
   - Product → Clean Build Folder (or Shift+Cmd+K)

2. **Build and Run:**
   - Select the "Khandoba Secure Docs" scheme (main app)
   - Build and run on your device/simulator (Cmd+R)

3. **Force Quit Messages App:**
   - Double-tap home button (or swipe up on newer devices)
   - Swipe up on Messages app to force quit

4. **Restart Messages:**
   - Open Messages app
   - Start a new conversation or open existing one
   - Tap the App Store icon (or long-press) in the keyboard area
   - Find "Khandoba Secure Docs" in the iMessage apps list

5. **Test the New Flow:**
   - Tap "Invite Nominee"
   - You should now see the Apple Cash-style interface with:
     - Large vault name display (like "$1" in Apple Cash)
     - "Change Vault" button in header
     - Vault card at bottom
     - "Send Invitation" button

## If You Still Don't See Changes:

1. **Check Console Logs:**
   - In Xcode, open the console (View → Debug Area → Show Debug Area)
   - Look for these log messages:
     - "🚀 presentSimpleVaultSelection - Starting Apple Cash-style flow"
     - "🎨 Creating NomineeInvitationFlowView..."
     - "✅ Apple Cash-style invitation flow presented successfully!"

2. **Verify Extension is Installed:**
   - Settings → Messages → iMessage Apps
   - Make sure "Khandoba Secure Docs" is enabled

3. **Delete and Reinstall:**
   - Delete the app from device
   - Rebuild and reinstall from Xcode

## What Changed:

- **Old Design:** Simple list of vaults
- **New Design:** Apple Cash-style interface with:
  - Card-based vault display
  - Rolodex-style vault selector (swipe to browse)
  - Large prominent vault name
  - Smooth animations and transitions
  - "Send Invitation" button at bottom

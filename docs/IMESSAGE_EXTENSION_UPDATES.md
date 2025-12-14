# iMessage Extension Updates

## Summary

Updated the iMessage extension to better handle media sharing and provide clearer user instructions. The extension now:

1. **Better File Detection**: Improved detection of shared files from various sources
2. **Enhanced UI**: Updated "Share File" to "Save Media to Vault" with step-by-step instructions
3. **Better File Type Handling**: Supports images, videos, audio, PDFs, and other file types
4. **Comprehensive Unit Tests**: Added unit tests for file type determination, icon selection, and file size formatting

## Changes Made

### 1. MainMenuMessageView.swift
- Changed "Share File" button to "Save Media to Vault"
- Updated icon from `square.and.arrow.up` to `photo.on.rectangle.angled`
- Added detailed instructions card explaining how to save media from conversations
- Updated description text to be more user-friendly

### 2. MessagesViewController.swift
- Enhanced file detection logic to check multiple sources
- Added logging for debugging shared file detection
- Improved handling of `extensionContext.inputItems`

### 3. FileSharingMessageView.swift
- Updated empty state with better instructions
- Changed navigation title from "Share Files" to "Save Media to Vault"
- Improved file loading to handle multiple file types (images, videos, audio, PDFs)
- Added `determineFileType()` helper function
- Better error handling and user feedback

## Unit Tests

Created comprehensive unit tests in `iMessageExtensionTests.swift`:

### Test Coverage
- ✅ File type determination (images, videos, audio, PDF, unknown)
- ✅ File icon selection for different file types
- ✅ File size formatting (bytes, KB, MB)
- ✅ SharedFile model initialization and Identifiable conformance

### Running Tests

To run the unit tests:

1. **In Xcode:**
   - Open the project in Xcode
   - Press `⌘ + U` to run all tests
   - Or select the test target and run specific tests

2. **Command Line:**
   ```bash
   xcodebuild test -scheme "Khandoba Secure Docs" -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.1'
   ```

## User Flow

### How Users Save Media from iMessage:

1. **Long-press** any photo or video in the iMessage conversation
2. **Tap "Share"** from the context menu
3. **Select "Khandoba"** from the share sheet
4. **Choose a vault** to save the media to
5. Media is saved securely to the selected vault

## Technical Details

### File Type Support
The extension now properly handles:
- **Images**: JPEG, PNG, HEIC, and other image formats
- **Videos**: MP4, MOV, and other video formats
- **Audio**: MP3, AAC, and other audio formats
- **Documents**: PDF and other document types
- **Generic Data**: Any other file type

### File Detection Priority
Files are detected in this order:
1. Images (`UTType.image`)
2. Movies/Videos (`UTType.movie`, `UTType.video`)
3. Audio (`UTType.audio`)
4. PDF (`UTType.pdf`)
5. Generic data (`UTType.data`)

## Share Extension vs iMessage Extension

### Share Extension
- **Purpose**: Handle files shared from other apps (Photos, Files, etc.)
- **When Used**: User shares files from Photos/Files app to Khandoba
- **Status**: Still useful for direct file sharing from other apps

### iMessage Extension
- **Purpose**: Handle vault invitations, ownership transfers, and media from iMessage
- **When Used**: User interacts with Khandoba within iMessage conversations
- **Status**: Primary interface for iMessage-related features

**Recommendation**: Keep both extensions as they serve different purposes:
- Share Extension: Direct file sharing from any app
- iMessage Extension: iMessage-specific features and media from conversations

## Testing Checklist

- [x] Unit tests for file type determination
- [x] Unit tests for file icon selection
- [x] Unit tests for file size formatting
- [x] Unit tests for SharedFile model
- [ ] Manual testing: Share image from Photos to iMessage extension
- [ ] Manual testing: Share video from Photos to iMessage extension
- [ ] Manual testing: Share PDF from Files to iMessage extension
- [ ] Manual testing: Vault selection and file saving
- [ ] Manual testing: Error handling for invalid files

## Next Steps

1. Test the extension manually in iMessage
2. Verify file saving works correctly
3. Test with various file types (images, videos, PDFs)
4. Verify vault selection and file upload
5. Test error handling scenarios

## Notes

- The iMessage extension cannot directly access media already in conversations due to privacy restrictions
- Users must use the share sheet workflow: Long-press → Share → Khandoba
- The extension properly detects files shared to it via the share sheet
- All file operations are secure and encrypted

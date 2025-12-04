# Recording and NLP Naming Fixes

## Issues Fixed

### 1. ✅ Video Recording Save Fixed
**Problem**: Video recordings were saving directly to `CachedVideoDocument` instead of using the standard upload flow, missing encryption, wrapping, and credit deduction.

**Solution**: 
- Updated `VideoRecordingService.saveVideoToVault()` to use `DocumentUploadService.uploadDocument()`
- Now properly encrypts, wraps in `.khd` format, deducts credits, and indexes metadata
- Returns `UUID` (document ID) instead of `VideoDocument` struct

**Files Changed**:
- `Khandoba/Core/Services/VideoRecordingService.swift` - Updated `saveVideoToVault()` method
- `Khandoba/Features/Vaults/Views/VideoRecordingView.swift` - Updated to handle new return type

### 2. ✅ Voice Memo Recording Option Added
**Problem**: Voice memo option was not accessible from client vault detail view.

**Solution**:
- Added "Record Voice Memo" button to `ClientVaultDetailView`
- Added sheet presentation for `VoiceMemoRecordingView`
- Voice memo is now accessible alongside video recording

**Files Changed**:
- `Khandoba/Features/Client/Views/ClientVaultDetailView.swift` - Added voice memo button and sheet

### 3. ✅ NLP-Based File Naming Implemented
**Problem**: Files were being saved with generic names like "Document.pdf" or "Video Recording".

**Solution**:
- Created `DocumentNamingService` for smart file naming using NLP
- Analyzes file content, extracts tags, and generates descriptive names
- Integrated into `DocumentUploadService` and `VoiceMemoRecordingView`
- Names are generated based on:
  - Content analysis (text extraction, entity recognition)
  - AI tags (categories, keywords)
  - File metadata (date, type)
  - File extension

**Files Created**:
- `Khandoba/Core/Services/DocumentNamingService.swift` (NEW)

**Files Changed**:
- `Khandoba/Core/Services/DocumentUploadService.swift` - Integrated NLP naming
- `Khandoba/Features/Vaults/Views/VoiceMemoRecordingView.swift` - Uses NLP naming
- `Khandoba/Core/Services/VideoRecordingService.swift` - Uses NLP naming

## Action Required

### ⚠️ Add DocumentNamingService.swift to Xcode Project

The file `Khandoba/Core/Services/DocumentNamingService.swift` exists but needs to be added to the Xcode project target:

1. In Xcode, right-click `Khandoba/Core/Services/` folder
2. Select "Add Files to Khandoba..."
3. Navigate to and select `DocumentNamingService.swift`
4. Ensure "Copy items if needed" is **unchecked** (file is already in place)
5. Ensure "Khandoba" target is **checked**
6. Click "Add"

## How NLP Naming Works

### Example Transformations:

**Before** → **After**:
- "Document.pdf" → "Invoice - 2024-11-28.pdf" (if content contains invoice keywords)
- "Video Recording" → "Meeting - 2024-11-28.mp4" (if tags indicate meeting)
- "Voice Memo" → "Call Recording - 2024-11-28.m4a" (if audio analysis suggests call)
- "image.jpg" → "Passport - 2024-11-28.jpg" (if EXIF/metadata indicates passport)

### Naming Logic:
1. **Check if name is descriptive**: If original name is already meaningful (>10 chars, not generic), use it
2. **Extract metadata**: Index document to get text, tags, dates
3. **Generate tags**: Use `AITaggingService` to identify content type
4. **Build name**: Combine primary tag + date + extension
5. **Fallback**: If no tags found, use file type + date

## Testing Checklist

- [ ] Add `DocumentNamingService.swift` to Xcode project
- [ ] Test video recording - should save successfully
- [ ] Test voice memo recording - should be accessible from client view
- [ ] Test file upload - should get smart names based on content
- [ ] Verify credits are deducted for recordings
- [ ] Verify files are encrypted and wrapped in `.khd` format

## Expected Behavior

### Video Recording:
1. Start recording → Shows live preview
2. Stop recording → Shows save alert with smart name suggestion
3. Save → File is encrypted, wrapped, saved with NLP-generated name
4. Credits deducted (1 credit per document)

### Voice Memo:
1. Tap "Record Voice Memo" → Opens recording interface
2. Record → Shows timer and recording indicator
3. Stop → Can review and name (or use auto-generated name)
4. Save → File is encrypted, wrapped, saved with NLP-generated name
5. Credits deducted (1 credit per document)

### File Upload:
1. Upload any file → System analyzes content
2. Generates smart name based on:
   - Text content (if extractable)
   - File metadata
   - AI tags
   - Date and type
3. Saves with descriptive name instead of generic "Document.pdf"


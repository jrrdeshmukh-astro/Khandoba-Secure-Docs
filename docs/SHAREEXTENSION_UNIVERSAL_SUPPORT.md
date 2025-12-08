# Share Extension - Universal File Type Support

> **Last Updated:** December 2024  
> **Status:** Implemented in Build 22

## Overview

The Share Extension has been enhanced to support universal file types and improved sharing from WhatsApp and other applications.

## Supported File Types

### Images
- JPEG, PNG, HEIC, GIF
- Any image format supported by iOS

### Videos
- MP4, MOV, M4V
- Any video format supported by iOS

### Documents
- PDF files
- Text files (.txt, .md, etc.)
- Generic data files

### Audio
- MP3, M4A, AAC
- Any audio format supported by iOS

### URLs
- Web links
- WhatsApp links (wa.me, whatsapp.com, api.whatsapp.com)
- Custom URL schemes

## Architecture

### File Type Detection

The Share Extension uses `UTType` identifiers to detect file types:

```swift
// Images
if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier)

// Videos
if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier)

// PDFs
if attachment.hasItemConformingToTypeIdentifier(UTType.pdf.identifier)

// Audio
if attachment.hasItemConformingToTypeIdentifier(UTType.audio.identifier)

// Generic files
if attachment.hasItemConformingToTypeIdentifier(UTType.data.identifier)

// URLs
if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier)
```

### WhatsApp Support

**Detection:**
```swift
if url.absoluteString.contains("wa.me") || 
   url.absoluteString.contains("whatsapp.com") ||
   url.absoluteString.contains("api.whatsapp.com") {
    // Handle WhatsApp link
}
```

**Storage:**
- WhatsApp links are saved as text documents
- Name: "WhatsApp Link"
- MIME type: "text/plain"
- Content: Full URL string

### Dedicated Loaders

Each file type has a dedicated loader function:

- `loadImage(from:completion:)` - Handles images
- `loadVideo(from:completion:)` - Handles videos
- `loadPDF(from:completion:)` - Handles PDFs
- `loadAudio(from:completion:)` - Handles audio
- `loadFile(from:completion:)` - Handles generic files
- `loadText(from:completion:)` - Handles text

### MIME Type Detection

**URL Extension:**
```swift
extension URL {
    func mimeType() -> String? {
        if let uti = UTType(filenameExtension: self.pathExtension) {
            return uti.preferredMIMEType
        }
        return nil
    }
}
```

## User Interface

### Items Preview Card

- Shows first 3 items with icons
- Displays file names and sizes
- "+ X more" indicator for additional items

### Vault Selection

- Only shows **unlocked vaults** (with active sessions)
- Active session indicator (green dot + "Open" badge)
- Vault description preview
- Auto-selects first vault

### Upload Progress

- Linear progress bar
- Item count (e.g., "Uploading 2 of 5 items...")
- Percentage display
- Real-time updates

## Security

### Biometric Authentication

- Face ID/Touch ID required before showing vaults
- Graceful fallback if biometrics unavailable
- Secure access to vault list

### Vault Filtering

**Only Unlocked Vaults:**
```swift
let unlockedVaults = fetchedVaults.filter { vault in
    guard !vault.isSystemVault else { return false }
    
    if let sessions = vault.sessions {
        return sessions.contains { session in
            session.isActive && session.expiresAt > now
        }
    }
    return false
}
```

**Benefits:**
- Users can only save to vaults they've opened
- Prevents accidental uploads to locked vaults
- Clear security model

## File Upload Flow

1. **Load Items:**
   - Detect file types from attachments
   - Load file data
   - Create `SharedItem` objects

2. **Authenticate:**
   - Biometric authentication
   - Load vaults from App Group

3. **Select Vault:**
   - Show only unlocked vaults
   - User selects target vault

4. **Upload:**
   - Create `Document` for each item
   - Encrypt file data
   - Save to vault
   - Sync to CloudKit

5. **Complete:**
   - Show success
   - Close extension

## Error Handling

### File Loading Errors

```swift
guard error == nil else {
    print("⚠️ Error loading file: \(error?.localizedDescription ?? "unknown")")
    completion(nil)
    return
}
```

### Vault Loading Errors

- Shows error message to user
- Provides retry option
- Logs detailed error information

### Upload Errors

- Displays error alert
- Allows user to retry
- Preserves selected vault

## CloudKit Sync

### App Group Configuration

```swift
let appGroupIdentifier = "group.com.khandoba.securedocs"
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    groupContainer: .identifier(appGroupIdentifier),
    cloudKitDatabase: .automatic
)
```

### Sync Timing

- 1 second initial wait for CloudKit sync
- 2 additional seconds if no vaults found
- 0.5 seconds after upload completion
- 0.1 seconds between individual file saves

## Best Practices

### File Type Detection

1. Check URL type first (for WhatsApp links)
2. Check specific types (image, video, PDF, audio)
3. Fall back to generic data type
4. Handle text separately

### Error Handling

1. Log all errors with context
2. Show user-friendly messages
3. Provide retry mechanisms
4. Preserve user selections

### Performance

1. Load files asynchronously
2. Use `DispatchGroup` for parallel loading
3. Cache `ModelContainer` instance
4. Batch CloudKit syncs

## Testing

### Test Cases

1. **Images:** Share photo from Photos app
2. **Videos:** Share video from Camera app
3. **PDFs:** Share PDF from Files app
4. **WhatsApp:** Share WhatsApp link
5. **Multiple Files:** Share multiple items at once
6. **Locked Vaults:** Verify only unlocked vaults shown
7. **Biometric Auth:** Test Face ID/Touch ID flow

### Edge Cases

- Very large files (>100MB)
- Unsupported file types
- Network connectivity issues
- CloudKit sync delays
- Multiple simultaneous shares

## Related Documentation

- `SHAREEXTENSION_VAULT_LOADING_TROUBLESHOOTING.md` - Vault loading issues
- `SHAREEXTENSION_LAUNCHSERVICES_ERRORS.md` - Common warnings
- `MODERN_NOMINEE_ARCHITECTURE.md` - Nominee management


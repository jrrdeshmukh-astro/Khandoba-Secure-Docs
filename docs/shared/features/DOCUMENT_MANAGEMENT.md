# Document Management Feature

> Comprehensive documentation for document handling across all platforms

---

## Overview

Documents are the core content stored in vaults. All documents are encrypted with AES-256-GCM and support automatic indexing, tagging, and preview.

---

## Document Types

### Source Documents
- Created by the user
- Examples: Photos taken, recordings made, files created

### Sink Documents
- Received from others
- Examples: Files shared, documents received

### Both
- Can be both source and sink
- Examples: Documents that are both created and shared

---

## Document Operations

### Upload Document

**Supported Sources:**
- Camera (photo/video)
- File picker
- Gallery/library
- Drag and drop (desktop platforms)

**Process:**
1. User selects file/source
2. File read into memory
3. Encrypted with AES-256-GCM
4. Uploaded to Supabase Storage
5. Metadata stored in database
6. Automatic indexing triggered

### Download Document

**Process:**
1. Retrieve document metadata
2. Download encrypted file from storage
3. Retrieve encryption key
4. Decrypt file
5. Return decrypted data to user

### Preview Document

**Supported Formats:**
- Images (JPEG, PNG, etc.)
- PDFs (with text extraction)
- Videos (with player)
- Audio (with player)
- Text files

### Delete Document

- Removes from database
- Deletes from Supabase Storage
- Cascade delete from vault

---

## Encryption

### Encryption Flow

```
Original Document
    ↓
Generate Encryption Key (per document)
    ↓
Encrypt with AES-256-GCM
    ↓
Upload Encrypted Data to Supabase Storage
    ↓
Store Encryption Key (encrypted with vault key) in Database
```

### Decryption Flow

```
Request Document
    ↓
Retrieve Encryption Key from Database
    ↓
Download Encrypted Data from Storage
    ↓
Decrypt with AES-256-GCM
    ↓
Return Decrypted Data
```

### Key Management

- Each document has its own encryption key
- Keys stored encrypted in database
- Vault-level key encryption for additional security
- Platform-specific secure storage for key protection

---

## Automatic Indexing

### ML-Based Indexing

**Steps:**
1. Extract text from document (OCR, PDF parsing, etc.)
2. Detect language
3. Extract entities (people, organizations, locations, dates)
4. Generate automatic tags
5. Suggest document name
6. Calculate importance score

### Extracted Information

- **Entities:** People, organizations, locations, dates
- **Key Phrases:** Important phrases and concepts
- **Tags:** Automatic categorization tags
- **Language:** Detected document language
- **Suggested Name:** AI-suggested document name

---

## Platform-Specific Implementation

### Apple

**Text Extraction:**
- Vision framework for OCR
- PDFKit for PDF text
- Speech framework for audio transcription

**Services:**
- `DocumentIndexingService` - ML indexing
- `NLPTaggingService` - Automatic tagging
- `PDFTextExtractor` - PDF text extraction
- `TranscriptionService` - Audio transcription

### Android

**Text Extraction:**
- ML Kit Text Recognition for OCR
- PDF libraries for PDF text
- Speech-to-Text API for audio

**Services:**
- `DocumentIndexingService` - ML Kit indexing
- `DocumentService` - Upload/download management

### Windows

**Text Extraction:**
- Azure Cognitive Services for OCR
- PdfPig for PDF text extraction

**Services:**
- `DocumentIndexingService` - Azure Cognitive Services
- `DocumentService` - Upload/download with PDF extraction

---

## Storage

### Supabase Storage Buckets

- **encrypted-documents** - Document files
- **profile-pictures** - User profile pictures
- **voice-memos** - Audio files (Apple only)
- **intel-reports** - Intel report data (Apple only)

### Storage Path Structure

```
{vaultId}/{documentId}.{extension}
```

Example:
```
a1b2c3d4-e5f6-7890-abcd-ef1234567890/12345678-90ab-cdef-1234-567890abcdef.pdf
```

---

## Metadata

### Document Metadata Fields

- `id` - Unique identifier
- `vaultId` - Associated vault
- `name` - Document name
- `fileExtension` - File extension
- `mimeType` - MIME type
- `fileSize` - File size in bytes
- `storagePath` - Path in Supabase Storage
- `documentType` - Type (image, pdf, video, audio, text, other)
- `sourceSinkType` - Source, sink, or both
- `encryptionKeyData` - Encrypted encryption key
- `extractedText` - Extracted text content
- `aiTags` - Automatic tags
- `createdAt` - Creation timestamp
- `updatedAt` - Last update timestamp

---

## Preview Support

### Images
- Full-screen preview
- Zoom and pan
- Platform-native image viewer

### PDFs
- Text extraction and display
- Page navigation (if supported)
- Text search (if available)

### Videos
- Native video player
- Playback controls
- Full-screen mode

### Audio
- Audio player controls
- Playback progress
- Volume control

### Text Files
- Plain text display
- Syntax highlighting (if applicable)
- Text search

---

## Cross-Platform Sync

### Real-Time Updates

When a document is uploaded on one platform:
1. Uploaded to Supabase Storage
2. Metadata saved to database
3. Real-time event broadcast
4. Other platforms receive update
5. UI refreshes automatically

### Conflict Resolution

- Last-write-wins for metadata
- File updates create new versions
- Access logs prevent conflicts

---

## API Reference

### Upload

**Apple:**
```swift
func uploadDocument(
    vaultId: UUID,
    data: Data,
    name: String,
    mimeType: String
) async throws -> Document
```

**Android:**
```kotlin
suspend fun uploadDocument(
    vaultId: UUID,
    uri: Uri,
    name: String,
    uploadedByUserID: UUID
): Result<DocumentEntity>
```

**Windows:**
```csharp
Task<Document> UploadDocumentAsync(
    Guid vaultId,
    StorageFile file,
    string name
);
```

### Download

**All Platforms:**
```swift/kotlin/csharp
func downloadDocument(document: Document) -> Data/ByteArray
```

---

**Last Updated:** December 2024

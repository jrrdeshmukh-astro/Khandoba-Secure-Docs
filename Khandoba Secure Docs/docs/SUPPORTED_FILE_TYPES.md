# Supported File Types

**Date:** December 2024  
**Status:** ✅ **All File Types Supported**

---

## Overview

Khandoba Secure Docs supports uploading **any file type** to vaults. The app explicitly supports common document formats and uses a fallback (`.data`) to allow any other file type.

---

## Explicitly Supported File Types

### Images
- ✅ **JPEG** (.jpg, .jpeg)
- ✅ **PNG** (.png)
- ✅ **HEIC** (.heic)
- ✅ **GIF** (.gif)
- ✅ **BMP** (.bmp)
- ✅ **TIFF** (.tiff, .tif)

### Documents
- ✅ **PDF** (.pdf)
- ✅ **Microsoft Word** (.docx, .doc)
- ✅ **Microsoft Excel** (.xlsx, .xls)
- ✅ **Microsoft PowerPoint** (.pptx, .ppt)

### Text Files
- ✅ **Plain Text** (.txt)
- ✅ **RTF** (.rtf)
- ✅ **Markdown** (.md, .markdown)

### Archives
- ✅ **ZIP** (.zip)
- ✅ **RAR** (.rar)

### Video
- ✅ **MP4** (.mp4)
- ✅ **QuickTime** (.mov)
- ✅ **AVI** (.avi)
- ✅ **All video formats** (via `.video` type)

### Audio
- ✅ **M4A** (.m4a)
- ✅ **MP3** (.mp3)
- ✅ **WAV** (.wav)
- ✅ **All audio formats** (via `.audio` type)

### Other
- ✅ **Any file type** (via `.data` fallback)

---

## Upload Methods

### 1. Camera (Source)
- Takes photos directly
- Classified as "Source" data
- Format: JPEG

### 2. Photos (Source)
- Selects from photo library
- Classified as "Source" data
- Formats: JPEG, PNG, HEIC

### 3. Files (Sink)
- **Browses any file from device**
- Classified as "Sink" data
- **Supports ALL file types** including:
  - Office documents (.docx, .xlsx, .pptx)
  - PDFs
  - Archives (.zip, .rar)
  - Any other file type

---

## Document Type Classification

The app automatically classifies uploaded files:

| File Type | Classification | Notes |
|-----------|---------------|-------|
| Images | `"image"` | JPEG, PNG, HEIC, GIF, BMP, TIFF |
| PDFs | `"pdf"` | PDF documents |
| Word Docs | `"document"` | .docx, .doc |
| Excel Files | `"spreadsheet"` | .xlsx, .xls |
| PowerPoint | `"presentation"` | .pptx, .ppt |
| Videos | `"video"` | MP4, MOV, AVI, etc. |
| Audio | `"audio"` | M4A, MP3, WAV, etc. |
| Text | `"text"` | TXT, RTF, Markdown |
| Archives | `"archive"` | ZIP, RAR |
| Other | `"other"` | Any other file type |

---

## Features for All File Types

### ✅ Encryption
- All files are encrypted with AES-256-GCM
- Encrypted at rest in vault

### ✅ Metadata Extraction
- File name, size, extension stored
- MIME type detection
- Upload timestamp

### ✅ AI Tagging
- Automatic tag generation (for supported types)
- Document type tags
- Content-based tags (for images, PDFs, text)

### ✅ Text Extraction
- **PDFs:** Full text extraction
- **Images:** OCR text extraction
- **Office Documents:** Text extraction (if supported)
- **Text Files:** Full content extraction

### ✅ Search
- Search by filename
- Search by extracted text (if available)
- Search by AI tags

### ✅ Preview
- **Images:** Full image preview
- **PDFs:** Multi-page PDF preview
- **Videos:** Video playback
- **Audio:** Audio playback
- **Other:** File info display

---

## Office Document Support

### Microsoft Word (.docx, .doc)
- ✅ Can be uploaded
- ✅ Stored encrypted
- ✅ Classified as "document" type
- ⚠️ Text extraction: Limited (depends on file format)
- ⚠️ Preview: File info only (no native preview)

### Microsoft Excel (.xlsx, .xls)
- ✅ Can be uploaded
- ✅ Stored encrypted
- ✅ Classified as "spreadsheet" type
- ⚠️ Text extraction: Limited
- ⚠️ Preview: File info only

### Microsoft PowerPoint (.pptx, .ppt)
- ✅ Can be uploaded
- ✅ Stored encrypted
- ✅ Classified as "presentation" type
- ⚠️ Text extraction: Limited
- ⚠️ Preview: File info only

**Note:** Office documents are stored securely but don't have native preview support. Users can download and open them in other apps.

---

## File Size Limits

- **No explicit size limit** in code
- **Recommended:** Files under 10MB for optimal AI analysis
- **Large files:** Still supported but may skip deep AI analysis

---

## Upload Process

1. **Select File**
   - Choose from Files app
   - Any file type can be selected

2. **File Detection**
   - MIME type detected from extension
   - Document type classified automatically

3. **Encryption**
   - File encrypted with AES-256-GCM
   - Encrypted data stored in vault

4. **Indexing**
   - Metadata extracted
   - Text extracted (if applicable)
   - AI tags generated (for supported types)

5. **Storage**
   - Encrypted file stored in vault
   - Available for preview, search, share

---

## Examples

### Supported Uploads:
- ✅ `document.docx` - Microsoft Word document
- ✅ `spreadsheet.xlsx` - Microsoft Excel file
- ✅ `presentation.pptx` - Microsoft PowerPoint
- ✅ `report.pdf` - PDF document
- ✅ `archive.zip` - ZIP archive
- ✅ `data.json` - JSON file
- ✅ `script.py` - Python script
- ✅ `video.mp4` - Video file
- ✅ `audio.m4a` - Audio file
- ✅ `image.jpg` - Image file
- ✅ **Any other file type**

---

## Technical Details

### File Picker Configuration
```swift
allowedContentTypes: [
    .png, .jpeg, .heic, .pdf,
    UTType(filenameExtension: "docx") ?? .data,
    UTType(filenameExtension: "xlsx") ?? .data,
    // ... more types
    .data  // Fallback for any file type
]
```

### MIME Type Detection
- Automatic detection from file extension
- Comprehensive mapping for common formats
- Falls back to generic type if unknown

### Document Type Classification
- Automatic classification based on MIME type
- Office documents recognized as specific types
- Unknown types classified as "other"

---

## Conclusion

✅ **Yes, you can upload any file type to the vault!**

The app explicitly supports:
- Office documents (.docx, .xlsx, .pptx, etc.)
- PDFs
- Images
- Videos
- Audio
- Archives
- Text files
- **And any other file type** (via `.data` fallback)

All files are:
- ✅ Encrypted
- ✅ Stored securely
- ✅ Searchable (by name/tags)
- ✅ Shareable
- ✅ Version controlled

---

**Last Updated:** December 2024  
**Status:** ✅ **Fully Supported**

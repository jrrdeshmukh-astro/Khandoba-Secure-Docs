# Documents Feature

> **Last Updated:** December 2024
> 
> Complete documentation of document management features.

## Overview

Documents are stored within vaults with full encryption, indexing, and version control.

## Document Types

- **Images**: JPEG, PNG, HEIC
- **PDFs**: PDF documents
- **Videos**: MP4, MOV
- **Audio**: M4A, WAV
- **Text**: TXT, RTF
- **Other**: Any file type

## Document Operations

### Upload

1. Select document source
2. Virus scan
3. Indexing (metadata, EXIF, OCR)
4. Encryption
5. Upload to vault

### Preview

- Full document preview
- Zoom and pan
- Multi-page support (PDFs)
- Video playback

### Actions

- **Archive/Unarchive**: Hide/show documents
- **Redact**: Permanent redaction (HIPAA)
- **Share**: iOS share sheet, WhatsApp
- **Delete**: Remove from vault
- **Rename**: Edit document name
- **Version History**: View and restore versions

## Document Search

### Cross-Vault Search

- Search all documents across all open vaults
- Filter by source/sink type
- Filter by document type
- Filter by date range
- AI tags prominently displayed

### Search Features

- Text search
- Metadata search
- OCR text search
- Tag-based filtering

## Document Indexing

### Metadata Extraction

- File properties
- EXIF data (images)
- PDF metadata
- OCR text extraction
- AI tagging

### Indexing Process

1. Document uploaded
2. Metadata extracted
3. OCR processed (if applicable)
4. AI tags generated
5. Index stored in CoreData

## Version Control

- Track all document versions
- Compare versions
- Restore previous versions
- Version history audit trail

## HIPAA Compliance

- Document archiving
- Permanent redaction
- Audit trails
- Access logging


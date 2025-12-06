# LLAMA Auto-Tagging and Naming

## Overview

The app now uses **LLAMA-style understanding** to automatically generate intelligent names and tags for all uploaded files, recordings, and images. This provides context-aware naming and comprehensive tagging without manual input.

---

## How It Works

### **Automatic During Upload**

When you upload any file (image, video, audio, document), the system:

1. **Analyzes content** using LLAMA-style understanding
2. **Generates intelligent name** based on content analysis
3. **Creates comprehensive tags** automatically
4. **Saves with smart naming** - no more generic filenames!

---

## LLAMA Analysis by File Type

### **Images** (CLIP-style Scene Understanding)

**What LLAMA analyzes:**
- Scene classification (office, outdoor, medical, etc.)
- Face detection (portrait, group photo)
- OCR text extraction (invoice, receipt, contract, medical document)
- Image characteristics (landscape, portrait, orientation)

**Example naming:**
- `Invoice_1734567890.pdf` (from scanned invoice)
- `Portrait_1734567890.jpg` (single person photo)
- `Medical_Document_1734567890.jpg` (medical record scan)
- `Receipt_1734567890.jpg` (receipt photo)

**Example tags:**
- `Invoice`, `Financial`, `Document with text`
- `Portrait`, `Single Person`, `Landscape`
- `Medical`, `Healthcare`, `Document`

---

### **Videos** (Video-LLaMA Style)

**What LLAMA analyzes:**
- Duration analysis
- Audio transcription (if available)
- Frame analysis (opening scene description)
- Content inference (meeting, presentation, personal video)

**Example naming:**
- `Meeting_1734567890.mp4` (meeting recording with transcript)
- `Presentation_1734567890.mov` (presentation capture)
- `VoiceMemo_1734567890.mp4` (voice note video)

**Example tags:**
- `Meeting`, `Recording`, `With Audio`, `Medium Length`
- `Presentation`, `Recording`, `Brief Recording`
- `Voice Memo`, `Personal Note`, `Short Clip`

---

### **Audio Recordings** (Transcription + Context)

**What LLAMA analyzes:**
- Duration analysis
- Speech-to-text transcription
- Content inference (meeting, personal note, intelligence briefing)
- Context understanding

**Example naming:**
- `Meeting_Recording_1734567890.m4a` (meeting transcript detected)
- `VoiceMemo_1734567890.m4a` (personal voice note)
- `Intelligence_Briefing_1734567890.m4a` (intel report)

**Example tags:**
- `Meeting`, `Recording`, `Voice Memo`, `Brief Recording`
- `Voice Memo`, `Personal Note`, `Quick Note`
- `Intelligence Briefing`, `Recording`, `Medium Length`

---

### **Documents/PDFs** (Text Analysis)

**What LLAMA analyzes:**
- Text content extraction
- Document type detection (invoice, receipt, contract, report, medical)
- Named entity recognition (people, places, organizations)
- Keyword extraction

**Example naming:**
- `Invoice_1734567890.pdf` (invoice document)
- `Contract_1734567890.pdf` (legal contract)
- `Medical_Report_1734567890.pdf` (medical document)

**Example tags:**
- `Invoice`, `Financial`, `PDF`, `Document`
- `Contract`, `Legal`, `PDF`, `Document`
- `Medical`, `Healthcare`, `Report`, `PDF`

---

## Integration Points

### **Automatic During Upload**

The LLAMA analysis is automatically triggered in `DocumentService.uploadDocument()`:

```swift
// Generate intelligent document name using LLAMA
let intelligentName = await NLPTaggingService.generateDocumentName(
    for: data,
    mimeType: mimeType,
    fallbackName: name
)
document.name = intelligentName

// Generate comprehensive AI tags using LLAMA
document.aiTags = await NLPTaggingService.generateTags(
    for: data,
    mimeType: mimeType,
    documentName: name
)
```

### **Works For All Upload Methods**

- ✅ **Single file upload** (`DocumentUploadView`)
- ✅ **Bulk upload** (`BulkOperationsView`)
- ✅ **Photo picker** (PhotosPicker)
- ✅ **File picker** (fileImporter)
- ✅ **Video recording** (`VideoRecordingView`)
- ✅ **Voice recording** (`VoiceRecordingView`)

---

## Performance Optimization

### **Smart File Size Limits**

- **Files < 10MB**: Full LLAMA analysis (scene, OCR, transcription)
- **Files > 10MB**: Basic tags only (document type, filename analysis)

This prevents the app from hanging on very large files while still providing intelligent naming and basic tags.

### **Async Processing**

All LLAMA analysis runs asynchronously, so uploads don't block the UI. Progress is tracked and displayed to the user.

---

## Example Workflows

### **Scenario 1: Upload Receipt Photo**

1. User takes photo of receipt
2. LLAMA analyzes:
   - OCR extracts "Receipt", "Total: $45.99", "Date: 12/6/2024"
   - Scene classification: "Document being photographed"
3. **Auto-generated name**: `Receipt_1734567890.jpg`
4. **Auto-generated tags**: `Receipt`, `Financial`, `Document with text`, `Image`, `JPEG`

### **Scenario 2: Record Meeting Audio**

1. User records 5-minute meeting
2. LLAMA analyzes:
   - Transcription: "Meeting about Q4 planning..."
   - Duration: 300 seconds
   - Content inference: "Meeting recording"
3. **Auto-generated name**: `Meeting_1734567890.m4a`
4. **Auto-generated tags**: `Meeting`, `Recording`, `Voice Memo`, `Medium Length`, `With Audio`

### **Scenario 3: Upload Medical Document PDF**

1. User uploads PDF medical report
2. LLAMA analyzes:
   - Text extraction: "Patient: John Doe, Diagnosis:..."
   - Document type: "Medical document"
   - Named entities: "John Doe" (person)
3. **Auto-generated name**: `Medical_1734567890.pdf`
4. **Auto-generated tags**: `Medical`, `Healthcare`, `PDF`, `Document`, `Person: John Doe`

---

## Benefits

### **For Users**

- ✅ **No manual naming** - files automatically get meaningful names
- ✅ **Better organization** - intelligent tags make search easier
- ✅ **Context preservation** - content understanding captured in name/tags
- ✅ **Faster workflow** - upload and forget, system handles naming

### **For Search**

- ✅ **Better discoverability** - search by content, not just filename
- ✅ **Tag-based filtering** - find all invoices, receipts, meetings, etc.
- ✅ **Content-aware search** - find documents by what they contain

---

## Technical Details

### **LLAMA-Style Understanding**

The system uses Apple's frameworks to provide LLAMA-style understanding:

- **Vision Framework**: Scene classification, face detection, OCR
- **Speech Framework**: Audio transcription
- **NaturalLanguage Framework**: Entity recognition, keyword extraction
- **AVFoundation**: Video/audio analysis

### **Naming Algorithm**

1. Generate LLAMA-style description
2. Extract document type (invoice, receipt, contract, etc.)
3. Extract scene/context (meeting, portrait, medical, etc.)
4. Combine into meaningful name: `[Type]_[Context]_[Timestamp].[ext]`

### **Tagging Algorithm**

1. Generate LLAMA-style description
2. Extract document type tags
3. Extract scene/context tags
4. Extract content tags (people, places, organizations)
5. Extract metadata tags (duration, orientation, etc.)
6. Combine and deduplicate

---

## Configuration

### **File Size Limits**

Default: 10MB for deep analysis
- Can be adjusted in `NLPTaggingService.generateTags()`
- Larger files still get basic tags

### **Tag Limits**

- Maximum tags per document: Unlimited (deduplicated)
- Keyword extraction: Top 10 keywords
- Scene classification: Top 3 scenes

---

## Future Enhancements

Potential improvements:

- [ ] Custom LLM integration for even better understanding
- [ ] User-defined tag preferences
- [ ] Learning from user corrections
- [ ] Multi-language support
- [ ] Custom naming templates

---

## Testing

### **How to Test**

1. **Upload an image** (receipt, invoice, photo)
   - Check auto-generated name
   - Check auto-generated tags

2. **Record audio** (voice memo, meeting)
   - Check transcription-based naming
   - Check content-aware tags

3. **Upload video** (meeting, presentation)
   - Check frame analysis
   - Check audio transcription tags

4. **Upload PDF** (document, contract)
   - Check text extraction
   - Check document type detection

### **Expected Results**

- ✅ Files get meaningful names (not generic like "photo_123.jpg")
- ✅ Comprehensive tags automatically added
- ✅ Search works better with intelligent tags
- ✅ No manual input required

---

**Last Updated**: December 2024
**Status**: ✅ Fully Implemented
**Service**: `NLPTaggingService` with LLAMA-style understanding

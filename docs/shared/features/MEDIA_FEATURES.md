# Media Features

> Documentation for media capture and playback across platforms

---

## Overview

Khandoba Secure Docs supports media capture (photos, videos, audio) and playback, with platform-specific implementations.

---

## Photo Capture

### Apple

**Implementation:**
- Camera API integration
- UIImagePickerController
- Custom camera views (AVFoundation)

**Features:**
- Photo capture
- Live preview
- Multiple photo selection
- Image editing (basic)

### Android

**Implementation:**
- CameraX for camera access
- Activity result contracts
- File provider for image storage

**Features:**
- Photo capture
- Live preview
- Gallery integration
- Image selection

### Windows

**Status:** 🚧 Planned

**Implementation:**
- Windows.Media.Capture APIs
- Camera access

---

## Video Recording

### Apple

**Implementation:**
- AVFoundation
- AVCaptureSession
- Video recording with preview

**Features:**
- Video recording
- Live preview
- Video quality settings
- Recording duration limits

### Android

**Implementation:**
- CameraX VideoCapture
- Video recording API
- MediaStore integration

**Features:**
- Video recording
- Live preview
- Recording timer
- Video quality settings

**Service:**
- `VideoRecordingView.kt` - CameraX implementation

### Windows

**Status:** 🚧 Foundation

**Service:**
- `VideoRecordingService.cs` - Basic implementation

---

## Audio Recording

### Apple

**Implementation:**
- AVAudioRecorder
- Audio session management
- Voice memo service with TTS

**Features:**
- Audio recording
- Playback
- Voice memo generation (TTS)
- Audio transcription

**Service:**
- `VoiceMemoService.swift` - Voice memo generation
- `TranscriptionService.swift` - Speech-to-text

### Android

**Implementation:**
- MediaRecorder
- Audio recording APIs

**Features:**
- Audio recording
- Playback (basic)

**Service:**
- `VoiceRecordingView.kt` - Audio recording

### Windows

**Implementation:**
- Windows.Media.Capture
- Audio recording APIs

**Service:**
- `VoiceRecordingService.cs` - Audio recording

---

## Media Playback

### Image Preview

**All Platforms:**
- Full-screen preview
- Zoom and pan
- Platform-native image viewer

### Video Playback

**Apple:**
- AVPlayer
- Full video player controls
- Picture-in-picture support

**Android:**
- MediaPlayer / ExoPlayer
- Video player controls
- Full-screen playback

**Windows:**
- MediaPlayerElement
- Video playback controls

### Audio Playback

**Apple:**
- AVAudioPlayer
- Audio session management
- Background playback support

**Android:**
- MediaPlayer
- Audio playback controls
- Background playback

**Windows:**
- MediaPlayer
- Audio playback controls

---

## Media Processing

### Image Processing

**Apple:**
- Core Image
- Vision framework for analysis
- Image filters and transformations

**Android:**
- ML Kit image labeling
- Image analysis
- Basic transformations

**Windows:**
- Windows.Graphics.Imaging
- Image processing APIs

### Video Processing

**Apple:**
- AVFoundation
- Video composition
- Video analysis (Vision)

**Android:**
- MediaMetadataRetriever
- Video thumbnail generation
- Basic processing

**Windows:**
- Media APIs
- Video processing (planned)

### Audio Processing

**Apple:**
- AVAudioEngine
- Audio analysis
- Speech recognition

**Android:**
- Audio processing APIs
- Speech recognition (basic)

**Windows:**
- Windows.Media.SpeechRecognition
- Audio processing APIs

---

## File Formats

### Supported Formats

**Images:**
- JPEG, PNG, HEIC (Apple)
- JPEG, PNG, WebP (Android)

**Videos:**
- MP4, MOV (Apple)
- MP4 (Android)

**Audio:**
- M4A, AAC (Apple)
- MP3, AAC, M4A (Android)
- MP3, WAV (Windows)

---

## Storage

### Local Storage

- Temporary storage during capture
- Encrypted storage after upload
- Platform-specific file systems

### Cloud Storage

- Supabase Storage buckets
- Encrypted upload
- Metadata in database

---

## Permissions

### Required Permissions

**Apple:**
- Camera usage
- Photo library access
- Microphone access

**Android:**
- CAMERA permission
- READ_EXTERNAL_STORAGE
- RECORD_AUDIO
- WRITE_EXTERNAL_STORAGE (if needed)

**Windows:**
- Camera capability
- Microphone capability
- Pictures library access

---

## Platform-Specific Features

### Apple

**Advanced Features:**
- Voice memo generation with TTS
- Intel Reports with audio narration
- Multi-modal analysis (Vision + Speech)
- Live Photos support

### Android

**Features:**
- CameraX integration
- ML Kit image analysis
- Basic audio/video capture

### Windows

**Status:**
- Foundation implementation
- Basic capture capabilities
- Advanced features planned

---

**Last Updated:** December 2024

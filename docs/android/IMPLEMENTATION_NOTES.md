# Android Platform Implementation Notes

> Detailed implementation documentation for Android platform

---

## Overview

**Platform:** Android (API 26+)  
**Language:** Kotlin  
**Framework:** Jetpack Compose (Material 3)  
**Services:** 9  
**Status:** ✅ Production Ready

---

## Architecture

### MVVM Architecture

```
Views (Jetpack Compose)
    ↓
ViewModels
    ↓
Services (Business Logic)
    ↓
Repositories
    ↓
Room (Local) + Supabase (Cloud)
```

### Key Patterns

- **Jetpack Compose** - Declarative UI
- **Room Database** - Local persistence
- **Kotlin Coroutines + Flow** - Async operations
- **StateFlow** - Reactive state management
- **Material 3** - Modern Android design system

---

## Services (9 Total)

### Core Services

1. **AuthenticationService**
   - Google Sign In integration
   - Session management
   - User profile management
   - Location: `service/AuthenticationService.kt`

2. **VaultService**
   - Vault CRUD operations
   - Vault locking/unlocking
   - Session management
   - Location: `service/VaultService.kt`

3. **DocumentService**
   - Document upload/download
   - Document management
   - Encryption integration
   - Location: `service/DocumentService.kt`

4. **EncryptionService**
   - AES-256-GCM encryption (Android Keystore)
   - Key generation and management
   - Zero-knowledge architecture
   - Location: `service/EncryptionService.kt`

5. **DocumentIndexingService**
   - ML Kit document indexing
   - Entity extraction
   - Text analysis
   - Location: `service/DocumentIndexingService.kt`

6. **DualKeyApprovalService**
   - Dual-key request handling
   - ML-based approval logic
   - Location: `service/DualKeyApprovalService.kt`

7. **LocationService**
   - Geographic tracking
   - Location-based access control
   - Location: `service/LocationService.kt`

8. **ThreatMonitoringService**
   - Access pattern monitoring
   - Security event tracking
   - Location: `service/ThreatMonitoringService.kt`

9. **SubscriptionService**
   - Play Billing subscriptions
   - Subscription management
   - Location: `service/SubscriptionService.kt`

---

## Data Layer

### Room Database

Entities:
- **UserEntity** - User accounts
- **VaultEntity** - Vault definitions
- **DocumentEntity** - Document metadata
- **VaultSessionEntity** - Active sessions
- **VaultAccessLogEntity** - Access logs
- **NomineeEntity** - Nominees
- **DualKeyRequestEntity** - Dual-key requests
- **ChatMessageEntity** - Messages

### DAOs (Data Access Objects)

- `UserDao` - User data access
- `VaultDao` - Vault data access
- `DocumentDao` - Document data access
- `VaultSessionDao` - Session data access
- `VaultAccessLogDao` - Access log data access
- `NomineeDao` - Nominee data access
- `DualKeyRequestDao` - Dual-key request data access
- `ChatMessageDao` - Chat message data access

### Repositories

- `UserRepository` - User data management
- `VaultRepository` - Vault data management
- `DocumentRepository` - Document data management

---

## UI Components

### Views (Jetpack Compose)

**Authentication:**
- `WelcomeView` - Sign in screen

**Vaults:**
- `VaultListView` - List of vaults
- `VaultDetailView` - Vault details and documents
- `ClientMainView` - Main navigation

**Documents:**
- `DocumentUploadView` - Upload documents
- `DocumentPreviewView` - Document preview

**Profile:**
- `ProfileView` - User profile
- `NotificationsSettingsView` - Notification settings
- `SecuritySettingsView` - Security settings
- `AboutView` - About screen

**Media:**
- `VideoRecordingView` - Video recording (CameraX)
- `VoiceRecordingView` - Voice recording

**Store:**
- `StoreView` - Subscription store

---

## Configuration

### Build Variants

- **dev** - Development (`com.khandoba.securedocs.dev`)
- **test** - Testing (`com.khandoba.securedocs.test`)
- **prod** - Production (`com.khandoba.securedocs`)

### Configuration Files

- `app/src/dev/res/values/config.xml` - Dev config
- `app/src/test/res/values/config.xml` - Test config
- `app/src/prod/res/values/config.xml` - Prod config
- `app/src/main/res/values/strings.xml` - App strings

### App Configuration

- `config/AppConfig.kt` - App-wide settings
- `config/EnvironmentConfig.kt` - Environment-specific settings

---

## Key Features

### 1. Vault Management

- Create, list, unlock, lock, delete vaults
- Session management with timeout
- Dual-key vaults with ML approval

### 2. Document Management

- Upload from files, camera, gallery
- Automatic encryption (AES-256-GCM via Android Keystore)
- ML Kit indexing and tagging
- Preview support (images, videos)
- Download and delete

### 3. Media Capture

- **Camera** - Photo capture via CameraX
- **Video** - Video recording via CameraX
- **Gallery** - File picker integration

### 4. Security

- **Android Keystore** - Hardware-backed key storage
- **Biometric Authentication** - Fingerprint/Face unlock
- **Zero-knowledge** - Server can't decrypt
- **Access logging** - Complete audit trail

### 5. Cross-Platform Sync

- **Supabase Backend** - Shared with iOS/Windows
- **Real-time Updates** - Live synchronization
- **RLS Policies** - Row-level security

---

## Integration Points

### Supabase Integration

- **Database:** PostgreSQL (via Supabase Kotlin client)
- **Storage:** Supabase Storage (encrypted documents, profile pictures)
- **Real-time:** Supabase Realtime channels
- **Auth:** Google Sign In → Supabase Auth

### ML Kit Integration

- **Text Recognition** - OCR from images
- **Entity Extraction** - Named entity recognition
- **Language Identification** - Automatic language detection

### CameraX Integration

- **Photo Capture** - Camera preview and capture
- **Video Recording** - Video recording with preview
- **Image Analysis** - On-device image processing

---

## Build & Deployment

### Development Build
```bash
./gradlew assembleDevDebug
```

### Production Build
```bash
./scripts/android/build_release.sh prod
```

### Sign & Upload
```bash
./scripts/android/sign_release.sh [aab_file]
./scripts/android/upload_to_playstore.sh
```

---

## Dependencies

### Core
- Jetpack Compose (Material 3)
- Room Database
- Kotlin Coroutines
- ViewModel & LiveData

### Networking
- Supabase Kotlin Client
- OkHttp

### Media
- CameraX
- MediaRecorder

### ML/AI
- ML Kit

### Billing
- Play Billing Library

---

## Implementation Status

### ✅ Complete

- User authentication (Google Sign In)
- Vault management
- Document management
- Encryption (Android Keystore)
- ML Kit document indexing
- Camera and video recording
- Cross-platform sync
- Real-time subscriptions (implemented)
- Profile settings screens

### 🚧 Partial

- Some advanced AI features from Apple platform
- PDF text extraction (can be added)

### ❌ Not Implemented

- Intel Reports
- Voice Memos with TTS
- Some advanced AI/ML services

---

## Known Limitations

1. **Intel Reports** - Not available (Apple-only feature)
2. **Voice Memos** - Not available (Apple-only feature)
3. **Advanced AI Services** - Some features from Apple platform not ported
4. **iMessage Extension** - Android doesn't have equivalent

---

**Last Updated:** December 2024

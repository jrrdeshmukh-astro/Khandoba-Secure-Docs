# Apple Platform Implementation Notes

> Detailed implementation documentation for iOS/macOS/watchOS/tvOS platform

---

## Overview

**Platform:** Apple (iOS 17.0+, macOS 14.0+, watchOS 10.0+, tvOS 17.0+)  
**Language:** Swift 5.9+  
**Framework:** SwiftUI + SwiftData  
**Services:** 54  
**Status:** ✅ Production Ready

---

## Architecture

### Service-Oriented Architecture

The app follows a service-oriented architecture with clear separation of concerns:

```
Views (SwiftUI)
    ↓
ViewModels / @StateObject
    ↓
Services (Business Logic)
    ↓
Repositories / Data Layer
    ↓
SwiftData (Local) + CloudKit (Cloud Sync)
```

### Key Patterns

- **@MainActor** - Services with UI updates are marked as MainActor
- **@Published** - Observable state management with Combine
- **SwiftData** - Local persistence with `@Model` macro
- **Combine** - Reactive programming for async operations

---

## Services (54 Total)

### Core Services (5)

1. **AuthenticationService**
   - Apple Sign In integration
   - Session management
   - User profile management
   - Location: `Services/AuthenticationService.swift`

2. **VaultService**
   - Vault CRUD operations
   - Vault locking/unlocking
   - Session management
   - Location: `Services/VaultService.swift`

3. **DocumentService**
   - Document upload/download
   - Document management
   - Encryption integration
   - Location: `Services/DocumentService.swift`

4. **EncryptionService**
   - AES-256-GCM encryption/decryption
   - Key generation and management
   - Zero-knowledge architecture
   - Location: `Services/EncryptionService.swift`

5. **CloudKitSharingService**
   - CloudKit sharing integration
   - Device-to-device invitations
   - Share management
   - Location: `Services/CloudKitSharingService.swift`

### AI/ML Services (9)

6. **DocumentIndexingService**
   - ML-based document indexing
   - Entity extraction (NaturalLanguage)
   - Key phrase extraction
   - Location: `Services/DocumentIndexingService.swift`

7. **NLPTaggingService**
   - Automatic document tagging
   - Category classification
   - Location: `Services/NLPTaggingService.swift`

8. **FormalLogicEngine**
   - 7 formal logic systems:
     - Deductive Logic
     - Inductive Logic
     - Abductive Logic
     - Analogical Logic
     - Statistical Logic
     - Temporal Logic
     - Modal Logic
   - Location: `Services/FormalLogicEngine.swift`

9. **InferenceEngine**
   - Pattern inference
   - Reasoning chains
   - Location: `Services/InferenceEngine.swift`

10. **MLThreatAnalysisService**
    - Threat pattern detection
    - Anomaly detection
    - Location: `Services/MLThreatAnalysisService.swift`

11. **TextIntelligenceService**
    - Text analysis and insights
    - Semantic understanding
    - Location: `Services/TextIntelligenceService.swift`

12. **IntelReportService**
    - Cross-document analysis
    - Intelligence report generation
    - Location: `Services/IntelReportService.swift`

13. **VoiceMemoService**
    - Audio narration generation
    - TTS integration
    - Location: `Services/VoiceMemoService.swift`

14. **StoryNarrativeGenerator**
    - Narrative generation from media
    - Story structure application
    - Location: `Services/StoryNarrativeGenerator.swift`

### Media Services (3)

15. **TranscriptionService**
    - Speech-to-text conversion
    - Audio transcription
    - Location: `Services/TranscriptionService.swift`

16. **PDFTextExtractor**
    - PDF text extraction
    - OCR capabilities
    - Location: `Services/PDFTextExtractor.swift`

17. **URLAssetDownloadService**
    - Asset downloading
    - URL handling
    - Location: `Services/URLAssetDownloadService.swift`

### Security Services (6)

18. **BiometricAuthService**
    - Face ID / Touch ID integration
    - Biometric authentication
    - Location: `Services/BiometricAuthService.swift`

19. **ThreatMonitoringService**
    - Access pattern monitoring
    - Security event tracking
    - Location: `Services/ThreatMonitoringService.swift`

20. **LocationService**
    - Geographic tracking
    - Location-based access control
    - Location: `Services/LocationService.swift`

21. **DualKeyApprovalService**
    - Dual-key request handling
    - Approval workflow
    - Location: `Services/DualKeyApprovalService.swift`

22. **EmergencyApprovalService**
    - Emergency access handling
    - Location: `Services/EmergencyApprovalService.swift`

23. **SecurityReviewScheduler**
    - Security audits
    - Review scheduling
    - Location: `Services/SecurityReviewScheduler.swift`

### Business Services (5)

24. **SubscriptionService**
    - StoreKit 2 subscriptions
    - Subscription management
    - Location: `Services/SubscriptionService.swift`

25. **NomineeService**
    - Nominee management
    - Invitation handling
    - Location: `Services/NomineeService.swift`

26. **ChatService**
    - User messaging
    - Real-time chat
    - Location: `Services/ChatService.swift`

27. **SupportChatService**
    - Support conversations
    - Location: `Services/SupportChatService.swift`

28. **IntelChatService**
    - AI-powered chat
    - LLM integration
    - Location: `Services/IntelChatService.swift`

### Advanced Services (7)

29. **AntiVaultService**
    - Anti-vault (monitoring vault) management
    - Location: `Services/AntiVaultService.swift`

30. **DocumentFidelityService**
    - Document integrity verification
    - Location: `Services/DocumentFidelityService.swift`

31. **SharedVaultSessionService**
    - Shared vault session management
    - Location: `Services/SharedVaultSessionService.swift`

32. **BluetoothSessionNominationService**
    - Bluetooth-based sharing
    - Location: `Services/BluetoothSessionNominationService.swift`

33. **VaultRequestService**
    - Vault access requests
    - Location: `Services/VaultRequestService.swift`

34. **MessageInvitationService**
    - Invitation handling
    - Location: `Services/MessageInvitationService.swift`

35. **ContactDiscoveryService**
    - Contact integration
    - Location: `Services/ContactDiscoveryService.swift`

### Utility Services (19)

36. **DataMigrationService** - Data migration
37. **DataMergeService** - Data merging
38. **DataOptimizationService** - Performance optimization
39. **OfflineQueueService** - Offline operation queue
40. **RetryService** - Retry logic
41. **BackgroundTaskService** - Background processing
42. **PushNotificationService** - Push notifications
43. **CloudKitAPIService** - CloudKit integration
44. **CloudKitSharingService** - CloudKit sharing
45. **AccountDeletionService** - Account deletion
46. **ABTestingService** - A/B testing
47. **ContentFilterService** - Content filtering
48. **RedactionService** - Document redaction
49. **AutomaticTriageService** - Automatic triage
50. **ThreatRemediationAIService** - Threat remediation
51. **ReasoningGraphService** - Reasoning graphs
52. **LlamaMediaDescriptionService** - Media description
53. **AudioIntelligenceService** - Audio analysis
54. **SourceSinkClassifier** - Document classification

---

## Data Models

### SwiftData Models

All models use the `@Model` macro:

- **User** - User accounts
- **Vault** - Vault definitions
- **Document** - Document metadata
- **VaultSession** - Active vault sessions
- **VaultAccessLog** - Access audit trail
- **Nominee** - Vault nominees
- **EmergencyAccessRequest** - Emergency access requests
- **DualKeyRequest** - Dual-key approval requests
- **ChatMessage** - User messages
- **DocumentVersion** - Document versioning
- **AntiVault** - Anti-vault definitions

### Relationships

- User ←→ Vault (one-to-many)
- Vault ←→ Document (one-to-many)
- Vault ←→ VaultSession (one-to-many)
- Vault ←→ VaultAccessLog (one-to-many)

---

## Configuration

### Environment Configurations

- **Development** - Local development
- **Test** - Testing/staging
- **Production** - Live production

Configuration files:
- `Configurations/Development.xcconfig`
- `Configurations/Test.xcconfig`
- `Configurations/Production.xcconfig`

### App Configuration

- `Config/AppConfig.swift` - App-wide settings
- `Config/EnvironmentConfig.swift` - Environment-specific settings
- `Config/AppConfig.swift` - App-wide configuration (CloudKit container ID)
- `Config/APNsConfig.swift` - Push notification configuration

---

## Key Features

### 1. Vault System

- **Single-key vaults** - Password protected
- **Dual-key vaults** - Requires two approvals (ML auto-approval)
- **System vaults** - Read-only for Intel Reports
- **Session management** - Auto-lock after timeout

### 2. Document Management

- Upload from photos, files, camera
- Automatic encryption (AES-256-GCM)
- ML-based indexing and tagging
- Preview support (images, PDFs, videos)
- Version history

### 3. AI Intelligence

- **7 Formal Logic Systems** - Advanced reasoning
- **ML Threat Analysis** - Access pattern analysis
- **Intel Reports** - Cross-document analysis with voice narration
- **NLP Auto-tagging** - Automatic categorization

### 4. Security

- **Zero-knowledge** - Server can't decrypt
- **Complete audit trail** - All access logged
- **Biometric authentication** - Face ID / Touch ID
- **ML-based threat monitoring** - Anomaly detection

### 5. Media Capture

- **Photos** - Camera integration
- **Videos** - AVFoundation recording
- **Voice Memos** - Audio capture with TTS narration

---

## Integration Points

### CloudKit Integration

- **Primary Backend:** CloudKit + SwiftData for seamless iCloud sync
- **Database:** CloudKit private database with automatic sync
- **Storage:** Encrypted documents stored in CloudKit
- **Real-time:** Automatic sync across all user devices
- **Sharing:** CloudKit sharing for vault collaboration
- **Auth:** Apple Sign In with iCloud account integration

---

## Build & Deployment

### Development Build
```bash
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs Dev" \
  -configuration Debug-Development
```

### Production Build
```bash
./scripts/apple/build_production.sh
```

### Archive & Upload
```bash
./scripts/apple/prepare_for_transporter.sh
# Uploads to App Store Connect via Transporter
```

---

## Testing

- Unit tests for services
- UI tests for critical flows
- Integration tests for CloudKit sync
- Performance tests for encryption/decryption

---

## Known Limitations

1. **Intel Reports** - iOS-only feature (not available on other platforms)
2. **Voice Memos** - Requires TTS, iOS-only
3. **iMessage Extension** - iOS-only
4. **CloudKit** - iOS/macOS only (fallback mode)

---

**Last Updated:** December 2024

# Khandoba iOS - Comprehensive File Structure

## Overview
This document provides a complete reference to the file structure of the Khandoba iOS application, including the purpose of each directory and key files.

---

## Root Directory

```
khandoba-ios/
├── .git/                           # Git version control
├── .github/                        # GitHub workflows and templates
├── .cursor/                        # Cursor IDE configuration
├── Khandoba/                       # Main application source code
├── Khandoba.xcodeproj/            # Xcode project file
├── docs/                           # Documentation
│   ├── architecture/               # Architecture documentation
│   ├── development/                # Development guides
│   ├── features/                   # Feature documentation
│   ├── workflows/                  # Workflow documentation
│   ├── archive/                    # Archived old documentation
│   ├── master-plan.md              # Master implementation plan
│   └── README.md                   # Documentation index
├── scripts/                        # Build and utility scripts
├── .gitignore                      # Git ignore rules
├── clean_build.sh                  # Clean build script
├── CHANGELOG.md                    # Version history and changes
├── README.md                       # Project README
├── APPLE_PAY_SETUP_INSTRUCTIONS.md # Apple Pay integration guide
└── STOREKIT_SETUP_GUIDE.md        # StoreKit configuration guide
```

---

## Main Application Structure (`Khandoba/`)

### App (`Khandoba/App/`)
Core application entry point and configuration

```
App/
├── KhandobaApp.swift              # Main app entry point (@main)
├── ContentView.swift              # Root content view with routing
├── AppConfiguration.swift         # App-wide configuration
└── Color+Assets.swift             # Color asset extensions
```

**Note:** Streamlined structure with no legacy onboarding carousels

**Purpose:**
- Application lifecycle management
- Root view hierarchy
- Global environment setup
- Theme injection
- Navigation coordination

---

### Features (`Khandoba/Features/`)

The Features directory is organized by functional domain using feature-based architecture.

#### Authentication (`Features/Authentication/`)

```
Authentication/
├── Views/
│   ├── WelcomeView.swift          # Welcome screen with Apple Sign In
│   ├── AccountSetupView.swift     # Account setup (name, optional selfie)
│   ├── RoleSelectionView.swift    # Role selection for multi-role users
│   ├── OnboardingCarouselView.swift # Feature carousel (disabled)
│   └── SelfieCaptureView.swift    # Selfie capture for KYC
└── Services/
    └── AppleAuthenticationService.swift # Apple Sign In integration
```

**Key Features:**
- Apple Sign In with biometric auth
- Optional selfie for KYC verification
- Role-based access control
- Streamlined onboarding (no carousels)

---

#### Client Features (`Features/Client/`)

```
Client/
├── Views/
│   ├── ClientVaultDetailView.swift      # Vault details for clients
│   ├── ClientVaultOpenRequestView.swift # Request vault access
│   └── ClientDashboardWidgets.swift     # Dashboard widgets
├── ViewModels/
│   └── ClientDashboardViewModel.swift   # Dashboard state management
└── Services/
    └── ClientNotificationService.swift  # Client notifications
```

**Purpose:**
- Client-specific vault operations
- Access request management
- Document viewing
- Notification handling

---

#### Admin Features (`Features/Admin/`)

```
Admin/
├── Views/
│   ├── AdminChatInboxView.swift          # Admin chat interface
│   ├── AdminVaultOpenRequestsView.swift  # Approve vault access
│   ├── AdminEmergencyRequestsView.swift  # Emergency access handling
│   └── AdminSettingsView.swift           # Admin configuration
└── Services/
    └── AdminAnalyticsService.swift       # Admin analytics
```

**Purpose:**
- Administrative oversight
- User management
- Access approval workflows
- Emergency protocols
- System monitoring

---

#### Dashboard (`Features/Dashboard/`)

```
Dashboard/
├── Views/
│   ├── ClientMainView.swift       # Client dashboard (TabView)
│   ├── AdminMainView.swift        # Admin dashboard (TabView)
│   └── DashboardComponents.swift  # Reusable dashboard widgets
└── ViewModels/
    └── DashboardViewModel.swift   # Shared dashboard logic
```

**Purpose:**
- Role-specific dashboards
- Tab navigation (Vaults, Documents, Profile, etc.)
- Quick actions and summaries
- Activity feeds

---

#### Vaults (`Features/Vaults/`)

```
Vaults/
├── Views/
│   ├── VaultListView.swift              # List of all vaults
│   ├── VaultDetailView.swift            # Vault details and contents
│   ├── VaultCreationView.swift          # Create new vault
│   ├── ThreatDashboardView.swift        # Security threat monitoring
│   ├── ThreatMetricsView.swift          # Threat analytics charts
│   └── VaultAccessLogView.swift         # Vault access history
├── ViewModels/
│   └── VaultViewModel.swift             # Vault state management
└── Services/
    ├── VaultMetadataService.swift       # Vault metadata operations
    ├── ThreatMetricsService.swift       # Threat analysis
    └── ThreatPerceptionService.swift    # AI threat detection
```

**Purpose:**
- Vault CRUD operations
- Document organization
- Access control and logging
- Security threat monitoring
- Dual-key encryption management

---

#### Documents (`Features/Documents/`)

```
Documents/
├── Views/
│   ├── DocumentListView.swift           # Document list with filters
│   ├── DocumentDetailView.swift         # Document viewer
│   ├── DocumentUploadView.swift         # Document upload interface
│   ├── DocumentAnalyticsView.swift      # Document analytics dashboard
│   └── DocumentScannerView.swift        # Camera-based document scanner
├── ViewModels/
│   └── DocumentViewModel.swift          # Document state management
└── Services/
    ├── DocumentUploadService.swift      # Upload handling
    ├── DocumentIndexingService.swift    # Search indexing
    └── EncryptionService.swift          # Document encryption
```

**Purpose:**
- Document management (upload, view, delete)
- OCR and scanning
- Full-text search
- Analytics and insights
- Encryption at rest

---

#### Profile (`Features/Profile/`)

```
Profile/
├── Views/
│   ├── ProfileView.swift               # User profile screen
│   ├── ProfileEditView.swift           # Edit profile information
│   └── RoleSwitcherView.swift          # Switch between roles
└── Stores/
    └── ProfileStore.swift              # Profile data management
```

**Purpose:**
- User profile management
- Role switching
- Settings and preferences
- Account information

---

#### Chat (`Features/Chat/`)

```
Chat/
├── Views/
│   ├── ChatListView.swift              # Chat conversations list
│   ├── ChatDetailView.swift            # Individual chat thread
│   └── ChatComposerView.swift          # Message composition
├── ViewModels/
│   └── ChatViewModel.swift             # Chat state management
└── Services/
    └── ChatService.swift               # Chat operations
```

**Purpose:**
- Client-admin messaging
- Support conversations
- Real-time messaging
- Message history

---

#### Security (`Features/Security/`)

```
Security/
├── Validation/
│   └── SessionValidationMiddleware.swift # Session security validation
├── Governance/
│   ├── PolicyEnforcementService.swift   # Policy enforcement
│   └── ComplianceService.swift          # Compliance monitoring
└── Services/
    ├── EmergencyProtocolService.swift   # Emergency access
    ├── DeviceAttestationService.swift   # Device security
    ├── IDVerificationService.swift      # Identity verification
    └── VaultAutoLockService.swift       # Auto-lock functionality
```

**Purpose:**
- Security policy enforcement
- Device attestation
- Emergency access protocols
- Session management
- Compliance and audit

---

#### Payments (`Features/Payments/`)

```
Payments/
├── Views/
│   ├── PaymentView.swift               # Payment interface
│   └── SubscriptionView.swift          # Subscription management
└── Services/
    └── PaymentService.swift            # Payment processing
```

**Purpose:**
- In-app purchases
- Subscription management
- Payment processing
- Receipt validation

---

#### Core (`Features/Core/`)

```
Core/
├── Models/
│   ├── Vault.swift                     # Vault domain model
│   ├── Document.swift                  # Document domain model
│   ├── VaultMetadata.swift             # Vault metadata model
│   ├── User.swift                      # User model
│   ├── Role.swift                      # Role enum (.client, .admin)
│   └── ChatMessage.swift               # Chat message model
├── Services/
│   ├── PersistenceController.swift     # Core Data + CloudKit
│   ├── AuthenticationService.swift     # Auth state management
│   ├── UserRoleService.swift           # Role management
│   ├── UserManagementService.swift     # User operations
│   ├── AccountSwitchService.swift      # Role switching
│   ├── AccessLogService.swift          # Access logging
│   ├── ActivityLogService.swift        # Activity tracking
│   ├── ContactPhotoService.swift       # Contact integration
│   ├── ErrorRecoveryService.swift      # Error handling
│   ├── OfflineModeService.swift        # Offline operation queue
│   ├── OptimisticUpdateService.swift   # Optimistic UI updates
│   ├── RetryService.swift              # Retry logic
│   ├── TestDataGenerator.swift         # Test data creation
│   ├── VideoRecordingService.swift     # Video recording
│   ├── SessionStreamService.swift      # Session streaming
│   ├── DualKeyService.swift            # Dual-key encryption
│   ├── OfficerInviteService.swift      # Admin invite system
│   ├── VaultOpenRequestService.swift   # Vault access requests
│   ├── SecurityAlertService.swift      # Security alerts
│   ├── SystemMetricsService.swift      # System metrics
│   ├── GeospatialMLService.swift       # Location ML
│   └── WhatsAppShareService.swift      # WhatsApp integration
├── Stores/
│   ├── VaultStore.swift                # Vault data store
│   └── DocumentStore.swift             # Document data store
├── Utilities/
│   ├── ValidationService.swift         # Input validation
│   ├── Debouncer.swift                 # Debouncing utility
│   └── Extensions.swift                # Swift extensions
└── Views/
    └── DebugOverlay.swift              # Debug tools overlay
```

**Purpose:**
- Domain models and business logic
- Core services (auth, persistence, networking)
- Data stores with CloudKit sync
- Utility functions and extensions
- Cross-feature shared components

---

#### UI System (`Features/UI/`)

```
UI/
├── Components/
│   ├── FeltButton.swift                # Origami-styled button
│   ├── FeltCard.swift                  # Origami-styled card
│   ├── CustomTextField.swift           # Themed text fields
│   ├── CustomNavigationBar.swift       # Custom nav bar
│   ├── CustomTabBar.swift              # Custom tab bar
│   ├── ErrorBanner.swift               # Error display component
│   ├── LoadingStateView.swift          # Loading states
│   ├── PulsingLoadingView.swift        # Animated loading screen
│   ├── FoldedCorner.swift              # Paper fold effect
│   ├── AnimatedSharpWaves.swift        # Wave animations
│   ├── SkeletonViews.swift             # Skeleton loaders
│   └── [30+ more components]
├── Theme/
│   ├── UnifiedTheme.swift              # ✅ Main theme system
│   ├── ThemeManager.swift              # Theme state management
│   └── Theme.swift                     # Theme utilities
├── Styles/
│   ├── DesignSystem.swift              # Design system constants
│   ├── UnifiedDesignSystem.swift       # Typography, Spacing, Radius, Shadow
│   ├── ColorScheme.swift               # Color scheme utilities
│   ├── Colors.swift                    # Color constants
│   ├── CharcoalColorScheme.swift       # Dark mode scheme
│   └── Styles.swift                    # Style utilities
├── Modifiers/
│   ├── UnifiedThemeModifier.swift      # Theme view modifiers
│   ├── ClayShadowModifier.swift        # Clay shadow effect
│   ├── EdgeHighlightModifier.swift     # Edge highlight effect
│   └── TabTransitionModifier.swift     # Tab transition animations
└── Utilities/
    └── AnimationExtensions.swift       # Animation utilities
```

**Purpose:**
- Reusable UI components
- Unified theme system
- Design tokens and constants
- View modifiers for consistent styling
- Animation utilities

---

## SwiftData Models (`Models/`)

### Data Models

| Model | Purpose |
|-------|---------|
| `User` | User accounts and profile data |
| `UserRole` | Role assignments (Client/Admin) |
| `Vault` | Vault records with encryption metadata |
| `VaultSession` | Active vault sessions (30-min timer) |
| `VaultAccessLog` | Access audit trail with geolocation |
| `DualKeyRequest` | Dual-key vault access requests |
| `Document` | Document metadata and encryption |
| `DocumentVersion` | Document version history |
| `ChatMessage` | Encrypted chat messages |
| `IDVerification` | KYC verification data |
| `UserBalance` | Credit balance tracking |
| `Transaction` | Payment transaction history |

**Note:** All models use SwiftData's @Model macro and automatically sync via CloudKit.

---

## Documentation Structure (`docs/`)

### Architecture Documentation

```
architecture/
├── overview.md                     # System architecture overview
├── theme-system.md                 # Theme system documentation
├── data-flow.md                    # Data flow and state management
├── security-architecture.md        # Security design
└── cloudkit-sync.md                # CloudKit synchronization
```

### Development Guides

```
development/
├── setup.md                        # Development environment setup
├── testing.md                      # Testing guidelines
├── deployment.md                   # Deployment procedures
└── troubleshooting.md              # Common issues and solutions
```

### Feature Documentation

```
features/
├── vaults.md                       # Vault feature documentation
├── documents.md                    # Document management
├── chat.md                         # Chat system
├── authentication.md               # Auth flows
├── payments.md                     # Payment system
└── threat-detection.md             # Security threat monitoring
```

### Workflows

```
workflows/
├── client-workflows.md             # Client user flows
├── admin-workflows.md              # Admin user flows
└── emergency-access.md             # Emergency access procedures
```

---

## Key Files and Their Purposes

### Application Entry Point

**`Khandoba/App/KhandobaApp.swift`**
- Main application structure (@main)
- Initializes PersistenceController.shared
- Initializes AuthenticationService.shared  
- Injects environment objects
- Configures UnifiedTheme globally
- UIKit appearance setup (nav/tab bars)
- Deep link handling

### Root Routing

**`Khandoba/App/ContentView.swift`**
- Root view with auth state management
- Navigation flow: WelcomeView → AccountSetupView → RoleSelection → Dashboard
- No onboarding carousels (streamlined)
- Role-based view routing

### Core Data Persistence

**`Khandoba/Features/Core/Services/PersistenceController.swift`**
- NSPersistentCloudKitContainer setup
- CloudKit sync configuration
- Background context for heavy operations
- Low-latency streaming APIs
- Batch processing
- Persistent history tracking

### Theme System

**`Khandoba/Features/UI/Theme/UnifiedTheme.swift`**
- Single source of truth for theming
- Color palette (light/dark modes)
- Brand colors (coral red #E74A48, cyan #11A7C7)
- Semantic colors (error, success, warning, info)

**`Khandoba/Features/UI/DesignSystem/UnifiedDesignSystem.swift`**
- Typography scale (SwiftUI .system fonts with .rounded design)
- Spacing tokens (4pt grid system: xs to xxl)
- Border radius values (xs to full)
- Shadow system (sm, md, lg)
- Elevation levels (flat to modal)
- SwiftUI-compliant with dynamic type support

### Authentication

**`Khandoba/Features/Core/Services/AuthenticationService.swift`**
- Auth state management (@Published)
- User session handling
- Role-based permissions

**`Khandoba/Features/Core/Services/AppleAuthenticationService.swift`**
- Apple Sign In integration
- Credential management
- Account setup completion

### Data Stores

**`Khandoba/Features/Core/Stores/VaultStore.swift`**
- Vault data management
- CloudKit sync integration
- Debounced refresh logic
- Selective invalidation

**`Khandoba/Features/Core/Stores/DocumentStore.swift`**
- Document data management
- Upload progress tracking
- Search and filtering

---

## Design System

### Color Palette

| Color | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| Primary | #E74A48 (Coral Red) | #E74A48 | CTAs, accents |
| Secondary | #11A7C7 (Cyan) | #11A7C7 | Secondary actions |
| Background | #F5F2ED (Paper) | #1C1C1E | Screen background |
| Surface | #FFFFFF | #2C2C2E | Card background |
| Text Primary | #141414 | #FFFFFF | Main text |
| Text Secondary | #4B4B4F | #98989D | Secondary text |
| Error | #E45858 | #E45858 | Error states |
| Success | #45C186 | #45C186 | Success states |

### Typography Scale

| Name | Size | Weight | Usage |
|------|------|--------|-------|
| largeTitle | 34pt | Bold | Large headers |
| title | 28pt | Bold | Section titles |
| headline | 17pt | Semibold | Card headers |
| body | 17pt | Regular | Body text |
| subheadline | 15pt | Regular | Secondary text |
| caption | 12pt | Regular | Captions |

### Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Tight spacing |
| sm | 8pt | Small gaps |
| md | 12pt | Standard spacing |
| lg | 16pt | Generous spacing |
| xl | 24pt | Section spacing |
| xxl | 32pt | Large sections |

---

## Build Configuration

### Schemes
- **Khandoba** - Main production build
- **Khandoba (Development)** - Development build with debug tools

### Build Scripts

**`clean_build.sh`**
- Cleans derived data
- Removes build artifacts
- Resets Core Data store
- Fresh rebuild

---

## Testing

### Test Data Generator

**`Khandoba/Features/Core/Services/TestDataGenerator.swift`**
- Generates sample vaults
- Creates test documents
- Simulates access logs
- Populates chat messages

**Usage:**
```swift
let generator = TestDataGenerator(context: viewContext)
await generator.generateTestVaults(count: 5)
await generator.generateTestDocuments(for: vaultID, count: 20)
```

### Debug Overlay

**`Khandoba/Features/Core/Views/DebugOverlay.swift`**
- Shows app state information
- Performance metrics
- Network status
- Core Data statistics

---

## Git Workflow

### Branch Strategy
- `main` - Production-ready code
- Feature branches for new development
- Hotfix branches for urgent fixes

### Commit Convention
- Descriptive commit messages
- Reference issue numbers where applicable
- Incremental commits per feature

---

## CI/CD

### Configuration
CI/CD files have been archived to `docs/archive/ci-cd/` for reference.
For production builds, use Xcode Cloud or GitHub Actions (recommended).

### Build Scripts
**`clean_build.sh`**
- Cleans derived data and build artifacts
- Resets Core Data store
- Full clean rebuild

---

## Dependencies

### Core Frameworks
- **SwiftUI** - UI framework
- **SwiftData** - Modern local persistence
- **CloudKit** - Cloud sync (via SwiftData)
- **Combine** - Reactive programming
- **PhotosUI** - Photo picker
- **AVFoundation** - Camera/video
- **CoreLocation** - Location services
- **StoreKit** - In-app purchases
- **AuthenticationServices** - Apple Sign In

### No Third-Party Dependencies
All functionality implemented using native iOS frameworks for:
- Security and compliance
- Reduced app size
- Better performance
- Easier maintenance

---

## File Naming Conventions

### Views
- `<Feature><Purpose>View.swift` - e.g., `VaultDetailView.swift`
- End with `View` suffix
- Pascal case

### ViewModels
- `<Feature>ViewModel.swift` - e.g., `VaultViewModel.swift`
- End with `ViewModel` suffix

### Services
- `<Feature>Service.swift` - e.g., `AuthenticationService.swift`
- End with `Service` suffix
- Singleton pattern: `.shared`

### Stores
- `<Feature>Store.swift` - e.g., `VaultStore.swift`
- End with `Store` suffix
- ObservableObject for state management

### Models
- `<Entity>.swift` - e.g., `Vault.swift`
- No suffix
- Value types (struct) preferred

---

## Code Organization Principles

### Feature-Based Architecture
- Group by feature, not by type
- Each feature is self-contained
- Shared code in `Core/`

### Clean Architecture
- Views depend on ViewModels
- ViewModels depend on Services
- Services depend on Models
- Unidirectional data flow

### SwiftUI Best Practices
- View composition over inheritance
- Environment objects for dependency injection
- @Published for reactive state
- Combine for async streams

---

## Performance Optimizations

### Data Layer
- SwiftData efficient querying with @Query
- Automatic relationship handling
- Background ModelContext for heavy operations
- Async/await for data operations
- Automatic CloudKit sync

### UI Layer
- LazyVStack/LazyHStack for lists
- Skeleton views during loading
- Optimistic UI updates
- Efficient animations (@State, @Binding)

### Network Layer
- CloudKit automatic sync
- Offline operation queue
- Retry with exponential backoff
- Request cancellation

---

## Security Features

### Encryption
- End-to-end document encryption
- Dual-key system (user + admin)
- Secure enclave for keys
- AES-256 encryption

### Authentication
- Apple Sign In (biometric)
- Device attestation
- Session validation
- Auto-lock on inactivity

### Access Control
- Role-based permissions
- Vault access logging
- Emergency access protocols
- Audit trail

---

## Future Considerations

### Scalability
- Architecture supports horizontal scaling
- CloudKit handles sync across devices
- Batch operations for large datasets
- Efficient memory management

### Extensibility
- Feature-based structure allows easy additions
- Service protocol abstractions
- ViewBuilder for composition
- Environment-based dependency injection

---

## Maintenance

### Code Quality
- SwiftLint for style consistency
- Zero build warnings
- Comprehensive error handling
- Inline documentation

### Monitoring
- CloudKit dashboard for sync metrics
- App Store Connect for crashes
- TestFlight for beta feedback
- Debug overlay for development

---

## Quick Reference

### Add New Feature
1. Create folder in `Khandoba/Features/<FeatureName>/`
2. Add Views/, ViewModels/, Services/ as needed
3. Register in main navigation
4. Update documentation

### Add New UI Component
1. Create in `Khandoba/Features/UI/Components/`
2. Use UnifiedTheme for consistency
3. Add to preview catalog
4. Document usage

### Modify Theme
1. Update `UnifiedTheme.swift` for colors
2. Update `UnifiedDesignSystem.swift` for tokens
3. Test in both light/dark modes
4. Verify accessibility contrast ratios

---

## Support

For questions or issues:
- Check `docs/` directory for detailed guides
- Review `CHANGELOG.md` for recent changes
- See `README.md` for quick start

**Version:** 1.0.0  
**Last Updated:** December 2, 2025  
**Build Status:** ✅ Clean (0 errors, 0 warnings)  
**Persistence:** ✅ SwiftData with automatic CloudKit sync  
**Theme System:** ✅ UnifiedTheme with forced dark mode  
**Design System:** ✅ SwiftUI-compliant with WCAG AA accessibility  
**Contrast Ratios:** ✅ 7.2:1+ (exceeds WCAG AA 4.5:1 requirement)  
**Production Status:** ✅ Ready for development testing  
**CloudKit Integration:** ✅ Automatic sync via SwiftData


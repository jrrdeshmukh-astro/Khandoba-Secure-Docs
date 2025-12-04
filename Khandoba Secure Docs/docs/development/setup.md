# Setup Guide

> **Last Updated:** December 2024
> 
> Complete setup instructions for the Khandoba iOS application.

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Apple Developer Account (for App Store submission)

## Project Structure

```
Khandoba/
├── App/                    # App entry point and main views
├── Core/                   # Core models, services, utilities
│   ├── Models/            # Data models
│   ├── Services/          # Business logic services
│   └── Utilities/        # Helper functions and extensions
├── Features/               # Feature modules
│   ├── Admin/             # Admin-specific views
│   ├── Authentication/     # Auth and onboarding
│   ├── Client/            # Client-specific views
│   ├── Dashboard/         # Role-based dashboards
│   ├── Documents/         # Document management
│   ├── Payments/          # Payment management
│   ├── Profile/           # User profile and settings
│   └── Vaults/            # Vault management
├── UI/                     # UI components and styling
│   ├── Components/        # Reusable UI components
│   ├── Styles/            # Color schemes and themes
│   └── Utilities/         # UI utilities
└── Assets.xcassets/        # Images, colors, icons
```

## Setup Steps

### 1. Clone the Repository

```bash
git clone <repository-url>
cd khandoba-ios
```

### 2. Open in Xcode

```bash
open Khandoba.xcodeproj
```

### 3. Configure Signing & Capabilities

1. Select the project in Xcode
2. Go to "Signing & Capabilities"
3. Select your development team
4. Ensure the following capabilities are enabled:
   - Sign in with Apple
   - CloudKit
   - Push Notifications (if needed)
   - Background Modes (if needed)

### 4. Configure CloudKit

1. In Xcode, go to Signing & Capabilities
2. Add CloudKit capability
3. Ensure the CloudKit container is configured
4. The Core Data model should sync automatically

### 5. Build and Run

```bash
# Using Xcode
⌘ + R

# Or using command line
xcodebuild -project Khandoba.xcodeproj -scheme Khandoba -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Development Mode

The app automatically detects development vs production mode:

- **Development**: `#if DEBUG` - Shows dev indicators, enables debug features
- **Production**: `#else` - Production API URLs, no debug features

See `AppConfiguration.swift` for environment-specific settings.

## Troubleshooting

### Build Errors

1. Clean build folder: `⌘ + Shift + K`
2. Delete DerivedData
3. Rebuild: `⌘ + B`

### CoreData Warnings

Unused import warnings in auto-generated CoreData files are suppressed via compiler flags in `project.pbxproj`.

### CloudKit Sync Issues

1. Check CloudKit container configuration
2. Verify signing certificates
3. Check network connectivity


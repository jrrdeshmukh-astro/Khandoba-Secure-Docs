# 📁 Cross-Platform Project Structure

> **Purpose:** Organized structure for Apple, Android, and Windows implementations of Khandoba Secure Docs

---

## 🎯 Structure Overview

```
Khandoba Secure Docs/
│
├── platforms/                          # Platform-specific source code
│   ├── apple/                         # Apple platforms (iOS/macOS/watchOS/tvOS)
│   │   ├── Khandoba Secure Docs/     # Main app source
│   │   ├── Khandoba Secure Docs.xcodeproj/
│   │   ├── KhandobaSecureDocsMessageApp/  # iMessage extension
│   │   ├── Configurations/           # Environment configs (dev/test/prod)
│   │   ├── README.md
│   │   └── .gitignore
│   │
│   ├── android/                       # Android (Kotlin/Jetpack Compose)
│   │   ├── app/
│   │   ├── build.gradle.kts
│   │   ├── settings.gradle.kts
│   │   ├── gradle.properties
│   │   ├── README.md
│   │   └── .gitignore
│   │
│   └── windows/                       # Windows (C#/WinUI 3/.NET 8)
│       ├── KhandobaSecureDocs/
│       ├── README.md
│       └── .gitignore
│
├── docs/                              # All documentation
│   ├── 00_START_HERE.md              # Main documentation entry point
│   ├── README.md                      # Documentation index
│   │
│   ├── shared/                        # Cross-platform docs
│   │   ├── architecture/             # System architecture
│   │   ├── api/                      # Supabase API docs
│   │   ├── database/                 # Database schemas & migrations
│   │   ├── security/                 # Security architecture
│   │   ├── workflows/                # Feature workflows
│   │   └── environments/             # Dev/test/prod environment docs
│   │
│   ├── apple/                        # Apple-specific docs
│   │   ├── REBUILD_GUIDE.md         # Complete rebuild guide
│   │   ├── SETUP.md                  # Initial setup
│   │   ├── DEPLOYMENT.md             # App Store deployment
│   │   └── FEATURES.md               # Feature documentation
│   │
│   ├── android/                      # Android-specific docs
│   │   ├── SETUP.md                  # Initial setup
│   │   ├── DEPLOYMENT.md             # Play Store deployment
│   │   └── FEATURES.md               # Feature documentation
│   │
│   └── windows/                      # Windows-specific docs
│       ├── SETUP.md                  # Initial setup
│       ├── DEPLOYMENT.md             # Store deployment
│       └── FEATURES.md               # Feature documentation
│
├── scripts/                           # Build and utility scripts
│   ├── apple/                        # Apple build scripts
│   │   ├── build_production.sh
│   │   ├── prepare_for_transporter.sh
│   │   ├── validate_for_transporter.sh
│   │   └── upload_to_testflight.sh
│   │
│   ├── android/                      # Android build scripts
│   │   ├── build_release.sh
│   │   ├── build_debug.sh
│   │   └── upload_to_playstore.sh
│   │
│   ├── windows/                      # Windows build scripts
│   │   ├── build_release.ps1
│   │   └── create_installer.ps1
│   │
│   └── shared/                       # Cross-platform scripts
│       ├── validate_config.sh
│       └── sync_translations.sh
│
├── builds/                            # Build artifacts (gitignored)
│   ├── apple/
│   │   ├── archives/
│   │   ├── ipas/
│   │   └── derived-data/
│   │
│   ├── android/
│   │   ├── apks/
│   │   ├── aabs/                      # Android App Bundles
│   │   └── intermediates/
│   │
│   └── windows/
│       ├── releases/
│       ├── installers/
│       └── packages/
│
├── assets/                            # Shared assets
│   ├── apple/                        # Apple platform assets
│   │   ├── AppStoreAssets/           # App Store screenshots, etc.
│   │   └── icons/
│   │
│   ├── android/                      # Android platform assets
│   │   ├── PlayStoreAssets/          # Play Store assets
│   │   └── icons/
│   │
│   └── windows/                      # Windows platform assets
│       ├── StoreAssets/              # Microsoft Store assets
│       └── icons/
│
├── database/                          # Database schemas and migrations
│   ├── setup_rls_policies.sql        # RLS policies
│   ├── schema.sql                    # Database schema
│   └── SUPABASE_RLS_POLICIES.md      # RLS documentation
│
├── config/                            # Configuration files
│   └── apple/                        # Apple-specific configs
│       └── ExportOptions.plist
│
├── .cursorrules                       # Cursor IDE rules
├── .gitignore                         # Git ignore rules
├── README.md                          # Main project README
├── CROSS_PLATFORM_STRUCTURE.md        # This file
└── ENVIRONMENT_STRUCTURE.md           # Dev/test/prod structure
```

---

## 📋 Directory Purposes

### `platforms/`
**Purpose:** Contains platform-specific source code  
**Structure:** Each platform has its own subdirectory with complete source tree  
**Note:** These are standalone projects that can be built independently

**Platforms:**
- `apple/` - iOS, macOS, watchOS, tvOS (Swift/SwiftUI)
- `android/` - Android (Kotlin/Jetpack Compose)
- `windows/` - Windows (C#/WinUI 3/.NET 8)

### `docs/`
**Purpose:** All documentation organized by platform and topic  
**Structure:**
- `shared/` - Architecture, API contracts, database schemas that apply to all platforms
- `apple/`, `android/`, `windows/` - Platform-specific guides, setup, deployment

### `scripts/`
**Purpose:** Build automation and utility scripts  
**Structure:** Organized by platform, with shared utilities in `shared/`

### `builds/`
**Purpose:** Build output artifacts (gitignored)  
**Structure:** Organized by platform, contains archives, installers, IPAs, APKs, etc.

### `assets/`
**Purpose:** Images, icons, branding materials  
**Structure:** Platform-specific assets in respective folders

### `database/`
**Purpose:** Database schemas, migrations, RLS policies  
**Structure:** Shared across all platforms (Supabase backend)

### `config/`
**Purpose:** Configuration files and examples  
**Structure:** Platform-specific configs

---

## 📝 Platform-Specific Notes

### Apple (iOS/macOS/watchOS/tvOS)
- Uses Xcode project structure
- Swift/SwiftUI codebase
- App Store deployment
- iMessage extension included
- Supports multiple Apple platforms from single codebase

### Android
- Uses Gradle build system
- Kotlin/Jetpack Compose
- Google Play Store deployment
- Follows Android project conventions
- Build flavors: dev, test, prod

### Windows
- Uses .NET/C# (WinUI 3)
- Microsoft Store deployment
- Follows Windows app conventions
- Build configurations: Debug, Release

---

## 🚀 Quick Start

### For Apple Development:
```bash
cd platforms/apple
open "Khandoba Secure Docs.xcodeproj"
```

### For Android Development:
```bash
cd platforms/android
./gradlew build
```

### For Windows Development:
```bash
cd platforms/windows
dotnet build
```

---

## 📚 Documentation Index

- **[Main README](README.md)** - Project overview
- **[Documentation Start](docs/00_START_HERE.md)** - Documentation entry point
- **[Apple README](platforms/apple/README.md)** - Apple setup and development
- **[Android README](platforms/android/README.md)** - Android setup and development
- **[Windows README](platforms/windows/README.md)** - Windows setup and development
- **[Shared Documentation](docs/shared/README.md)** - Cross-platform docs
- **[Environment Structure](ENVIRONMENT_STRUCTURE.md)** - Dev/test/prod setup

---

## 🔐 Security Notes

- All platform folders have their own `.gitignore`
- Sensitive files (keystores, certificates) should be in `config/` with `.example` suffix
- Actual credentials should never be committed
- Each platform should document its security requirements
- Environment-specific configs are gitignored (see `.gitignore`)

---

## 🏗️ Environment Structure

All platforms support three environments:
- **Development (dev)** - Local development, debugging enabled
- **Test** - Testing/staging environment
- **Production (prod)** - Live production environment

See **[ENVIRONMENT_STRUCTURE.md](ENVIRONMENT_STRUCTURE.md)** for detailed configuration.

---

**Last Updated:** December 2024  
**Status:** Clean Structure - No Duplications

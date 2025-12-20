# Development Environment Setup

> Complete guide to set up clean development environments for all platforms

---

## Overview

This guide provides step-by-step instructions to set up development environments for Apple, Android, and Windows platforms, enabling efficient cross-platform development and feature parity work.

---

## Prerequisites

### Required Tools

**All Platforms:**
- Git
- Terminal/Command Line
- Text Editor or IDE (Xcode, Android Studio, Visual Studio)

**Apple:**
- macOS 13.0+
- Xcode 15.0+
- Apple Developer Account (free for development)
- CocoaPods (if needed)

**Android:**
- macOS, Windows, or Linux
- Android Studio (latest stable)
- Android SDK (API 26+)
- Java Development Kit (JDK 17+)

**Windows:**
- Windows 10+ (or macOS/Linux with .NET)
- Visual Studio 2022 or VS Code
- .NET 8 SDK
- Windows SDK (if targeting Windows-specific APIs)

---

## Quick Start

### 1. Clone Repository

```bash
git clone [repository-url]
cd "Khandoba Secure Docs"
```

### 2. Verify Structure

```bash
# Verify platform directories exist
ls -la platforms/
# Should show: apple/, android/, windows/

# Verify scripts exist
ls -la scripts/
# Should show platform-specific and master scripts

# Verify documentation
ls -la docs/
# Should show organized documentation structure
```

### 3. Platform-Specific Setup

Follow platform-specific setup guides:
- **[Apple Setup](apple/SETUP.md)**
- **[Android Setup](android/SETUP.md)**
- **[Windows Setup](windows/SETUP.md)**

---

## Development Workflow

### Standard Development Flow

```
1. Setup Development Environment (this guide)
    ↓
2. Choose Platform to Work On
    ↓
3. Setup Platform-Specific Environment
    ↓
4. Identify Feature/Workflow Gap
    ↓
5. Implement Feature
    ↓
6. Test Locally
    ↓
7. Test Cross-Platform Sync (if applicable)
    ↓
8. Commit and Push
```

### Feature Parity Workflow

```
1. Review Feature Parity Document
   → docs/FEATURE_PARITY.md
    ↓
2. Identify Missing Feature on Target Platform
    ↓
3. Reference Implementation on Source Platform
   → Check docs/apple/IMPLEMENTATION_NOTES.md or similar
    ↓
4. Create Implementation Plan
    ↓
5. Implement Feature
    ↓
6. Test Feature
    ↓
7. Update Feature Parity Document
    ↓
8. Document Implementation
```

---

## Environment Configuration

### Development Environments

All platforms support three environments:

1. **Development (dev)** - Local development
2. **Test** - Testing/staging
3. **Production (prod)** - Live production

### Environment Setup

See: **[Environment Setup Guide](shared/environments/SETUP_GUIDE.md)**

---

## Platform-Specific Setup

### Apple Platform

**Setup Steps:**

1. **Open Xcode Project:**
```bash
cd platforms/apple
open "Khandoba Secure Docs.xcodeproj"
```

2. **Configure Signing:**
   - Select project in navigator
   - Select target "Khandoba Secure Docs"
   - Go to "Signing & Capabilities"
   - Select development team

3. **Select Development Scheme:**
   - Product → Scheme → "Khandoba Secure Docs Dev"
   - Build Configuration: Debug-Development

4. **Configure Environment:**
   - Edit `Configurations/Development.xcconfig`
   - Set Supabase keys (if using separate dev project)

5. **Run:**
   - Press ⌘R or Product → Run

**See:** [Apple Setup Guide](apple/SETUP.md)

### Android Platform

**Setup Steps:**

1. **Open Android Studio:**
```bash
cd platforms/android
# Then open in Android Studio
```

2. **Sync Gradle:**
   - Android Studio will auto-sync
   - Or: File → Sync Project with Gradle Files

3. **Select Build Variant:**
   - Build → Select Build Variant
   - Choose: `devDebug` for development

4. **Configure Environment:**
   - Edit `app/src/dev/res/values/config.xml`
   - Set Supabase keys

5. **Run:**
   - Click Run button or Shift+F10

**See:** [Android Setup Guide](android/SETUP.md)

### Windows Platform

**Setup Steps:**

1. **Open Solution:**
```bash
cd platforms/windows
# Open in Visual Studio
```

2. **Restore Packages:**
```bash
dotnet restore
```

3. **Select Configuration:**
   - Build → Configuration Manager
   - Select: Debug (Development)

4. **Configure Environment:**
   - Edit `Config/AppConfig.cs`
   - Set Azure credentials (if using)
   - Set Supabase keys

5. **Build:**
```bash
dotnet build -c Debug
```

6. **Run:**
   - Press F5 or Debug → Start Debugging

**See:** [Windows Setup Guide](windows/SETUP.md)

---

## Feature Parity Development

### Identifying Gaps

1. **Review Feature Parity Document:**
   ```bash
   cat docs/FEATURE_PARITY.md
   ```

2. **Compare Implementations:**
   - Check source platform implementation
   - Review target platform current state
   - Identify missing components

### Implementation Strategy

**For Each Gap:**

1. **Analyze Source Implementation:**
   - Read source platform code
   - Understand architecture
   - Identify dependencies

2. **Plan Adaptation:**
   - Adapt to target platform patterns
   - Identify platform-specific alternatives
   - Plan integration points

3. **Implement:**
   - Create/update services
   - Create/update UI components
   - Test functionality

4. **Verify:**
   - Test feature works
   - Test cross-platform sync (if applicable)
   - Update documentation

---

## Workflow Improvements

### Common Workflow Issues

#### Issue 1: Cross-Platform Sync Not Working

**Diagnosis:**
```bash
# Check Supabase connection
# Test on each platform
# Check RLS policies
```

**Solution:**
- Verify Supabase keys in environment configs
- Check network connectivity
- Review RLS policies: `docs/shared/database/SUPABASE_RLS_POLICIES.md`

#### Issue 2: Feature Missing on Platform

**Diagnosis:**
- Check `docs/FEATURE_PARITY.md`
- Compare service counts
- Review implementation notes

**Solution:**
- Follow feature parity workflow
- Reference source platform implementation
- Adapt to target platform

#### Issue 3: Build Errors

**Diagnosis:**
- Check build logs
- Verify dependencies
- Check environment configuration

**Solution:**
- Review platform setup guides
- Verify environment configs
- Check for missing dependencies

---

## Development Best Practices

### Code Organization

1. **Follow Platform Patterns:**
   - Apple: MVVM with Services
   - Android: MVVM with ViewModels
   - Windows: MVVM with Services

2. **Maintain Consistency:**
   - Use same naming conventions
   - Follow architectural patterns
   - Keep structure similar across platforms

3. **Document Changes:**
   - Update implementation notes
   - Update feature parity doc
   - Document platform-specific differences

### Testing Strategy

**Unit Tests:**
- Test services independently
- Mock dependencies
- Test error cases

**Integration Tests:**
- Test service interactions
- Test database operations
- Test Supabase integration

**Cross-Platform Tests:**
- Create vault on Platform A
- Verify on Platform B
- Test sync behavior

### Git Workflow

**Branch Strategy:**
```bash
main          # Production-ready code
develop       # Integration branch
feature/*     # Feature branches
platform/*    # Platform-specific work
```

**Commit Messages:**
```
[Platform] Feature: Description
[All] Fix: Bug description
[Android] Feature: Feature name
```

---

## Troubleshooting

### Common Issues

**Issue: Supabase Connection Fails**

**Solution:**
1. Check environment config (dev/test/prod)
2. Verify Supabase URL and keys
3. Check network connectivity
4. Review Supabase dashboard

**Issue: Build Fails**

**Solution:**
1. Clean build: `xcodebuild clean` / `./gradlew clean` / `dotnet clean`
2. Verify dependencies installed
3. Check environment configuration
4. Review platform setup guide

**Issue: Feature Not Syncing**

**Solution:**
1. Check real-time subscriptions enabled
2. Verify RLS policies allow access
3. Check Supabase logs
4. Test with Supabase dashboard

---

## Development Resources

### Documentation Index

- **[Start Here](docs/00_START_HERE.md)** - Main entry point
- **[Implementation Notes](docs/IMPLEMENTATION_NOTES.md)** - Feature matrix
- **[Feature Parity](docs/FEATURE_PARITY.md)** - Gap analysis
- **[Platform Notes](docs/apple/IMPLEMENTATION_NOTES.md)** - Platform details

### Architecture

- **[System Architecture](docs/shared/architecture/COMPLETE_SYSTEM_ARCHITECTURE.md)** - Full architecture
- **[Database Schema](docs/shared/database/SCHEMA.md)** - Database structure

### Platform Guides

- **[Apple Setup](docs/apple/SETUP.md)**
- **[Android Setup](docs/android/SETUP.md)**
- **[Windows Setup](docs/windows/SETUP.md)**

---

## Next Steps

### For Feature Parity Work

1. Review `docs/FEATURE_PARITY.md`
2. Identify priority gaps
3. Set up development environment for target platform
4. Follow implementation workflow
5. Test and document

### For Workflow Improvements

1. Identify workflow pain points
2. Review existing workflows
3. Plan improvements
4. Implement changes
5. Document new workflows

---

**Last Updated:** December 2024

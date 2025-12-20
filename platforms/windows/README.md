# 🪟 Khandoba Secure Docs - Windows

> Windows port of Khandoba Secure Docs using WinUI 3 and .NET 8

## 📋 Prerequisites

- **Visual Studio 2022** (17.8 or later)
- **Windows 10 SDK** (10.0.17763.0 or later)
- **.NET 8 SDK**
- **Windows App SDK** (1.5 or later)

## 🚀 Quick Start

1. **Open in Visual Studio**
   ```
   Open KhandobaSecureDocs.sln
   ```

2. **Restore NuGet Packages**
   ```
   Right-click solution → Restore NuGet Packages
   ```

3. **Build Project**
   ```
   Build → Build Solution (Ctrl+Shift+B)
   ```

4. **Run**
   ```
   Debug → Start Debugging (F5)
   ```

## 📚 Documentation

- **[Windows Port Guide](../WINDOWS_PORT_GUIDE.md)** - Complete implementation guide
- **[Cross-Platform Summary](../CROSS_PLATFORM_PORT_SUMMARY.md)** - Multi-platform overview

## 🏗️ Project Structure

```
KhandobaSecureDocs/
├── Config/          # App configuration
├── Data/            # Database, entities, repositories
├── Services/        # Business logic services
├── ViewModels/      # MVVM view models
├── Views/           # WinUI 3 XAML views
├── Theme/           # Theming system
└── Utils/           # Utilities
```

## 🔧 Configuration

Edit `Config/AppConfig.cs` to configure:
- Azure AD credentials
- Azure Cognitive Services endpoints
- Feature flags
- Security settings

## 📦 Dependencies

Key NuGet packages:
- `Microsoft.WindowsAppSDK` - WinUI 3 framework
- `Microsoft.EntityFrameworkCore.Sqlite` - Database
- `Microsoft.Graph` - Microsoft Graph API
- `Azure.AI.TextAnalytics` - AI/ML features
- `System.Reactive` - Reactive extensions

## 🎯 Features

- ✅ Secure vault management
- ✅ Document encryption
- ✅ Microsoft Account authentication
- ✅ AI-powered document indexing
- ✅ Voice memo generation
- ✅ Video/audio recording
- 🚧 Premium subscriptions (in progress)

## 🔐 Security

- Windows Data Protection API (DPAPI)
- Windows Credential Manager
- Windows Hello biometric authentication
- AES-256-GCM encryption

## 📱 Platform Support

- **Windows 10** (version 1809 or later)
- **Windows 11**
- **Architectures:** x64, x86, ARM64

## 🚀 Deployment

### Microsoft Store
1. Create app in Partner Center
2. Configure app identity
3. Build release package
4. Submit for certification

### Sideloading
1. Build release package
2. Sign with certificate
3. Distribute via MSIX

## 📞 Support

See main project [README](../README.md) for documentation links.

---

**Status:** Foundation created, ready for implementation  
**Last Updated:** December 2024

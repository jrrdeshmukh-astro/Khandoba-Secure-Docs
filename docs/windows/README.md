# 🪟 Windows Documentation

> Windows platform documentation for Khandoba Secure Docs

---

## 📚 Documentation Index

### Essential Guides
- **[Windows Setup](SETUP.md)** - Initial project setup
- **[Windows Deployment](DEPLOYMENT.md)** - Store submission
- **[Windows Features](FEATURES.md)** - Feature documentation

---

## 🚀 Quick Start

### Prerequisites
- Visual Studio 2022 (17.8+)
- Windows 10 SDK (10.0.17763.0+)
- .NET 8 SDK
- Windows App SDK (1.5+)

### Setup
```bash
cd platforms/windows
# Open KhandobaSecureDocs.sln in Visual Studio
```

### Build
```bash
dotnet build
```

---

## 🏗️ Project Structure

```
platforms/windows/
├── KhandobaSecureDocs/
│   ├── Config/          # App configuration
│   ├── Data/            # Database, entities, repositories
│   ├── Services/        # Business logic services
│   ├── ViewModels/      # MVVM view models
│   ├── Views/           # WinUI 3 XAML views
│   ├── Theme/           # Theming system
│   └── Utils/           # Utilities
└── KhandobaSecureDocs.sln
```

---

## 🔧 Technology Stack

- **Language:** C#
- **UI:** WinUI 3
- **Framework:** .NET 8
- **Persistence:** Entity Framework Core + Supabase
- **Encryption:** Windows DPAPI
- **Authentication:** Microsoft Account (Azure AD)
- **AI/ML:** Azure Cognitive Services
- **Media:** Windows Media APIs

---

## 🚧 Implementation Status

- 🚧 Foundation created
- 🚧 Basic structure in place
- ⏳ Full implementation in progress

---

## 📖 Documentation

### Setup & Configuration
- **[Setup Guide](SETUP.md)** - Initial setup, dependencies, configuration

### Development
- **[Features](FEATURES.md)** - Feature documentation
- **[Architecture](../../shared/architecture/)** - System architecture

### Deployment
- **[Deployment Guide](DEPLOYMENT.md)** - Microsoft Store submission

---

## 🔄 Cross-Platform Sync

The Windows app will share the **same Supabase database** as iOS and Android:

- Real-time synchronization
- Same RLS policies
- Shared data model
- Unified authentication (Microsoft Account)

---

## 🔗 Related Documentation

- **[Shared Architecture](../../shared/architecture/)** - System architecture
- **[Shared API](../../shared/api/)** - Supabase API docs
- **[Shared Security](../../shared/security/)** - Security documentation
- **[Database Setup](../../shared/database/)** - Database setup and migrations

---

**Last Updated:** December 2024  
**Status:** 🚧 Foundation Created

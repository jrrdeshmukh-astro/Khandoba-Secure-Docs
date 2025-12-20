# 🪟 Windows Setup Guide

> Initial setup instructions for Windows development

---

## Prerequisites

- Visual Studio 2022 (17.8+)
- Windows 10 SDK (10.0.17763.0+)
- .NET 8 SDK
- Windows App SDK (1.5+)
- Azure account (for authentication and AI services)

---

## Quick Setup

### 1. Open Project

```bash
cd platforms/windows
# Open KhandobaSecureDocs.sln in Visual Studio
```

### 2. Restore NuGet Packages

```bash
# In Visual Studio: Right-click solution → Restore NuGet Packages
# Or command line:
dotnet restore
```

### 3. Configure App

Edit `Config/AppConfig.cs`:

```csharp
public static class AppConfig
{
    public static string SupabaseUrl = "YOUR_SUPABASE_URL";
    public static string SupabaseAnonKey = "YOUR_SUPABASE_ANON_KEY";
    // ... other configuration
}
```

---

## Build Configuration

### Development Build

```bash
dotnet build
# Or in Visual Studio: Build → Build Solution (Ctrl+Shift+B)
```

### Production Build

```bash
dotnet build -c Release
```

---

## Testing

```bash
# Run tests
dotnet test
```

---

## Troubleshooting

**Build fails:**
- Verify .NET 8 SDK is installed
- Restore NuGet packages
- Check Windows SDK version

**Runtime errors:**
- Verify Windows App SDK runtime is installed
- Check app manifest permissions

---

## Project Structure

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

---

## Technology Stack

- **UI:** WinUI 3
- **Framework:** .NET 8
- **Persistence:** Entity Framework Core + Supabase
- **Encryption:** Windows DPAPI
- **Authentication:** Microsoft Account (Azure AD)
- **AI/ML:** Azure Cognitive Services

---

## Next Steps

- **[Features](FEATURES.md)** - Feature documentation
- **[Deployment](DEPLOYMENT.md)** - Store deployment
- **[Shared Architecture](../../shared/architecture/)** - System architecture

---

**Last Updated:** December 2024  
**Status:** 🚧 Foundation Created

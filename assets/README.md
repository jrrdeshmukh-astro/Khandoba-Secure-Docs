# Assets Directory - Khandoba Secure Docs

## 🎨 Design System

### Color Palette
See [COLOR_PALETTE.md](./COLOR_PALETTE.md) for the complete color system inspired by the isometric temple architecture.

**Key Colors:**
- **Primary:** `#E8A87C` - Warm muted orange/peach (temple structure)
- **Secondary:** `#2D4A5F` - Dark teal/blue-grey (temple base)
- **Tertiary:** `#F5F0E8` - Light cream/off-white (tower cap)
- **Background:** `#FAF9F5` - Light beige

### Icon System
See [ICON_SETUP_GUIDE.md](./ICON_SETUP_GUIDE.md) for complete icon setup instructions.

**Base Icon:** Isometric 3D temple structure design

## 📁 Directory Structure

```
assets/
├── apple/              # iOS-specific assets
│   ├── Icons/         # App icons (AppIcon.appiconset)
│   └── AppStoreAssets/ # Screenshots and metadata
│
├── android/            # Android-specific assets
│   └── Icons/         # Launcher icons (mipmap densities)
│
├── windows/            # Windows-specific assets
│   └── Icons/         # App icons (various sizes)
│
└── shared/             # Cross-platform assets
    ├── branding/      # Logos, favicons
    ├── icons/         # Base icon files
    └── logos/         # Brand logos
```

## 🚀 Quick Setup

### 1. Set Up Icons
```bash
# Place your temple icon image here:
# assets/shared/icons/temple-icon-base.png (1024x1024px minimum)

# Generate all platform icons:
./scripts/generate_icons.sh assets/shared/icons/temple-icon-base.png
```

### 2. Verify Theme
The UnifiedTheme has been updated with the temple color palette. Colors are automatically applied throughout the app.

### 3. Platform-Specific Assets

#### iOS
- Icons: `assets/apple/Icons/AppIcon.appiconset/`
- Configured via Xcode Assets.xcassets

#### Android
- Icons: `assets/android/Icons/mipmap-*/`
- Adaptive icons: `assets/android/Icons/adaptive-icon/`
- Referenced in `AndroidManifest.xml`

#### Windows
- Icons: `assets/windows/Icons/`
- Configured in `.csproj` or `Package.appxmanifest`

## 📚 Documentation

- **[COLOR_PALETTE.md](./COLOR_PALETTE.md)** - Complete color system documentation
- **[ICON_SETUP_GUIDE.md](./ICON_SETUP_GUIDE.md)** - Icon generation and setup guide

## 🎯 Design Principles

1. **Consistency:** Same temple design across all platforms
2. **Scalability:** Recognizable at all sizes (16px to 1024px)
3. **Accessibility:** High contrast, WCAG AA compliant
4. **Brand Identity:** Warm, secure, architectural aesthetic

## ✅ Checklist

After setting up assets:

- [ ] Base icon image placed in `assets/shared/icons/temple-icon-base.png`
- [ ] All platform icons generated using `generate_icons.sh`
- [ ] iOS icons verified in Xcode
- [ ] Android icons verified in Android Studio
- [ ] Windows icons verified in Visual Studio
- [ ] Favicons generated and tested
- [ ] Theme colors applied and tested
- [ ] Icons display correctly on all platforms

---

**Last Updated:** December 2024  
**Design Theme:** Isometric Temple Architecture


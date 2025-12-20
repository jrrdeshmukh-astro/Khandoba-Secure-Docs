# 🎨 Khandoba Secure Docs - Complete Asset Structure

**Comprehensive asset organization for iOS, Android, and Windows platforms**

---

## 📁 Directory Structure

```
assets/
├── ASSET_STRUCTURE.md          # This file - master asset guide
├── ASSET_GENERATION_GUIDE.md   # How to generate/create assets
├── BRANDING_GUIDELINES.md      # Brand colors, fonts, usage
│
├── shared/                      # Shared across all platforms
│   ├── branding/
│   │   ├── logos/
│   │   │   ├── logo-primary.svg
│   │   │   ├── logo-primary.png (1024x1024)
│   │   │   ├── logo-white.svg
│   │   │   ├── logo-dark.svg
│   │   │   ├── logo-icon.svg
│   │   │   └── logo-icon.png (512x512)
│   │   ├── wordmarks/
│   │   │   ├── wordmark-horizontal.svg
│   │   │   ├── wordmark-vertical.svg
│   │   │   └── wordmark-icon.svg
│   │   └── favicons/
│   │       ├── favicon.ico
│   │       ├── favicon-16x16.png
│   │       ├── favicon-32x32.png
│   │       └── apple-touch-icon.png (180x180)
│   │
│   ├── icons/
│   │   ├── app-icon-base.svg    # Base icon design (vector)
│   │   ├── app-icon-base.png    # Base icon (1024x1024)
│   │   ├── feature-icons/       # Feature-specific icons
│   │   │   ├── vault.svg
│   │   │   ├── document.svg
│   │   │   ├── security.svg
│   │   │   ├── ai-intelligence.svg
│   │   │   ├── threat-monitor.svg
│   │   │   └── dual-key.svg
│   │   └── social/
│   │       ├── twitter.png
│   │       ├── facebook.png
│   │       └── linkedin.png
│   │
│   └── marketing/
│       ├── screenshots/         # High-res screenshots for marketing
│       ├── videos/              # App preview videos
│       ├── banners/             # Web banners
│       └── press-kit/           # Press release materials
│
├── apple/                       # iOS/macOS/watchOS/tvOS assets
│   ├── AppStoreAssets/          # App Store Connect assets
│   │   ├── METADATA.md          # ✅ Already exists
│   │   ├── Screenshots/         # ✅ Already exists
│   │   ├── AppIcon/             # App Store icon
│   │   │   └── AppIcon-1024x1024.png
│   │   └── AppPreview/          # App preview videos
│   │       ├── iPhone_6.7/
│   │       ├── iPhone_6.5/
│   │       └── iPad_13/
│   │
│   ├── Icons/                   # iOS app icons (all sizes)
│   │   ├── AppIcon.appiconset/
│   │   │   ├── Contents.json
│   │   │   ├── icon-20x20@1x.png
│   │   │   ├── icon-20x20@2x.png
│   │   │   ├── icon-20x20@3x.png
│   │   │   ├── icon-29x29@1x.png
│   │   │   ├── icon-29x29@2x.png
│   │   │   ├── icon-29x29@3x.png
│   │   │   ├── icon-40x40@1x.png
│   │   │   ├── icon-40x40@2x.png
│   │   │   ├── icon-40x40@3x.png
│   │   │   ├── icon-60x60@2x.png
│   │   │   ├── icon-60x60@3x.png
│   │   │   ├── icon-76x76@1x.png
│   │   │   ├── icon-76x76@2x.png
│   │   │   ├── icon-83.5x83.5@2x.png
│   │   │   ├── icon-1024x1024.png
│   │   │   └── README.md
│   │   └── README.md
│   │
│   ├── LaunchScreens/           # Launch screen assets
│   │   ├── LaunchScreen.storyboard
│   │   ├── LaunchImage.png
│   │   └── README.md
│   │
│   └── README.md
│
├── android/                     # Android assets
│   ├── PlayStoreAssets/         # Google Play Store assets
│   │   ├── METADATA.md
│   │   ├── Screenshots/
│   │   │   ├── phone/
│   │   │   ├── tablet-7/
│   │   │   ├── tablet-10/
│   │   │   └── tv/
│   │   ├── FeatureGraphic/
│   │   │   └── feature-graphic-1024x500.png
│   │   └── AppPreview/
│   │       └── app-preview-video.mp4
│   │
│   ├── Icons/                    # Android app icons
│   │   ├── mipmap-mdpi/
│   │   │   └── ic_launcher.png (48x48)
│   │   ├── mipmap-hdpi/
│   │   │   └── ic_launcher.png (72x72)
│   │   ├── mipmap-xhdpi/
│   │   │   └── ic_launcher.png (96x96)
│   │   ├── mipmap-xxhdpi/
│   │   │   └── ic_launcher.png (144x144)
│   │   ├── mipmap-xxxhdpi/
│   │   │   └── ic_launcher.png (192x192)
│   │   ├── adaptive-icon/
│   │   │   ├── ic_launcher_foreground.png (1024x1024)
│   │   │   ├── ic_launcher_background.png (1024x1024)
│   │   │   └── ic_launcher.xml
│   │   └── README.md
│   │
│   ├── SplashScreens/            # Android splash screens
│   │   ├── splash_screen.xml
│   │   ├── splash_background.png
│   │   └── README.md
│   │
│   └── README.md
│
└── windows/                     # Windows assets
    ├── StoreAssets/              # Microsoft Store assets
    │   ├── METADATA.md
    │   ├── Screenshots/
    │   │   ├── desktop/
    │   │   └── tablet/
    │   ├── StoreLogo/
    │   │   └── StoreLogo-300x300.png
    │   ├── Square150x150Logo/
    │   │   └── Square150x150Logo-150x150.png
    │   ├── Square44x44Logo/
    │   │   └── Square44x44Logo-44x44.png
    │   ├── Wide310x150Logo/
    │   │   └── Wide310x150Logo-310x150.png
    │   └── AppPreview/
    │       └── app-preview-video.mp4
    │
    ├── Icons/                    # Windows app icons
    │   ├── AppIcon-16x16.png
    │   ├── AppIcon-32x32.png
    │   ├── AppIcon-48x48.png
    │   ├── AppIcon-256x256.png
    │   └── README.md
    │
    └── README.md
```

---

## 🎨 Brand Colors

Based on `UnifiedTheme.swift`:

### Primary Colors
- **Primary (Coral Red):** `#E74A48` - Main brand color
- **Secondary (Cyan):** `#11A7C7` - Client role, vaults
- **Tertiary (Amber):** `#E7A63A` - Admin role, warnings

### Background Colors
- **Light Background:** `#F5F2ED` (Paper/cream)
- **Dark Background:** `#1F2430` (Dark charcoal)
- **Light Surface:** `#FFFFFF`
- **Dark Surface:** `#252C39`

### Semantic Colors
- **Success:** `#45C186` (Green)
- **Error:** `#E45858` (Red)
- **Warning:** `#E7A63A` (Amber)
- **Info:** `#11A7C7` (Cyan)

### Tab Colors
- **Dashboard:** `#E74A48` (Coral red)
- **Vaults:** `#11A7C7` (Cyan)
- **Documents:** `#6C63FF` (Purple)
- **Store:** `#45C186` (Green)
- **Profile:** `#8E8E93` (Gray)

---

## 📐 Icon Design Guidelines

### App Icon Concept
- **Theme:** Security, vault, documents, protection
- **Elements:** Shield, lock, document, vault door
- **Style:** Modern, clean, professional
- **Colors:** Primary coral red (#E74A48) with secondary cyan (#11A7C7)

### Design Principles
1. **Recognizable at small sizes** (16x16 to 1024x1024)
2. **No transparency** (solid background)
3. **High contrast** (works in light and dark modes)
4. **Simple shapes** (avoid fine details)
5. **Brand consistency** (matches app theme)

### Icon Variations Needed
- **Base icon:** 1024x1024 (source)
- **iOS:** 20pt, 29pt, 40pt, 60pt, 76pt, 83.5pt (all @1x, @2x, @3x)
- **Android:** mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi + adaptive icon
- **Windows:** 16x16, 32x32, 48x48, 256x256

---

## 📱 Platform-Specific Requirements

### iOS (Apple)
- **App Icon:** 1024x1024 (App Store)
- **Launch Screen:** Storyboard or static image
- **Screenshots:** 
  - iPhone 6.7" (1290x2796) - Required
  - iPhone 6.5" (1242x2688) - Optional
  - iPad 13" (2048x2732) - Optional
- **App Preview:** 30-second video (optional but recommended)

### Android
- **App Icon:** 512x512 (Play Store)
- **Adaptive Icon:** Foreground + Background (1024x1024 each)
- **Feature Graphic:** 1024x500 (Play Store banner)
- **Screenshots:**
  - Phone: 16:9 or 9:16 aspect ratio
  - Tablet 7": 16:9 or 9:16
  - Tablet 10": 16:9 or 9:16
  - TV: 1920x1080 (16:9)
- **App Preview:** 30-second video (optional)

### Windows
- **Store Logo:** 300x300
- **Square Logo:** 150x150, 44x44
- **Wide Logo:** 310x150
- **Screenshots:**
  - Desktop: 1366x768 minimum
  - Tablet: 1920x1080
- **App Preview:** 30-second video (optional)

---

## 🚀 Quick Start

1. **Create base icon design** (1024x1024)
2. **Generate platform-specific sizes** (use scripts)
3. **Create launch/splash screens**
4. **Capture screenshots** for all platforms
5. **Create app preview videos** (optional)
6. **Add to project** and configure

See `ASSET_GENERATION_GUIDE.md` for detailed instructions.

---

## ✅ Asset Checklist

### Shared Assets
- [ ] Primary logo (SVG + PNG)
- [ ] App icon base (1024x1024)
- [ ] Feature icons (SVG)
- [ ] Favicons
- [ ] Marketing materials

### iOS Assets
- [ ] App icon (all sizes)
- [ ] Launch screen
- [ ] App Store screenshots
- [ ] App preview video (optional)

### Android Assets
- [ ] App icon (all densities)
- [ ] Adaptive icon
- [ ] Splash screen
- [ ] Play Store screenshots
- [ ] Feature graphic
- [ ] App preview video (optional)

### Windows Assets
- [ ] App icon (all sizes)
- [ ] Store logos (all sizes)
- [ ] Screenshots
- [ ] App preview video (optional)

---

**Last Updated:** December 2024  
**Status:** Structure defined, assets to be generated


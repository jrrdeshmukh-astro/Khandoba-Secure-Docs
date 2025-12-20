# ⚡ Asset Quick Reference

**Quick lookup guide for all asset requirements**

---

## 🎯 Base Icon

**Location:** `assets/shared/icons/app-icon-base.png`  
**Size:** 1024x1024 pixels  
**Format:** PNG (no transparency)  
**Status:** ⚠️ **NEEDS TO BE CREATED**

---

## 🍎 iOS Assets

### App Icon
- **App Store:** 1024x1024 (`AppStoreAssets/AppIcon/`)
- **All Sizes:** 20pt-1024pt (`Icons/AppIcon.appiconset/`)
- **Status:** ⚠️ Run `generate_all_assets.sh` to generate

### Launch Screen
- **Format:** Storyboard or SwiftUI
- **Location:** `LaunchScreens/`
- **Status:** ⚠️ **NEEDS TO BE CREATED**

### Screenshots
- **iPhone 6.7":** 1290x2796 (✅ Has 5 screenshots)
- **Status:** ✅ Complete

---

## 🤖 Android Assets

### App Icon
- **All Densities:** mdpi to xxxhdpi (`Icons/mipmap-*/`)
- **Adaptive Icon:** Foreground + Background (`Icons/adaptive-icon/`)
- **Status:** ⚠️ Run `generate_all_assets.sh` to generate

### Splash Screen
- **Format:** XML drawable
- **Location:** `SplashScreens/`
- **Status:** ⚠️ **NEEDS TO BE CREATED**

### Feature Graphic
- **Size:** 1024x500
- **Location:** `PlayStoreAssets/FeatureGraphic/`
- **Status:** ⚠️ **NEEDS TO BE CREATED**

### Screenshots
- **Phone, Tablet, TV:** Various sizes
- **Status:** ⚠️ **NEEDS TO BE CREATED**

---

## 🪟 Windows Assets

### App Icon
- **Sizes:** 16x16, 32x32, 48x48, 256x256
- **Location:** `Icons/`
- **Status:** ⚠️ Run `generate_all_assets.sh` to generate

### Store Logos
- **Store Logo:** 300x300
- **Square 150x150:** 150x150
- **Square 44x44:** 44x44
- **Wide 310x150:** 310x150
- **Status:** ⚠️ Run `generate_all_assets.sh` to generate

### Screenshots
- **Desktop, Tablet:** Various sizes
- **Status:** ⚠️ **NEEDS TO BE CREATED**

---

## 🌐 Shared Assets

### Logos
- **Primary:** SVG + PNG (1024x1024)
- **White:** SVG (for dark backgrounds)
- **Dark:** SVG (for light backgrounds)
- **Icon Only:** SVG + PNG (512x512)
- **Status:** ⚠️ **NEEDS TO BE CREATED**

### Favicons
- **ICO:** Multi-size Windows favicon
- **PNG:** 16x16, 32x32
- **Apple Touch:** 180x180
- **Status:** ⚠️ Run `generate_all_assets.sh` to generate

### Feature Icons
- **Vault, Document, Security, AI, Threat, Dual-Key:** SVG
- **Status:** ⚠️ **NEEDS TO BE CREATED**

---

## 🚀 Quick Start

### Step 1: Create Base Icon
1. Design 1024x1024 icon (security/vault theme)
2. Save as `assets/shared/icons/app-icon-base.png`
3. Also export as SVG: `app-icon-base.svg`

### Step 2: Generate All Icons
```bash
cd scripts
./generate_all_assets.sh
```

### Step 3: Create Missing Assets
- Launch screens (iOS)
- Splash screens (Android)
- Feature graphic (Android)
- Logos (shared)
- Feature icons (shared)
- Screenshots (all platforms)

### Step 4: Add to Projects
- iOS: Add to Xcode Assets.xcassets
- Android: Add to res/ directories
- Windows: Add to project resources

---

## 📋 Asset Checklist

### ✅ Completed
- [x] Asset structure documentation
- [x] iOS screenshots (iPhone 6.7", 6.5", iPad 13")
- [x] App Store metadata (iOS)
- [x] Play Store metadata (Android)
- [x] Store metadata (Windows)
- [x] Asset generation script

### ⚠️ Needs Creation
- [ ] Base app icon (1024x1024)
- [ ] All platform icons (run script after base icon)
- [ ] Logos (primary, white, dark, icon-only)
- [ ] Feature icons (vault, document, security, etc.)
- [ ] Launch screens (iOS)
- [ ] Splash screens (Android)
- [ ] Feature graphic (Android)
- [ ] Screenshots (Android, Windows)
- [ ] App preview videos (all platforms, optional)

---

## 🛠️ Tools Needed

- **Design:** Figma, Sketch, Adobe Illustrator, or Canva
- **Image Processing:** ImageMagick (for script)
- **Screenshots:** Platform simulators/emulators
- **Video:** iMovie, Final Cut Pro, or Adobe Premiere

---

## 📚 Documentation

- **Master Guide:** `ASSET_STRUCTURE.md`
- **Generation Guide:** `ASSET_GENERATION_GUIDE.md`
- **Branding:** `BRANDING_GUIDELINES.md`
- **Platform Guides:**
  - iOS: `apple/README.md`
  - Android: `android/README.md`
  - Windows: `windows/README.md`

---

**Last Updated:** December 2024


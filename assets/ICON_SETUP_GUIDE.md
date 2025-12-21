# Icon Setup Guide - Isometric Temple Design

## 🎨 Overview

This guide explains how to set up the isometric temple icon across all platforms (iOS, Android, Windows) using the provided temple architecture image.

## 📐 Design Specifications

### Base Image Requirements
- **Format:** PNG with transparency (recommended) or solid background
- **Minimum Size:** 1024x1024 pixels (for best quality)
- **Aspect Ratio:** 1:1 (square)
- **Design:** Isometric 3D temple structure
  - Main structure: Warm muted orange/peach (#E8A87C)
  - Base: Dark teal/blue-grey (#2D4A5F)
  - Tower cap: Light cream/off-white (#F5F0E8)
  - Background: Light beige (#FAF9F5) or transparent

### Icon Design Principles
1. **Centered Composition:** Temple should be centered with safe margins
2. **High Contrast:** Ensure visibility on both light and dark backgrounds
3. **Scalability:** Design should be recognizable at small sizes (16x16px)
4. **Platform Guidelines:** Follow platform-specific icon guidelines

## 🚀 Quick Start

### Step 1: Prepare Base Image
1. Ensure your temple image is at least 1024x1024 pixels
2. Save as PNG format
3. Place in: `assets/shared/icons/temple-icon-base.png`

### Step 2: Generate All Icons
```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
./scripts/generate_icons.sh assets/shared/icons/temple-icon-base.png
```

### Step 3: Verify Icons
Check that all icons were generated in:
- iOS: `assets/apple/Icons/AppIcon.appiconset/`
- Android: `assets/android/Icons/`
- Windows: `assets/windows/Icons/`
- Favicons: `assets/shared/branding/favicons/`

## 📱 Platform-Specific Requirements

### iOS Icons

**Location:** `assets/apple/Icons/AppIcon.appiconset/`

**Required Sizes:**
- 20x20 (@1x, @2x, @3x) - Notification icons
- 29x29 (@1x, @2x, @3x) - Settings icons
- 40x40 (@1x, @2x, @3x) - Spotlight search
- 60x60 (@2x, @3x) - App icon (iPhone)
- 76x76 (@1x, @2x) - App icon (iPad)
- 83.5x83.5 (@2x) - App icon (iPad Pro)
- 1024x1024 - App Store

**Configuration:**
Icons are automatically configured via Xcode's `AppIcon.appiconset` asset catalog.

### Android Icons

**Location:** `assets/android/Icons/`

**Required Sizes:**
- `mipmap-mdpi/ic_launcher.png` - 48x48px
- `mipmap-hdpi/ic_launcher.png` - 72x72px
- `mipmap-xhdpi/ic_launcher.png` - 96x96px
- `mipmap-xxhdpi/ic_launcher.png` - 144x144px
- `mipmap-xxxhdpi/ic_launcher.png` - 192x192px

**Adaptive Icons:**
- `adaptive-icon/ic_launcher_foreground.png` - 432x432px (108dp safe zone)
- `adaptive-icon/ic_launcher_background.png` - 432x432px (solid color)

**Configuration:**
Icons are referenced in `AndroidManifest.xml`:
```xml
android:icon="@mipmap/ic_launcher"
android:roundIcon="@mipmap/ic_launcher_round"
```

### Windows Icons

**Location:** `assets/windows/Icons/`

**Required Sizes:**
- `AppIcon-16x16.png` - Taskbar
- `AppIcon-32x32.png` - Taskbar (high DPI)
- `AppIcon-48x48.png` - File explorer
- `AppIcon-256x256.png` - Start menu, app list

**Configuration:**
Icons are configured in the `.csproj` file or `Package.appxmanifest`.

### Web/Favicons

**Location:** `assets/shared/branding/favicons/`

**Required Sizes:**
- `favicon-16x16.png` - Browser tab
- `favicon-32x32.png` - Browser tab (high DPI)
- `favicon-48x48.png` - Browser bookmark
- `apple-touch-icon.png` - 180x180px (iOS Safari)

## 🛠️ Manual Icon Generation

If the automated script doesn't work, you can generate icons manually:

### Using ImageMagick (Command Line)
```bash
# Install ImageMagick
brew install imagemagick  # macOS
# or
apt-get install imagemagick  # Linux

# Generate iOS icon (example: 60x60@3x = 180x180px)
convert temple-icon-base.png -resize 180x180 icon-60x60@3x.png

# Generate Android icon (example: xxhdpi = 144x144px)
convert temple-icon-base.png -resize 144x144 ic_launcher.png

# Generate Windows icon (example: 256x256px)
convert temple-icon-base.png -resize 256x256 AppIcon-256x256.png
```

### Using Online Tools
1. **AppIcon.co** - https://appicon.co
   - Upload 1024x1024 base image
   - Download all platform icons

2. **IconKitchen** - https://icon.kitchen
   - Upload base image
   - Generate adaptive icons for Android

3. **Favicon Generator** - https://realfavicongenerator.net
   - Generate favicons and app icons

### Using Design Tools
1. **Figma/Sketch/Adobe XD:**
   - Create 1024x1024 artboard
   - Export at required sizes
   - Use export presets for each platform

2. **Xcode:**
   - Open `AppIcon.appiconset` in Assets.xcassets
   - Drag and drop icons into appropriate slots

## ✅ Verification Checklist

After generating icons, verify:

- [ ] All iOS icon sizes generated (20pt to 1024pt)
- [ ] All Android mipmap densities generated (mdpi to xxxhdpi)
- [ ] Android adaptive icons created (foreground + background)
- [ ] All Windows icon sizes generated (16px to 256px)
- [ ] Favicons generated (16px, 32px, 48px, 180px)
- [ ] Icons display correctly in simulators/emulators
- [ ] Icons are recognizable at small sizes
- [ ] Icons maintain brand consistency across platforms

## 🎨 Design Tips

1. **Safe Zone:** Keep important elements within 80% of the icon area
2. **Padding:** Add 10-15% padding around the design
3. **Contrast:** Test icons on both light and dark backgrounds
4. **Simplicity:** Ensure the temple design is recognizable at 16x16px
5. **Consistency:** Use the same temple design across all platforms

## 🔧 Troubleshooting

### Icons appear blurry
- Ensure base image is at least 1024x1024px
- Use high-quality source image
- Check that ImageMagick is using proper resampling

### Icons don't appear in app
- Verify icon paths in platform configurations
- Clear build cache and rebuild
- Check file permissions

### Adaptive icons not working (Android)
- Ensure foreground is 432x432px with safe zone
- Background should be solid color or simple pattern
- Check `AndroidManifest.xml` configuration

## 📚 Additional Resources

- [Apple Human Interface Guidelines - Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Android Icon Design Guidelines](https://developer.android.com/guide/practices/ui_guidelines/icon_design)
- [Windows App Icon Guidelines](https://docs.microsoft.com/en-us/windows/uwp/design/style/app-icons-and-logos)

---

**Last Updated:** December 2024  
**Base Design:** Isometric Temple Architecture


# 🎨 Asset Generation Guide

**Step-by-step guide to create all assets for Khandoba Secure Docs**

---

## 🎯 Overview

This guide walks you through generating all required assets for iOS, Android, and Windows platforms.

---

## 📐 Step 1: Create Base App Icon

### Design Requirements
- **Size:** 1024x1024 pixels
- **Format:** PNG (no transparency)
- **Design:** Security/vault theme with brand colors
- **Tools:** Figma, Sketch, Adobe Illustrator, or Canva

### Design Concept
1. **Primary Element:** Shield or lock icon
2. **Secondary Element:** Document or vault door
3. **Colors:** 
   - Primary: #E74A48 (Coral red)
   - Secondary: #11A7C7 (Cyan)
   - Background: White or light gray
4. **Style:** Modern, clean, professional

### Export
- Save as: `assets/shared/icons/app-icon-base.png`
- Also export as SVG: `assets/shared/icons/app-icon-base.svg`

---

## 🍎 Step 2: Generate iOS Assets

### 2.1 App Icons

**Option A: Using Xcode Asset Catalog (Recommended)**
1. Open Xcode project
2. Open `Assets.xcassets`
3. Select `AppIcon`
4. Drag your 1024x1024 icon to the App Store slot
5. Xcode will auto-generate all sizes

**Option B: Manual Generation**
Use ImageMagick or online tools to generate all sizes:

```bash
# Install ImageMagick (if not installed)
brew install imagemagick

# Generate all iOS icon sizes
cd assets/apple/Icons/AppIcon.appiconset/

# 20pt icons
convert ../../../../shared/icons/app-icon-base.png -resize 20x20 icon-20x20@1x.png
convert ../../../../shared/icons/app-icon-base.png -resize 40x40 icon-20x20@2x.png
convert ../../../../shared/icons/app-icon-base.png -resize 60x60 icon-20x20@3x.png

# 29pt icons
convert ../../../../shared/icons/app-icon-base.png -resize 29x29 icon-29x29@1x.png
convert ../../../../shared/icons/app-icon-base.png -resize 58x58 icon-29x29@2x.png
convert ../../../../shared/icons/app-icon-base.png -resize 87x87 icon-29x29@3x.png

# 40pt icons
convert ../../../../shared/icons/app-icon-base.png -resize 40x40 icon-40x40@1x.png
convert ../../../../shared/icons/app-icon-base.png -resize 80x80 icon-40x40@2x.png
convert ../../../../shared/icons/app-icon-base.png -resize 120x120 icon-40x40@3x.png

# 60pt icons (iPhone)
convert ../../../../shared/icons/app-icon-base.png -resize 120x120 icon-60x60@2x.png
convert ../../../../shared/icons/app-icon-base.png -resize 180x180 icon-60x60@3x.png

# 76pt icons (iPad)
convert ../../../../shared/icons/app-icon-base.png -resize 76x76 icon-76x76@1x.png
convert ../../../../shared/icons/app-icon-base.png -resize 152x152 icon-76x76@2x.png

# 83.5pt icons (iPad Pro)
convert ../../../../shared/icons/app-icon-base.png -resize 167x167 icon-83.5x83.5@2x.png

# 1024x1024 (App Store)
cp ../../../../shared/icons/app-icon-base.png icon-1024x1024.png
```

### 2.2 Create Contents.json

Create `assets/apple/Icons/AppIcon.appiconset/Contents.json`:

```json
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "idiom" : "ios-marketing",
      "size" : "1024x1024",
      "scale" : "1x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### 2.3 Launch Screen

Create a simple launch screen using SwiftUI or Storyboard:

**Option A: SwiftUI (Recommended)**
```swift
// LaunchScreen.swift
import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Color(hex: "F5F2ED") // Light background
            Image("AppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
        }
    }
}
```

**Option B: Storyboard**
- Create `LaunchScreen.storyboard` in Xcode
- Add app icon centered on brand background color

---

## 🤖 Step 3: Generate Android Assets

### 3.1 App Icons (All Densities)

```bash
cd assets/android/Icons/

# mdpi (48x48)
convert ../../shared/icons/app-icon-base.png -resize 48x48 mipmap-mdpi/ic_launcher.png

# hdpi (72x72)
convert ../../shared/icons/app-icon-base.png -resize 72x72 mipmap-hdpi/ic_launcher.png

# xhdpi (96x96)
convert ../../shared/icons/app-icon-base.png -resize 96x96 mipmap-xhdpi/ic_launcher.png

# xxhdpi (144x144)
convert ../../shared/icons/app-icon-base.png -resize 144x144 mipmap-xxhdpi/ic_launcher.png

# xxxhdpi (192x192)
convert ../../shared/icons/app-icon-base.png -resize 192x192 mipmap-xxxhdpi/ic_launcher.png
```

### 3.2 Adaptive Icon

Android 8.0+ requires adaptive icons with foreground and background:

**Foreground (1024x1024):**
- Your app icon (centered, with safe zone)
- Safe zone: 66% of canvas (leave 17% margin on all sides)
- Export: `adaptive-icon/ic_launcher_foreground.png`

**Background (1024x1024):**
- Solid color or gradient
- Use brand color: #E74A48 or #11A7C7
- Export: `adaptive-icon/ic_launcher_background.png`

**Create `adaptive-icon/ic_launcher.xml`:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
```

### 3.3 Splash Screen

Create `assets/android/SplashScreens/splash_screen.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_background"/>
    <item>
        <bitmap
            android:gravity="center"
            android:src="@mipmap/ic_launcher"/>
    </item>
</layer-list>
```

### 3.4 Feature Graphic (Play Store)

- **Size:** 1024x500 pixels
- **Design:** App name, tagline, key features
- **Colors:** Brand colors (#E74A48, #11A7C7)
- **Export:** `PlayStoreAssets/FeatureGraphic/feature-graphic-1024x500.png`

---

## 🪟 Step 4: Generate Windows Assets

### 4.1 App Icons

```bash
cd assets/windows/Icons/

convert ../../shared/icons/app-icon-base.png -resize 16x16 AppIcon-16x16.png
convert ../../shared/icons/app-icon-base.png -resize 32x32 AppIcon-32x32.png
convert ../../shared/icons/app-icon-base.png -resize 48x48 AppIcon-48x48.png
convert ../../shared/icons/app-icon-base.png -resize 256x256 AppIcon-256x256.png
```

### 4.2 Store Logos

```bash
cd assets/windows/StoreAssets/

# Store Logo (300x300)
convert ../../shared/icons/app-icon-base.png -resize 300x300 StoreLogo/StoreLogo-300x300.png

# Square 150x150
convert ../../shared/icons/app-icon-base.png -resize 150x150 Square150x150Logo/Square150x150Logo-150x150.png

# Square 44x44
convert ../../shared/icons/app-icon-base.png -resize 44x44 Square44x44Logo/Square44x44Logo-44x44.png

# Wide 310x150
convert ../../shared/icons/app-icon-base.png -resize 310x150 -gravity center -extent 310x150 Wide310x150Logo/Wide310x150Logo-310x150.png
```

---

## 📸 Step 5: Create Screenshots

### iOS Screenshots

**Required Sizes:**
- iPhone 6.7" (1290x2796) - **REQUIRED**
- iPhone 6.5" (1242x2688) - Optional
- iPad 13" (2048x2732) - Optional

**Screenshot Scenarios:**
1. Welcome/Sign In screen
2. Vault List with dual-key badge
3. Document Upload (all 6 methods)
4. Intel Reports view
5. Premium Subscription screen

**How to Capture:**
1. Run app in iOS Simulator
2. Use Cmd+S to capture screenshot
3. Or use Xcode's screenshot tool
4. Save to `assets/apple/AppStoreAssets/Screenshots/`

### Android Screenshots

**Required Sizes:**
- Phone: 16:9 or 9:16 aspect ratio
- Tablet 7": 16:9 or 9:16
- Tablet 10": 16:9 or 9:16
- TV: 1920x1080 (16:9)

**How to Capture:**
1. Run app in Android Emulator
2. Use device screenshot (Power + Volume Down)
3. Or use Android Studio's screenshot tool
4. Save to `assets/android/PlayStoreAssets/Screenshots/`

### Windows Screenshots

**Required Sizes:**
- Desktop: 1366x768 minimum
- Tablet: 1920x1080

**How to Capture:**
1. Run app in Windows
2. Use Windows + Shift + S
3. Or use Snipping Tool
4. Save to `assets/windows/StoreAssets/Screenshots/`

---

## 🎬 Step 6: Create App Preview Videos (Optional)

### iOS App Preview
- **Duration:** 15-30 seconds
- **Sizes:**
  - iPhone 6.7": 1290x2796
  - iPhone 6.5": 1242x2688
  - iPad 13": 2048x2732
- **Format:** MOV or MP4
- **Content:** Show key features, use text overlays from `APP_PREVIEW_TEXT_OVERLAYS.txt`

### Android App Preview
- **Duration:** 30 seconds
- **Size:** 1920x1080 (16:9)
- **Format:** MP4
- **Content:** Show key features

### Windows App Preview
- **Duration:** 30 seconds
- **Size:** 1920x1080 (16:9)
- **Format:** MP4
- **Content:** Show key features

---

## 🛠️ Automation Scripts

### Generate All Icons Script

Create `scripts/generate_icons.sh`:

```bash
#!/bin/bash

# Generate all platform icons from base icon
BASE_ICON="assets/shared/icons/app-icon-base.png"

if [ ! -f "$BASE_ICON" ]; then
    echo "Error: Base icon not found at $BASE_ICON"
    exit 1
fi

echo "Generating iOS icons..."
# iOS icon generation commands here

echo "Generating Android icons..."
# Android icon generation commands here

echo "Generating Windows icons..."
# Windows icon generation commands here

echo "✅ All icons generated!"
```

---

## ✅ Verification Checklist

After generating assets, verify:

- [ ] All iOS icon sizes present
- [ ] All Android icon densities present
- [ ] Adaptive icon created
- [ ] All Windows icons present
- [ ] Screenshots captured for all platforms
- [ ] Launch/splash screens created
- [ ] App preview videos created (optional)
- [ ] All assets follow brand guidelines
- [ ] No transparency in app icons
- [ ] All sizes match requirements

---

## 📚 Resources

### Tools
- **Figma:** Design app icon
- **ImageMagick:** Generate icon sizes
- **Xcode:** iOS asset management
- **Android Studio:** Android asset management
- **Canva:** Marketing graphics

### Online Generators
- **AppIcon.co:** Generate all icon sizes
- **MakeAppIcon.com:** iOS icon generator
- **IconKitchen:** Android adaptive icon generator

---

**Last Updated:** December 2024


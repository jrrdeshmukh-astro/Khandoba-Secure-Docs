# 🤖 Android Platform Assets

**Android assets for Khandoba Secure Docs**

---

## 📁 Directory Structure

```
android/
├── PlayStoreAssets/         # Google Play Store assets
│   ├── METADATA.md          # Play Store listing info
│   ├── Screenshots/         # Store screenshots
│   ├── FeatureGraphic/      # Store banner (1024x500)
│   └── AppPreview/          # App preview videos
│
├── Icons/                   # App icons (all densities)
│   ├── mipmap-mdpi/         # 48x48
│   ├── mipmap-hdpi/         # 72x72
│   ├── mipmap-xhdpi/        # 96x96
│   ├── mipmap-xxhdpi/       # 144x144
│   ├── mipmap-xxxhdpi/      # 192x192
│   └── adaptive-icon/       # Android 8.0+ adaptive icon
│
├── SplashScreens/           # Splash screen assets
│   └── splash_screen.xml
│
└── README.md               # This file
```

---

## ✅ Current Status

### Needed
- [ ] All app icon sizes (mdpi to xxxhdpi)
- [ ] Adaptive icon (foreground + background)
- [ ] Splash screen
- [ ] Play Store metadata
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (phone, tablet, TV)
- [ ] App preview video (optional)

---

## 📐 Icon Requirements

### Standard Icons (All Densities)

| Density | Size | Location |
|---------|------|----------|
| mdpi | 48x48 | `Icons/mipmap-mdpi/ic_launcher.png` |
| hdpi | 72x72 | `Icons/mipmap-hdpi/ic_launcher.png` |
| xhdpi | 96x96 | `Icons/mipmap-xhdpi/ic_launcher.png` |
| xxhdpi | 144x144 | `Icons/mipmap-xxhdpi/ic_launcher.png` |
| xxxhdpi | 192x192 | `Icons/mipmap-xxxhdpi/ic_launcher.png` |

### Adaptive Icon (Android 8.0+)

**Required Components:**
1. **Foreground:** `adaptive-icon/ic_launcher_foreground.png` (1024x1024)
   - App icon (centered, 66% safe zone)
   - Leave 17% margin on all sides
   
2. **Background:** `adaptive-icon/ic_launcher_background.png` (1024x1024)
   - Solid color or gradient
   - Use brand color: #E74A48 or #11A7C7

3. **XML:** `adaptive-icon/ic_launcher.xml`
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
       <background android:drawable="@color/ic_launcher_background"/>
       <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
   </adaptive-icon>
   ```

**Location:** `Icons/adaptive-icon/`

---

## 🚀 Splash Screen

### Requirements
- **Format:** XML drawable
- **Content:** App icon centered on brand background
- **Colors:** Use brand colors

### Implementation

**Create `SplashScreens/splash_screen.xml`:**
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

**Add to colors.xml:**
```xml
<color name="splash_background">#F5F2ED</color>
```

**Location:** `SplashScreens/`

---

## 📸 Play Store Screenshots

### Required Sizes

#### Phone Screenshots
- **Aspect Ratio:** 16:9 or 9:16
- **Minimum:** 320px width
- **Recommended:** 1080x1920 (portrait) or 1920x1080 (landscape)
- **Quantity:** Minimum 2, Maximum 8

#### Tablet 7" Screenshots
- **Aspect Ratio:** 16:9 or 9:16
- **Recommended:** 1080x1920 or 1920x1080
- **Quantity:** Optional but recommended

#### Tablet 10" Screenshots
- **Aspect Ratio:** 16:9 or 9:16
- **Recommended:** 1080x1920 or 1920x1080
- **Quantity:** Optional but recommended

#### TV Screenshots
- **Size:** 1920x1080 (16:9)
- **Quantity:** Optional

### Screenshot Scenarios
1. Welcome/Sign In screen
2. Vault List with dual-key badge
3. Document Upload interface
4. Intel Reports view
5. Premium Subscription screen

**Location:** `PlayStoreAssets/Screenshots/`

---

## 🎨 Feature Graphic

### Requirements
- **Size:** 1024x500 pixels
- **Format:** PNG or JPG
- **Content:** App name, tagline, key features
- **Colors:** Brand colors (#E74A48, #11A7C7)

### Design Guidelines
- **Text:** App name "Khandoba Secure Docs"
- **Tagline:** "Enterprise-grade secure document management"
- **Features:** Highlight key features (Security, AI, Unlimited)
- **Style:** Professional, clean, modern

**Location:** `PlayStoreAssets/FeatureGraphic/feature-graphic-1024x500.png`

---

## 🎬 App Preview Video (Optional)

### Requirements
- **Duration:** 30 seconds
- **Size:** 1920x1080 (16:9)
- **Format:** MP4
- **Content:** Show key features, smooth transitions

**Location:** `PlayStoreAssets/AppPreview/app-preview-video.mp4`

---

## 📝 Play Store Metadata

### Required Information

**App Name:** Khandoba Secure Docs  
**Short Description:** 80 characters max  
**Full Description:** 4000 characters max  
**App Category:** Productivity  
**Content Rating:** Everyone  
**Privacy Policy URL:** Required

**Location:** `PlayStoreAssets/METADATA.md` (to be created)

---

## 🛠️ Generation

See `../ASSET_GENERATION_GUIDE.md` for detailed instructions.

### Quick Commands

```bash
# Generate all Android icon sizes
cd assets/android/Icons/
# Use ImageMagick to resize base icon
```

---

## ✅ Checklist

- [ ] All icon densities created (mdpi to xxxhdpi)
- [ ] Adaptive icon created (foreground + background)
- [ ] Splash screen created
- [ ] Feature graphic created (1024x500)
- [ ] Screenshots captured (phone, tablet, TV)
- [ ] Play Store metadata written
- [ ] App preview video created (optional)
- [ ] All assets added to Android project

---

**Last Updated:** December 2024


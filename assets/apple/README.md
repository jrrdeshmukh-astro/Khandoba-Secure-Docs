# 🍎 Apple Platform Assets

**iOS, macOS, watchOS, and tvOS assets for Khandoba Secure Docs**

---

## 📁 Directory Structure

```
apple/
├── AppStoreAssets/          # App Store Connect assets
│   ├── METADATA.md          # ✅ Complete
│   ├── Screenshots/         # ✅ Has screenshots
│   ├── AppIcon/             # App Store icon (1024x1024)
│   └── AppPreview/          # App preview videos
│
├── Icons/                   # App icons (all sizes)
│   └── AppIcon.appiconset/  # Asset catalog icon set
│
├── LaunchScreens/           # Launch screen assets
│   └── LaunchScreen.storyboard
│
└── README.md               # This file
```

---

## ✅ Current Status

### Completed
- ✅ App Store metadata (`METADATA.md`)
- ✅ Screenshots (iPhone 6.7", 6.5", iPad 13")
- ✅ App preview text overlays

### Needed
- [ ] App icon (1024x1024 for App Store)
- [ ] All iOS icon sizes (20pt-1024pt)
- [ ] Launch screen
- [ ] App preview videos (optional)

---

## 📐 Icon Requirements

### App Store Icon
- **Size:** 1024x1024 pixels
- **Format:** PNG (no transparency)
- **Location:** `AppStoreAssets/AppIcon/AppIcon-1024x1024.png`

### iOS App Icons (Asset Catalog)

All sizes needed for `AppIcon.appiconset/`:

| Size | @1x | @2x | @3x |
|------|-----|-----|-----|
| 20pt | 20x20 | 40x40 | 60x60 |
| 29pt | 29x29 | 58x58 | 87x87 |
| 40pt | 40x40 | 80x80 | 120x120 |
| 60pt | - | 120x120 | 180x180 |
| 76pt | 76x76 | 152x152 | - |
| 83.5pt | - | 167x167 | - |
| 1024pt | - | - | 1024x1024 |

**Location:** `Icons/AppIcon.appiconset/`

---

## 🚀 Launch Screen

### Requirements
- **Format:** Storyboard or SwiftUI
- **Content:** App icon centered on brand background
- **Colors:** Use brand colors (#F5F2ED light, #1F2430 dark)

### Options

**Option 1: Storyboard (Legacy)**
- Create `LaunchScreen.storyboard`
- Add image view with app icon
- Set background color

**Option 2: SwiftUI (Modern)**
- Create `LaunchScreen.swift`
- Use SwiftUI view with app icon
- Set background color

**Location:** `LaunchScreens/`

---

## 📸 Screenshots

### Required Sizes

#### iPhone 6.7" (iPhone 15 Pro Max) - **REQUIRED**
- **Size:** 1290 x 2796 pixels
- **Quantity:** Minimum 3, Maximum 10
- **Status:** ✅ Has 5 screenshots

#### iPhone 6.5" (iPhone 14 Pro Max) - Optional
- **Size:** 1242 x 2688 pixels
- **Status:** ✅ Has 5 screenshots

#### iPad 13" (iPad Pro 12.9") - Optional
- **Size:** 2048 x 2732 pixels
- **Status:** ✅ Has 5 screenshots

### Screenshot Scenarios
1. Welcome/Sign In screen
2. Vault List with dual-key badge
3. Document Upload (all 6 methods)
4. Intel Reports view
5. Premium Subscription screen

**Location:** `AppStoreAssets/Screenshots/`

---

## 🎬 App Preview Videos (Optional)

### Requirements
- **Duration:** 15-30 seconds
- **Format:** MOV or MP4
- **Sizes:**
  - iPhone 6.7": 1290x2796
  - iPhone 6.5": 1242x2688
  - iPad 13": 2048x2732

### Content
Use text overlays from `APP_PREVIEW_TEXT_OVERLAYS.txt`:
1. "Military-Grade Security"
2. "Unlimited Secure Vaults"
3. "Dual-Key Protection"
4. "AI-Powered Intelligence"
5. "Intel Reports"
6. "Real-Time Monitoring"
7. "Share Securely"
8. "$5.99/month • Unlimited"

**Location:** `AppStoreAssets/AppPreview/`

---

## 🛠️ Generation

See `../ASSET_GENERATION_GUIDE.md` for detailed instructions on generating all assets.

### Quick Commands

```bash
# Generate all iOS icon sizes from base icon
cd assets/apple/Icons/AppIcon.appiconset/
# Use ImageMagick or Xcode Asset Catalog
```

---

## ✅ Checklist

- [ ] App icon 1024x1024 created
- [ ] All iOS icon sizes generated
- [ ] Contents.json created for AppIcon.appiconset
- [ ] Launch screen created
- [ ] Screenshots captured (✅ Done)
- [ ] App preview videos created (optional)
- [ ] All assets added to Xcode project

---

**Last Updated:** December 2024


# 🪟 Windows Platform Assets

**Windows assets for Khandoba Secure Docs**

---

## 📁 Directory Structure

```
windows/
├── StoreAssets/             # Microsoft Store assets
│   ├── METADATA.md          # Store listing info
│   ├── Screenshots/         # Store screenshots
│   ├── StoreLogo/           # 300x300 store logo
│   ├── Square150x150Logo/   # 150x150 square logo
│   ├── Square44x44Logo/    # 44x44 square logo
│   ├── Wide310x150Logo/     # 310x150 wide logo
│   └── AppPreview/          # App preview videos
│
├── Icons/                   # App icons (all sizes)
│   ├── AppIcon-16x16.png
│   ├── AppIcon-32x32.png
│   ├── AppIcon-48x48.png
│   └── AppIcon-256x256.png
│
└── README.md               # This file
```

---

## ✅ Current Status

### Needed
- [ ] All app icon sizes (16x16 to 256x256)
- [ ] Store logos (all sizes)
- [ ] Store metadata
- [ ] Screenshots (desktop, tablet)
- [ ] App preview video (optional)

---

## 📐 Icon Requirements

### App Icons

| Size | Location |
|------|----------|
| 16x16 | `Icons/AppIcon-16x16.png` |
| 32x32 | `Icons/AppIcon-32x32.png` |
| 48x48 | `Icons/AppIcon-48x48.png` |
| 256x256 | `Icons/AppIcon-256x256.png` |

**Format:** PNG (no transparency)  
**Location:** `Icons/`

---

## 🏪 Microsoft Store Assets

### Store Logo
- **Size:** 300x300 pixels
- **Format:** PNG
- **Usage:** Primary store logo
- **Location:** `StoreAssets/StoreLogo/StoreLogo-300x300.png`

### Square 150x150 Logo
- **Size:** 150x150 pixels
- **Format:** PNG
- **Usage:** Medium tile
- **Location:** `StoreAssets/Square150x150Logo/Square150x150Logo-150x150.png`

### Square 44x44 Logo
- **Size:** 44x44 pixels
- **Format:** PNG
- **Usage:** Small tile, taskbar
- **Location:** `StoreAssets/Square44x44Logo/Square44x44Logo-44x44.png`

### Wide 310x150 Logo
- **Size:** 310x150 pixels
- **Format:** PNG
- **Usage:** Wide tile
- **Location:** `StoreAssets/Wide310x150Logo/Wide310x150Logo-310x150.png`

### Design Guidelines
- **No transparency**
- **High contrast**
- **Recognizable at small sizes**
- **Brand colors:** #E74A48, #11A7C7

---

## 📸 Store Screenshots

### Required Sizes

#### Desktop Screenshots
- **Minimum:** 1366x768 pixels
- **Recommended:** 1920x1080 (16:9)
- **Quantity:** Minimum 1, Maximum 9
- **Format:** PNG or JPG

#### Tablet Screenshots
- **Size:** 1920x1080 pixels (16:9)
- **Quantity:** Optional
- **Format:** PNG or JPG

### Screenshot Scenarios
1. Welcome/Sign In screen
2. Vault List with dual-key badge
3. Document Upload interface
4. Intel Reports view
5. Premium Subscription screen

**Location:** `StoreAssets/Screenshots/`

---

## 🎬 App Preview Video (Optional)

### Requirements
- **Duration:** 30 seconds
- **Size:** 1920x1080 (16:9)
- **Format:** MP4
- **Content:** Show key features, smooth transitions

**Location:** `StoreAssets/AppPreview/app-preview-video.mp4`

---

## 📝 Store Metadata

### Required Information

**App Name:** Khandoba Secure Docs  
**Description:** 10000 characters max  
**Category:** Productivity  
**Age Rating:** Everyone  
**Privacy Policy URL:** Required  
**Support URL:** Required

**Location:** `StoreAssets/METADATA.md` (to be created)

---

## 🛠️ Generation

See `../ASSET_GENERATION_GUIDE.md` for detailed instructions.

### Quick Commands

```bash
# Generate all Windows icon sizes
cd assets/windows/Icons/
# Use ImageMagick to resize base icon
```

---

## ✅ Checklist

- [ ] All app icon sizes created (16x16 to 256x256)
- [ ] Store logo created (300x300)
- [ ] Square logos created (150x150, 44x44)
- [ ] Wide logo created (310x150)
- [ ] Screenshots captured (desktop, tablet)
- [ ] Store metadata written
- [ ] App preview video created (optional)
- [ ] All assets added to Windows project

---

**Last Updated:** December 2024


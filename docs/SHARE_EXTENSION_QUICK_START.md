# Share Extension Quick Start

> Quick reference for Share Extension setup using Xcode CLI

## Files Created

✅ **ShareExtension/ShareExtensionViewController.swift** - Main extension code  
✅ **ShareExtension/Info.plist** - Extension configuration  
✅ **ShareExtension/ShareExtension.entitlements** - Capabilities  
✅ **scripts/setup_share_extension.sh** - Setup script  

## Quick Setup (Xcode GUI)

### 1. Add Target
```
File → New → Target → iOS → Share Extension
- Product Name: ShareExtension
- Bundle ID: com.khandoba.securedocs.ShareExtension
```

### 2. Configure Capabilities
```
ShareExtension Target → Signing & Capabilities:
- App Groups: group.com.khandoba.securedocs
- CloudKit: iCloud.com.khandoba.securedocs
```

### 3. Add Files
- Replace auto-generated ShareExtensionViewController.swift
- Add ShareExtension/Info.plist
- Add ShareExtension/ShareExtension.entitlements
- Add Models to target membership

### 4. Build
```
Select ShareExtension scheme → Cmd+B
```

## Testing

1. Run app on device
2. Open Photos app
3. Select photo → Share → Khandoba
4. Select vault → Import

## Troubleshooting

**Extension not appearing?**
- Clean build (Cmd+Shift+K)
- Delete app, rebuild, reinstall

**No vaults available?**
- Create vault in main app first
- Check CloudKit sync enabled

**Build errors?**
- Check Models added to ShareExtension target
- Verify frameworks linked (SwiftUI, SwiftData)

## Full Documentation

See `docs/SHARE_EXTENSION_SETUP_GUIDE.md` for complete instructions.


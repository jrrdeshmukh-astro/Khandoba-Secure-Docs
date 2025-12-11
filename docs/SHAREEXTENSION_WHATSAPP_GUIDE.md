# Share Extension: How Apps Like Preview Handle WhatsApp Shares

## Overview

Apps like **Preview**, **Files**, and **Photos** successfully accept shared data from WhatsApp by being **extremely permissive** and trying multiple approaches. Here's how they do it:

---

## 🔑 Key Principles

### 1. **Don't Trust Reported Type Conformance**

WhatsApp (and many other apps) may **not correctly report** what types they support. The `registeredTypeIdentifiers` or `hasItemConformingToTypeIdentifier` may return incorrect or incomplete information.

**Solution:** Try loading data with multiple type identifiers, even if they're not reported.

### 2. **WhatsApp's Type Identifiers**

WhatsApp uses **dynamic type identifiers** (dyn.*) that may not be standard:

- `dyn.ah62d4rv4ge80k5p2` - JPEG images
- `dyn.ah62d4rv4ge80k5p3` - PNG images
- `dyn.ah62d4rv4ge80k5p4` - HEIC images
- Standard types: `public.jpeg`, `public.png`, `public.image`, `public.data`

**Apps like Preview try ALL of these**, not just the reported ones.

### 3. **Handle Multiple Data Formats**

The same image can come in different formats:
- **URL** (`file://` path to temporary file)
- **Data** (raw bytes)
- **UIImage** (already decoded image object)

**Successful apps handle all three formats.**

### 4. **Priority Order Matters**

Try types in this order:
1. **Specific image types** (`public.jpeg`, `public.png`) - most reliable
2. **Generic image type** (`public.image`) - fallback
3. **Generic data type** (`public.data`) - last resort, then detect format from data

---

## 📋 How Preview Does It (Best Practices)

### Step 1: Check Info.plist Configuration

```xml
<key>NSExtensionActivationRule</key>
<dict>
    <key>NSExtensionActivationSupportsImage</key>
    <true/>
    <key>NSExtensionActivationSupportsImageWithMaxCount</key>
    <integer>100</integer>
    <key>NSExtensionActivationSupportsFileWithMaxCount</key>
    <integer>100</integer>
</dict>
```

✅ **Your app already has this configured correctly!**

### Step 2: Aggressive Type Loading

```swift
// Priority list - try in this order
let priorityTypes = [
    "public.jpeg",           // Most specific
    "public.png",
    "public.heic",
    "public.image",          // Generic image
    "dyn.ah62d4rv4ge80k5p2", // WhatsApp JPEG
    "dyn.ah62d4rv4ge80k5p3", // WhatsApp PNG
    "public.data"            // Generic data (detect format)
]

// Try each type, even if not reported
for typeID in priorityTypes {
    attachment.loadItem(forTypeIdentifier: typeID, options: nil) { data, error in
        // Process data
    }
}
```

✅ **Your app already does this!**

### Step 3: Handle Multiple Return Types

```swift
// Data can come as:
// 1. URL (file:// path)
if let url = data as? URL, url.isFileURL {
    let imageData = try? Data(contentsOf: url)
}

// 2. UIImage (already decoded)
if let image = data as? UIImage {
    let imageData = image.jpegData(compressionQuality: 0.9)
}

// 3. Data (raw bytes)
if let imageData = data as? Data {
    // Use directly
}
```

✅ **Your app handles all three!**

### Step 4: Format Detection from Data

If you get generic `Data`, detect the format from file signatures:

```swift
// JPEG: FF D8 FF
if data.count > 2 && data[0] == 0xFF && data[1] == 0xD8 {
    mimeType = "image/jpeg"
}

// PNG: 89 50 4E 47
if data.count > 8 && data[0] == 0x89 && data[1] == 0x50 {
    mimeType = "image/png"
}

// HEIC: ftyp box with heic/heif
if data.count > 12 {
    let header = String(data: data.prefix(12), encoding: .ascii) ?? ""
    if header.contains("ftyp") && header.contains("heic") {
        mimeType = "image/heic"
    }
}
```

✅ **Your app already does this!**

---

## 🐛 Common Issues & Solutions

### Issue 1: "No supported items found"

**Cause:** Extension activates but can't load the data.

**Solution:**
- Try `public.data` even if not reported
- Try all registered types, not just image types
- Handle URL, Data, and UIImage formats

### Issue 2: Blank Screen

**Cause:** View doesn't render or theme isn't available.

**Solution:**
- Set explicit background colors
- Provide UnifiedTheme via environment
- Show content immediately (don't wait for async operations)

### Issue 3: WhatsApp Images Not Loading

**Cause:** WhatsApp uses dynamic type identifiers not in standard list.

**Solution:**
- Include `dyn.ah62d4rv4ge80k5p2` and `dyn.ah62d4rv4ge80k5p3` in priority list
- Try generic `public.data` and detect format from bytes

---

## 🔍 Debugging Tips

### 1. Log All Type Identifiers

```swift
for typeID in attachment.registeredTypeIdentifiers {
    print("   📎 Registered type: \(typeID)")
}
```

### 2. Log What Actually Works

```swift
attachment.loadItem(forTypeIdentifier: typeID, options: nil) { data, error in
    if let error = error {
        print("   ❌ Failed: \(typeID) - \(error)")
    } else {
        print("   ✅ Success: \(typeID) - \(type(of: data))")
    }
}
```

### 3. Check Data Format

```swift
if let url = data as? URL {
    print("   📄 Got URL: \(url.path)")
} else if let image = data as? UIImage {
    print("   🖼️ Got UIImage: \(image.size)")
} else if let data = data as? Data {
    print("   📦 Got Data: \(data.count) bytes")
}
```

---

## ✅ Your Current Implementation Status

Your ShareExtension implementation is **already very good** and follows most best practices:

✅ **Correct Info.plist configuration**
✅ **Aggressive type loading** (tries multiple types)
✅ **Handles URL, Data, and UIImage**
✅ **Format detection from data signatures**
✅ **WhatsApp-specific type identifiers included**

### Recent Improvements Made:

1. ✅ **UnifiedTheme environment** - Prevents blank screens
2. ✅ **Explicit background colors** - Ensures visibility
3. ✅ **Immediate content display** - Shows items preview right away
4. ✅ **Better logging** - Easier debugging

---

## 🚀 Additional Recommendations

### 1. Add More WhatsApp Type Identifiers

Consider adding more dynamic identifiers if you encounter issues:

```swift
let whatsappTypes = [
    "dyn.ah62d4rv4ge80k5p2", // JPEG
    "dyn.ah62d4rv4ge80k5p3", // PNG
    "dyn.ah62d4rv4ge80k5p4", // HEIC
    "dyn.ah62d4rv4ge80k5p5", // GIF
]
```

### 2. Timeout for Loading

Add a timeout to prevent hanging:

```swift
let timeout: TimeInterval = 10.0
let semaphore = DispatchSemaphore(value: 0)

attachment.loadItem(forTypeIdentifier: typeID, options: nil) { data, error in
    // Process data
    semaphore.signal()
}

if semaphore.wait(timeout: .now() + timeout) == .timedOut {
    print("   ⏱️ Timeout loading \(typeID)")
}
```

### 3. Memory Management

For large images, consider resizing:

```swift
if let image = UIImage(data: imageData) {
    let maxDimension: CGFloat = 2048
    if image.size.width > maxDimension || image.size.height > maxDimension {
        // Resize to prevent memory issues
        let resized = image.resized(to: maxDimension)
        imageData = resized.jpegData(compressionQuality: 0.8)
    }
}
```

---

## 📚 References

- [Apple: Share Extensions](https://developer.apple.com/documentation/xcode/configuring-a-share-extension)
- [Apple: NSItemProvider](https://developer.apple.com/documentation/foundation/nsitemprovider)
- [Apple: Uniform Type Identifiers](https://developer.apple.com/documentation/uniformtypeidentifiers)

---

## 🎯 Summary

**Apps like Preview succeed because they:**
1. ✅ Try multiple type identifiers (even unreported ones)
2. ✅ Handle data in multiple formats (URL, Data, UIImage)
3. ✅ Detect formats from file signatures
4. ✅ Are permissive, not strict
5. ✅ Show UI immediately (don't wait for data)

**Your implementation already follows these patterns!** The recent fixes for the blank screen should resolve the remaining issues.

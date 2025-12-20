# Share to Vault Implementation Guide

## Overview
This document describes how the share to vault feature works across all platforms, allowing users to share content from other applications directly into vaults.

---

## ✅ Android Implementation

### Manifest Configuration
The Android manifest (`AndroidManifest.xml`) includes intent filters to handle shared content:

```xml
<!-- Handle ACTION_SEND for single file/share -->
<intent-filter>
    <action android:name="android.intent.action.SEND" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="*/*" />
</intent-filter>

<!-- Handle ACTION_SEND_MULTIPLE for multiple files -->
<intent-filter>
    <action android:name="android.intent.action.SEND_MULTIPLE" />
    <category android:name="android.intent.category.DEFAULT" />
    <data android:mimeType="*/*" />
</intent-filter>
```

### MainActivity Handling
- `MainActivity.onCreate()` checks for share intent
- Extracts URI from `Intent.EXTRA_STREAM`
- Shows `ShareToVaultView` for vault selection
- After selection, uploads file to selected vault

### ShareToVaultView
- Composable UI for selecting destination vault
- Lists available vaults
- Handles vault selection callback
- Integrates with `DocumentService.uploadDocument()`

### Next Steps:
- [ ] Complete ShareToVaultHandler integration with ContentView
- [ ] Handle multiple files (ACTION_SEND_MULTIPLE)
- [ ] Add progress indicator during upload
- [ ] Show success/error messages

---

## ✅ Windows Implementation

### Package.appxmanifest Configuration
The Windows manifest (`Package.appxmanifest`) includes Share Target declaration:

```xml
<uap:Extension Category="windows.shareTarget">
  <uap:ShareTarget Description="Share to Khandoba Secure Docs Vault">
    <uap:SupportedFileTypes>
      <!-- Images: jpg, jpeg, png, gif, bmp, heic -->
      <!-- Documents: pdf, doc, docx, xls, xlsx, ppt, pptx, txt -->
      <!-- Video: mp4, mov, avi -->
      <!-- Audio: mp3, m4a, wav -->
    </uap:SupportedFileTypes>
    <uap:DataFormat>File</uap:DataFormat>
    <uap:DataFormat>Bitmap</uap:DataFormat>
    <uap:DataFormat>Text</uap:DataFormat>
    <uap:DataFormat>Uri</uap:DataFormat>
    <uap:DataFormat>StorageItems</uap:DataFormat>
  </uap:ShareTarget>
</uap:Extension>
```

### App.xaml.cs Activation
- `OnLaunched()` checks for `ActivationKind.ShareTarget`
- Handles `ShareTargetActivatedEventArgs`
- Passes shared content to MainWindow or dedicated handler

### Next Steps:
- [ ] Create ShareTargetHandler view/page
- [ ] Implement vault selection UI
- [ ] Integrate with DocumentService.UploadDocumentAsync()
- [ ] Handle different data formats (File, Bitmap, Text, Uri, StorageItems)

---

## ⚠️ Apple Implementation (Guide)

### Share Extension Target
To implement share to vault on Apple platforms, you need to:

1. **Create Share Extension Target** (in Xcode):
   - File → New → Target
   - Choose "Share Extension"
   - Name: "KhandobaSecureDocsShareExtension"

2. **Info.plist Configuration**:
```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <dict>
            <key>NSExtensionActivationSupportsFileWithMaxCount</key>
            <integer>10</integer>
            <key>NSExtensionActivationSupportsImageWithMaxCount</key>
            <integer>10</integer>
            <key>NSExtensionActivationSupportsMovieWithMaxCount</key>
            <integer>10</integer>
            <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
            <integer>1</integer>
            <key>NSExtensionActivationSupportsWebPageWithMaxCount</key>
            <integer>1</integer>
        </dict>
    </dict>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
</dict>
```

3. **ShareViewController Implementation**:
   - Handle `SLComposeServiceViewController`
   - Present vault selection UI
   - Upload to selected vault using App Group for data sharing
   - Call `DocumentService.uploadDocument()`

4. **App Group Configuration**:
   - Enable App Groups capability
   - Share identifier: `group.com.khandoba.securedocs`
   - Use shared UserDefaults/FileManager for communication

### Current Status:
- ⚠️ Share Extension target not yet created (requires Xcode)
- ✅ App Group capability likely already configured (referenced in code)
- 📝 Implementation guide provided above

---

## Implementation Checklist

### Android ✅
- [x] Intent filters added to AndroidManifest.xml
- [x] MainActivity handles share intents
- [x] ShareToVaultView composable created
- [ ] Complete integration with ContentView navigation
- [ ] Test with various file types

### Windows ✅
- [x] Share Target declared in Package.appxmanifest
- [x] App.xaml.cs checks for share activation
- [ ] Create ShareTargetHandler view
- [ ] Implement vault selection UI
- [ ] Test share activation

### Apple ⚠️
- [ ] Create Share Extension target in Xcode
- [ ] Configure Info.plist for extension
- [ ] Implement ShareViewController
- [ ] Configure App Group if needed
- [ ] Test share from various apps

---

## Testing

### Android:
1. Share an image from Gallery
2. Select "Khandoba Secure Docs" from share sheet
3. Select a vault
4. Verify file appears in vault

### Windows:
1. Right-click a file → Share
2. Select "Khandoba Secure Docs"
3. Select a vault
4. Verify file appears in vault

### Apple:
1. Share a document from Files app
2. Tap "Khandoba Secure Docs" extension
3. Select a vault
4. Verify file appears in vault

---

**Last Updated**: Current session
**Status**: Android & Windows configuration complete, Apple requires Xcode project modifications

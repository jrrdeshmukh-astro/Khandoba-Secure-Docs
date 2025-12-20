# Installing Cursor Extensions - Quick Guide

> Step-by-step guide to install recommended extensions in Cursor

---

## Method 1: Automatic (Recommended)

When you open this project in Cursor, you should see a notification:

**"This workspace has extension recommendations. Would you like to install them?"**

Click **"Install All"** to install all recommended extensions automatically.

If you don't see the notification:
1. Press `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux)
2. Type "Extensions: Show Recommended Extensions"
3. Click "Install All" in the recommendations panel

---

## Method 2: Manual Installation

### Universal Extensions (All Platforms)

1. Press `Cmd+Shift+X` (macOS) or `Ctrl+Shift+X` (Windows/Linux) to open Extensions
2. Search and install each extension:

**Essential:**
- **GitLens** (`eamodio.gitlens`) - Enhanced Git capabilities
- **Error Lens** (`usernamehw.errorlens`) - Inline error highlighting
- **Todo Tree** (`Gruntfuggly.todo-tree`) - TODO comment tracking
- **Markdown All in One** (`yzhang.markdown-all-in-one`) - Markdown editing

---

### Apple/Swift Extensions

1. **Swift Language Support** (`sswg.swift-lang`)
   - Search: "Swift Language Support"
   - Provides: Syntax highlighting, basic IntelliSense

2. **Sweetpad** (Recommended for Swift builds)
   - Search: "Sweetpad"
   - Provides: Build, run, debug Swift projects in Cursor
   - Alternative: **FlowDeck** (search "FlowDeck")

---

### Android/Kotlin Extensions

1. **Kotlin Language** (`fwcd.kotlin`)
   - Search: "Kotlin Language" by Mathias Frøhlich
   - Provides: Syntax highlighting, code completion

2. **Extension Pack for Java** (`vscjava.vscode-java-pack`)
   - Search: "Extension Pack for Java" by Microsoft
   - Provides: Java language support, debugger, test runner (required for Android)

3. **Gradle for Java** (`vscjava.vscode-gradle`)
   - Search: "Gradle for Java" by Microsoft
   - Provides: Gradle build system support

**After installing Java extensions:**
- Configure JDK path if needed:
  - `Cmd/Ctrl+,` → Search "java.home"
  - Set path to your JDK 17+ installation

---

### Windows/.NET Extensions

1. **C# Dev Kit** (`ms-dotnettools.csdevkit`)
   - Search: "C# Dev Kit" by Microsoft
   - Provides: Comprehensive .NET development (includes C# extension)

2. **.NET MAUI Extension** (Optional, if developing .NET MAUI apps)
   - Search: ".NET MAUI" by Microsoft
   - Provides: Cross-platform .NET app development

---

## Method 3: Command Line (If Available)

If the `cursor` command is available in your terminal:

```bash
# Universal extensions
cursor --install-extension eamodio.gitlens
cursor --install-extension usernamehw.errorlens
cursor --install-extension Gruntfuggly.todo-tree
cursor --install-extension yzhang.markdown-all-in-one

# Apple/Swift
cursor --install-extension sswg.swift-lang

# Android/Kotlin
cursor --install-extension fwcd.kotlin
cursor --install-extension vscjava.vscode-java-pack
cursor --install-extension vscjava.vscode-gradle

# Windows/.NET
cursor --install-extension ms-dotnettools.csdevkit
cursor --install-extension ms-dotnettools.csharp
```

---

## Verification

After installing extensions:

1. **Check installed extensions:**
   - Press `Cmd+Shift+X` / `Ctrl+Shift+X`
   - Click "Installed" in the sidebar
   - Verify all recommended extensions are listed

2. **Reload Cursor:**
   - Press `Cmd+Shift+P` / `Ctrl+Shift+P`
   - Type "Developer: Reload Window"
   - Press Enter

---

## Troubleshooting

### Extensions Not Installing

**Issue:** Can't install extensions from marketplace

**Solutions:**
1. Check internet connection
2. Restart Cursor
3. Try installing one extension at a time
4. Check Cursor is up to date

### Extension Not Working

**Issue:** Extension installed but not working

**Solutions:**
1. Reload Cursor window
2. Check extension requirements (e.g., JDK for Java extensions)
3. Check extension output panel for errors:
   - View → Output → Select extension name
4. Disable and re-enable the extension

### Java Extensions Not Working

**Issue:** Java/Kotlin extensions can't find JDK

**Solution:**
1. Install JDK 17+ if not installed
2. Configure in Cursor settings:
   ```json
   {
     "java.jdt.ls.java.home": "/path/to/jdk-17"
   }
   ```
3. Reload Cursor

---

## Extension List Summary

### All Platforms
- ✅ GitLens
- ✅ Error Lens
- ✅ Todo Tree
- ✅ Markdown All in One

### Apple/Swift
- ✅ Swift Language Support
- ⚠️ Sweetpad or FlowDeck (manual search)

### Android/Kotlin
- ✅ Kotlin Language
- ✅ Extension Pack for Java
- ✅ Gradle for Java

### Windows/.NET
- ✅ C# Dev Kit
- ⚠️ .NET MAUI Extension (optional)

---

**Tip:** The `.vscode/extensions.json` file in this project automatically recommends these extensions. Cursor will prompt you to install them when you open the project!

---

**Last Updated:** December 2024

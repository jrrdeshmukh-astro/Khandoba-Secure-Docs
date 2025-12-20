# Windows Project on macOS

## Important Note

This Windows project (WinUI 3) can be **edited** in Cursor on macOS, but cannot be **built or run** on macOS. Building requires Windows with Visual Studio or .NET SDK on Windows.

## What Works on macOS

✅ **Code Editing** - Edit C# files, XAML, configuration files  
✅ **IntelliSense** - C# code completion (with C# Dev Kit extension)  
✅ **Syntax Highlighting** - All code files  
✅ **Project Loading** - Project file loads in Cursor  
⚠️ **Package Restore** - May have limited success on macOS  

## What Doesn't Work on macOS

❌ **Building** - Requires Windows SDK and Windows-specific tools  
❌ **Running** - Windows executables require Windows OS  
❌ **Full Package Restore** - Some Windows-specific packages may fail  

## To Build This Project

You must use:
- **Windows 10/11** with Visual Studio 2022 or .NET 8 SDK
- Or use a Windows VM/remote machine
- Or use GitHub Actions/CI/CD on Windows runners

## Editing on macOS

The project is configured to allow loading on macOS for editing purposes. You can:
1. Open the project in Cursor
2. Edit code files
3. Use AI assistance
4. Review code
5. Commit changes

But you'll need Windows to actually build and test.

---

**Last Updated:** December 2024

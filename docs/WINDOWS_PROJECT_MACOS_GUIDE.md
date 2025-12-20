# Windows Project in Cursor on macOS - Quick Guide

> Quick reference for editing Windows/.NET projects in Cursor on macOS

---

## ✅ What Works

**Code Editing:**
- ✅ Edit C# code files
- ✅ Edit XAML files  
- ✅ Syntax highlighting
- ✅ Basic code navigation
- ✅ Cursor AI features (code generation, refactoring)
- ✅ Git operations
- ✅ Multi-file editing

**Limited Support:**
- ⚠️ Basic IntelliSense (limited without package restore)
- ⚠️ Code completion (partial)
- ⚠️ Error checking (syntax only, not semantic)

---

## ❌ What Doesn't Work

- ❌ **Package restore** - Windows-specific packages can't be restored on macOS
- ❌ **Building** - Requires Windows SDK
- ❌ **Running** - Windows executables require Windows OS
- ❌ **Full IntelliSense** - Requires successful package restore
- ❌ **Debugging** - Requires Windows environment

---

## 🔧 Expected Warnings

When opening a Windows project in Cursor on macOS, you'll see:

### Normal Warnings (Safe to Ignore)

1. **"Project has unresolved dependencies"**
   - ✅ **Expected** - Windows packages can't restore on macOS
   - ✅ **Safe to ignore** - Doesn't affect code editing

2. **"Unable to load service index for NuGet"**
   - ✅ **Expected** - Network/package restore issues
   - ✅ **Safe to ignore** - For editing purposes only

3. **"Error while loading project"**
   - ⚠️ Check if `EnableWindowsTargeting=true` is set (should be in .csproj)
   - ⚠️ May indicate missing files (check `app.manifest` exists)

### How to Check Project Configuration

Verify your `.csproj` file has:

```xml
<PropertyGroup>
  <EnableWindowsTargeting>true</EnableWindowsTargeting>
  <!-- RuntimeIdentifiers should NOT be present for macOS editing -->
</PropertyGroup>
```

---

## 🚀 Quick Start Workflow

### 1. Open Project in Cursor

```bash
cursor "Khandoba Secure Docs/platforms/windows"
```

### 2. Reload Window (Clear Stale Errors)

- `Cmd+Shift+P` → "Developer: Reload Window"

### 3. Start Editing

- Edit code files normally
- Use Cursor AI features (`Cmd+K` or `Cmd+L`)
- Ignore package restore warnings

### 4. Build/Test on Windows

When ready to build:
- Transfer code to Windows machine
- Or use CI/CD (GitHub Actions with Windows runner)
- Or use Windows VM

---

## 📋 Daily Workflow

### Morning Setup

1. Open project in Cursor
2. Reload window to clear errors
3. Ignore "unresolved dependencies" warnings
4. Start coding

### During Development

- ✅ Use Cursor AI for code generation
- ✅ Edit code freely
- ✅ Commit changes regularly
- ⚠️ Accept that IntelliSense is limited

### Testing/Building

- Transfer to Windows environment
- Or push to GitHub and use CI/CD
- Or use remote Windows machine

---

## 🔍 Troubleshooting

### Issue: Project Won't Load

**Symptoms:** Constant errors, project won't open

**Solutions:**
1. Check `.csproj` has `<EnableWindowsTargeting>true</EnableWindowsTargeting>`
2. Verify `app.manifest` exists (if referenced)
3. Reload window: `Cmd+Shift+P` → "Developer: Reload Window"
4. Check C# extension is installed (C# Dev Kit)

### Issue: No IntelliSense

**Symptoms:** No code completion, no suggestions

**Solutions:**
1. This is **expected** - IntelliSense requires package restore
2. Still works for:
   - Syntax highlighting
   - Basic code structure
   - AI-assisted coding (Cursor)
3. For full IntelliSense, use Windows environment

### Issue: Too Many Warnings

**Symptoms:** Constant warnings in output panel

**Solutions:**
1. Warnings are **normal** and **safe to ignore**
2. Filter output: View → Output → Select different output source
3. Focus on Problems panel instead (actual syntax errors only)

### Issue: Files Not Recognized

**Symptoms:** `.cs` files show as plain text

**Solutions:**
1. Install C# Dev Kit extension
2. Reload window
3. Check file associations in settings

---

## 💡 Pro Tips

### Tip 1: Use Cursor AI Extensively

Since IntelliSense is limited, leverage Cursor's AI:
- `Cmd+K` - Edit selected code with AI
- `Cmd+L` - Chat with AI about code
- `Cmd+I` - Inline AI suggestions

### Tip 2: Organize by File Type

Focus on editing, not building:
- Edit `.cs` files (business logic)
- Edit `.xaml` files (UI markup)
- Edit config files
- Skip worrying about builds

### Tip 3: Regular Commits

Commit frequently so you can:
- Test on Windows easily
- Rollback if needed
- Share with team

### Tip 4: Use GitHub Actions

Set up CI/CD to automatically:
- Build on Windows runners
- Run tests
- Validate changes

---

## 🔄 Recommended Setup

### Development Environment

**On macOS (Cursor):**
- ✅ Code editing
- ✅ AI-assisted development
- ✅ Version control
- ✅ Documentation

**On Windows (Visual Studio):**
- ✅ Building
- ✅ Testing
- ✅ Debugging
- ✅ Package management

### Alternative: Windows VM

If you need both in one place:
- Parallels Desktop / VMware Fusion
- Windows 11 VM
- Full development environment

---

## 📝 File Checklist

When opening Windows project in Cursor:

- [ ] `.csproj` has `EnableWindowsTargeting=true`
- [ ] `app.manifest` exists (if referenced)
- [ ] No `RuntimeIdentifiers` in `.csproj` (for macOS editing)
- [ ] C# Dev Kit extension installed
- [ ] Window reloaded after opening

---

## 🎯 Common Tasks

### Task: Add New C# File

1. Create file: `NewFile.cs`
2. Write code (with AI assistance)
3. Add to project if needed
4. Commit changes
5. Build on Windows to verify

### Task: Modify Existing Code

1. Open file in Cursor
2. Edit with AI assistance (`Cmd+K`)
3. Use syntax highlighting
4. Commit changes
5. Test on Windows

### Task: Add NuGet Package

1. Edit `.csproj` file
2. Add `<PackageReference>` entry
3. Commit changes
4. Restore on Windows machine
5. Use in code

---

## ⚠️ Important Notes

1. **Warnings are Normal**
   - Package restore warnings are expected
   - Don't try to "fix" them on macOS
   - They won't affect code editing

2. **Building Requires Windows**
   - You cannot build Windows projects on macOS
   - This is a platform limitation
   - Use Windows VM or remote Windows machine

3. **IntelliSense is Limited**
   - Accept reduced IntelliSense
   - Use Cursor AI as supplement
   - Full features require Windows

---

## 🔗 Related Documentation

- [Development Environment Setup](DEVELOPMENT_ENVIRONMENT.md)
- [Cursor Development Setup](CURSOR_DEVELOPMENT_SETUP.md)
- [Windows Setup Guide](windows/SETUP.md)
- [Feature Parity Roadmap](FEATURE_PARITY_ROADMAP.md)

---

## 📞 Quick Commands Reference

| Task | Command |
|------|---------|
| Reload window | `Cmd+Shift+P` → "Developer: Reload Window" |
| AI edit | `Cmd+K` |
| AI chat | `Cmd+L` |
| Show output | `Cmd+Shift+U` |
| Show problems | `Cmd+Shift+M` |
| Go to file | `Cmd+P` |

---

**Remember: These warnings are cosmetic. Your code editing works perfectly!** ✨

---

**Last Updated:** December 2024

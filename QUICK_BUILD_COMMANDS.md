# Quick Build Commands for v1.0.1

## 🚀 Fastest Way to Build

### Step 1: Validate Configuration
```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
./scripts/validate_for_transporter.sh
```
**Note:** StoreKit warning is OK - you have a paid app, not subscriptions.

### Step 2: Build & Export IPA
```bash
./scripts/prepare_for_transporter.sh
```

**This will:**
1. Clean previous builds
2. Verify configuration
3. Create archive
4. Export IPA for App Store
5. Show upload instructions

**Duration:** 5-10 minutes

**Output:** `./build/Final_IPA/Khandoba Secure Docs.ipa`

---

## 📤 Upload to App Store Connect

### Option A: Transporter App (Easiest)

1. Open **Transporter** app
2. Click **"+"** button
3. Select: `./build/Final_IPA/Khandoba Secure Docs.ipa`
4. Click **"Deliver"**
5. Wait 10-20 minutes

### Option B: Xcode Organizer

1. Open Xcode
2. Window → Organizer (Cmd+Shift+O)
3. Select archive
4. Click **"Distribute App"**
5. Select **"App Store Connect"**
6. Click **"Upload"**

---

## ✅ Verify Version Before Building

```bash
# Check version in project file
grep "MARKETING_VERSION" "Khandoba Secure Docs.xcodeproj/project.pbxproj" | head -1
# Should show: MARKETING_VERSION = 1.0.1;

grep "CURRENT_PROJECT_VERSION" "Khandoba Secure Docs.xcodeproj/project.pbxproj" | head -1
# Should show: CURRENT_PROJECT_VERSION = 29;
```

---

## 🎯 One-Command Build (If Scripts Work)

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs" && ./scripts/prepare_for_transporter.sh && echo "✅ Build complete! IPA ready at: ./build/Final_IPA/Khandoba Secure Docs.ipa"
```

---

**Ready to build!** 🚀

# 📱 Capture Native iPad Screenshots - Step by Step

## 🎯 Goal
Capture proper iPad screenshots that aren't stretched from iPhone versions

---

## 🚀 Quick Steps

### **Step 1: Open iPad Simulator**

**In Terminal:**
```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Boot iPad Pro 13-inch simulator
xcrun simctl boot "iPad Pro (13-inch) (M4)" 2>/dev/null

# Open Simulator app
open -a Simulator

# Wait for it to boot
sleep 5

# Set to dark mode
xcrun simctl ui booted appearance dark
```

**Or manually:**
1. Open **Simulator** app
2. **File → Open Simulator → iPad Pro (13-inch)**
3. Wait for it to boot
4. **Features → Appearance → Dark**

---

### **Step 2: Build and Run App on iPad**

**In Terminal:**
```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Build for iPad simulator
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -destination 'platform=iOS Simulator,name=iPad Pro (13-inch) (M4)' \
  build
```

**Or in Xcode:**
1. Select **iPad Pro (13-inch)** as destination
2. Press `Cmd+R` to run
3. App launches on iPad simulator

---

### **Step 3: Take Screenshots**

**In Simulator:**

1. **Navigate to each screen:**
   - Welcome/Sign In
   - Dashboard
   - Vault List
   - Document Search
   - Profile

2. **For each screen, press `Cmd+S`**
   - Simulator captures screenshot
   - Saves to Desktop automatically

3. **Take 5 screenshots total**

**Screenshot locations:**
```
~/Desktop/Simulator Screen Shot - iPad Pro (13-inch) (M4) - 2025-12-03 at XX.XX.XX.png
```

---

### **Step 4: Convert to App Store Format**

**Run this after taking screenshots:**

```bash
cd ~/Desktop

# Create iPad screenshots folder
mkdir -p "/Users/jaideshmukh/Desktop/Khandoba Secure Docs/AppStoreAssets/Screenshots/iPad_Native"

# Convert each screenshot
for img in "Simulator Screen Shot - iPad Pro"*.png; do
  if [ -f "$img" ]; then
    echo "Converting: $img"
    
    # Resize to exact iPad 13" dimensions (2064 x 2752)
    sips -z 2752 2064 "$img" --out "temp_resize.png"
    
    # Convert to JPEG (no alpha)
    sips -s format jpeg -s formatOptions 85 "temp_resize.png" \
      --out "/Users/jaideshmukh/Desktop/Khandoba Secure Docs/AppStoreAssets/Screenshots/iPad_Native/$(basename "$img" .png).jpg"
    
    rm -f "temp_resize.png"
  fi
done

echo "✅ iPad screenshots ready!"
```

---

## 🎯 Automated Script

**I'll create a script to do all of this:**

```bash
#!/bin/bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# 1. Boot iPad simulator
echo "📱 Starting iPad Pro simulator..."
xcrun simctl boot "iPad Pro (13-inch) (M4)" 2>/dev/null
open -a Simulator
sleep 5
xcrun simctl ui booted appearance dark

# 2. Build for iPad
echo "🏗️ Building for iPad..."
xcodebuild -project "Khandoba Secure Docs.xcodeproj" \
  -scheme "Khandoba Secure Docs" \
  -destination 'platform=iOS Simulator,name=iPad Pro (13-inch) (M4)' \
  build

echo ""
echo "✅ iPad simulator ready!"
echo ""
echo "📸 NOW TAKE SCREENSHOTS:"
echo "========================"
echo "1. Navigate to each screen in the app"
echo "2. Press Cmd+S to capture"
echo "3. Take 5 screenshots total"
echo "4. They'll save to your Desktop"
echo ""
echo "When done, run the conversion script to resize them!"
```

---

## 📸 What Screens to Capture

**Capture these 5 screens on iPad:**

1. **Welcome/Sign In**
   - Khandoba logo
   - "Sign in with Apple" button
   - Clean, professional first impression

2. **Dashboard**
   - Vault count, document count, storage
   - Shows app's main features
   - Stats cards visible

3. **Vault List**
   - Multiple vaults displayed
   - Dual-key icon visible
   - "Create Vault" button

4. **Vault Detail / Documents**
   - Open vault showing documents
   - Document list with AI tags
   - Security features visible

5. **Profile / Settings**
   - User profile
   - Settings options
   - Premium status

---

## 📐 Proper iPad Dimensions

**iPad Pro 13-inch (required):**
- **Portrait:** 2064 x 2752
- **Landscape:** 2752 x 2064
- Use portrait (vertical orientation)

**iPad Pro 12.9-inch (optional):**
- **Portrait:** 2048 x 2732
- **Landscape:** 2732 x 2048

---

## ⚡ Quick Method

**If you want native iPad screenshots RIGHT NOW:**

1. **Run app on iPad simulator** (Xcode or command above)
2. **Press `Cmd+S`** five times on different screens
3. **Find screenshots** on Desktop
4. **Run conversion script** to resize and remove alpha
5. **Upload to App Store Connect** iPad tab

**Time:** ~15 minutes for perfect iPad screenshots!

---

## 🎯 Why Native iPad Screenshots are Better

**Auto-resized from iPhone:**
- ❌ Wrong aspect ratio
- ❌ Stretched/squashed UI
- ❌ Looks unprofessional
- ❌ Doesn't show iPad layout

**Native iPad screenshots:**
- ✅ Correct aspect ratio
- ✅ Proper iPad UI layout
- ✅ Professional appearance
- ✅ Shows how app looks on iPad

---

## 📋 Next Steps

1. **Boot iPad simulator** (command or Xcode)
2. **Run your app**
3. **Take 5 screenshots** (`Cmd+S`)
4. **Convert to JPEG** (run conversion script)
5. **Upload to App Store Connect** (iPad tab)

**Want me to create an automated script for you?** (Switch to Agent mode)


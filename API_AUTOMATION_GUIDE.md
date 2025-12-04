# 🤖 App Store Connect API Automation

**Status:** ✅ Scripts Created  
**Approach:** Hybrid (API + Manual)

---

## 🚀 CREATED SCRIPTS:

### 1. `scripts/generate_jwt.sh`
- Generates JWT tokens for API authentication
- Uses your API key (PR62QK662L)
- Valid for 20 minutes
- Required for all API calls

### 2. `scripts/submit_to_appstore_api.sh`
- Complete automation script
- Uses App Store Connect API
- Handles metadata, build linking, submission

### 3. `scripts/upload_to_testflight.sh`
- Already exists and working!
- Uploads builds to TestFlight

---

## 📋 WHAT CAN BE AUTOMATED:

**✅ Via API (Automated):**
1. ✅ Upload build to TestFlight
2. ✅ Create app version (1.0)
3. ✅ Update app description
4. ✅ Set keywords
5. ✅ Set promotional text
6. ✅ Set support URL
7. ✅ Link build to version
8. ✅ Submit for review

**⚠️ Requires Manual (API Limitations):**
1. ❌ Create subscription (MUST be done in browser)
2. ⚠️ Upload screenshots (API possible but complex)
3. ⚠️ Upload app preview video (API possible but complex)

---

## 🎯 RECOMMENDED WORKFLOW:

### Option A: Maximum Automation (What I Built)

**Run this command:**
```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
./scripts/submit_to_appstore_api.sh
```

**This will:**
1. Upload build to TestFlight
2. Wait for processing
3. Create version 1.0
4. Set all metadata
5. Link build
6. Submit for review

**Then manually (15 min):**
1. Create subscription in browser
2. Upload 5 screenshots
3. Upload app preview (optional)

---

### Option B: Hybrid (Recommended - Faster)

**1. Upload Build (Automated - 5 min):**
```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Increment build
agvtool next-version -all

# Upload
./scripts/upload_to_testflight.sh
```

**2. Complete in Browser (20 min):**
- Create subscription
- Upload screenshots  
- Set metadata
- Submit

**Why Recommended:**
- Browser is actually faster for screenshots/subscription
- Drag & drop is easier than API multipart upload
- Subscription MUST be done in browser anyway
- Less error-prone

---

## 🔧 FULL API COMMAND (If You Want It):

**Complete automation command:**

```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# 1. Increment build number
agvtool next-version -all

# 2. Run complete API submission
./scripts/submit_to_appstore_api.sh

# This will:
# - Upload build to TestFlight
# - Set all metadata
# - Submit for review
# - Print what needs manual work
```

---

## ⚠️ IMPORTANT: Subscription Creation

**This CANNOT be automated via API!**

**You MUST manually:**
1. Go to https://appstoreconnect.apple.com/apps/6753986878
2. Features → Subscriptions
3. Create: com.khandoba.premium.monthly
4. Price: $5.99/month
5. Family Sharing: ON

**Apple doesn't provide API endpoints for subscription creation.**

---

## 📸 Screenshot Upload (Optional API Method)

**If you want to automate screenshots via API:**

```bash
# Create this script: scripts/upload_screenshots_api.sh

#!/bin/bash
JWT=$(./scripts/generate_jwt.sh)

# 1. Reserve screenshot slot
# 2. Upload image file
# 3. Commit upload
# (Complex 3-step process)
```

**But honestly:** Drag & drop in browser is faster! 😄

---

## 🎯 MY RECOMMENDATION:

**Use the hybrid approach:**

**Run API script:**
```bash
./scripts/upload_to_testflight.sh
```

**Then in browser (15 min):**
1. Create subscription
2. Drag 5 screenshots
3. Submit

**Why:**
- ✅ Faster overall
- ✅ Less error-prone
- ✅ Subscription must be manual anyway
- ✅ Screenshots drag & drop is instant

---

## 🚀 READY TO GO:

**All scripts are created and executable!**

**Next command:**
```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"

# Option 1: Just upload build
./scripts/upload_to_testflight.sh

# Option 2: Full API automation (metadata + submit)
./scripts/submit_to_appstore_api.sh
```

---

**Scripts are ready! Run the upload command now!** 🚀


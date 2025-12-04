# 🚀 TestFlight Upload Instructions

## ✅ Build #3 is Ready!

**IPA Created:** ✅ `build/Khandoba Secure Docs.ipa` (13 MB)  
**Build Number:** 3  
**Version:** 1.0

---

## ⚠️ API Key Issue

The App Store Connect API key authentication failed with error 401. This could be due to:
- API key permissions not properly configured in App Store Connect
- API key expired
- Team ID mismatch

---

## 🎯 Upload Methods (Choose One)

### Option 1: Xcode Organizer (Recommended - Most Reliable)

**Steps:**
1. Open Xcode
2. Go to **Window** → **Organizer** (or `Cmd+Option+Shift+O`)
3. Click **Archives** tab on the left
4. Find **Khandoba Secure Docs** (build 3)
5. Click **Distribute App**
6. Select **App Store Connect**
7. Click **Upload**
8. Select **Automatically manage signing**
9. Click **Upload**
10. ✅ Done!

**Time:** ~5 minutes

---

### Option 2: Open Archive Directly

**Command just executed:**
```bash
open Archives/*.xcarchive
```

**This opens Xcode Organizer automatically with your build selected.**

**Then:**
1. Click **Distribute App**
2. Follow steps 6-10 above

---

### Option 3: Fix API Key and Use Script

**If you want to use API automation:**

**1. Check API Key Permissions in App Store Connect:**
```
https://appstoreconnect.apple.com/access/integrations/api
→ Find key "PR62QK662L"
→ Ensure it has "Admin" or "App Manager" role
→ Verify it hasn't expired
```

**2. Regenerate Key if Needed:**
```
→ Revoke old key
→ Create new key with "App Manager" role
→ Download new .p8 file
→ Update scripts with new key ID
```

**3. Re-run Upload:**
```bash
./scripts/upload_to_testflight.sh
```

---

### Option 4: Use Transporter App

**Apple's Official Upload Tool:**

**Steps:**
1. Download **Transporter** from Mac App Store
2. Open Transporter
3. Sign in with your Apple ID
4. Drag & drop `build/Khandoba Secure Docs.ipa`
5. Click **Deliver**
6. ✅ Done!

**Time:** ~3 minutes  
**Success Rate:** Very high

---

## 📊 What's in Build #3

**All Fixes Included:**
- ✅ Video recording live preview
- ✅ Access event logging (created, opened, closed, upload)
- ✅ Access Map metadata summary
- ✅ Dual-key unlock request banner
- ✅ Profile tab theme fixed
- ✅ Unified sharing flow (nominees + transfer)
- ✅ Intel Vault pre-loaded for ALL users
- ✅ Concurrent access model clarified
- ✅ ML threat monitoring
- ✅ Enhanced Access Maps

---

## ⏱️ Processing Time

**After Upload:**
- Upload to Apple: ~10 minutes
- Apple Processing: ~10-20 minutes
- **Total:** ~30 minutes until "Ready to Test"

**Check Status:**
https://appstoreconnect.apple.com/apps/6753986878/testflight/ios

---

## 🎯 Recommended: Use Xcode Organizer

**Why:**
- ✅ Most reliable (built into Xcode)
- ✅ No API key issues
- ✅ Handles signing automatically
- ✅ Shows progress clearly
- ✅ Error handling built-in

**Already running:** The `open Archives/*.xcarchive` command should have opened Xcode Organizer.

**If not open:**
```bash
cd "/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
open Archives/*.xcarchive
```

**Or manually:**
1. Open Xcode
2. Window → Organizer
3. Find Khandoba Secure Docs build 3
4. Distribute App → Upload

---

## ✅ After Upload Completes

**While Build Processes (~30 min), Complete These:**

### 1. Create Subscription (10 min)
```
https://appstoreconnect.apple.com/apps/6753986878/features
→ Subscriptions → Create
→ Product ID: com.khandoba.premium.monthly
→ Price: $5.99/month
→ Family Sharing: ON
```

### 2. Prepare Screenshots (Already Done!)
```
Location: AppStoreAssets/Screenshots/
Files: 5 screenshots ready
```

### 3. Set Metadata
```
Description: See AppStoreAssets/METADATA.md
Keywords: secure,vault,documents,encryption,HIPAA,medical,legal,AI
Promo: Bank-level security for your documents. $5.99/month.
```

---

## 🎊 You're Almost There!

**Current Status:**
- ✅ Build #3 created (13 MB)
- ✅ All fixes included
- ⏳ Upload in progress (use Xcode Organizer)
- ⏳ 30 minutes until submission ready

**Next:** Upload via Xcode Organizer, then complete App Store listing! 🚀


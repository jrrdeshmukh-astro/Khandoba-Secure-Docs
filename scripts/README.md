# 📋 Scripts Directory

**Streamlined scripts for App Store submission**

---

## 🚀 Main Scripts:

### `submit_to_appstore.sh` ⭐
**Complete App Store submission workflow**

```bash
./scripts/submit_to_appstore.sh
```

**What it does:**
- Prompts for Issuer ID
- Opens App Store Connect
- Shows all metadata to copy-paste
- Guides through final submission

**Time:** 5 minutes + manual steps  
**Use:** After build is in TestFlight

---

### `build_production.sh`
**Build for production with Xcode CLI**

```bash
./scripts/build_production.sh
```

**What it does:**
- Cleans build folder
- Builds for iOS Release configuration
- Validates no errors

**Time:** 2-3 minutes  
**Use:** Verify build before submission

---

### `final_submit.sh`
**Final verification before clicking Submit**

```bash
./scripts/final_submit.sh
```

**What it does:**
- Interactive checklist
- Confirms all requirements met
- Opens browser to submission page
- Guides final click

**Time:** 5 minutes  
**Use:** After all metadata and screenshots are added

---

## 📚 Documentation:

All metadata and instructions are in the root folder:
- `FINAL_SUBMISSION.md` - Copy-paste text
- `AppStoreAssets/METADATA.md` - Complete metadata
- `START_HERE.md` - Quick start

---

## ✅ Complete Workflow:

```bash
# 1. Build for production (optional - verify build)
./scripts/build_production.sh

# 2. Submit to App Store (opens browser, shows metadata)
./scripts/submit_to_appstore.sh

# 3. Complete steps in browser (30 min)
# - Add description, keywords, URLs
# - Upload screenshots
# - Create subscription
# - Select build

# 4. Final verification and submit
./scripts/final_submit.sh
```

**Total Time:** ~40 minutes  
**Result:** App submitted! 🎉

---

## 🎯 Quick Submit:

**If everything is ready:**

```bash
./scripts/final_submit.sh
```

**This is your FINAL command!**

---

**All scripts are ready to use!** 🚀

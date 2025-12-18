# Quick Update Guide - Khandoba v1.0.1

**For updating existing app from 1.0.0 to 1.0.1**

---

## 🎯 Quick Summary

Since **Khandoba v1.0.0** is already live on the App Store, this is a straightforward update process.

**Key Differences from New Submission:**
- ✅ App listing already exists
- ✅ Subscriptions already created
- ✅ Screenshots can be reused (if UI unchanged)
- ✅ Faster review process (typically 24-48 hours)
- ✅ No need to create new app

---

## 📋 Update Checklist

### Before Building
- [ ] Increment version to **1.0.1** in Xcode
- [ ] Increment build number (e.g., 29)
- [ ] Test all new features
- [ ] Verify existing features still work
- [ ] Check for breaking changes

### Before Uploading
- [ ] Build archive for App Store
- [ ] Validate archive
- [ ] Export IPA
- [ ] Verify bundle ID matches existing app

### Before Submitting
- [ ] Create new version (1.0.1) in App Store Connect
- [ ] Write "What's New" text
- [ ] Add new build to version
- [ ] Update screenshots (if UI changed)
- [ ] Review all metadata

---

## 🚀 Quick Update Steps

### Step 1: Build & Upload (30 minutes)

1. **In Xcode:**
   - Set version: **1.0.1**
   - Set build: **29** (or next number)
   - Select "Generic iOS Device"
   - Product → Archive

2. **Validate & Upload:**
   - In Organizer, click "Validate App"
   - Fix any issues
   - Click "Distribute App" → "App Store Connect" → "Upload"

### Step 2: Create New Version (10 minutes)

1. **App Store Connect:**
   - Go to: My Apps → Khandoba
   - Click "+ Version or Platform"
   - Enter version: **1.0.1**

2. **Add Build:**
   - Wait for build to process (10-15 minutes)
   - Click "+" next to Build
   - Select your new build

### Step 3: Update Metadata (15 minutes)

1. **What's New:**
   - Write update description
   - Highlight new features/fixes

2. **Screenshots:**
   - Reuse existing (if UI unchanged)
   - Or update if UI changed

3. **Review:**
   - Check all information
   - Verify build is correct

### Step 4: Submit (5 minutes)

1. **Review Summary:**
   - Check all items
   - Verify version number

2. **Submit:**
   - Click "Submit for Review"
   - Confirm submission

---

## 📝 What's New Template

Use this template for your update description:

```
Version 1.0.1 - Update

✨ IMPROVEMENTS:
• Fixed transfer ownership flow - now seamlessly integrates with nominee system
• Enhanced nominee acceptance process
• Improved error handling and user feedback
• Performance optimizations
• Bug fixes and stability improvements

🔧 TECHNICAL UPDATES:
• Updated Supabase integration
• Improved cloud sync reliability
• Enhanced security monitoring
• Better offline support

📱 USER EXPERIENCE:
• Smoother navigation
• Faster document loading
• Improved voice report generation
• Better notification handling

Thank you for using Khandoba! We're constantly improving based on your feedback.
```

---

## ⚠️ Important Notes

### Version Numbering
- **Current Live**: 1.0.0
- **New Version**: 1.0.1
- **Build Number**: Must be higher than previous build

### Breaking Changes
- If you have breaking changes, consider version 1.1.0 instead
- Document any API changes
- Provide migration notes if needed

### Screenshots
- **Can reuse** if UI hasn't changed
- **Must update** if UI changed significantly
- Apple may require new screenshots for major updates

### Subscriptions
- Existing subscriptions continue to work
- No need to recreate unless adding new products
- Verify subscription IDs match in code

---

## 🔍 Common Update Issues

### Build Rejected
- **Check**: Version number must be higher
- **Check**: Build number must be higher
- **Check**: Bundle ID must match exactly

### Screenshots Required
- Even if UI unchanged, Apple may request new screenshots
- Use same screenshots from 1.0.0 if UI is identical
- Update if any UI elements changed

### Review Time
- **Updates**: Typically 24-48 hours
- **Faster** than initial submissions
- **Weekends**: May take longer

---

## ✅ Post-Update Checklist

After approval:
- [ ] Monitor crash reports
- [ ] Check user reviews
- [ ] Verify subscriptions working
- [ ] Test on multiple devices
- [ ] Monitor analytics

---

## 📞 Support

If you encounter issues:
- **App Store Connect Support**: https://help.apple.com/app-store-connect/
- **Your Support**: support@khandoba.org

---

## 🎉 Success!

Once approved, your update will:
- Automatically replace 1.0.0 (if set to auto-release)
- Or wait for manual release
- Users will see update in App Store
- Existing users will be prompted to update

---

**Good luck with your update!** 🚀

**Khandoba v1.0.1 Update Guide**  
**Last Updated: December 18, 2025**

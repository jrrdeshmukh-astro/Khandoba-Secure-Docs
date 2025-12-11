# Website Migration Summary - khandoba.com → khandoba.org

## Overview

All references to `khandoba.com` have been updated to `khandoba.org` throughout the codebase. HTML versions of Terms of Service and Privacy Policy have been created for upload to your website.

## Changes Made

### 1. Code Updates

All Swift files updated to use `khandoba.org`:

- ✅ `Views/Legal/TermsOfServiceView.swift` - Updated links and email
- ✅ `Views/Legal/PrivacyPolicyView.swift` - Updated links and email
- ✅ `Views/Subscription/SubscriptionRequiredView.swift` - Updated Terms/Privacy links
- ✅ `Config/AppConfig.swift` - Updated API base URL

### 2. Documentation Updates

- ✅ `docs/APP_STORE_REVIEW_FIXES.md` - Updated all URLs
- ✅ `docs/APP_STORE_RESUBMISSION_CHECKLIST.md` - Updated all URLs

### 3. Website Files Created

New files in `docs/website/`:

- ✅ `terms-of-service.html` - Complete Terms of Service page
- ✅ `privacy-policy.html` - Complete Privacy Policy page
- ✅ `WEBSITE_UPLOAD_GUIDE.md` - Step-by-step upload instructions
- ✅ `README.md` - Quick reference guide

## URLs Changed

| Old URL | New URL |
|---------|---------|
| `https://khandoba.com/terms` | `https://khandoba.org/terms` |
| `https://khandoba.com/privacy` | `https://khandoba.org/privacy` |
| `https://api.khandoba.com` | `https://api.khandoba.org` |
| `legal@khandoba.com` | `legal@khandoba.org` |
| `privacy@khandoba.com` | `privacy@khandoba.org` |

## Next Steps

### 1. Upload HTML Files to Website

Follow the guide in `docs/website/WEBSITE_UPLOAD_GUIDE.md`:

1. Upload `terms-of-service.html` to `https://khandoba.org/terms`
2. Upload `privacy-policy.html` to `https://khandoba.org/privacy`
3. Verify both URLs are accessible
4. Test links from the app

### 2. Configure Email Addresses

Set up email forwarding or mailboxes:

- `legal@khandoba.org` - For Terms of Service inquiries
- `privacy@khandoba.org` - For Privacy Policy inquiries

### 3. Update App Store Connect

After uploading files to your website:

1. **Privacy Policy URL:**
   - App Store Connect → Your App → App Privacy
   - Set: `https://khandoba.org/privacy`

2. **Terms of Service:**
   - Option A: Add to App Description:
     - "Terms of Service: https://khandoba.org/terms"
   - Option B: Custom EULA:
     - App Store Connect → App Information → License Agreement
     - Link: `https://khandoba.org/terms`

### 4. Test Everything

- [ ] Verify `https://khandoba.org/terms` loads correctly
- [ ] Verify `https://khandoba.org/privacy` loads correctly
- [ ] Test links from the app (Profile → Terms/Privacy)
- [ ] Test links from subscription view
- [ ] Verify email addresses work
- [ ] Test on mobile devices

## File Locations

### Website Files
- `docs/website/terms-of-service.html`
- `docs/website/privacy-policy.html`
- `docs/website/WEBSITE_UPLOAD_GUIDE.md`
- `docs/website/README.md`

### Updated Code Files
- `Khandoba Secure Docs/Views/Legal/TermsOfServiceView.swift`
- `Khandoba Secure Docs/Views/Legal/PrivacyPolicyView.swift`
- `Khandoba Secure Docs/Views/Subscription/SubscriptionRequiredView.swift`
- `Khandoba Secure Docs/Config/AppConfig.swift`

### Updated Documentation
- `docs/APP_STORE_REVIEW_FIXES.md`
- `docs/APP_STORE_RESUBMISSION_CHECKLIST.md`

## Verification

To verify all changes:

```bash
# Search for any remaining khandoba.com references
grep -r "khandoba\.com" "Khandoba Secure Docs" --exclude-dir=archive
```

Should return no results (except in archive files which are historical).

## Notes

- All HTML files are self-contained and mobile-responsive
- Files use professional styling matching your brand
- Email addresses updated to @khandoba.org
- All links in the app now point to khandoba.org
- Documentation updated to reflect new domain

## Support

If you encounter issues:

1. Check `docs/website/WEBSITE_UPLOAD_GUIDE.md` for troubleshooting
2. Verify file permissions on your web server
3. Ensure DNS and SSL certificates are valid
4. Test URLs in multiple browsers

# Website Upload Guide - khandoba.org

This guide explains how to upload the Terms of Service and Privacy Policy to your website at khandoba.org.

## Files to Upload

1. **Terms of Service:** `docs/website/terms-of-service.html`
2. **Privacy Policy:** `docs/website/privacy-policy.html`

## URL Structure

Upload the files to these URLs:
- **Terms of Service:** `https://khandoba.org/terms` (or `https://khandoba.org/terms.html`)
- **Privacy Policy:** `https://khandoba.org/privacy` (or `https://khandoba.org/privacy.html`)

## Upload Methods

### Option 1: Direct File Upload (FTP/SFTP)

1. Connect to your web server via FTP/SFTP
2. Navigate to your website's root directory (usually `public_html`, `www`, or `htdocs`)
3. Upload `terms-of-service.html` to the root directory
4. Upload `privacy-policy.html` to the root directory
5. Rename files if needed:
   - `terms-of-service.html` → `terms.html` (or keep as is)
   - `privacy-policy.html` → `privacy.html` (or keep as is)

### Option 2: Using cPanel File Manager

1. Log into your cPanel account
2. Open "File Manager"
3. Navigate to `public_html` (or your website root)
4. Click "Upload" and select both HTML files
5. After upload, rename if needed to match your URL structure

### Option 3: Using WordPress (if applicable)

1. Log into WordPress admin
2. Go to Pages → Add New
3. Create a new page titled "Terms of Service"
4. Switch to "Text" or "Code" editor
5. Paste the HTML content from `terms-of-service.html` (body content only)
6. Publish the page
7. Set permalink to `/terms`
8. Repeat for Privacy Policy with permalink `/privacy`

### Option 4: Using Static Site Generator

If you're using a static site generator (Jekyll, Hugo, etc.):

1. Copy the HTML files to your static site's content directory
2. Ensure they're accessible at `/terms` and `/privacy`
3. Rebuild and deploy your site

## URL Configuration

### Apache (.htaccess)

If you want clean URLs without `.html` extension, add to your `.htaccess`:

```apache
# Rewrite rules for Terms and Privacy
RewriteEngine On
RewriteRule ^terms$ terms-of-service.html [L]
RewriteRule ^privacy$ privacy-policy.html [L]
```

### Nginx

Add to your Nginx configuration:

```nginx
location = /terms {
    rewrite ^ /terms-of-service.html last;
}

location = /privacy {
    rewrite ^ /privacy-policy.html last;
}
```

## Verification Checklist

After uploading, verify:

- [ ] Terms of Service accessible at `https://khandoba.org/terms`
- [ ] Privacy Policy accessible at `https://khandoba.org/privacy`
- [ ] Both pages load correctly in a web browser
- [ ] Links in the app point to the correct URLs
- [ ] Pages are mobile-responsive (test on phone)
- [ ] SSL certificate is valid (HTTPS works)
- [ ] Pages are indexed by search engines (optional)

## Testing

1. **Direct URL Test:**
   - Open `https://khandoba.org/terms` in a browser
   - Open `https://khandoba.org/privacy` in a browser
   - Verify both pages display correctly

2. **Link Test from App:**
   - Open the app
   - Navigate to Profile → Terms of Service
   - Click "View Full Terms of Service"
   - Verify it opens the website correctly
   - Repeat for Privacy Policy

3. **Mobile Test:**
   - Open the URLs on a mobile device
   - Verify pages are readable and properly formatted

## App Store Connect Configuration

After uploading, update App Store Connect:

1. **Privacy Policy URL:**
   - Go to App Store Connect → Your App → App Privacy
   - Set Privacy Policy URL: `https://khandoba.org/privacy`

2. **Terms of Service:**
   - Option A: Add to App Description:
     - "Terms of Service: https://khandoba.org/terms"
   - Option B: Provide Custom EULA:
     - Go to App Store Connect → App Information → License Agreement
     - Select "Apply a custom EULA"
     - Enter link: `https://khandoba.org/terms`

## Email Configuration

Ensure these email addresses are set up and monitored:

- **Legal inquiries:** `legal@khandoba.org`
- **Privacy inquiries:** `privacy@khandoba.org`

You can set up email forwarding in your domain registrar or hosting provider's control panel.

## Maintenance

- Review and update the documents annually
- Update the "Last Updated" date when making changes
- Keep the HTML files in sync with the in-app content
- Test links periodically to ensure they remain functional

## Support

If you encounter issues:

1. Check file permissions (should be 644 for HTML files)
2. Verify file paths are correct
3. Check server error logs
4. Ensure `.htaccess` rules are correct (if using Apache)
5. Verify DNS and SSL certificate are valid

## File Locations in Repository

- **HTML Files:** `docs/website/terms-of-service.html` and `docs/website/privacy-policy.html`
- **This Guide:** `docs/website/WEBSITE_UPLOAD_GUIDE.md`

## Next Steps

1. Upload both HTML files to your website
2. Verify URLs are accessible
3. Update App Store Connect with the new URLs
4. Test links from the app
5. Monitor email addresses for inquiries

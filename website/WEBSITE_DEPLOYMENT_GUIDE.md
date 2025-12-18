# Website Deployment Guide for khandoba.org

## Overview

This guide explains how to deploy the privacy policy, terms of service, and marketing content to khandoba.org.

---

## Files to Deploy

### Required Pages
1. **Privacy Policy** - `/privacy` or `/privacy-policy`
2. **Terms of Service** - `/terms` or `/terms-of-service`
3. **Homepage** - `/` (using marketing content)
4. **Support** - `/support`

### Optional Pages
- **Features** - `/features`
- **Pricing** - `/pricing`
- **Documentation** - `/docs`

---

## Step 1: Choose Hosting Platform

### Recommended Options

**Option A: GitHub Pages (Free)**
- Pros: Free, easy setup, version control
- Cons: Static pages only
- Best for: Simple website with markdown content

**Option B: Netlify (Free Tier)**
- Pros: Free, automatic deployments, custom domains
- Cons: Limited bandwidth on free tier
- Best for: Static sites with forms

**Option C: Vercel (Free Tier)**
- Pros: Free, fast CDN, easy deployments
- Cons: Limited on free tier
- Best for: React/Next.js sites

**Option D: Traditional Web Hosting**
- Pros: Full control, no limitations
- Cons: Requires server management
- Best for: Existing hosting setup

---

## Step 2: Convert Markdown to HTML

### Option A: Use Static Site Generator

**Jekyll (GitHub Pages Compatible)**
```bash
# Install Jekyll
gem install jekyll bundler

# Create site
jekyll new khandoba-website
cd khandoba-website

# Copy markdown files to _posts or create pages
# Convert to HTML automatically
```

**Hugo (Fast Static Generator)**
```bash
# Install Hugo
brew install hugo

# Create site
hugo new site khandoba-website
cd khandoba-website

# Add content
# Build static site
hugo
```

### Option B: Manual HTML Conversion

Convert each markdown file to HTML:

**Privacy Policy:**
- File: `privacy.html` or `privacy/index.html`
- URL: `https://khandoba.org/privacy`

**Terms of Service:**
- File: `terms.html` or `terms/index.html`
- URL: `https://khandoba.org/terms`

**Homepage:**
- File: `index.html`
- URL: `https://khandoba.org`

---

## Step 3: Website Structure

### Recommended Structure

```
khandoba.org/
├── index.html (Homepage - use marketing content)
├── privacy.html (Privacy Policy)
├── terms.html (Terms of Service)
├── support.html (Support page)
├── features.html (Features page - optional)
├── pricing.html (Pricing page - optional)
├── css/
│   └── style.css (Custom styling)
├── images/
│   ├── logo.png
│   ├── app-icon.png
│   └── screenshots/
└── js/
    └── main.js (Optional JavaScript)
```

---

## Step 4: HTML Template

### Basic HTML Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy - Khandoba Secure Docs</title>
    <meta name="description" content="Privacy Policy for Khandoba Secure Docs - AI-Powered Secure Document Management">
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <nav>
            <a href="/">Home</a>
            <a href="/privacy">Privacy</a>
            <a href="/terms">Terms</a>
            <a href="/support">Support</a>
        </nav>
    </header>
    
    <main>
        <!-- Content from PRIVACY_POLICY.md -->
    </main>
    
    <footer>
        <p>&copy; 2025 Khandoba Secure Docs. All rights reserved.</p>
        <nav>
            <a href="/privacy">Privacy Policy</a>
            <a href="/terms">Terms of Service</a>
            <a href="/support">Support</a>
        </nav>
    </footer>
</body>
</html>
```

---

## Step 5: Styling

### CSS Recommendations

**Create `css/style.css`:**

```css
/* Modern, clean design matching app aesthetic */
:root {
    --primary-color: #FF3B30; /* Red/coral theme */
    --secondary-color: #5856D6; /* Purple */
    --text-primary: #000000;
    --text-secondary: #666666;
    --background: #FFFFFF;
    --surface: #F5F5F5;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    color: var(--text-primary);
    background: var(--background);
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

h1, h2, h3 {
    color: var(--primary-color);
    margin-top: 2em;
}

a {
    color: var(--primary-color);
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

header, footer {
    border-top: 2px solid var(--primary-color);
    padding: 20px 0;
    margin: 40px 0;
}

nav a {
    margin-right: 20px;
}
```

---

## Step 6: Deployment Steps

### GitHub Pages Deployment

1. **Create Repository**
   ```bash
   mkdir khandoba-website
   cd khandoba-website
   git init
   ```

2. **Add Files**
   ```bash
   # Copy HTML files
   cp ../website/*.html .
   
   # Add CSS
   mkdir css
   # Create style.css
   
   # Commit
   git add .
   git commit -m "Initial website deployment"
   ```

3. **Push to GitHub**
   ```bash
   git remote add origin https://github.com/yourusername/khandoba-website.git
   git push -u origin main
   ```

4. **Enable GitHub Pages**
   - Go to repository Settings
   - Pages section
   - Select branch: `main`
   - Select folder: `/ (root)`
   - Save

5. **Custom Domain (Optional)**
   - Add `CNAME` file with: `khandoba.org`
   - Update DNS records:
     - Type: `CNAME`
     - Name: `@` or `www`
     - Value: `yourusername.github.io`

### Netlify Deployment

1. **Sign up** at https://netlify.com
2. **Drag and drop** your website folder
3. **Configure custom domain**: khandoba.org
4. **Update DNS**:
   - Add A record: `185.199.108.153` (Netlify IP)
   - Or CNAME: `your-site.netlify.app`

### Vercel Deployment

1. **Sign up** at https://vercel.com
2. **Import project** from GitHub
3. **Configure** build settings (if needed)
4. **Deploy**

---

## Step 7: Verify URLs

### Required URLs (Must be Live Before App Submission)

1. **Privacy Policy**
   - URL: `https://khandoba.org/privacy`
   - Must be accessible
   - Must match content in `PRIVACY_POLICY.md`

2. **Terms of Service**
   - URL: `https://khandoba.org/terms`
   - Must be accessible
   - Must match content in `TERMS_OF_SERVICE.md`

3. **Support**
   - URL: `https://khandoba.org/support`
   - Can be simple contact form or email link

### Test URLs

Before submitting to App Store, verify:
- [ ] Privacy policy URL loads correctly
- [ ] Terms of service URL loads correctly
- [ ] Support URL loads correctly
- [ ] All links work
- [ ] Mobile-responsive design
- [ ] Fast loading times

---

## Step 8: SEO Optimization

### Meta Tags

Add to each page:

```html
<!-- Privacy Policy -->
<meta name="description" content="Privacy Policy for Khandoba Secure Docs. Learn how we protect your data with zero-knowledge encryption and AI-powered security.">
<meta name="keywords" content="privacy policy, data protection, encryption, secure storage">

<!-- Terms of Service -->
<meta name="description" content="Terms of Service for Khandoba Secure Docs. Read our terms and conditions for using our secure document management app.">

<!-- Homepage -->
<meta name="description" content="Khandoba Secure Docs - AI-Powered Secure Vault with Voice Intelligence. Military-grade encryption, ML auto-approval, and geographic intelligence.">
```

### Open Graph Tags

```html
<meta property="og:title" content="Khandoba Secure Docs">
<meta property="og:description" content="AI-Powered Secure Document Management">
<meta property="og:image" content="https://khandoba.org/images/app-icon.png">
<meta property="og:url" content="https://khandoba.org">
```

---

## Step 9: Content Updates

### Keep Content Updated

- **Privacy Policy**: Update when data practices change
- **Terms of Service**: Update when service terms change
- **Marketing Content**: Update with new features

### Version Control

- Keep markdown source files in repository
- Use Git for version tracking
- Tag releases: `v1.0.1-website`

---

## Quick Start Checklist

### Before Deployment
- [ ] Convert markdown to HTML
- [ ] Create CSS styling
- [ ] Add navigation
- [ ] Test all links
- [ ] Verify mobile responsiveness

### Deployment
- [ ] Choose hosting platform
- [ ] Set up domain (khandoba.org)
- [ ] Deploy files
- [ ] Test all URLs
- [ ] Verify SSL certificate (HTTPS)

### After Deployment
- [ ] Test privacy policy URL
- [ ] Test terms URL
- [ ] Test support URL
- [ ] Submit to search engines (Google, Bing)
- [ ] Monitor analytics

---

## Support Page Content

### Basic Support Page

```html
<h1>Support</h1>

<h2>Get Help</h2>
<p>Need assistance? We're here to help!</p>

<h3>Email Support</h3>
<p>Email us at: <a href="mailto:support@khandoba.org">support@khandoba.org</a></p>
<p>We typically respond within 24 hours.</p>

<h3>Common Questions</h3>
<ul>
    <li><a href="#faq-account">Account Issues</a></li>
    <li><a href="#faq-subscription">Subscription Questions</a></li>
    <li><a href="#faq-security">Security & Privacy</a></li>
    <li><a href="#faq-technical">Technical Support</a></li>
</ul>

<h3>Resources</h3>
<ul>
    <li><a href="/privacy">Privacy Policy</a></li>
    <li><a href="/terms">Terms of Service</a></li>
    <li><a href="/docs">Documentation</a></li>
</ul>
```

---

## Maintenance

### Regular Updates
- Review privacy policy quarterly
- Update terms when service changes
- Refresh marketing content with new features
- Monitor and respond to user feedback

### Analytics
- Set up Google Analytics (optional)
- Track page views
- Monitor user engagement
- Identify popular content

---

**Website Deployment Complete!**

All files are ready in the `website/` folder. Follow the steps above to deploy to khandoba.org.

**Last Updated: December 18, 2025**

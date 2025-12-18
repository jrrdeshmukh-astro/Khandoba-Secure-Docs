# Documentation Site Deployment Guide

## Overview

This guide explains how to deploy the Khandoba Secure Docs documentation site to khandoba.org/docs.

---

## Deployment Options

### Option 1: GitHub Pages (Recommended - Free)

**Pros:**
- Free hosting
- Automatic deployments
- Version control
- Easy updates

**Cons:**
- Static pages only
- Limited customization

**Steps:**
1. Create GitHub repository
2. Push markdown files
3. Enable GitHub Pages
4. Configure custom domain

### Option 2: Read the Docs (Recommended for Documentation)

**Pros:**
- Built for documentation
- Automatic builds
- Search functionality
- Versioning

**Cons:**
- Requires GitHub integration
- Some limitations on free tier

**Steps:**
1. Sign up at readthedocs.org
2. Connect GitHub repository
3. Configure build settings
4. Deploy

### Option 3: MkDocs (Static Site Generator)

**Pros:**
- Beautiful documentation themes
- Search built-in
- Easy navigation
- Markdown support

**Cons:**
- Requires build process
- Need hosting

**Steps:**
1. Install MkDocs
2. Configure mkdocs.yml
3. Build static site
4. Deploy to hosting

### Option 4: Netlify/Vercel (Modern Static Hosting)

**Pros:**
- Free tier available
- Automatic deployments
- Fast CDN
- Custom domains

**Cons:**
- Requires build step
- Some limitations

**Steps:**
1. Create account
2. Connect repository
3. Configure build
4. Deploy

---

## Recommended: MkDocs + GitHub Pages

### Step 1: Install MkDocs

```bash
pip install mkdocs mkdocs-material
```

### Step 2: Create mkdocs.yml

```yaml
site_name: Khandoba Secure Docs Documentation
site_description: Complete documentation for Khandoba Secure Docs
site_author: Khandoba Team
site_url: https://khandoba.org/docs

theme:
  name: material
  palette:
    - scheme: default
      primary: red
      accent: purple
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
    - scheme: slate
      primary: red
      accent: purple
      toggle:
        icon: material/brightness-4
        name: Switch to light mode
  features:
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - navigation.top
    - search.suggest
    - search.highlight
    - content.code.annotate

nav:
  - Home: index.md
  - Getting Started:
    - Installation: getting-started/installation.md
    - Quick Start: getting-started/quick-start.md
    - First Vault: getting-started/first-vault.md
    - Concepts: getting-started/concepts.md
  - User Guide:
    - Vaults: user-guide/vaults.md
    - Documents: user-guide/documents.md
    - Sharing: user-guide/sharing.md
    - Security: user-guide/security.md
    - AI Features: user-guide/ai-features.md
    - Subscriptions: user-guide/subscriptions.md
  - Features:
    - Voice Reports: features/voice-reports.md
    - ML Auto-Approval: features/ml-approval.md
    - Geographic Intelligence: features/geographic-intelligence.md
    - Source/Sink: features/source-sink.md
    - Threat Monitoring: features/threat-monitoring.md
    - Intel Reports: features/intel-reports.md
  - Architecture:
    - Overview: architecture/overview.md
    - Data Models: architecture/data-models.md
    - Services: architecture/services.md
    - Security: architecture/security.md
    - AI Systems: architecture/ai-systems.md
  - Developer Guide:
    - Codebase: developer/codebase.md
    - Adding Features: developer/adding-features.md
    - Testing: developer/testing.md
    - Contributing: developer/contributing.md
  - API Reference:
    - Services: api/services.md
    - Models: api/models.md
    - Utilities: api/utilities.md
  - Guides:
    - Deployment: guides/deployment.md
    - Troubleshooting: guides/troubleshooting.md
    - Best Practices: guides/best-practices.md

markdown_extensions:
  - pymdownx.highlight:
      anchor_linenums: true
  - pymdownx.inlinehilite
  - pymdownx.snippets
  - pymdownx.superfences
  - admonition
  - pymdownx.details
  - pymdownx.tabbed:
      alternate_style: true
```

### Step 3: Build Site

```bash
mkdocs build
```

Output: `site/` directory with HTML files

### Step 4: Deploy

**GitHub Pages:**
```bash
mkdocs gh-deploy
```

**Manual:**
1. Upload `site/` directory to web server
2. Configure web server to serve files
3. Set up custom domain

---

## Quick Start (5 Minutes)

### Using MkDocs

1. **Install:**
   ```bash
   pip install mkdocs mkdocs-material
   ```

2. **Initialize:**
   ```bash
   cd website/docs
   mkdocs new .
   ```

3. **Configure:**
   - Edit `mkdocs.yml` (use template above)
   - Add markdown files

4. **Preview:**
   ```bash
   mkdocs serve
   ```
   - Open http://localhost:8000

5. **Deploy:**
   ```bash
   mkdocs gh-deploy
   ```

---

## Custom Domain Setup

### GitHub Pages

1. **Add CNAME file:**
   ```
   docs.khandoba.org
   ```

2. **Update DNS:**
   - Type: `CNAME`
   - Name: `docs`
   - Value: `yourusername.github.io`

3. **Wait for propagation:**
   - Usually 5-30 minutes

---

## Maintenance

### Updating Documentation

1. **Edit markdown files**
2. **Test locally:**
   ```bash
   mkdocs serve
   ```
3. **Deploy:**
   ```bash
   mkdocs gh-deploy
   ```

### Versioning

MkDocs supports versioning:
- Multiple versions
- Version selector in UI
- Archive old versions

---

## Alternative: Simple HTML Site

If you prefer simple HTML:

1. **Convert markdown to HTML:**
   ```bash
   # Using pandoc
   pandoc file.md -o file.html
   ```

2. **Create index.html:**
   - Link to all pages
   - Add navigation
   - Style with CSS

3. **Deploy:**
   - Upload HTML files to web server
   - Configure custom domain

---

## Recommended Structure

```
khandoba.org/
├── / (Homepage)
├── /privacy (Privacy Policy)
├── /terms (Terms of Service)
├── /support (Support Page)
└── /docs (Documentation)
    ├── /getting-started
    ├── /user-guide
    ├── /features
    ├── /architecture
    ├── /developer
    ├── /api
    └── /guides
```

---

## SEO Optimization

### Meta Tags

Add to each page:
```html
<meta name="description" content="Khandoba Secure Docs Documentation - Complete guide to using AI-powered secure document management">
<meta name="keywords" content="documentation, secure vault, AI security, user guide">
```

### Sitemap

Create `sitemap.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://khandoba.org/docs/</loc>
    <changefreq>weekly</changefreq>
  </url>
  <!-- Add all pages -->
</urlset>
```

---

## Support

For deployment issues:
- **Email**: support@khandoba.org
- **Documentation**: Check MkDocs documentation

---

**Ready to deploy?** Follow the steps above to get your documentation site live!

# 🪟 Windows Deployment Guide

> Microsoft Store deployment instructions

---

## Prerequisites

- Microsoft Partner Center account
- App signing certificate
- Windows Dev Center access

---

## Deployment Steps

### 1. Create App in Partner Center

1. Go to [Partner Center](https://partner.microsoft.com/dashboard)
2. Create new app
3. Fill in app information
4. Set up subscription products (if needed)

### 2. Build Release Package

```bash
dotnet publish -c Release
```

Or use Visual Studio:
1. Right-click project → Publish
2. Create App Packages
3. Select Microsoft Store
4. Build package

### 3. Upload to Partner Center

1. Go to Partner Center
2. App submissions
3. Create new submission
4. Upload package
5. Complete store listing
6. Submit for certification

---

## App Signing

Windows apps must be signed for Store submission. Visual Studio can generate certificates automatically, or you can use your own.

---

## Subscription Setup

1. Set up subscription products in Partner Center
2. Configure pricing
3. Test with test accounts

---

## Troubleshooting

**Upload fails:**
- Verify package is signed
- Check version number increment
- Verify package name matches Partner Center

**Certification fails:**
- Check [Store Policies](https://docs.microsoft.com/en-us/windows/uwp/publish/store-policies)
- Review certification notes
- Fix issues and resubmit

---

## Related Documentation

- **[Windows Setup](SETUP.md)** - Initial setup
- **[Features](FEATURES.md)** - Feature documentation
- **[Shared Architecture](../../shared/architecture/)** - System architecture

---

**Last Updated:** December 2024  
**Status:** 🚧 Foundation Created

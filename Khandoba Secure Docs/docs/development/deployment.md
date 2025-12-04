# Deployment Guide

> **Last Updated:** December 2024
> 
> Guide for deploying the Khandoba iOS application to production.

## Pre-Deployment Checklist

- [ ] All tests passing
- [ ] Code signing configured
- [ ] CloudKit container configured
- [ ] App Store Connect app created
- [ ] Version and build numbers updated
- [ ] Production API URLs configured
- [ ] App icons and screenshots prepared
- [ ] Privacy policy and terms of service ready

## Build Configuration

### Production Build

1. Select "Any iOS Device" or specific device
2. Product → Archive
3. Wait for archive to complete
4. Distribute App → App Store Connect
5. Follow App Store Connect submission process

### Environment Configuration

The app uses `AppConfiguration` to distinguish dev/prod:

```swift
#if DEBUG
    return .development
#else
    return .production
#endif
```

Production uses:
- API URL: `https://api.khandoba.org`
- Debug features: Disabled

## App Store Submission

1. Archive the app
2. Upload to App Store Connect
3. Complete App Store listing
4. Submit for review
5. Monitor review status

## Post-Deployment

- Monitor crash reports
- Track analytics
- Review user feedback
- Plan updates


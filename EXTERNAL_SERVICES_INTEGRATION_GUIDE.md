# External Services Integration Guide

## Overview

The app integrates with external services using OAuth 2.0 for secure authentication and data access.

## Supported Services

### Email Providers
- **Gmail**: Via Google OAuth
- **Outlook**: Via Microsoft OAuth
- **IMAP**: Generic IMAP support (manual configuration)

### Cloud Storage Providers
- **Google Drive**: Via Google OAuth
- **Dropbox**: Via Dropbox OAuth
- **OneDrive**: Via Microsoft OAuth
- **iCloud Drive**: Native iOS integration

## Architecture

### OAuth Service

**OAuthService** handles:
- OAuth 2.0 authentication flows
- Token management and refresh
- Secure keychain storage
- Provider-specific configurations

### Email Integration Service

**EmailIntegrationService** provides:
- Email fetching with filters
- Attachment extraction
- Automatic ingestion to vaults

### Cloud Storage Service

**CloudStorageService** provides:
- File listing and browsing
- File download
- Integration with document service

## Configuration

### OAuth Client IDs

Add to `Info.plist`:
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `DROPBOX_CLIENT_ID`
- `DROPBOX_CLIENT_SECRET`
- `MICROSOFT_CLIENT_ID`
- `MICROSOFT_CLIENT_SECRET`

### Redirect URI

The app uses `khandoba-oauth://oauth/{provider}` as the redirect scheme.

## Usage

### Connect Email Provider

```swift
try await emailService.connectProvider(.gmail)
let emails = try await emailService.fetchEmails(from: .gmail, maxResults: 50)
```

### Connect Cloud Storage

```swift
try await cloudStorageService.connectProvider(.googleDrive)
let files = try await cloudStorageService.listFiles(provider: .googleDrive)
```

### Ingest to Vault

```swift
try await emailService.ingestAttachmentsToVault(
    email: email,
    vault: vault,
    documentService: documentService
)
```

## Views

- **ConnectedAccountsView**: Manage OAuth connections
- **EmailSourceConfigurationView**: Configure email sources
- **EmailFilterView**: Filter email ingestion
- **CloudStorageSourceView**: Configure cloud storage sources


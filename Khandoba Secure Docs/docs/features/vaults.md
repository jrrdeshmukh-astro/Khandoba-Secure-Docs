# Vaults Feature

> **Last Updated:** December 2024
> 
> Complete documentation of vault management features.

## Overview

Vaults are secure containers for documents with zero-knowledge architecture. Each vault can be single-key (client only) or dual-key (requires admin approval).

## Vault Types

### Single-Key Vaults

- Client has full access
- No approval required for operations
- Standard vault operations

### Dual-Key Vaults

- Requires both client and admin keys
- Admin approval needed for access
- Enhanced security for sensitive data

## Vault Operations

### Create Vault

1. Navigate to Vaults tab
2. Tap "+" button
3. Enter vault name and description
4. Select key type (Single/Dual)
5. Configure source/sink settings
6. Create vault

### Open Vault

1. Tap vault in list
2. Session starts (30-minute timer)
3. Vault unlocks
4. Documents become accessible

### Vault Detail View

- Status card with vault information
- Active session timer
- Documents list
- Sharing section (nominees)
- Access & Security (logs, threats)
- Actions (add document, video, share, etc.)

## Session Management

- **Duration**: 30 minutes
- **Extension**: User can extend session
- **Auto-Lock**: Vaults auto-lock after session expires
- **Streaming**: Real-time session updates to nominees

## Document Management

### Upload Document

1. Select source (Files, Photos, Camera)
2. Virus scan (automatic)
3. Document indexing
4. Encryption
5. Upload to vault

### Document Actions

- Preview
- Archive/Unarchive
- Redact (HIPAA compliance)
- Share
- Delete
- Version History

## Sharing

### Nominees

- Invite nominees via iPhone messaging
- Manage existing nominees
- View nominee status

### Vault Sharing

- Share via WhatsApp
- Generate share link
- Set expiration date

## Security

### Access Logs

- Complete audit trail
- Geolocation data
- Access type filtering

### Threat Dashboard

- Threat level graphs
- Access frequency charts
- Anomaly detection
- ML predictions

## Admin Oversight

Admins can:
- View all vaults
- Access vault metadata (zero-knowledge)
- Approve dual-key requests
- Review emergency access requests
- Monitor threat metrics


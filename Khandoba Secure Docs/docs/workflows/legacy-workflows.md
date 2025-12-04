# Legacy Workflows Documentation

> **Note**: This document is kept for historical reference. Officer role has been removed and merged into admin.

This document outlines the clear workflows for Client, Officer, and Admin roles in the Khandoba vault system.

**Current Status**: Officer role removed - all capabilities merged into admin. See [admin-workflows.md](admin-workflows.md) for current admin workflows.

## Client Workflow

### Primary Flow

1. **Dashboard (Home)**
   - Overview: Quick stats (vault count, document count, total storage, active sessions)
   - Recent activity: Last 5 access logs
   - Active sessions: Vaults currently open with 30-minute session timers
   - Quick actions: Access to frequently used features

2. **Vaults**
   - Browse: List all vaults with status indicators
   - Open: Tap a vault → Session starts (30-min timer begins)
   - Vault Detail View:
     - Status card showing vault information
     - Active session timer (if session is active)
     - Documents section (full access to view and manage)
     - Sharing section (nominees, share vault)
     - Access & Security (access logs, threat dashboard, threat metrics)
     - Actions section:
       - Add Document (scan → index → encrypt → upload)
       - Video Recording
       - Share Vault
       - Transfer Ownership
       - Emergency Access
       - Settings

3. **Vault Detail → Add Document**
   - Document upload flow:
     1. Select file from Files, Photos, or Camera
     2. Virus scan (automatic)
     3. Document indexing (metadata extraction, EXIF, PDF metadata, OCR)
     4. Encryption
     5. Upload to vault
   - View documents in vault

4. **Document → Preview**
   - Full document preview (image, PDF, video, text)
   - Actions menu:
     - Archive/Unarchive
     - Redact
     - Share
     - Delete

5. **Vault Actions**
   - Video Record: Live video recording stored in vault
   - Share: Share vault via WhatsApp or other methods
   - Transfer Ownership: Initiate ownership transfer request
   - Emergency Access: Request emergency access (requires officer approval)

6. **Documents Tab**
   - Search all documents across all vaults
   - Filter by source/sink type
   - Show documents from vaults with active sessions only
   - Display AI tags prominently
   - Filter by source/sink type
   - Preview documents
   - Access document actions

### Secondary Flows

- **Profile**
  - Account switcher (if user has multiple roles: client/officer/admin)
  - Settings
  - Help & Support

- **Vault → Nominees**
  - Invite nominee via iPhone messaging
  - Manage existing nominees
  - View nominee status

- **Vault → Threat Metrics**
  - View threat level graphs
  - Access frequency charts
  - Anomaly score visualization
  - ML predictions

- **Vault → Access Logs**
  - Review all access activity
  - View geolocation data
  - Filter by access type (opened, closed, viewed, modified)

## Officer Workflow (DEPRECATED - Merged into Admin)

> **Note**: Officer role has been removed. All officer capabilities are now available to admins. See [admin-workflows.md](admin-workflows.md) for current admin workflows.

### Primary Flow

1. **Dashboard**
   - Pending Actions:
     - KYC Verifications (clickable → Review → Approve/Reject)
     - Dual-Key Requests (clickable → Approve/Deny)
     - Emergency Requests (clickable → Review → Approve/Deny)
   - Quick Access:
     - Threat Assessment
     - Access Logs
   - Recent Officer Activity

2. **Clients**
   - Browse assigned clients
   - Client Detail:
     - Client information
     - Assigned vaults (metadata only - zero-knowledge)
     - Vault actions (threat assessment, dual-key approval, emergency review)

3. **Client → Vault (Metadata)**
   - Zero-knowledge view (no document content access)
   - Vault metadata:
     - Name, status, key type
     - Document count
     - Total size
     - Last access time
     - Threat level
   - Actions:
     - Threat Assessment
     - Approve/Deny Dual-Key Access
     - Review Emergency Requests
     - View Access Logs (zero-knowledge audit)

4. **Vault (Metadata) → Threat Assessment**
   - View threat metrics
   - Review anomaly detection
   - Approve/deny dual-key requests
   - Emergency access review

5. **KYC**
   - Pending verifications list
   - Review verification documents
   - Approve/Reject with comments

6. **Vaults**
   - Assigned vaults list
   - Metadata view for each vault
   - Threat monitoring dashboard

### Secondary Flows

- **Dashboard → Recent Activity**
  - Audit trail review
  - Activity timeline

- **Client → Chat**
  - Support communication
  - In-app messaging

- **Vault → Access Logs**
  - Zero-knowledge audit
  - Review access patterns
  - Geolocation tracking

## Admin Workflow

### Primary Flow

1. **Dashboard**
   - System overview:
     - Total users
     - Active officers
     - Total vaults
     - Dual-key vaults
   - Critical alerts
   - Recent activity
   - Quick actions

2. **Users**
   - All users list
   - User Detail:
     - User information
     - Role management (assign/remove roles)
     - Client-officer pairing
     - Access logs
     - Activity review

3. **Users → User Detail → Role Management**
   - Assign roles (client, officer, admin)
   - Remove roles (with restrictions for last admin)
   - View role history

4. **Users → User Detail → Client-Officer Pairing**
   - Assign officer to client
   - Assign admin to client
   - View assignment history

5. **Invites**
   - Create officer invites
   - Track invite status
   - Resend invites

6. **Vaults**
   - All vaults list
   - Vault Detail (full oversight - admin can see content):
     - Full document access
     - Vault metadata
     - Threat analysis
     - Admin actions

7. **Security**
   - System-wide monitoring:
     - Threat metrics across all vaults
     - Security events
     - ML metrics
     - Anomaly detection
   - Threat dashboard
   - Security alerts

8. **Settings**
   - System configuration
   - Compliance settings
   - Maintenance tools
   - Payment management

9. **Profile**
   - Account switcher (if multiple roles)
   - Database purge
   - System maintenance

### Secondary Flows

- **Users → User Detail → Access Logs**
  - Activity review
  - Access pattern analysis

- **Vaults → Vault Detail → Full Content Access**
  - Admin can see all document content
  - Admin actions on documents
  - Full audit trail

- **Security → Threat Dashboard**
  - ML metrics visualization
  - Anomaly detection results
  - System-wide threat trends

- **Settings → Database Purge**
  - System maintenance
  - Data cleanup
  - Backup management

## Key Features by Role

### Client Features
- ✅ Full vault content access
- ✅ Document upload with virus scanning
- ✅ Video recording
- ✅ Ownership transfer
- ✅ Emergency access requests
- ✅ HIPAA features (archive, redaction)
- ✅ Threat metrics visualization
- ✅ Access logs
- ✅ Nominee management
- ✅ WhatsApp sharing
- ✅ Source/Sink document classification
- ✅ AB Testing for Intel Reports

### Officer Features
- ✅ Zero-knowledge vault metadata view
- ✅ KYC verification
- ✅ Dual-key approval
- ✅ Emergency request management
- ✅ Threat assessment
- ✅ Client chat
- ✅ Access log audit (zero-knowledge)

### Admin Features
- ✅ Full system oversight
- ✅ User management
- ✅ Role assignment
- ✅ Client-officer pairing
- ✅ Full vault content access
- ✅ System-wide threat monitoring
- ✅ Payment management
- ✅ Database maintenance

## Session Management

- **Vault Sessions**: 30-minute sessions when vault is opened
- **Session Extension**: Client can extend session
- **Auto-Lock**: Vaults auto-lock after session expires
- **Session Timer**: Prominently displayed in vault detail view
- **Session Streaming**: Real-time session updates streamed to all nominees and owners

## Zero-Knowledge Architecture

- **Admin View (Zero-Knowledge)**: Admins see vault metadata only, no document content (default)
- **Admin View (Full Access)**: Admins can be granted full content access if needed
- **Audit Trail**: All access is logged for compliance
- **Threat Monitoring**: Admins monitor threats without seeing content (zero-knowledge)

## Source vs Sink Document System

- **Source Documents**: Manually captured documents (camera, written, voice memo)
- **Sink Documents**: External uploads and forwarded documents
- **Vault Types**: Vaults can be source-only, sink-only, or both
- **AB Testing**: Intel reports compare source vs sink documents for insights
- **Documents Tab**: Shows documents from open sessions with source/sink labels and AI tags

## HIPAA Compliance Features

- **Archiving**: Documents can be archived with retention policies
- **Redaction**: Sensitive information can be redacted from documents
- **Audit Trails**: Complete access logging
- **Encryption**: All documents encrypted at rest and in transit

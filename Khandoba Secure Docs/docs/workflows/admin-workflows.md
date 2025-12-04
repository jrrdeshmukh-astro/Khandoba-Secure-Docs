# Admin Workflows - Complete Reference

> **Last Updated:** December 2024
> 
> Comprehensive documentation of all admin workflows in the Khandoba iOS application.
> 
> **Note:** Admin role now includes all capabilities previously available to officers.

## Table of Contents

1. [Authentication & Onboarding](#authentication--onboarding)
2. [Admin Dashboard](#admin-dashboard)
3. [User Management](#user-management)
4. [Vault Oversight](#vault-oversight)
5. [KYC Verification](#kyc-verification)
6. [Dual-Key Approval](#dual-key-approval)
7. [Vault Open Requests](#vault-open-requests)
8. [Emergency Access Management](#emergency-access-management)
9. [Security Monitor](#security-monitor)
10. [Chat Inbox](#chat-inbox)
11. [Access Logs](#access-logs)
12. [System Settings](#system-settings)
13. [Payment Management](#payment-management)

---

## Authentication & Onboarding

### Initial Launch Flow

**Entry Point:**
- App launches → Checks authentication state
- Shows `StandardLoadingView` during initial check

**Not Authenticated:**
- Same flow as client (Welcome → Sign In → Account Setup)
- Role Selection: Admin role must be assigned separately (not through UI)

**Authenticated as Admin:**
- Direct navigation to `AdminMainView` (TabView)
- Admin dashboard with system overview

### Authentication State Management

- Authentication status checked on app launch
- Session persistence via Apple Sign In credentials
- Automatic role detection
- Support for users with multiple roles (Client/Admin via `AccountSwitcherView`)

---

## Admin Dashboard

### Layout Structure

**Header Section:**
- "Secure Docs" title
- "Admin Console" subtitle
- "System-wide monitoring and control" description

**System Stats Grid:**
- 2-column grid showing:
  1. **Total Users** - All users in system
  2. **Clients** - Total client count
  3. **Total Vaults** - All vaults in system
  4. **Dual-Key Vaults** - Vaults requiring approval

**Vault Open Requests (Notifications):**
- Pending requests count badge
- List of recent requests (up to 3)
- "View All Requests" link
- Quick approve/reject actions

**Critical Alerts:**
- High-priority security alerts
- System warnings
- Threat notifications
- Alert severity indicators

**System Metrics:**
- CPU Usage bar
- Memory Usage bar
- Storage Percentage bar
- Network Usage bar

**Recent Admin Activity:**
- Last 5 admin actions
- Activity type icons
- Timestamps
- Color-coded by action type

---

## User Management

### User List View

**All Users:**
- Complete list of all users in system
- User information:
  - Name
  - Email (if available)
  - Profile picture
  - Roles assigned
  - Account status

**User Detail View:**
- Full user information
- Profile picture
- Account creation date
- Last active time
- KYC status

### Role Management

**Assign Role:**
- Select user
- Choose role (Client/Admin)
- Confirm assignment
- Validation:
  - Only one admin allowed
  - Cannot remove last admin

**Remove Role:**
- Select user
- Choose role to remove
- Confirm removal
- Restrictions:
  - Cannot remove last admin
  - Cannot remove own admin role

**Role History:**
- View role assignment history
- Who granted/revoked roles
- Timestamps

### Client-Admin Pairing

**Assign Admin to Client:**
- Select client
- Choose admin to assign
- Confirm assignment
- View assignment history

**View Assignments:**
- List of all client-admin pairs
- Assignment dates
- Active status

---

## Vault Oversight

### All Vaults View

**Vault List:**
- Complete list of all vaults in system
- Vault information:
  - Name
  - Owner
  - Status
  - Key type
  - Document count
  - Last accessed

**Vault Detail (Full Access):**
- **Full Document Access** (admin privilege)
- Vault metadata
- Threat analysis
- Access logs
- Admin actions

**Admin Actions:**
- View all documents
- Access vault settings
- Review threat metrics
- View access logs
- Manage vault (if needed)

---

## KYC Verification

### KYC Verification View

**Pending Verifications:**
- List of pending ID verifications
- Client information
- Submission date
- Verification status

**Review Verification:**
- View verification documents
- Client information
- Document details
- Verification history

**Approve/Reject:**
- Approve with optional comments
- Reject with required reason
- Notification sent to client
- Status updated in system

---

## Dual-Key Approval

### Dual-Key Requests View

**Pending Requests:**
- List of pending dual-key vault access requests
- Client information
- Vault information
- Request reason
- Request date

**Review Request:**
- View request details
- Client information
- Vault metadata
- Threat assessment
- Request history

**Approve/Deny:**
- Approve request (grants access)
- Deny request (with reason)
- Notification sent to client
- Status updated

---

## Vault Open Requests

### Vault Open Requests View

**Pending Requests:**
- List of client requests to open vaults
- Vault information
- Client information
- Request timestamp
- Request reason (if provided)

**Review Request:**
- View request details
- Vault metadata
- Client information
- Access history
- Threat assessment

**Approve/Reject:**
- Approve request (unlocks vault)
- Reject request (with reason)
- Notification sent to client
- Vault status updated

---

## Emergency Access Management

### Emergency Requests View

**Pending Requests:**
- List of emergency access requests
- Client information
- Vault information
- Emergency reason
- Request urgency

**Review Request:**
- View emergency details
- Client information
- Vault metadata
- Request reason
- Historical emergency requests

**Approve/Deny:**
- Approve emergency access
- Deny with reason
- Notification sent to client
- Access granted/denied

---

## Security Monitor

### Security Dashboard

**System-Wide Threat Metrics:**
- Aggregated threat metrics across all vaults
- ML-based analysis results
- Threat trends
- Anomaly detection

**Threat Metrics Dashboard:**
- View ML-based threat analysis
- Per-vault threat metrics
- System-wide trends
- Predictive analytics

**Threat Perceptions:**
- System-wide threat assessments
- Per-vault threat levels
- Risk analysis
- Recommendations

### Security Events

**Recent Security Events:**
- Login from new device
- Multiple failed login attempts
- Biometric verification success
- Suspicious activity

**Threat Analysis:**
- Brute force attacks
- Malware detected
- Suspicious IPs blocked
- Trend indicators

### Security Status

**System Status:**
- Encryption status
- Firewall status
- Intrusion detection status
- Backup status

---

## Chat Inbox

### Chat Inbox View

**Conversations List:**
- All client conversations
- Unread message count badges
- Last message preview
- Timestamp

**Chat View:**
- Message history
- Message input
- Send button
- Real-time updates
- Read receipts

**Chat Features:**
- Respond to client messages
- View conversation history
- Mark as read
- Archive conversations

---

## Access Logs

### Access Logs View

**All Access Logs:**
- Complete audit trail
- Filter by user
- Filter by vault
- Filter by access type
- Filter by date range

**Access Log Details:**
- User information
- Vault information
- Access type
- Timestamp
- Geolocation data
- Device information

**Zero-Knowledge Audit:**
- Audit trail without content access
- Access patterns
- Anomaly detection
- Compliance reporting

---

## System Settings

### System Configuration

**Session Settings:**
- Session timeout duration
- Max login attempts
- Encryption algorithm

**Compliance Settings:**
- DPDPA mode
- HIPAA mode
- Audit logging level

**Notifications:**
- Security alerts
- System updates
- Backup reports

### Maintenance Tools

**Security Scan:**
- Run system-wide security scan
- Scan results
- Threat detection

**Audit Report:**
- Generate audit reports
- Export reports
- Report history

**Backup System:**
- Manual backup trigger
- Backup status
- Restore options

---

## Payment Management

### Payment Overview

**Revenue:**
- Total revenue
- Active subscriptions count
- Revenue trends

**Payment Products:**
- List of available products
- Product details
- Pricing information
- Active subscription status

**Transaction History:**
- All transactions
- Transaction details
- Refund management
- Revenue reports

---

## Error Handling

### Common Error Scenarios

1. **System Errors:**
   - Database errors
   - Service failures
   - Network issues

2. **Permission Errors:**
   - Unauthorized actions
   - Role validation failures

3. **Validation Errors:**
   - Invalid data
   - Missing required fields

4. **Operation Errors:**
   - Failed approvals
   - Failed rejections
   - System maintenance errors

---

## Performance Considerations

- Efficient user queries
- Optimized vault loading
- Background data sync
- Real-time updates
- Caching strategies

---

## Accessibility

- VoiceOver labels
- Dynamic Type support
- High contrast mode
- Haptic feedback
- Clear focus indicators


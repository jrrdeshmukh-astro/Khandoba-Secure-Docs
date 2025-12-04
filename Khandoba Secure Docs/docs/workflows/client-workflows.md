# Client Workflows - Complete Reference

> **Last Updated:** December 2024
> 
> Comprehensive documentation of all client workflows in the Khandoba iOS application.

## Table of Contents

1. [Authentication & Onboarding](#authentication--onboarding)
2. [Dashboard (Home Tab)](#dashboard-home-tab)
3. [Vaults Tab](#vaults-tab)
4. [Vault Detail View](#vault-detail-view)
5. [Document Management](#document-management)
6. [Documents Tab](#documents-tab)
7. [Store Tab](#store-tab)
8. [Profile Tab](#profile-tab)
9. [Sharing & Collaboration](#sharing--collaboration)
10. [Security & Monitoring](#security--monitoring)
11. [Chat & Communication](#chat--communication)

---

## Authentication & Onboarding

### Initial Launch Flow

**Entry Point:**
- App launches → Checks authentication state
- Shows `StandardLoadingView` during initial check

**Not Authenticated:**
1. **Welcome View**
   - App branding (Khandoba logo)
   - "Sign In with Apple" button with haptic feedback
   - Privacy and security messaging
   - Smooth transitions

2. **Sign In with Apple**
   - Tap "Sign In with Apple" → Haptic feedback
   - Apple authentication sheet appears
   - User authenticates with Face ID/Touch ID/Password
   - System handles authentication
   - App receives authentication result

3. **Account Setup (First Time Users)**
   - `AccountSetupView` appears after successful authentication
   - User must provide:
     - Full name (required, validated)
     - Profile picture/selfie (required, camera access)
   - Name input field with validation
   - Camera access for profile picture capture
   - Preview and confirm profile picture
   - Submit button to complete setup
   - **Note:** Setup is mandatory before proceeding

4. **Role Selection**
   - `RoleSelectionView` appears if no roles assigned
   - **Only two options:**
     1. **Client** (default, always available)
        - Icon: User icon
        - Description: "Standard user access"
        - Selected by default for new users
     2. **Admin** (restricted)
        - Icon: Crown icon
        - Description: "Full system access"
        - Note: "Admin role must be assigned separately"
        - Disabled for regular signup (grayed out)
        - Only enabled if admin assignment exists
   - User selects or confirms role
   - System assigns role and proceeds to main interface

**Authenticated:**
- Direct navigation to `ClientMainView` (TabView)
- No onboarding screens shown

### Authentication State Management

- Authentication status checked on app launch
- Session persistence via Apple Sign In credentials
- Automatic role detection and assignment
- Support for users with multiple roles (via `AccountSwitcherView`)
- Admin role assignment handled separately (not through signup flow)

---

## Dashboard (Home Tab)

### Layout Structure

**Header Section:**
- "Secure Docs" title
- "Welcome Back" subtitle
- "Your secure vault dashboard" description
- Security shield icon

**Data Saved Estimate Card:**
- Shows "Data Protected: X GB"
- Small shield/lock icon
- Compact typography

**Balance Warning Banner (Conditional):**
- Only displays when balance < 20% threshold
- Warning icon and text
- Link to Store tab
- Hidden when balance is sufficient

**Quick Stats Grid:**
- 2-column grid showing:
  1. **Vaults** - Total vault count (real-time)
  2. **Documents** - Total document count across all vaults (real-time)
  3. **Active Sessions** - Number of vaults with active sessions
  4. **Storage** - Total storage used (formatted: KB, MB, GB)

**Recent Activity Section:**
- Section header: "Recent Activity"
- List of last 5 access logs
- Each activity row shows:
  - Icon (based on access type)
  - Action name (opened, closed, viewed, modified, deleted)
  - Time ago (relative format: "2h ago", "5m ago")
  - Color coding by action type

---

## Vaults Tab

### Vault List View

**Header:**
- Navigation title: "Vaults"
- "+" button (primary action) → Opens `CreateVaultView`
- Refresh button

**Vault List:**
- Inset grouped list style
- Each vault shown as `VaultRow`:
  - Icon: Status-based icon in colored circle
  - Name: Vault name (headline font)
  - Description: Optional description (caption, single line, truncated)
  - Document Count: Only shown when vault is locked/closed
  - Status Indicator: Color-coded based on vault status
- Swipe to delete (shows delete action)
- Tap vault → Navigate to `ClientVaultDetailView`

**Loading States:**
- `StandardLoadingView` shows while loading
- `ImprovedEmptyState` displayed when no vaults exist

### Create Vault Flow

**Access:**
- Tap "+" button in toolbar
- Sheet presentation: `CreateVaultView`

**Vault Creation Form:**
- Name input (required, validated)
- Description input (optional)
- Key type selection (Single/Dual-key)
- Source/Sink configuration
- Create button with loading state
- Cancel button

**Post-Creation:**
- Sheet dismisses
- Vault list refreshes
- New vault appears in list
- Haptic feedback on success

---

## Vault Detail View

### View Structure

**Navigation:**
- Back button
- Vault name as title
- Settings button (optional)

**Status Card:**
- Vault name and description
- Key type indicator
- Status (Active/Locked/Archived)
- Document count (if locked)
- Last accessed time

**Active Session Timer (if session active):**
- Prominent countdown timer
- Time remaining display
- Extend session button
- Auto-lock warning

**Documents Section:**
- List of all documents in vault
- Filter options (All/Archived/Active)
- Search within vault
- Add Document button
- Document count badge

**Sharing Section:**
- Nominees list
- Add Nominee button
- Share Vault button
- Transfer Ownership button

**Access & Security:**
- Access Logs link
- Threat Dashboard link
- Threat Metrics link

**Actions Section:**
- Add Document
- Video Recording
- Voice Memo Recording
- Share Vault
- Transfer Ownership
- Emergency Access Request
- Vault Settings

---

## Document Management

### Upload Document Flow

1. **Select Source:**
   - Files app
   - Photos library
   - Camera capture
   - Share extension

2. **Virus Scan:**
   - Automatic virus scanning
   - Progress indicator
   - Error handling if virus detected

3. **Document Indexing:**
   - Metadata extraction
   - EXIF data extraction
   - PDF metadata extraction
   - OCR processing (if applicable)
   - AI tagging

4. **Encryption:**
   - AES-256 encryption
   - Zero-knowledge architecture

5. **Upload to Vault:**
   - Progress indicator
   - Success confirmation
   - Error handling

### Document Preview

**Preview Types:**
- `ImagePreviewView` - Images (JPEG, PNG, etc.)
- `PDFPreviewView` - PDF documents
- `VideoPreviewView` - Video files
- `TextPreviewView` - Text documents
- `AudioPreviewView` - Audio files
- `UnsupportedPreviewView` - Unsupported formats

**Document Actions:**
- Archive/Unarchive
- Redact (HIPAA compliance)
- Share (iOS share sheet, WhatsApp)
- Delete (with confirmation)
- Rename
- Version History

### Document Operations

- **Archive:** Toggle archive status, archived documents hidden by default
- **Redact:** Navigate to `RedactionView`, select regions, apply permanent redaction
- **Share:** iOS share sheet, WhatsApp integration
- **Delete:** Destructive action with confirmation dialog
- **Rename:** Edit document name with validation
- **Version History:** View all versions, compare, restore previous version

---

## Documents Tab

### Document Retrieval View

**Search & Filter:**
- Search bar for text search
- Filter by source/sink type
- Filter by vault
- Filter by document type
- Filter by date range

**Results Display:**
- List of documents from open vaults only
- Documents from locked vaults are hidden
- AI tags prominently displayed
- Document preview on tap
- Access to all document actions

**Empty States:**
- No documents found
- No open vaults (prompts to open vault)
- Search returned no results

---

## Premium Tab

### Subscription View

**Subscription Status:**
- Premium Active / Free Plan
- Current plan display
- Monthly price: $5.99

**Premium Features:**
- Unlimited vaults
- Unlimited storage
- AI intelligence
- Threat monitoring
- Family Sharing (6 people)
- All security features

**Subscription Management:**
- Subscribe Now button
- Manage Subscription link
- Restore Purchases button
- Terms and conditions

**Subscribe Flow:**
- View premium features
- Tap "Subscribe Now"
- Confirm via App Store
- Process via StoreKit 2
- Full access immediately
- Auto-renewal monthly

---

## Profile Tab

### Profile View

**User Info Section:**
- Profile picture or initials
- Full name
- Current role badge
- Client ID (with copy functionality)

**Account Switcher:**
- Switch between available roles (Client/Admin)
- Role descriptions
- Current role indicator

**Settings:**
- App preferences
- Notification settings
- Privacy settings
- Help & Support

**Sign Out:**
- Sign out button
- Confirmation alert
- Clear session data

---

## Sharing & Collaboration

### Nominee Management

**Invite Nominee:**
- Navigate to nominee management
- Add nominee button
- Enter nominee details
- Send invitation via iPhone messaging

**Manage Nominees:**
- List of existing nominees
- Nominee status (Pending/Accepted/Active)
- Remove nominee option

### Vault Sharing

**Share Vault:**
- Share via WhatsApp
- Share via other methods
- Generate share link
- Set expiration date

**Transfer Ownership:**
- Initiate ownership transfer
- Select new owner
- Confirm transfer
- Requires admin approval

---

## Security & Monitoring

### Threat Dashboard

**Threat Metrics:**
- Threat level graphs
- Access frequency charts
- Anomaly score visualization
- ML predictions

**Threat Assessment:**
- Current threat level
- Historical trends
- Risk factors

### Access Logs

**Access Log View:**
- List of all access activity
- Filter by access type
- Filter by date range
- Geolocation data display
- Access type indicators:
  - Opened (primary color)
  - Closed (tertiary color)
  - Viewed (secondary color)
  - Modified (warning color)
  - Deleted (error color)

### Emergency Access

**Request Emergency Access:**
- Navigate to emergency access
- Enter reason for request
- Submit request
- Wait for admin approval
- Notification on approval/rejection

---

## Chat & Communication

### Client-to-Admin Chat

**Chat View:**
- Message list
- Message input
- Send button
- Real-time message updates
- Unread message indicators

**Chat Features:**
- Text messages
- Message timestamps
- Read receipts (if implemented)
- Message history

---

## Error Handling

### Common Error Scenarios

1. **Network Errors:**
   - Retry mechanism
   - Offline mode handling
   - Error messages

2. **Authentication Errors:**
   - Session expiration handling
   - Re-authentication flow

3. **Permission Errors:**
   - Camera access denied
   - Photo library access denied
   - Location access denied

4. **Validation Errors:**
   - Form validation feedback
   - Inline error messages

5. **Operation Errors:**
   - Upload failures
   - Delete failures
   - Save failures

---

## Performance Considerations

- Lazy loading for document lists
- Image caching
- Optimistic UI updates
- Background data sync
- Efficient CoreData queries
- Memory management for large files

---

## Accessibility

- VoiceOver labels on all interactive elements
- Dynamic Type support
- High contrast mode support
- Haptic feedback for interactions
- Clear focus indicators


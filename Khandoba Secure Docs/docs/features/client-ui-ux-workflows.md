# Client UI/UX Workflows Documentation - Plan Building Guide

> **Last Updated:** December 2024
> 
> This document comprehensively covers all UI/UX workflows available to clients in the Khandoba iOS application. This document is structured for plan building with clear implementation requirements, current state, required state, and implementation notes for each feature.

**Document Purpose:**
- Plan building and implementation tracking
- Clear requirements documentation
- Incomplete logic identification
- Technical implementation guidance

---

## Table of Contents

1. [Authentication & Onboarding](#authentication--onboarding)
2. [Main Navigation Structure](#main-navigation-structure)
3. [Dashboard (Home Tab)](#dashboard-home-tab)
4. [Vaults Tab](#vaults-tab)
5. [Vault Detail View](#vault-detail-view)
6. [Document Management](#document-management)
7. [Documents Tab](#documents-tab)
8. [Store Tab](#store-tab)
9. [Profile Tab](#profile-tab)
10. [Advanced Features](#advanced-features)
11. [Error Handling & Edge Cases](#error-handling--edge-cases)
12. [Incomplete Logic & Implementation Gaps](#incomplete-logic--implementation-gaps)
13. [Implementation Requirements](#implementation-requirements)
14. [UI/UX Patterns & Conventions](#uiux-patterns--conventions)
15. [Performance Considerations](#performance-considerations)

---

## Authentication & Onboarding

### Initial Launch Flow

**Entry Point:**
- App launches → Checks authentication state
- Shows loading indicator during initial check

**Not Authenticated:**
1. **Welcome View**
   - App branding (Khandoba logo)
   - "Sign In with Apple" button
   - Privacy and security messaging

2. **Sign In with Apple**
   - Tap "Sign In with Apple"
   - Apple authentication sheet appears
   - User authenticates with Face ID/Touch ID/Password
   - System handles authentication
   - App receives authentication result

3. **Account Setup (First Time Users)**
   - **AccountSetupView** appears after successful authentication
   - User must provide:
     - Full name (required)
     - Profile picture/selfie (required)
   - Name input field with validation
   - Camera access for profile picture capture
   - Preview and confirm profile picture
   - Submit button to complete setup
   - **Note:** Setup is mandatory before proceeding

4. **Role Selection (Simplified)**
   - **RoleSelectionView** appears if no roles assigned
   - **Only two options:**
     1. **Client** (default, always available)
        - Icon: User icon
        - Description: "Standard user access"
        - Selected by default for new users
     2. **Admin** (restricted)
        - Icon: Shield with checkmark
        - Description: "Full system access"
        - Note: "Admin role must be assigned separately"
        - Disabled for regular signup (grayed out)
        - Only enabled if admin assignment exists
   - **Note:** Officer role removed - Admin includes all former Officer capabilities
   - **Note:** Single Admin per system, assigned separately (not through UI)
   - User selects or confirms role
   - System assigns role and proceeds to main interface

**Authenticated:**
- Direct navigation to **ClientMainView** (TabView)
- No onboarding screens shown

### Authentication State Management

- Authentication status checked on app launch
- Session persistence via Apple Sign In credentials
- Automatic role detection and assignment
- Support for users with multiple roles (via AccountSwitcherView)
- Admin role assignment handled separately (not through signup flow)

---

## Main Navigation Structure

### Tab Bar Navigation

The client interface uses a **TabView** with 5 main tabs:

1. **Home** (Tab 0)
   - Icon: Dashboard icon
   - View: `ClientDashboardView`
   - Shows overview and quick stats

2. **Vaults** (Tab 1)
   - Icon: Vaults icon
   - View: `VaultListView`
   - Shows all user vaults

3. **Documents** (Tab 2)
   - Icon: Documents icon
   - View: `DocumentRetrievalView`
   - Search and filter documents across vaults

4. **Store** (Tab 3)
   - Icon: Store icon
   - View: `PaymentStoreView`
   - Subscription and payment management

5. **Profile** (Tab 4)
   - Icon: Profile icon
   - View: `ProfileView`
   - User settings and account management

**Navigation Behavior:**
- Tab bar persists across all views
- Selected tab indicated by primary color tint
- Each tab maintains its own navigation stack

---

## Dashboard (Home Tab)

### Layout Structure

**Header Section:**
- Khandoba logo (32x32px) - *Reduced from 40x40px for smaller footprint*
- "Khandoba" branding text
- "Welcome Back" subtitle
- "Your secure vault dashboard" description
- Security shield icon (32pt) - *Reduced from 40pt*
- Compact spacing (12pt between elements) - *Reduced from 24pt*

**Data Saved Estimate Card (NEW):**
- Compact card with minimal footprint
- Shows "Data Protected: X GB" (e.g., "Data Protected: 2.5 GB")
- Small shield/lock icon (16pt)
- Minimal padding (8pt)
- Compact typography (caption font for label, subheadline for value)
- Positioned below header, above stats grid

**Balance Warning Banner (Conditional - NEW):**
- **Only displays when balance < 20% threshold**
- Compact warning banner:
  - Warning icon (exclamation triangle)
  - "Low balance: X credits remaining" text
  - Link to Store tab (Tab 4)
- Hidden when balance is sufficient
- Positioned below Data Saved Estimate card

**Quick Stats Grid:**
- Reduced padding (12pt instead of 16pt) - *Smaller footprint*
- Compact stat cards
- 2-column grid showing:
  1. **Vaults**
     - Icon: Vaults icon
     - Value: Total vault count (real-time)
     - Color: System primary (adapts to dark mode)

  2. **Documents**
     - Icon: Documents icon
     - Value: Total document count across all vaults (real-time)
     - Color: System secondary (adapts to dark mode)

  3. **Active Sessions**
     - Icon: Activity icon
     - Value: Number of vaults with active sessions
     - Color: System tertiary (adapts to dark mode)

  4. **Storage**
     - Icon: External drive icon
     - Value: Total storage used (formatted: KB, MB, GB)
     - Color: System accent (adapts to dark mode)

**Recent Activity Section:**
- Section header: "Recent Activity"
- Compact list style - *Reduced spacing*
- List of last 5 access logs
- Each activity row shows:
  - Icon (based on access type)
  - Action name (opened, closed, viewed, modified, deleted)
  - Time ago (relative format: "2h ago", "5m ago")
  - Color coding by action type (system colors, adapt to dark mode):
    - Opened: System primary
    - Closed: System tertiary
    - Viewed: System secondary
    - Modified: System tertiary
    - Deleted: System red
- Empty state: "No recent activity" message
- Divider between items

### User Interactions

**Pull to Refresh:**
- Drag down to refresh all dashboard data
- Shows refresh indicator
- Refreshes:
  - Vault list
  - Document counts
  - Access logs
  - Storage calculations
  - Subscription status

**Data Loading:**
- Real-time data loading on view appearance
- Background storage calculation
- Parallel loading of vaults and access logs
- Cached document counts from vault objects (optimized)
- Graceful exception handling with user-friendly messages
- Loading states don't block UI

**Dark Theme Implementation:**
- Use Apple system dark mode (`ColorScheme.dark`)
- Use system colors where possible (removes dependency on CharcoalColorScheme)
- System colors automatically adapt to light/dark mode
- Maintain readability in both themes

**Empty States:**
- Graceful handling when no data available
- Helpful placeholder text
- Appropriate iconography

---

## Vaults Tab

### Vault List View

**Header:**
- Navigation title: "Vaults"
- "+" button (primary action) → Opens CreateVaultView

**Vault List:**
- Inset grouped list style
- Each vault shown as **VaultRow**:
  - **Icon:** Status-based icon in colored circle
    - Active: Primary color
    - Locked: Tertiary color
    - Archived: Secondary color
  - **Name:** Vault name (headline font)
  - **Description:** Optional description (caption, single line, truncated)
  - **Document Count:** Icon + count text (e.g., "5 documents")
    - **IMPORTANT:** Only shown when vault is locked/closed
    - Hidden when vault is open/active (client should not know count when accessible)
  - **Status Indicator:** Color-coded based on vault status (system colors)
- Swipe to delete (shows delete action)
- Tap vault → Navigate to **ClientVaultDetailView**

### Loading States

**Initial Load:**
- **LoadingVaultsView** shows while loading
- Progress indicator displayed
- Prevents empty state flash

**Empty State:**
- **EmptyVaultsView** displayed when no vaults exist
- Large vault icon (80pt, semi-transparent)
- "No Vaults Yet" title
- "Create your first secure vault..." subtitle
- Encourages vault creation

**Error Handling:**
- Alert dialog on error
- "Retry" button to reload vaults
- "OK" button to dismiss
- Error message displayed in alert

### Create Vault Flow

**Access:**
- Tap "+" button in toolbar
- Sheet presentation: **CreateVaultView**

**Vault Creation Form:**
- Name input (required)
- Description input (optional)
- Vault type selection (if applicable)
- Key type selection (Single/Dual-key)
- Source/Sink configuration
- Create button
- Cancel button

**Post-Creation:**
- Sheet dismisses
- Vault list refreshes
- New vault appears in list
- Auto-navigation to vault detail (optional)

---

## Vault Detail View

### View Structure

**Navigation:**
- Large title display mode
- Vault name as title
- Settings gear icon (primary action) → Opens **VaultSettingsView**

**Content Sections (List-based):**

#### 1. Vault Status Section

**VaultStatusCard Component:**
- Status icon (lock/lock.open) in colored circle
- "Locked" or "Unlocked" status text
- Key type display (e.g., "Single Key", "Dual Key")
- **Unlock Button** (if locked):
  - "Unlock Vault" button
  - Lock icon + text
  - Full-width button
  - Primary color background
  - White text
  - Rounded corners
- Color coding:
  - Unlocked: Success (green)
  - Locked: Error (red)

#### 2. Active Session Section

**Conditional Display:**
- Only shows if vault has active session
- Section header: "Active Session"

**VaultSessionTimerView:**
- Displays countdown timer
- 30-minute session duration
- Visual timer representation
- Session expiration warning
- Extend session option (if available)

#### 3. Documents Section

**Locked State:**
- Lock icon (large, centered)
- "Vault is Locked" heading
- "Unlock the vault..." instruction text
- Gray/disabled appearance

**Unlocked/Active Session State:**
- Section header: "Documents"
- List of documents (if any):
  - **DocumentRow** for each document:
    - Document icon/thumbnail
    - Document name
    - Document metadata (size, date, type)
    - Source/Sink indicator
    - AI tags (if available)
  - Swipe actions:
    - Versions: Clock icon → Opens **DocumentVersionHistoryView**
    - Color: Primary
- Tap document → Navigate to **DocumentPreviewView**
- Swipe to delete (red delete action)
- Footer: "You have full access to view and manage all documents in this vault."
- **Empty State:** **EmptyDocumentsView** if no documents

#### 4. Sharing Section

**Section Header:** "Sharing"

**Actions:**
- **Manage Nominees:**
  - Icon: Person badge plus
  - Navigate to **NomineeManagementView**
- **Share Vault:**
  - Icon: Message fill
  - Navigate to **VaultShareView**

#### 5. Support Section (Conditional)

**Display Condition:** Only if vault has assigned officer (`relationshipOfficerID`)

**Section Header:** "Support"

**Actions:**
- **Chat with Officer:**
  - Icon: Message fill
  - Navigate to **ChatView** (clientID, officerID)
  - Footer: "Get help from your assigned officer..."

#### 6. Access & Security Section

**Section Header:** "Access & Security"

**Actions:**
- **Access Logs:**
  - Icon: Clock fill
  - Navigate to **VaultAccessLogView**
- **Threat Dashboard:**
  - Icon: Shield checkered
  - Navigate to **ThreatDashboardView**
- **Threat Metrics:**
  - Icon: Chart line uptrend
  - Navigate to **ThreatMetricsView**

#### 7. Actions Section

**Actions Available:**
- **Add Document:**
  - Icon: Document badge plus
  - Button action → Opens **AddDocumentView** sheet
- **Bulk Upload:**
  - Icon: Square stack fill
  - Navigate to **BulkUploadView**
- **Record Video:**
  - Icon: Video fill
  - Navigate to **VideoRecordingView**
- **Open Vault Session:**
  - Icon: Lock open fill
  - Button action → Starts 30-minute session
  - Disabled if session already active
  - Async task execution

#### 8. Emergency & Transfer Section

**Section Header:** "Emergency & Transfer"

**Actions:**
- **Emergency Access:**
  - Icon: Exclamation triangle fill
  - Warning color (orange/yellow)
  - Navigate to **EmergencyProtocolView**

### Vault Settings Sheet

**Access:** Settings gear icon in navigation bar

**VaultSettingsView Content:**
- Vault name editing
- Description editing
- Vault configuration options
- Retention policies
- Security settings
- Delete vault option (destructive)

### Data Loading Behavior

**On View Appearance:**
1. Load access logs for vault
2. Load active sessions
3. Load documents (only if unlocked/has active session)
4. Subscribe to session updates

**Real-time Updates:**
- **Combine publishers for reactive updates** - *Required implementation*
- Polling every 5 seconds (reduced from 10s) - *Performance improvement*
- Immediate UI updates on status change
- No hanging/freezing during updates
- Background refresh doesn't block UI
- Listens for `vaultSessionUpdate` notifications
- Auto-reloads session state on notification
- Reloads documents when session state changes
- Updates UI reactively

**Status Indicators (Real-Time):**
- Locked: Red indicator, lock icon (updates immediately)
- Unlocked: Green indicator, unlock icon (updates immediately)
- Active Session: Blue indicator, timer (updates immediately)
- Status updates propagate immediately to all views

**Session Management:**
- Vaults require active session to view documents
- Sessions expire after 30 minutes
- Documents hidden when vault locked/no active session
- Session extension available before expiration

---

## Document Management

### Document Upload Flow

**Access:**
- Vault Detail → "Add Document" button
- Opens **AddDocumentView** sheet

**Upload Options:**
1. **Files App:**
   - System document picker
   - Browse Files app
   - Select file(s)

2. **Photos Library:**
   - Photo picker
   - Select image(s)
   - Access to photo library

3. **Camera:**
   - Camera capture interface
   - Take photo directly
   - Real-time capture

**Upload Process:**
1. **File Selection:**
   - User selects file(s)
   - File validation (size, type)

2. **Virus Scanning (Automatic):**
   - Background virus scan
   - Scans file before upload
   - Blocks infected files
   - Shows scan progress

3. **Document Indexing:**
   - **Metadata Extraction:**
     - EXIF data (for images)
     - PDF metadata
     - File properties
   - **OCR Processing:**
     - Text extraction from images
     - PDF text extraction
     - Searchable text indexing
   - **AI Tagging (Enhanced):**
     - Automatic tag generation using Natural Language framework
     - Extracts entities (people, organizations, locations)
     - Extracts keywords from content
     - Generates semantic tags
     - Tags stored with document
     - **Used for source/sink comparison in Intel Reports** - *Required for intel reports*
     - *TODO: Enhance AITaggingService integration with IntelReportService*

4. **Auto PHI Redaction (NEW):**
   - Automatic PHI detection (SSN, DOB, MRN, patient names, etc.)
   - Pattern-based detection for medical reports
   - Auto-redact on medical reports following HIPAA PHI requirements
   - Manual override option available
   - *TODO: Implement PHIDetectionService*

5. **Encryption:**
   - Client-side encryption
   - Uses vault encryption key
   - Encrypts file content

6. **Upload to Vault:**
   - Upload progress indicator
   - Network request
   - Server storage
   - Success confirmation

**Upload States:**
- Selecting file
- Scanning...
- Indexing...
- Encrypting...
- Uploading... (with progress)
- Success ✅
- Error ❌ (with retry option)

### Bulk Upload

**Access:**
- Vault Detail → "Bulk Upload"
- Navigate to **BulkUploadView**

**Features:**
- Multiple file selection
- Batch processing
- Progress tracking for each file
- Error handling per file
- Continue on individual failures

### Video Recording

**Access:**
- Vault Detail → "Record Video"
- Navigate to **VideoRecordingView**

**Recording Flow:**
1. Camera preview
2. Start recording button
3. Recording indicator (red dot)
4. Stop recording button
5. **Preview recorded video** - *TEST REQUIRED: Verify preview shows immediately*
6. Save to vault or discard
7. Upload to vault (same process as documents)

**Testing Requirements:**
- Verify live recording works correctly
- Verify preview shows up immediately after recording
- Test save to vault flow
- Document any issues found
- *TEST REQUIRED: Video recording preview functionality*

### Document Preview

**Access:**
- Tap document in vault list
- Navigate to **DocumentPreviewView**

**Preview Types:**
- **ImagePreviewView:** Images (JPEG, PNG, etc.)
  - Full-screen image display
  - Zoom and pan gestures
  - Share sheet integration

- **PDFPreviewView:** PDF documents
  - PDF viewer with pages
  - Page navigation
  - Zoom controls
  - Text selection (if searchable)

- **VideoPreviewView:** Video files
  - Video player controls
  - Play/pause
  - Seek controls
  - Full-screen playback

- **TextPreviewView:** Text documents
  - Formatted text display
  - Scrollable content
  - Text selection

- **UnsupportedPreviewView:** Unsupported formats
  - Warning message
  - File information
  - Download option (if available)

**Document Actions Menu:**
Accessible from preview view:

1. **Archive/Unarchive:**
   - Toggle archive status
   - Archived documents hidden by default
   - HIPAA compliance feature

2. **Redact:**
   - Navigate to **RedactionView**
   - Select text/regions to redact
   - Apply redaction
   - Permanent redaction (HIPAA compliance)

3. **Share:**
   - iOS share sheet
   - Share to other apps
   - WhatsApp integration

4. **Delete:**
   - Destructive action
   - Confirmation dialog
   - Permanent deletion

5. **Rename Document (NEW):**
   - Edit button in document preview → Rename option
   - Text field with current name
   - Save/Cancel buttons
   - Validation: Non-empty, max length enforced
   - Updates document name immediately
   - *TODO: Implement rename UI*

6. **Version History:**
   - Navigate to **DocumentVersionHistoryView**
   - View all versions
   - Compare versions
   - Restore previous version

**Document Metadata Display:**
- File name
- File size
- MIME type
- Created date
- Last modified date
- Upload source
- AI tags list
- Source/Sink indicator
- Redaction status badge
- Archive status badge

---

## Documents Tab

### Document Retrieval View

**Purpose:**
Search and filter documents **ONLY from vaults with active/open sessions**

**CRITICAL FILTERING REQUIREMENT:**
- Only show documents from vaults with active/open sessions
- Filter: `sessionService.hasActiveSession(for: vault.id)`
- Empty state if no vaults are open: "Open a vault to view documents"
- *TODO: Implement active vault filtering*

**Layout:**

**Search Bar:**
- Magnifying glass icon (left)
- Text field: "Search documents..."
- Clear button (X) when text entered
- Search on submit
- Real-time filtering as user types

**Filter Chips (Horizontal Scroll):**
- **All** (default, selected)
- **Source** (blue indicator)
- **Sink** (green indicator)
- Chips update results immediately on selection

**Results Section:**

**Loading State:**
- Progress view: "Searching..."
- Centered on screen

**Empty State:**
- Large search icon (50pt)
- "No Documents Found" heading
- "Try adjusting your search or filters" subtitle
- Centered on screen

**Results List:**
- Section header: "Search Results (count)"
- **DocumentSearchRow** for each result:
  - **Selection Checkbox** (if selection mode):
    - Checkmark circle (filled when selected)
    - Primary color when selected
  - **Source/Sink Badge:**
    - Icon + text label
    - Color coding:
      - Source: Blue
      - Sink: Green
      - Both: Purple
  - **Document Name:** Headline font, single line
  - **AI Tags:**
    - Horizontal scrollable tags
    - Up to 5 tags shown
    - "+N more" indicator if more tags
    - Tag styling: Primary color background, rounded corners
    - "No AI tags" placeholder if none
  - **Background Highlight:** Selected documents have light primary background

**Toolbar Actions:**
- **Intel Reports Icon:** Opens **IntelReportView**
- **Filter Icon:** Opens **IndexFiltersView** sheet
- **Advanced Filters Icon:** Opens **AdvancedFiltersView** sheet
- **Selection Mode Icon:** Toggle selection mode
  - When active:
    - "Cancel" button
    - "Move" button (enabled when documents selected)
    - Shows vault selection sheet

### Advanced Filters

**Access:** Filter icon in toolbar → **AdvancedFiltersView** sheet

**Filter Options:**

**Sort By:**
- Dropdown picker
- Options:
  - Name (A-Z)
  - Name (Z-A)
  - Date (Newest)
  - Date (Oldest)
  - Size (Largest)
  - Size (Smallest)

**Date Range:**
- Toggle: "Filter by Date"
- When enabled:
  - Start date picker
  - End date picker
  - Date-only selection

**Options:**
- Toggle: "Show Archived"
- Toggle: "Show Redacted"

**Actions:**
- Cancel button (dismisses sheet)
- Apply button (applies filters and dismisses)

### Index Filters

**Access:** Filter icon → **IndexFiltersView** sheet

**Filter Options:**

**File Hash (SHA-256):**
- Text field for hash input
- Auto-capitalization disabled
- Footer: "Filter documents by their SHA-256 hash for exact matching"

**Extracted Text:**
- Text field for content search
- Footer: "Search within extracted text content from PDFs and images (OCR)"

**Author/Camera:**
- Text field
- Footer: "Filter by PDF author or EXIF camera information"

**Device ID:**
- Text field for device identifier
- Auto-capitalization disabled
- Footer: "Filter documents uploaded from a specific device"

**Actions:**
- Cancel button
- Apply button

### Document Selection & Move

**Selection Mode:**
1. Tap selection icon in toolbar
2. View enters selection mode
3. Tap documents to select/deselect
4. Selected count shown
5. "Move" button enabled when documents selected

**Move Documents:**
1. Tap "Move" button
2. **VaultSelectionView** sheet opens
3. Shows list of unlocked vaults (or vaults with active sessions)
4. Each vault shows:
   - Vault name
   - Key type
   - Chevron indicator
5. Tap vault to move documents
6. Confirmation footer: "Moving N document(s) to selected vault"
7. Documents moved to selected vault
8. Selection mode exits
9. Results refresh

### Intel Reports

**Access:** Chart icon in Documents tab toolbar → **IntelReportView**

**Features:**
- AB Testing for source vs sink documents
- Document analytics
- Insights and trends
- Comparative analysis
- **NLP-Generated Custom Tags Comparison:**
  - Compare source documents vs sink documents using NLP tags
  - Analyze tag patterns between source and sink
  - Generate insights based on tag differences
  - Visual comparison charts
  - *TODO: Integrate enhanced NLP tagging with IntelReportService*

### Data Loading

**Initial Load:**
- Loads all vaults
- Loads active sessions
- **Filters to vaults with active sessions only** - *Required implementation*
- Only loads documents from filtered vaults (active/open sessions)
- Shows results in list
- Empty state: "Open a vault to view documents" if no active sessions

**Search Behavior:**
- Real-time filtering as user types
- Filters by:
  - Document name (case-insensitive)
  - AI tags (case-insensitive)
- Applies source/sink filter if selected
- Updates results immediately

**Refresh:**
- Pull to refresh reloads:
  - Vault list
  - Active sessions
  - Documents from active vaults
  - Search results

---

## Store Tab

### Payment Store View

**Navigation:**
- Title: "Store"
- Large title display mode

**Content Sections:**

#### Current Balance Section

**Section Header:** "Current Balance"

**Balance Display:**
- Compact display showing current credits/balance
- Example: "1,250 credits" or "$125.00"
- Warning indicator if balance is low (< threshold)
- Link to add credits (scrolls to credit packages section)

#### Base Subscription Section

**Section Header:** "Monthly Subscription"

**Subscription Plan:**
- Plan name (e.g., "Base Plan")
- Monthly price display
- **Usage Limits Displayed:**
  - Storage limit (e.g., "10 GB")
  - Document limit (e.g., "1,000 documents/month")
  - Upload limit per month (e.g., "500 uploads/month")
- **Current Usage vs Limit:**
  - Progress bar showing usage
  - Text: "X of Y used" (e.g., "7.5 GB of 10 GB used")
  - Color coding: Green (under limit), Yellow (approaching), Red (over limit)
- Subscribe/Manage button
- Auto-renewal toggle (if subscribed)

**Subscription Status:**
- Active/Inactive indicator
- Renewal date (if active)
- Cancel subscription option (if active)

#### In-App Purchase Credits (Conditional)

**Display Condition:** Only shown when:
- User exceeds base plan limits, OR
- Balance is low (< threshold)

**Section Header:** "Additional Credits"

**Credit Packages:**
- **Small Package:**
  - 100 credits - $4.99
  - Purchase button (Apple Store integration)
- **Medium Package:**
  - 500 credits - $19.99
  - Purchase button (Apple Store integration)
- **Large Package:**
  - 1,000 credits - $34.99
  - Purchase button (Apple Store integration)

**Each Package Shows:**
- Credit amount (large, prominent)
- Price
- Value indicator (e.g., "$0.05 per credit")
- Purchase button

**Purchase Flow:**
1. Tap credit package
2. Apple Store purchase sheet appears
3. User confirms purchase with Face ID/Touch ID
4. Purchase processing
5. Credits added to balance automatically
6. Success confirmation: "X credits added to your account"
7. Balance updates immediately

**Error Handling:**
- Purchase failed: "Purchase could not be completed. Please try again."
- Network error: "Unable to connect. Check your internet and try again."
- Simple, elegant error messages

#### Developer/Testing Section (Dev Mode Only)

**Display Condition:** Only visible in development/debug mode

**Section Header:** "Developer Tools"

**Add Dummy Credits:**
- Text field for credit amount
- "Add Credits" button
- Adds credits to balance (for testing purposes)
- Confirmation: "X credits added"
- *Note: Testing purposes only*

**Reset Balance:**
- Button to reset balance to 0
- Confirmation dialog required
- *Note: Testing purposes only*

**Refresh:**
- Pull to refresh reloads:
  - Current balance
  - Subscription status
  - Credit packages
  - Usage statistics

---

## Profile Tab

### Profile View Structure

**Layout:** Inset grouped list style

#### Profile Section

**Section Header:** "Profile"

**User Info Card:**
- **Avatar:**
  - Profile picture (if available):
    - 80x80px circle
    - Border: Primary color, 2pt
    - Clipped to circle
  - Fallback: Initials circle:
    - Primary color gradient background
    - User initials (2 letters, uppercase)
    - White text, title font, semibold
- **User Details:**
  - Full name (title2, bold)
  - Email/Apple User ID (subheadline, secondary color)
  - **Role Badge:**
    - Icon (role-specific)
    - Role name (caption, medium weight)
    - Primary color text
    - Primary color background (10% opacity)
    - Capsule shape
- **Warning (if no profile picture):**
  - "Profile picture required" text
  - Warning color (orange/yellow)
  - Caption font

#### Account Section

**Section Header:** "Account"

**Switch Account:**
- Arrow triangle 2 circlepath icon (primary color)
- "Switch Account" heading
- Subtitle:
  - If multiple roles: "Change between N roles"
  - If single role: "Current role: [Role Name]"
- Chevron indicator
- Tap → Opens **AccountSwitcherView** sheet

**AccountSwitcherView:**
- Shows all available roles
- Current role highlighted
- Tap role to switch
- Sheet dismisses on selection
- App reloads with new role interface

#### Security Section

**Section Header:** "Security"
**Footer:** "Two-Factor Authentication is handled by Apple Sign In"

**Actions:**

**Biometric Authentication:**
- Face ID/Touch ID icon (primary color)
- "Biometric Authentication" label
- Navigate to **BiometricSettingsView**

**Accept Officer Invite** (Client role only):
- Envelope badge icon (secondary color)
- "Accept Officer Invite" label
- Navigate to **AcceptOfficerInviteView**

**BiometricSettingsView:**
- Biometric type icon (large, blue)
- Biometric type name (e.g., "Face ID")
- Status: "Enabled" or "Disabled"
- Toggle: "Enable [Biometric Type]"
- Footer: "Use [Biometric Type] to quickly unlock..."
- **Security Options** (if enabled):
  - Toggle: "Require for All Vaults" (enabled)
  - Toggle: "Require for Sensitive Actions" (enabled)

#### Payment Section

**Section Header:** "Payment"

**Current Balance:**
- Compact display showing:
  - Balance amount (e.g., "1,250 credits" or "$125.00")
  - Low balance warning (if applicable, e.g., "Low balance: 50 credits remaining")
- **Link to Store:**
  - "Manage in Store" button
  - Navigates to Store tab (Tab 4)
  - Opens Store tab with focus on balance section

#### Settings Section

**Section Header:** "Settings"

**Notifications:**
- Bell icon (tertiary color)
- "Notifications" label
- Navigate to **NotificationsSettingsView**

**Privacy:**
- Hand raised icon (accent color)
- "Privacy" label
- Navigate to **PrivacySettingsView**

**Help & Support:**
- Question mark circle icon (info color)
- "Help & Support" label
- Navigate to **HelpSupportView**

#### About Section

**Section Header:** "About"

**Items:**
- **Version:** "1.0.0" (labeled content)
- **Website:**
  - Globe icon
  - Link to: https://khandoba.org
  - Opens in Safari
- **Terms of Service:**
  - Document text icon
  - Link to: https://khandoba.org/terms
- **Privacy Policy:**
  - Lock document icon
  - Link to: https://khandoba.org/privacy

#### Developer Section

**Section Header:** "Developer"
**Footer:** "Warning: This will delete all data. Use only for testing."

**Purge Database:**
- Trash icon (red)
- "Purge Database" label (red text)
- Navigate to **DatabasePurgeView**
- Destructive action

#### Sign Out Section

**Sign Out Button:**
- Rectangle portrait and arrow right icon
- "Sign Out" label (destructive style/red)
- Tap → Shows confirmation alert:
  - Title: "Sign Out"
  - Message: "Are you sure you want to sign out?"
  - Actions:
    - Cancel
    - Sign Out (destructive, confirms action)
  - On confirm: Executes sign out, returns to WelcomeView

### Profile Data Loading

**On View Appearance:**
- Loads available roles from AccountSwitchService
- Checks if user has multiple roles
- Updates UI reactively

**Real-time Updates:**
- Profile picture updates immediately
- Role changes reflected instantly
- Account switcher updates dynamically

---

## Advanced Features

### Nominee Management

**Access:** Vault Detail → Sharing → Manage Nominees → **NomineeManagementView**

**Features:**
- List of current nominees
- Nominee status indicators
- Invite nominee button
- Remove nominee option
- Nominee invitation via iPhone messaging

**Invitation Flow:**
1. Tap "Invite Nominee"
2. **NomineeInvitationView** opens
3. Enter nominee details
4. Send invitation via Messages app
5. Nominee receives invitation link
6. Nominee accepts and gains access

### Vault Sharing

**Access:** Vault Detail → Sharing → Share Vault → **VaultShareView**

**Features:**
- Share vault via WhatsApp
- Share vault via other methods
- Generate shareable link
- Set sharing permissions
- Manage shared access

### Emergency Access

**Access:** Vault Detail → Emergency & Transfer → Emergency Access → **EmergencyProtocolView**

**Features:**
- Request emergency access
- Requires officer approval
- Justification required
- Status tracking
- Approval/denial notifications

### Threat Dashboard

**Access:** Vault Detail → Access & Security → Threat Dashboard → **ThreatDashboardView**

**Features:**
- Threat level visualization
- Anomaly detection results
- Security alerts
- Threat timeline
- Risk assessment

### Threat Metrics

**Access:** Vault Detail → Access & Security → Threat Metrics → **ThreatMetricsView**

**Features:**
- Threat level graphs
- Access frequency charts
- Anomaly score visualization
- ML predictions
- Historical trends

### Access Logs

**Access:** Vault Detail → Access & Security → Access Logs → **VaultAccessLogView**

**Features:**
- Complete access history
- Filter by access type (opened, closed, viewed, modified, deleted)
- Geolocation data
- Timestamp information
- User/IP information
- Export logs option

### Document Version History

**Access:** Document preview → Swipe action → Versions → **DocumentVersionHistoryView**

**Features:**
- List of all document versions
- Version metadata (date, size, changes)
- Compare versions
- Restore previous version
- Delete old versions

### Bulk Operations

**Bulk Upload:**
- Multiple file selection
- Batch processing
- Individual file progress
- Error handling per file

**Bulk Move:**
- Select multiple documents (Documents tab)
- Move to different vault
- Batch operation confirmation

### Chat with Officer

**Access:** Vault Detail → Support → Chat with Officer → **ChatView**

**Chat Header (NEW):**
- **Relationship Officer Name** - *Required implementation*
- Officer role badge
- Online/Offline status indicator
- Officer avatar (if available)
- *TODO: Add officer info header in ChatView*

**Features:**
- In-app messaging
- Real-time message delivery
- Message history
- Support communication
- Troubleshooting assistance

**Chat Interface:**
- Message list (scrollable)
- Text input field
- Send button
- Message bubbles (sent/received)
- Timestamps
- Read receipts (if available)

**Testing Requirements:**
- Test chat features with admin
- Verify real-time message delivery
- Test message history persistence
- *TEST REQUIRED: Chat functionality with admin*

---

## Error Handling & Edge Cases

### Notification Design (Simple & Elegant)

**Error Messages:**
- Simple, clear text (no technical jargon)
- Actionable guidance
- Example: "Unable to connect. Check your internet and try again."
- Brief, user-friendly language

**Warning Messages:**
- Subtle, non-intrusive
- Icon + brief text
- Dismissible
- Example: "Low balance: 50 credits remaining"
- Auto-dismiss after 5 seconds (optional)

**Success Messages:**
- Brief confirmation
- Auto-dismiss after 2 seconds
- Example: "Document uploaded successfully"
- Non-blocking, subtle appearance

**Loading States:**
- Minimal progress indicators
- Skeleton screens for lists
- Non-blocking where possible
- Clear "Loading..." text when needed
- Don't block UI interactions

### Network Errors

**Offline State:**
- Offline indicator (subtle banner)
- Cached data displayed
- Retry button when connection restored
- Error message: "No internet connection. Some features may be unavailable."

**Timeout Errors:**
- Simple message: "Request timed out. Please try again."
- Retry button
- Auto-retry option (configurable, max 3 attempts)

**Server Errors:**
- Simple message: "Something went wrong. Please try again."
- Retry option
- Contact support option (for persistent errors)
- No technical error codes shown to user

### Validation Errors

**File Upload:**
- File size limit exceeded
- Unsupported file type
- Invalid file format
- Clear error messages with guidance

**Form Validation:**
- Required field indicators
- Inline error messages
- Disabled submit until valid
- Real-time validation feedback

### Permission Errors

**Camera Access:**
- Permission denied alert
- Instructions to enable in Settings
- Deep link to Settings app

**Photo Library Access:**
- Permission denied alert
- Instructions to enable in Settings
- Alternative: Manual file selection

**Location Access:**
- Permission denied (for geolocation in access logs)
- Graceful degradation
- Continue without location

### Session Expiration

**Vault Session Expired:**
- Session expired notification
- Auto-lock vault
- Documents hidden
- Prompt to unlock again
- Session timer resets

**App Session Expired:**
- Re-authentication required
- Return to WelcomeView
- Sign in again prompt

### Empty States

**No Vaults:**
- Empty vaults view
- Create vault prompt
- Helpful guidance

**No Documents:**
- Empty documents view
- Upload document prompt
- Quick actions

**No Search Results:**
- Empty search state
- Adjust filters suggestion
- Clear search option

### Loading States

**Initial Load:**
- Loading indicators
- Skeleton screens (where applicable)
- Progress feedback

**Background Loading:**
- Non-blocking operations
- Subtle progress indicators
- Optimistic UI updates

### Data Synchronization

**Conflict Resolution:**
- Last-write-wins (or merge strategy)
- Conflict notification
- Manual resolution option

**Sync Errors:**
- Sync failure alert
- Retry sync button
- Offline mode indicator

---

## UI/UX Patterns & Conventions

### Color Scheme (Dark Theme - Apple System Colors)

**Primary Colors:**
- Primary: Use Apple system colors (`.primary`, `.secondary`, `.tertiary`)
- Secondary: System secondary color (adapts to dark mode)
- Tertiary: System tertiary color (adapts to dark mode)
- Accent: System accent color (adapts to dark mode)
- **Note:** Remove CharcoalColorScheme dependencies where possible
- System colors automatically adapt to light/dark mode

**Status Colors:**
- Success: System green (`.green`)
- Error: System red (`.red`)
- Warning: System orange (`.orange`)
- Info: System blue (`.blue`)

**Text Colors:**
- Primary: System primary label color (`.primary` or `.label`)
- Secondary: System secondary label color (`.secondaryLabel`)
- Tertiary: System tertiary label color (`.tertiaryLabel`)

**Background:**
- Background: System background (`.background`)
- Surface: System secondary background (`.secondarySystemBackground`)
- **Dark Mode:** Automatically handled by system colors

**Implementation:**
- Use `ColorScheme.dark` for dark theme
- System colors adapt automatically
- Test in both light and dark modes

### Typography

**Headings:**
- Title: Large, bold (system font)
- Headline: Medium, semibold (system font)
- Subheadline: Smaller, regular (system font)

**Body:**
- Body: Standard size, regular weight (system font)
- Caption: Small, secondary color (system font)

**Dark Mode:**
- System fonts maintain readability in dark mode
- Support Dynamic Type for accessibility
- Text colors automatically adapt

### Spacing (Reduced Footprint)

- Consistent padding: 12pt, 8pt, 6pt (reduced from 16pt, 12pt, 8pt)
- Section spacing: 12pt (reduced from 24pt)
- Item spacing: 8pt, 6pt (reduced from 12pt, 8pt)
- Compact list styles throughout

### Icons

- SF Symbols used throughout
- Enterprise icons for specific features
- Consistent sizing and styling
- Color-coded by context

### Navigation Patterns

- Large title navigation bars
- Sheet presentations for secondary actions
- Modal presentations for critical actions
- Tab-based navigation for main sections
- Stack navigation for drill-downs

### Gestures

- Pull to refresh (lists and scroll views)
- Swipe to delete (lists)
- Swipe actions (document rows)
- Tap to navigate (standard interaction)
- Long press (context menus, where applicable)

### Feedback

- Haptic feedback for actions
- Visual feedback (button states)
- Loading indicators
- Success/error alerts
- Toast messages (where applicable)

---

## Accessibility

### VoiceOver Support

- All UI elements labeled
- Navigation hints provided
- State announcements
- Error announcements

### Dynamic Type

- Supports system font scaling
- Adjusts layout for larger text
- Maintains readability at all sizes

### Color Contrast

- WCAG AA compliant
- High contrast options (if supported)
- Not relying solely on color

### Interaction

- Minimum touch target sizes (44x44pt)
- Clear focus indicators
- Keyboard navigation support (where applicable)

---

## Performance Considerations

### Loading Optimization

- Lazy loading where appropriate
- Pagination for large lists
- Cached data usage
- Background data fetching

### Memory Management

- Image caching
- Document preview optimization
- Cleanup of unused resources
- Efficient data structures

### Network Optimization

- Request batching
- Compression where applicable
- Retry logic with exponential backoff
- Offline-first approach

### Real-Time Update Performance

- Efficient polling (5s interval for vault status)
- Background refresh doesn't block UI
- Combine publishers for reactive updates
- Cache status to reduce API calls
- Exponential backoff for dual-key status polling (2s initially, back off to 10s)
- No hanging/freezing during updates

---

## Incomplete Logic & Implementation Gaps

This section documents incomplete logic, missing implementations, and areas requiring attention.

### Real-Time Vault Status Updates

**Current State:**
- Manual refresh or 10s timer
- Status updates may lag
- UI may not reflect current state immediately

**Missing:**
- WebSocket/polling for status changes
- Reactive updates using Combine publishers
- Immediate UI updates on status change

**Required:**
- Combine publishers for reactive updates
- Polling every 5 seconds (reduced from 10s)
- Immediate UI updates on status change
- No hanging/freezing during updates
- Background refresh doesn't block UI

**Implementation:**
- File: `Khandoba/Core/Services/VaultSessionService.swift`
- Add Combine publishers for vault status
- Implement 5s polling interval
- Update all views to subscribe to status changes

**Status:** TODO

---

### Dual-Key Approval Status Polling

**Current State:**
- Creates dual-key request
- No client-side polling for approval status
- User must manually check or refresh

**Missing:**
- Client-side polling for approval status
- Real-time approval notifications
- Status updates in UI

**Required:**
- Status polling with exponential backoff
- Poll every 2s initially, back off to 10s
- Update UI when approval status changes
- Show pending/approved/denied states

**Implementation:**
- File: `Khandoba/Core/Services/DualKeyService.swift`
- Add status polling mechanism
- Implement exponential backoff
- Update `ClientVaultDetailView` to show status

**Status:** TODO

**Testing:** Test with admin later

---

### Document Rename UI

**Current State:**
- No UI for renaming documents
- Documents can only be renamed through backend

**Missing:**
- Edit button in document preview
- Rename text field
- Save/cancel actions

**Required:**
- Edit button in `DocumentPreviewView`
- Rename option in actions menu
- Text field with current name
- Validation (non-empty, max length)
- Save/cancel buttons
- Immediate update after save

**Implementation:**
- File: `Khandoba/Features/Documents/Views/DocumentPreviewView.swift`
- Add edit button to toolbar
- Create `DocumentRenameView` sheet
- Update document name via `DocumentViewModel`

**Status:** TODO

---

### Enhanced NLP Tagging for Intel Reports

**Current State:**
- Basic AI tagging exists (`AITaggingService`)
- Tags generated but not used for intel reports comparison
- Source/sink comparison not leveraging NLP tags

**Missing:**
- Integration with IntelReportService
- Tag comparison between source and sink documents
- Semantic analysis for insights

**Required:**
- Generate enhanced NLP tags for source/sink comparison
- Extract entities (people, organizations, locations)
- Extract keywords and semantic patterns
- Compare tags between source and sink documents
- Generate insights based on tag differences

**Implementation:**
- File: `Khandoba/Core/Services/AITaggingService.swift` (enhance)
- File: `Khandoba/Core/Services/IntelReportService.swift` (integrate)
- Enhance tag generation with more semantic analysis
- Add tag comparison logic to IntelReportService

**Status:** TODO

---

### Auto PHI Redaction

**Current State:**
- Manual redaction only
- No automatic PHI detection
- User must manually select regions to redact

**Missing:**
- Automatic PHI detection
- Pattern-based detection (SSN, DOB, MRN, patient names, etc.)
- Auto-redact on medical reports

**Required:**
- Pattern detection for PHI:
  - SSN (XXX-XX-XXXX)
  - DOB (MM/DD/YYYY)
  - MRN (Medical Record Number)
  - Patient names
  - Medical procedure codes
- Auto-redact on medical reports following HIPAA PHI requirements
- Manual override option
- Detection confidence scoring

**Implementation:**
- Create: `Khandoba/Core/Services/PHIDetectionService.swift`
- Add pattern matching for PHI
- Integrate with document upload flow
- Auto-redact detected PHI in medical reports
- Add manual override option

**Status:** TODO

---

### Documents Tab Active Vault Filtering

**Current State:**
- Shows documents from all open vaults
- May show documents from vaults without active sessions

**Missing:**
- Filter to only active/open vaults
- Empty state when no vaults are open

**Required:**
- Only show documents from vaults with active/open sessions
- Filter: `sessionService.hasActiveSession(for: vault.id)`
- Empty state: "Open a vault to view documents"

**Implementation:**
- File: `Khandoba/Features/Documents/Views/DocumentRetrievalView.swift`
- Update `loadDocumentsFromOpenVaults()` to filter by active sessions
- Add empty state message

**Status:** TODO

---

### Document Count Conditional Display

**Current State:**
- Document count shown always in vault list
- Client can see count even when vault is accessible

**Missing:**
- Conditional display based on vault lock status
- Hide count when vault is open/active

**Required:**
- Vault list shows document count ONLY when vault is locked/closed
- When vault is open/active: Document count hidden
- Rationale: Client should not know document count when vault is accessible

**Implementation:**
- File: `Khandoba/Features/Vaults/Views/VaultListView.swift`
- Update `VaultRow` to conditionally show document count
- Check vault lock status and active session status

**Status:** TODO

---

### Chat Officer Info Display

**Current State:**
- Only shows chat interface
- No officer information displayed

**Missing:**
- Officer name/info in chat header
- Relationship officer display

**Required:**
- Display relationship officer name in chat header
- Officer role badge
- Online/Offline status indicator
- Officer avatar (if available)

**Implementation:**
- File: `Khandoba/Features/Chat/Views/ChatView.swift`
- Add officer info header
- Fetch officer details from `UserManagementService`
- Display officer information

**Status:** TODO

**Testing:** Test chat features with admin later

---

### Video Recording Preview

**Current State:**
- Video recording functionality exists
- Preview functionality needs verification

**Missing:**
- Verification that preview shows immediately
- Testing of live recording

**Required:**
- Verify live recording works correctly
- Verify preview shows up immediately after recording
- Test save to vault flow
- Document any issues found

**Implementation:**
- File: `Khandoba/Features/Vaults/Views/VideoRecordingView.swift`
- Test and verify preview functionality
- Fix any issues with preview display

**Status:** TEST REQUIRED

---

### Dual-Key Lock/Unlock Client Side

**Current State:**
- Client-side dual-key unlock flow exists
- Request creation works
- Approval status polling missing

**Missing:**
- Status polling for approval
- Real-time status updates

**Required:**
- Add status polling requirement (exponential backoff)
- Test with admin later
- Document current implementation status

**Implementation:**
- File: `Khandoba/Core/Services/DualKeyService.swift`
- Add status polling
- Update `ClientVaultDetailView` to show status

**Status:** TEST REQUIRED (with admin)

---

## Implementation Requirements

This section provides file paths, dependencies, and implementation details for each feature.

### Dashboard Updates

**Files to Modify:**
- `Khandoba/Features/Dashboard/Views/ClientMainView.swift`
- `Khandoba/Features/Dashboard/Views/ClientDashboardView.swift`

**New Components:**
- `Khandoba/UI/Components/DataSavedEstimateCard.swift` (NEW)
- `Khandoba/UI/Components/BalanceWarningBanner.swift` (NEW)

**Dependencies:**
- `PaymentUsageService` for balance checking
- `VaultViewModel` for storage calculation

**Testing Requirements:**
- Test balance warning threshold (20%)
- Test data saved calculation accuracy
- Test dark mode appearance

---

### Store Tab Rewrite

**Files to Modify:**
- `Khandoba/Features/Payments/Views/PaymentStoreView.swift` (complete rewrite)

**New Components:**
- `Khandoba/Features/Payments/Views/BaseSubscriptionView.swift` (NEW)
- `Khandoba/Features/Payments/Views/CreditPackagesView.swift` (NEW)
- `Khandoba/Features/Payments/Views/DummyCreditsView.swift` (NEW, dev only)

**Dependencies:**
- `StoreKit` for in-app purchases
- `PaymentService` for subscription management
- `PaymentUsageService` for balance tracking

**Testing Requirements:**
- Test subscription purchase flow
- Test credit package purchases
- Test dummy credits (dev mode)
- Test balance updates after purchase
- Test error handling

---

### Role Selection Simplification

**Files to Modify:**
- `Khandoba/Features/Authentication/Views/RoleSelectionView.swift`
- `Khandoba/App/RoleSelectionView.swift`

**Dependencies:**
- `UserRoleService` for role assignment
- Remove Officer role from UI

**Testing Requirements:**
- Test Client role selection
- Test Admin role (disabled for regular signup)
- Test role assignment flow

---

### Document Management Enhancements

**Files to Modify:**
- `Khandoba/Features/Documents/Views/DocumentPreviewView.swift` (add rename)
- `Khandoba/Core/Services/AITaggingService.swift` (enhance NLP)
- `Khandoba/Core/Services/IntelReportService.swift` (integrate tags)

**New Files:**
- `Khandoba/Core/Services/PHIDetectionService.swift` (NEW)
- `Khandoba/Features/Documents/Views/DocumentRenameView.swift` (NEW)

**Dependencies:**
- `NaturalLanguage` framework for NLP
- `DocumentViewModel` for rename operation

**Testing Requirements:**
- Test document renaming
- Test NLP tag generation
- Test PHI detection accuracy
- Test auto-redaction on medical reports

---

### Real-Time Vault Status Updates

**Files to Modify:**
- `Khandoba/Core/Services/VaultSessionService.swift`
- `Khandoba/Features/Vaults/Views/ClientVaultDetailView.swift`
- `Khandoba/Features/Vaults/Views/VaultListView.swift`

**Dependencies:**
- `Combine` framework for reactive updates
- Timer for polling

**Testing Requirements:**
- Test 5s polling interval
- Test immediate UI updates
- Test no UI blocking during updates
- Test status propagation to all views

---

### Dual-Key Status Polling

**Files to Modify:**
- `Khandoba/Core/Services/DualKeyService.swift`
- `Khandoba/Features/Client/Views/ClientVaultDetailView.swift`

**Dependencies:**
- `Combine` for reactive updates
- Exponential backoff implementation

**Testing Requirements:**
- Test polling with exponential backoff
- Test status updates in UI
- Test with admin approval flow

---

### Documents Tab Filtering

**Files to Modify:**
- `Khandoba/Features/Documents/Views/DocumentRetrievalView.swift`

**Dependencies:**
- `VaultSessionService` for active session checking

**Testing Requirements:**
- Test filtering by active sessions
- Test empty state when no vaults open
- Test document loading from active vaults only

---

### Chat Officer Display

**Files to Modify:**
- `Khandoba/Features/Chat/Views/ChatView.swift`

**Dependencies:**
- `UserManagementService` for officer details
- `Vault` model for relationship officer ID

**Testing Requirements:**
- Test officer info display
- Test online/offline status
- Test with admin chat

---

### Video Recording Preview

**Files to Review:**
- `Khandoba/Features/Vaults/Views/VideoRecordingView.swift`

**Testing Requirements:**
- Verify live recording works
- Verify preview shows immediately
- Test save to vault flow
- Document any issues

---

### Dark Theme Implementation

**Files to Modify:**
- All view files (systematic update)
- `Khandoba/UI/Styles/ColorScheme.swift` (update or remove)
- Replace `CharcoalColorScheme` with system colors

**Dependencies:**
- SwiftUI system colors
- `ColorScheme.dark` for dark mode

**Testing Requirements:**
- Test all views in dark mode
- Test system color adaptation
- Test readability in both themes
- Remove CharcoalColorScheme dependencies

---

## Future Enhancements (Placeholder)

_This section can be used to document planned features or improvements._

- [ ] Enhanced analytics dashboard
- [ ] Advanced document search
- [ ] Batch document operations
- [ ] Document templates

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| [Date] | 1.0 | Initial documentation | [Author] |

---

**Document Status:** ✅ Complete | 🔄 In Progress | 📝 Draft

**Last Reviewed:** [Date]

**Next Review Date:** [Date]

---

## Notes

_Add any additional notes, considerations, or context here._


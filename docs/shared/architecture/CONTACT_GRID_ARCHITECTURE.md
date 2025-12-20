# Contact Grid Selection Architecture

## Overview

Implemented a **Game Center-style contact selection interface** that shows which contacts are already app users and which can be invited, similar to the Game Center friend invitation flow.

---

## Features

### 1. Grid Layout
- **2-column grid** of contact cards
- Card-based design similar to Game Center
- Responsive layout that adapts to screen size

### 2. User Detection
- **Automatically checks** which contacts are already registered app users
- Uses `ContactDiscoveryService` to query CloudKit and local database
- Matches contacts by email address and phone number

### 3. Visual Indicators
- **Green message icon badge** on avatar for existing users
- Similar to Game Center's green message icon
- Clear visual distinction between existing users and new invites

### 4. Contact Cards
Each card displays:
- **Avatar** (contact photo or initials)
- **Name** (contact's full name)
- **"From Contacts"** label
- **"Invite" button** (green for existing users, primary color for new users)
- **Selection indicator** (border highlight when selected)

### 5. Search Functionality
- Real-time search by name, phone, or email
- Filters contacts as you type
- Maintains grid layout during search

---

## Implementation

### New View: `ContactGridSelectionView.swift`

**Location:** `Khandoba Secure Docs/Views/Sharing/ContactGridSelectionView.swift`

**Key Components:**

1. **ContactGridSelectionView**
   - Main view with grid layout
   - Integrates `ContactDiscoveryService` for user detection
   - Handles permissions and loading states

2. **ContactGridCard**
   - Individual contact card component
   - Shows avatar with user indicator badge
   - Displays name, source, and invite button
   - Visual feedback for selection

3. **ContactDiscoveryService Integration**
   - Automatically discovers registered contacts on load
   - Checks CloudKit for matching email addresses
   - Checks local SwiftData users
   - Normalizes phone numbers for matching

---

## How It Works

### Flow:

1. **User opens contact selection**
   - `ContactGridSelectionView` is presented
   - Requests contacts permission if needed

2. **Load contacts**
   - Fetches all contacts from device
   - Filters to contacts with phone/email

3. **Discover registered users**
   - `ContactDiscoveryService.discoverRegisteredContacts()` runs
   - Queries CloudKit for users matching contact emails
   - Checks local SwiftData users
   - Builds set of registered contact identifiers

4. **Display contacts in grid**
   - Each contact card checks: `discoveryService.isContactRegistered(contact)`
   - Shows green badge if registered
   - Shows appropriate invite button color

5. **User selects contact**
   - Taps "Invite" button
   - Callback provides: `(contact, isExistingUser)`
   - Parent view can handle differently if needed

---

## Visual Design

### Contact Card Layout:
```
┌─────────────────┐
│   [Avatar]      │  ← Green badge if existing user
│   [Badge]       │
│                 │
│   Contact Name  │
│   From Contacts │
│                 │
│   [Invite]      │  ← Green if user, Primary if new
└─────────────────┘
```

### Grid Layout:
```
┌─────┐ ┌─────┐
│  A  │ │  B  │
└─────┘ └─────┘
┌─────┐ ┌─────┐
│  C  │ │  D  │
└─────┘ └─────┘
```

---

## Integration

### Updated: `NomineeInvitationView.swift`

**Changed:**
- Replaced `ContactListView` with `ContactGridSelectionView`
- Now receives `(contact, isExistingUser)` callback
- Can differentiate invitation flow based on user status

**Before:**
```swift
ContactListView(
    onContactSelected: { contact in
        selectedContact = contact
    }
)
```

**After:**
```swift
ContactGridSelectionView(
    onContactSelected: { contact, isExistingUser in
        selectedContact = contact
        // isExistingUser indicates if contact is already a user
    }
)
```

---

## Benefits

### 1. Better UX
- **Visual clarity:** Users can immediately see who's on the app
- **Familiar pattern:** Matches Game Center/iMessage design
- **Efficient selection:** Grid layout shows more contacts at once

### 2. Smart Invitations
- **Existing users:** Can be invited directly (they already have the app)
- **New users:** Need app download invitation
- **Different flows:** Can customize invitation based on user status

### 3. Performance
- **Async discovery:** User detection happens in background
- **Cached results:** Registered contacts cached for quick lookup
- **Efficient queries:** CloudKit queries optimized for email matching

---

## Technical Details

### ContactDiscoveryService

**Methods:**
- `discoverRegisteredContacts()` - Discovers all registered contacts
- `isContactRegistered(_ contact: CNContact) -> Bool` - Quick check for single contact
- `checkIfRegistered(phone:email:) -> Bool` - Check specific identifier

**Matching Logic:**
1. Normalizes phone numbers (removes formatting, country codes)
2. Lowercases email addresses
3. Queries CloudKit `CD_User` records by email
4. Checks local SwiftData users
5. Builds set of registered identifiers

### Contact Matching

**Email Matching:**
- Exact match (case-insensitive)
- CloudKit query: `email IN [contact emails]`
- Local query: SwiftData fetch

**Phone Matching:**
- Normalized comparison
- Removes: spaces, dashes, parentheses
- Handles country codes (US, India)
- Last 10 digits comparison

---

## Usage Example

```swift
ContactGridSelectionView(
    onContactSelected: { contact, isExistingUser in
        if isExistingUser {
            // Contact already has the app
            // Can send direct vault share or invitation
            print("✅ \(contact.givenName) is already a user")
        } else {
            // Contact needs to download app first
            // Send app download link + invitation
            print("📱 \(contact.givenName) needs to be invited")
        }
        
        // Proceed with invitation
        selectedContact = contact
    },
    onDismiss: {
        // Handle dismissal
    }
)
```

---

## Future Enhancements

### Potential Improvements:
1. **Multi-select:** Allow selecting multiple contacts at once
2. **Batch invitations:** Invite multiple contacts in one action
3. **User profiles:** Show more info for existing users (last active, etc.)
4. **Smart suggestions:** Prioritize contacts you interact with most
5. **Recent contacts:** Show recently invited contacts at top

---

## Comparison

### Before (List View):
- Simple list of contacts
- No user detection
- No visual indicators
- One contact at a time

### After (Grid View):
- ✅ Grid layout (2 columns)
- ✅ User detection (existing vs new)
- ✅ Visual indicators (green badge)
- ✅ Better information density
- ✅ Game Center-style UX

---

**Status:** ✅ Implemented and integrated

**Files Created:**
- `ContactGridSelectionView.swift` - New grid-based contact selection

**Files Updated:**
- `NomineeInvitationView.swift` - Uses new grid view

**Build Status:** ✅ Builds successfully

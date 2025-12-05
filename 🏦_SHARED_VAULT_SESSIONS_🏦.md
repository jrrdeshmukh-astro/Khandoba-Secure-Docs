# 🏦 SHARED VAULT SESSIONS - BANK VAULT CONCEPT

## ✅ **THE CONCEPT**

**Like a physical bank vault:** If the vault is open, it's open for EVERYONE. If it's locked, it's locked for EVERYONE.

---

## 🎯 **BANK VAULT METAPHOR**

### **Physical Bank Vault:**
```
Morning: Employee opens vault
         ↓
Status: OPEN for all employees
         ↓
Multiple employees access throughout day
         ↓
Evening: Manager locks vault
         ↓
Status: LOCKED for everyone
```

### **Digital Implementation:**
```
User A opens vault
         ↓
SharedVaultSession created
         ↓
Status: OPEN for Users A, B, C, D, E
         ↓
All users can access documents
         ↓
User A (owner) locks vault
         ↓
SharedVaultSession closed
         ↓
Status: LOCKED for everyone
```

---

## 🏗️ **ARCHITECTURE**

### **Key Principles:**

**1. Single Session Instance**
- One session per vault (not per user)
- All users share the same session
- Session state is global for that vault

**2. Synchronized State**
- If open for one → open for all
- If locked → locked for all
- Real-time updates to all users

**3. Privileged Control**
- Vault owner can lock
- Admins can lock
- Regular members cannot lock (view-only control)

**4. Time-Lock Mechanism**
- Auto-lock after 30 minutes
- Activity extends timeout
- Like bank vault time-delay

**5. Notification System**
- Notify all members when vault opens
- Notify all when vault locks
- Notify all when auto-locks

---

## 📁 **SharedVaultSessionService.swift**

### **Core Functions:**

**Session Management:**
```swift
openSharedVault(vault, unlockedBy: user)
// Creates single session for ALL users
// Notifies everyone
// Starts auto-lock timer

lockSharedVault(vault, lockedBy: user)
// Closes session for ALL users
// Notifies everyone
// Logs who locked it

isVaultOpen(vault) -> Bool
// Check if vault currently has active shared session
// Works same for all users

extendSession(for: vault, activity:)
// User activity extends session for EVERYONE
// Recording, previewing, uploading → extends time
```

**Permission Control:**
```swift
canLockVault(vault, user:) -> Bool
// Owner: YES
// Admin: YES
// Regular member: NO
```

---

## 🎨 **USER EXPERIENCE**

### **Scenario 1: Opening Vault**

**User A (Owner):**
```
Taps "Unlock Vault"
   ↓
Vault opens
Notification: "You opened Medical Records"
```

**User B (Member):**
```
Sees vault icon change: 🔒 → 🔓
Notification: "John opened Medical Records"
Can now access documents
```

**User C, D, E (Members):**
```
All receive notification
All see vault as unlocked
All can access documents
```

---

### **Scenario 2: Locking Vault**

**User A (Owner):**
```
Taps "Lock Vault" button
   ↓
Vault locks
Notification: "You locked Medical Records"
```

**User B, C, D, E (Members):**
```
Notification: "John locked Medical Records (open for 2h 15m)"
Vault icon: 🔓 → 🔒
Can no longer access documents
```

---

### **Scenario 3: Auto-Lock**

**After 30 minutes of inactivity:**
```
System: Session expired
   ↓
Auto-lock triggered
   ↓
ALL users receive notification:
"Medical Records auto-locked (session expired)"
   ↓
Vault becomes locked for everyone
```

---

### **Scenario 4: Activity Extension**

**User B viewing documents:**
```
User B uploads document
   ↓
System: Activity detected
Session extended +15 minutes
   ↓
ALL users benefit from extension
Vault stays open longer for everyone
```

---

## 📊 **COMPARISON: INDIVIDUAL vs SHARED**

### **OLD (Individual Sessions):**
```
User A: Vault OPEN (their session)
User B: Vault LOCKED (no session)
User C: Vault OPEN (their session)
User D: Vault LOCKED (no session)

Result: Confusing, inconsistent
```

### **NEW (Shared Sessions):**
```
Vault Status: OPEN
   ↓
User A: Can access ✅
User B: Can access ✅
User C: Can access ✅
User D: Can access ✅

Result: Clear, synchronized
```

---

## 🔐 **SECURITY FEATURES**

### **Dual-Key Compatibility:**
- Dual-key vault requires approval to open
- Once approved → open for ALL approved users
- Any privileged user can lock
- Re-opening requires new approval

### **Access Logging:**
- Log who opened vault
- Log who locked vault
- Log session duration
- Log all members who accessed

### **Time-Lock:**
- Automatic timeout (30 min default)
- Activity extends timeout
- Cannot bypass time-lock
- Mimics physical vault time-delay

---

## 📱 **UI COMPONENTS**

### **Vault Detail View Updates:**

**Session Status Display:**
```
┌────────────────────────────┐
│ 🔓 Medical Records         │
│                            │
│ Status: OPEN               │
│ Opened by: John Smith      │
│ Time remaining: 15:23      │
│                            │
│ [🔒 Lock Vault]  ← Owner only
└────────────────────────────┘
```

**When Locked:**
```
┌────────────────────────────┐
│ 🔒 Medical Records         │
│                            │
│ Status: LOCKED             │
│ Last opened: 2h ago        │
│ By: John Smith             │
│                            │
│ [🔓 Unlock Vault]
└────────────────────────────┘
```

---

## 🔔 **NOTIFICATION TYPES**

### **1. Vault Opened**
```
Title: "Vault Opened"
Body: "John Smith opened Medical Records"
Icon: 🔓
Sound: Default
```

### **2. Vault Locked**
```
Title: "Vault Locked"
Body: "John Smith locked Medical Records (open for 2h 15m)"
Icon: 🔒
Sound: Default
```

### **3. Auto-Lock**
```
Title: "Vault Auto-Locked"
Body: "Medical Records was automatically locked"
Icon: ⏰
Sound: Default
```

### **4. Session Already Active**
```
Title: "Vault Already Open"
Body: "Medical Records is currently open"
Icon: ℹ️
Sound: None (info only)
```

---

## 🎯 **USE CASES**

### **Healthcare Team:**
```
Dr. Smith opens Patient Records vault (9:00 AM)
   ↓
Nurses A, B, C receive notification
All can now access patient documents
   ↓
Throughout day: Updates, reviews, notes
   ↓
Dr. Smith locks vault (5:00 PM)
   ↓
All team members notified
Vault locked for everyone
```

### **Legal Team:**
```
Attorney opens Case Files vault
   ↓
Paralegals and associates notified
Everyone accesses case documents
   ↓
After meeting: Attorney locks vault
   ↓
Team notified, vault secured
```

### **Family Vault:**
```
Parent opens Family Documents
   ↓
Spouse and adult children notified
Everyone can view/add memories
   ↓
Auto-locks after 30 min inactivity
   ↓
All family members notified
```

---

## 🔄 **REAL-TIME SYNC**

### **How It Works:**

**Session Monitoring:**
- Timer checks every 5 seconds
- Detects session changes
- Updates UI for all users
- Triggers notifications

**State Propagation:**
```
User A opens vault
   ↓
SharedVaultSession created in service
   ↓
@Published property updates
   ↓
SwiftUI views refresh
   ↓
All users see updated state
   ↓
Notifications sent
```

---

## 💡 **ADVANTAGES**

### **Clarity:**
- ✅ Everyone sees same state
- ✅ No confusion about access
- ✅ Clear who opened/locked

### **Security:**
- ✅ Controlled access
- ✅ Automatic timeout
- ✅ Audit trail
- ✅ Privileged control

### **Collaboration:**
- ✅ Team members informed
- ✅ Coordinated access
- ✅ Activity awareness
- ✅ Session transparency

### **Efficiency:**
- ✅ No duplicate sessions
- ✅ Shared resources
- ✅ Single session state
- ✅ Less complexity

---

## 🎨 **UI INTEGRATION (Next Steps)**

### **VaultDetailView Updates:**
- [ ] Show shared session status
- [ ] Display "Opened by [name]"
- [ ] Show time remaining
- [ ] Add "Lock Vault" button (owner/admin only)
- [ ] Real-time session updates

### **Vault List:**
- [ ] Show open/locked indicator
- [ ] Show who has it open
- [ ] Real-time status updates

### **Notifications:**
- [ ] In-app notification center
- [ ] Push notifications
- [ ] Notification badge
- [ ] History log

---

## 🚀 **IMPLEMENTATION STATUS**

- **Service:** ✅ Complete
- **Session Logic:** ✅ Implemented
- **Notifications:** ✅ Built
- **Permission System:** ✅ Ready
- **UI Integration:** 🔄 Next step
- **Testing:** 📝 Pending

---

## 📋 **TECHNICAL DETAILS**

### **Session Storage:**
```swift
@Published var sharedSessions: [UUID: SharedVaultSession]
// Key: Vault ID
// Value: Single shared session
```

### **Session Lifecycle:**
```
Create → Active → Extended (optional) → Expired → Auto-lock
```

### **Permission Logic:**
```swift
canLock = (user.id == vault.owner.id) || user.hasRole(.admin)
```

---

**Physical bank vault security in a digital app!** 🏦✨

One vault, one session, everyone synchronized! 🔐


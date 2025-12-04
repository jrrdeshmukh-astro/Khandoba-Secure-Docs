# 🔐 Admin Access in Production

**Document:** How to access Admin view in production app  
**Date:** December 2025

---

## 📱 HOW TO LOG INTO ADMIN VIEW:

### Method 1: For Users with Admin Role

**If you already have admin role assigned:**

1. **Open the app** and sign in with Apple
2. **Navigate to Profile tab** (bottom right)
3. **Look for "Switch Role" section**
4. **Tap on "Admin"**
5. **Admin tabs appear:**
   - Dashboard
   - Approvals
   - Messages
   - Vaults
   - Profile

---

### Method 2: Assign Admin Role (First Time)

**Admin roles must be assigned in one of these ways:**

#### Option A: Development Mode (Testing)
```swift
// In AppConfig.swift
static let isDevelopmentMode = true

// Dev user automatically gets both Client & Admin roles
```

#### Option B: Database Assignment
```swift
// In Xcode, add admin role to user:
1. Open app in simulator
2. Pause execution
3. View SwiftData database
4. Add UserRole with role = .admin to user
5. Continue execution
```

#### Option C: First User Auto-Admin
```swift
// Modify AuthenticationService.swift:
// Auto-assign admin role to first user who signs up

func signIn(with authorization: ASAuthorization) async throws {
    // ... existing code ...
    
    // Check if this is the first user
    let allUsers = try modelContext.fetch(FetchDescriptor<User>())
    if allUsers.count == 1 {
        // This is the first user - make them admin
        let adminRole = UserRole(role: .admin)
        adminRole.user = newUser
        newUser.roles?.append(adminRole)
        modelContext.insert(adminRole)
        try modelContext.save()
    }
}
```

---

### Method 3: Role Switching in App

**Once you have admin role:**

**From Client View:**
1. Profile tab → "Switch Role" → Tap "Admin"

**From Admin View:**
1. Profile tab → "Switch Role" → Tap "Client"

**The switch is instant and preserved between app launches.**

---

## 🔑 WHO CAN BE ADMIN:

**Admin role can be assigned to:**
- ✅ First user (auto-assign option)
- ✅ Development mode user
- ✅ Users manually promoted via database
- ✅ Users invited by existing admins (future feature)

**Admin capabilities:**
- View all users
- View all vaults (metadata only, zero-knowledge)
- Approve dual-key requests
- Respond to support chat
- Manage system
- **Cannot:** View document content (zero-knowledge)

---

## 📋 PRODUCTION SETUP:

### Recommended Approach:

**1. First User Auto-Admin (Easiest):**

Add this to `AuthenticationService.swift`:

```swift
// After creating new user, check if first user
let descriptor = FetchDescriptor<User>()
let allUsers = try modelContext.fetch(descriptor)

if allUsers.count == 1 {
    // First user - assign admin role
    let adminRole = UserRole(role: .admin)
    adminRole.user = newUser
    newUser.roles?.append(adminRole)
    modelContext.insert(adminRole)
    try modelContext.save()
}
```

**2. Admin Invitation System (Future):**

- Existing admin can invite new admins
- Send invitation code
- New user enters code during sign-up
- Auto-assigns admin role

---

## 🎯 QUICK ACCESS GUIDE:

**For App Owner/First User:**

1. Delete app
2. Reinstall from App Store
3. Sign in with Apple (you'll be first user)
4. Admin role auto-assigned
5. Go to Profile → See "Switch Role"
6. Tap "Admin"
7. **You're now in admin view!**

---

## ⚠️ IMPORTANT NOTES:

**Security:**
- Admin role is powerful
- Limit to trusted users only
- Zero-knowledge maintained (admins can't see document content)
- Approval-based system for dual-key vaults

**Role Management:**
- Users can have multiple roles
- Only one role active at a time
- Switch anytime via Profile
- Role persists between sessions

**Zero-Knowledge:**
- Even as admin, you CANNOT view:
  - Document content
  - Encrypted file data
  - Intel Reports
  - Private user data
- You CAN view:
  - User metadata (name, email)
  - Vault metadata (name, size)
  - Access logs (location, time)
  - Pending requests

---

## 🚀 PRODUCTION RECOMMENDATION:

**For Launch:**

1. **Enable First User Auto-Admin**
   - Ensures app owner becomes admin
   - Simplest setup
   - No manual database work

2. **Sign In First**
   - Before customers
   - Claim admin role
   - Test all features

3. **Later Users**
   - Get client role only
   - Can be promoted if needed
   - Controlled access

---

**File Location:** Save this to app documentation for future reference.

**Current Status:** Admin role assignment via "Switch Role" in Profile works perfectly for users who have the admin role assigned.


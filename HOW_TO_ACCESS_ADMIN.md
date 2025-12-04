# How to Access Admin Mode

## Changes Made to Profile View

### ✅ Fixed Theme Colors
- **Role Badge**: Now uses role-specific colors instead of red
  - Client role: Cyan/Blue (`#11A7C7`)
  - Admin role: Amber/Gold (`#E7A63A`)
- **Avatar Border**: Now matches the current role color
- **Role Switcher**: Icons and checkmarks use role-specific colors

### ✅ User Name & Photo
The profile already correctly displays:
- User's full name from Apple Sign In (or "User" if not set)
- Profile picture from camera/photos
- User's initials if no photo is set

---

## How to Access Admin Role

There are **three ways** to get admin access:

### Method 1: Add Your Email to Admin List (Recommended)

1. Open `/Khandoba Secure Docs/Config/AppConfig.swift`
2. Find the `adminEmails` array (line 39)
3. Add your Apple ID email:

```swift
static let adminEmails = [
    "jai.deshmukh@icloud.com",
    "dev@khandoba.local",
    "YOUR_EMAIL@icloud.com"  // Add your email here
]
```

4. **Sign out** from the app
5. **Sign in again** with Apple Sign In
6. The admin role will be automatically assigned
7. You'll see a "Switch Role" section in your Profile

### Method 2: Use Development Mode (Testing Only)

1. Open `/Khandoba Secure Docs/Config/AppConfig.swift`
2. Change line 12 from:
```swift
static let isDevelopmentMode = false
```
to:
```swift
static let isDevelopmentMode = true
```

3. Rebuild and run the app
4. You'll automatically be signed in as a dev user with BOTH client and admin roles
5. Use the Profile screen to switch between roles

**⚠️ Important**: Change this back to `false` before production builds!

### Method 3: Switch Roles (If Already Assigned)

If you already have both Client and Admin roles:

1. Open the app
2. Go to the **Profile** tab (bottom right)
3. Look for the **"Switch Role"** section
4. Tap on **Admin** to switch to admin mode
5. The app will reload showing the admin interface

---

## How to Know You're in Admin Mode

### Visual Indicators:

1. **Profile Badge**: Shows amber/gold color with shield icon
2. **Different Interface**: 
   - Client: Shows Home, Vaults, Documents, Premium, Profile tabs
   - Admin: Shows Dashboard, Users, Vaults, Analytics, Profile tabs

3. **Main View Title**:
   - Client: "Secure Docs Dashboard"
   - Admin: "Admin Dashboard"

---

## Switching Between Client & Admin

Once you have both roles assigned, you can easily switch:

1. Tap the **Profile** tab
2. Scroll to **"Switch Role"** section
3. Tap the role you want to switch to
4. Current role shows a checkmark (✓)
5. App automatically updates the interface

### Role-Specific Features:

**Client Mode:**
- Personal vaults management
- Document uploads
- Premium subscription
- Personal profile

**Admin Mode:**
- User management
- System-wide analytics
- All vaults overview
- Threat monitoring
- Audit logs

---

## Current App Configuration

- **Development Mode**: `false` (Production mode - requires real Apple Sign In)
- **Admin Emails**: 
  - `jai.deshmukh@icloud.com`
  - `dev@khandoba.local`

---

## Troubleshooting

### "I don't see the Switch Role section"
- You only have one role assigned
- Use Method 1 or 2 above to get admin access

### "Switch Role section is there but Admin is grayed out"
- The admin role exists but is inactive
- Check `AppConfig.adminEmails` includes your email
- Try signing out and signing back in

### "Changes not reflecting"
- Clean build folder: `Product > Clean Build Folder` (Cmd+Shift+K)
- Delete app from simulator/device
- Rebuild and reinstall
- Make sure you signed out and back in after config changes

---

## Profile View Color Scheme

The profile now correctly uses role-specific colors:

| Element | Client Color | Admin Color |
|---------|-------------|-------------|
| Avatar Border | Cyan (#11A7C7) | Amber (#E7A63A) |
| Role Badge Background | Cyan opacity | Amber opacity |
| Role Badge Text | Cyan | Amber |
| Role Icon | Person icon | Shield icon |

Dark mode and light mode are both supported with the same color scheme.

---

## Summary

✅ **Fixed**: Profile badge now uses correct theme colors (cyan for client, amber for admin)  
✅ **Fixed**: Avatar border uses role-specific colors  
✅ **Fixed**: Role switcher uses proper theming  
✅ **Working**: User name and photo display correctly  
✅ **Documented**: Three methods to access admin mode


# Navigation Structure

> **Last Updated:** December 2024
> 
> Documentation of the app's navigation architecture and routing.

## Overview

The Khandoba iOS app uses a role-based navigation structure with TabView for main navigation and NavigationStack for detail views.

## Role-Based Navigation

### Client Navigation

**Main Tabs:**
1. **Home** - Dashboard with stats and activity
2. **Vaults** - List of user's vaults
3. **Documents** - Cross-vault document search
4. **Store** - Credit purchase and subscriptions
5. **Profile** - Account info and settings

### Admin Navigation

**Main Tabs:**
1. **Dashboard** - System overview and pending actions
2. **Users** - User management and role assignment
3. **KYC** - KYC verification (merged from officer)
4. **Vaults** - Vault oversight
5. **Messages** - Chat inbox (merged from officer)
6. **Security** - Security monitoring
7. **More** - Settings and profile

## Routing System

### AppRouter

Centralized routing system that provides:
- Role-based route availability
- Deep linking support
- Route-to-view mapping

### Route Types

- **Client Routes**: Dashboard, Vaults, Documents, Store, Profile
- **Admin Routes**: Dashboard, Users, KYC, Vaults, Messages, Security, Settings, Profile

## Navigation Patterns

### Tab Navigation

- Uses SwiftUI `TabView`
- Role-specific tab configurations
- Smooth transitions between tabs

### Detail Navigation

- Uses `NavigationStack` for hierarchical navigation
- Supports deep linking
- Maintains navigation state

## Account Switching

Users with multiple roles can switch via:
- Profile tab → Account Switcher
- Smooth transition between role views
- Preserves navigation state where possible


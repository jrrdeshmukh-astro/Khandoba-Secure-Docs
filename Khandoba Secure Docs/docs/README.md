# Khandoba iOS Documentation

> **Last Updated:** December 2024
> 
> Complete documentation for the Khandoba iOS application.

## Documentation Structure

This documentation is organized into the following sections:

### Workflows (`workflows/`)

- **client-workflows.md**: Complete client user workflows
- **admin-workflows.md**: Complete admin workflows (includes all officer capabilities)
- **authentication-workflows.md**: Authentication and onboarding flows

### Architecture (`architecture/`)

- **theme-system.md**: Unified theme system documentation
- **navigation-structure.md**: App navigation and routing
- **data-flow.md**: Data flow patterns and state management

### Features (`features/`)

- **vaults.md**: Vault management features
- **documents.md**: Document management features
- **subscription.md**: Subscription and premium features
- **security.md**: Security features and protocols

### Development (`development/`)

- **setup.md**: Setup and installation guide
- **deployment.md**: Deployment guide
- **dev-mode.md**: Development mode features

### Master Plan

- **master-plan.md**: Comprehensive critique and implementation roadmap

## Quick Links

- [Setup Guide](development/setup.md)
- [Client Workflows](workflows/client-workflows.md)
- [Admin Workflows](workflows/admin-workflows.md)
- [Theme System](architecture/theme-system.md)
- [Master Plan](master-plan.md)

## Recent Changes

### December 2024

- **SwiftData Migration**: Complete migration from Core Data to SwiftData
  - All models use SwiftData @Model macro
  - ModelContext replaces NSManagedObjectContext
  - Modern Swift concurrency support
  - Simplified data persistence architecture
- **Officer Role Removed**: All officer capabilities merged into admin role
  - Complete migration of all UI text, comments, and documentation
  - All user-facing references updated to "admin"
- **Unified Theme**: Complete migration to UnifiedTheme with contrasting color palette
  - Consistent dark theme across all views
  - No local theme overrides
- **Master Plan Implementation**: All 5 phases completed
  - Optimistic UI updates, Error recovery, Retry logic, Offline mode
  - Smooth animations and transitions throughout
  - Comprehensive dev testing tools
- **Workflow Documentation**: Comprehensive workflow documentation created
- **UI/UX Improvements**: Standard components, accessibility, haptic feedback

## Role Structure

The app now supports two roles:

1. **Client**: Standard user with full vault access
2. **Admin**: System administrator with full oversight (includes all former officer capabilities)

## Getting Started

1. Read the [Setup Guide](development/setup.md)
2. Review [Client Workflows](workflows/client-workflows.md) or [Admin Workflows](workflows/admin-workflows.md)
3. Check the [Master Plan](master-plan.md) for implementation roadmap


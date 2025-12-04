# Data Flow Architecture

> **Last Updated:** December 2024
> 
> Documentation of data flow patterns and state management.

## Overview

The Khandoba iOS app uses a service-based architecture with SwiftData for persistence and CloudKit for sync.

## Data Layers

### 1. Services Layer

Business logic services that handle:
- Authentication (`AuthenticationService`)
- Vault management (`VaultService`)
- Document operations (`DocumentService`)
- Payments (`PaymentService`)
- Chat (`ChatService`)
- Security features

### 2. Persistence Layer

- **SwiftData**: Modern Swift-native local persistence
  - @Model macro for data models
  - ModelContext for data operations
  - Automatic CloudKit integration
- **CloudKit**: Cloud sync and backup (via SwiftData)
- **Keychain**: Sensitive data (tokens, keys)

### 3. View Layer

- SwiftUI views with `@StateObject` and `@ObservedObject`
- Environment objects for shared state
- ViewModels for view-specific logic

## Data Flow Patterns

### Authentication Flow

1. User signs in with Apple
2. `AuthenticationService` validates credentials
3. User data stored in SwiftData/CloudKit
4. Role assigned automatically
5. App navigates to role-specific view

### Vault Operations

1. User opens vault → `VaultService.loadVaults()`
2. Vault data fetched from SwiftData
3. Session started → 30-minute timer
4. Documents loaded from vault
5. Changes automatically synced via SwiftData's CloudKit integration

### Document Upload

1. User selects document
2. Virus scan (placeholder)
3. AI tagging for indexing
4. Encryption
5. Upload to vault
6. Automatic sync to CloudKit

## State Management

### Observable Objects

Services use `@MainActor` and `ObservableObject` for:
- Reactive UI updates
- Thread-safe state management
- Automatic view updates

### Environment Objects

Shared services injected via environment:
- `AuthenticationService`
- `AppConfiguration`
- `UnifiedTheme`

## Sync Strategy

- **CloudKit**: Automatic sync for CoreData entities
- **Background Sync**: Periodic background updates
- **Conflict Resolution**: Last-write-wins with manual override option

## Error Handling

- Service-level error handling
- User-friendly error messages
- Retry mechanisms for network operations
- Offline mode support


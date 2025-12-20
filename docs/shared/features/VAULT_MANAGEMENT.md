# Vault Management Feature

> Comprehensive documentation for the vault system across all platforms

---

## Overview

Vaults are the core security container for documents. Each vault is encrypted with AES-256-GCM and supports single-key or dual-key access control.

---

## Vault Types

### Single-Key Vaults

- Protected by a password
- Owner has full access
- Can be unlocked with password or biometrics
- Default vault type

### Dual-Key Vaults

- Requires two approvals to access
- ML-based auto-approval system
- Manual approval fallback
- Higher security for sensitive documents

### System Vaults

- Read-only vaults
- Used for system-generated content (e.g., Intel Reports)
- Automatically managed by the system

---

## Vault Operations

### Create Vault

**All Platforms:**
- Name and description
- Select key type (single or dual-key)
- Optional password for single-key vaults
- Encryption key automatically generated

**Implementation:**
- Apple: `VaultService.createVault()`
- Android: `VaultService.createVault()`
- Windows: `VaultService.CreateVaultAsync()`

### Unlock Vault

**Single-Key:**
- Password or biometric authentication
- Creates a session with timeout
- Session stored locally and in Supabase

**Dual-Key:**
- Creates a dual-key request
- ML approval service processes request
- If approved, creates session
- If denied, requires manual approval

**Implementation:**
- All platforms support unlock with session management
- Sessions expire after timeout (default: 30 minutes)

### Lock Vault

- Closes active session
- Documents no longer accessible
- Requires unlock to access again

### Delete Vault

- Removes vault and all documents
- Cascade delete from database
- Encrypted files remain in storage (orphaned)

---

## Session Management

### Session Lifecycle

1. **Create** - When vault is unlocked
2. **Active** - Documents accessible
3. **Expire** - After timeout period
4. **Extend** - User can extend session
5. **Close** - User locks vault or app closes

### Session Properties

- `vaultId` - Associated vault
- `userId` - User who unlocked
- `startedAt` - Session start time
- `expiresAt` - Session expiry time
- `isActive` - Session status

### Session Timeout

- **Default:** 30 minutes
- **Configurable:** Per user settings
- **Auto-lock:** On app background (optional)

---

## Access Control

### Permissions

- **Owner** - Full access (create, read, update, delete)
- **Nominee** - Access granted by owner
- **Session-based** - Temporary access when unlocked

### Dual-Key Approval Flow

```
User requests vault access
    ↓
Create DualKeyRequest
    ↓
ML Approval Service processes
    ↓
Risk Score Calculation
    ↓
Auto-approve (if low risk) OR Pending (if high risk)
    ↓
If approved: Create session
If pending: Require manual approval
```

### ML Approval Criteria

- User access history
- Access pattern consistency
- Request reason analysis
- Risk score threshold (typically 0.3 = 30% risk)

---

## Cross-Platform Sync

### Supabase Backend

All platforms share the same vault data via Supabase:
- Vault metadata stored in `vaults` table
- Sessions stored in `vault_sessions` table
- Access logs in `vault_access_logs` table
- Real-time sync via Supabase Realtime

### Sync Flow

```
Platform A: Create/Update Vault
    ↓
Supabase Database
    ↓
Real-time Event
    ↓
Platform B: Receives Update
    ↓
Local Database Updated
    ↓
UI Refreshes
```

---

## Security Features

### Encryption

- **Algorithm:** AES-256-GCM
- **Key Storage:** Platform-specific secure storage
  - Apple: Keychain
  - Android: Android Keystore
  - Windows: DPAPI
- **Zero-Knowledge:** Server cannot decrypt vault contents

### Access Logging

Every vault access is logged:
- Timestamp
- User ID and name
- Access type (opened, closed, viewed, modified)
- Location (if available)
- Device information
- IP address (if available)

### Threat Monitoring

- Access pattern analysis
- Geographic anomaly detection
- Unusual access time detection
- Deletion pattern monitoring

---

## Platform-Specific Details

### Apple

- **Additional Features:**
  - Shared vault sessions (multiple users)
  - Bluetooth session nomination
  - Anti-vault (monitoring vault)
  - CloudKit integration (fallback)

### Android

- **Implementation:**
  - Room database for local storage
  - Supabase for cloud sync
  - Real-time subscriptions for live updates

### Windows

- **Implementation:**
  - Entity Framework Core for local storage
  - Supabase for cloud sync
  - ML approval service integrated

---

## API Reference

### Apple (Swift)

```swift
// Create vault
func createVault(name: String, description: String?, keyType: VaultKeyType) async throws -> Vault

// Unlock vault
func unlockVault(vaultId: UUID, password: String?) async throws -> VaultSession

// Lock vault
func lockVault(vaultId: UUID) async throws

// Delete vault
func deleteVault(vaultId: UUID) async throws
```

### Android (Kotlin)

```kotlin
// Create vault
suspend fun createVault(name: String, description: String?, keyType: VaultKeyType): Result<Vault>

// Unlock vault
suspend fun unlockVault(vaultId: UUID, password: String?): Result<VaultSession>

// Lock vault
suspend fun lockVault(vaultId: UUID): Result<Unit>

// Delete vault
suspend fun deleteVault(vaultId: UUID): Result<Unit>
```

### Windows (C#)

```csharp
// Create vault
Task<Vault> CreateVaultAsync(string name, string? description, VaultKeyType keyType);

// Unlock vault
Task<VaultSession> UnlockVaultAsync(Guid vaultId, string? password);

// Lock vault
Task LockVaultAsync(Guid vaultId);

// Delete vault
Task DeleteVaultAsync(Guid vaultId);
```

---

**Last Updated:** December 2024

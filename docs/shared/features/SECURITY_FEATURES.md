# Security Features

> Comprehensive security documentation across all platforms

---

## Overview

Khandoba Secure Docs implements military-grade security with zero-knowledge architecture, ensuring that even the server cannot decrypt user data.

---

## Encryption

### AES-256-GCM

**Algorithm:** Advanced Encryption Standard with Galois/Counter Mode
- **Key Size:** 256 bits
- **Mode:** GCM (authenticated encryption)
- **IV:** 12 bytes (96 bits) for GCM
- **Tag:** 16 bytes (128 bits) for authentication

### Encryption Flow

```
Plaintext Data
    ↓
Generate Random IV
    ↓
Encrypt with AES-256-GCM
    ↓
Generate Authentication Tag
    ↓
Store: IV + Ciphertext + Tag
```

### Decryption Flow

```
Encrypted Data (IV + Ciphertext + Tag)
    ↓
Extract IV, Ciphertext, Tag
    ↓
Decrypt with AES-256-GCM
    ↓
Verify Authentication Tag
    ↓
Return Plaintext (if tag valid)
```

### Key Management

**Per-Document Keys:**
- Each document has unique encryption key
- Keys stored encrypted in database
- Vault-level key encryption (additional layer)

**Platform-Specific Storage:**
- **Apple:** iOS Keychain (hardware-backed)
- **Android:** Android Keystore (hardware-backed)
- **Windows:** DPAPI + secure storage

---

## Zero-Knowledge Architecture

### Principle

The server (Supabase) **never** has access to:
- Unencrypted document content
- Encryption keys
- Vault passwords
- Decrypted metadata (where possible)

### Implementation

```
Client (App)
    ├─ Encryption Key Generation
    ├─ Data Encryption
    ├─ Key Encryption (with vault key)
    └─ Upload Encrypted Data + Encrypted Key

Server (Supabase)
    ├─ Receives Encrypted Data
    ├─ Stores Encrypted Key
    └─ Cannot Decrypt (no access to keys)
```

---

## Authentication

### Platform-Specific Providers

**Apple:**
- Apple Sign In (primary)
- Face ID / Touch ID for vault access

**Android:**
- Google Sign In (primary)
- Fingerprint / Face unlock for vault access

**Windows:**
- Microsoft Account (primary)
- Windows Hello for vault access

### Biometric Authentication

**Supported Methods:**
- Face ID (Apple)
- Touch ID (Apple)
- Fingerprint (Android)
- Face unlock (Android)
- Windows Hello (Windows)

**Usage:**
- Vault unlocking
- App authentication
- Sensitive operations

---

## Vault Security

### Single-Key Vaults

- Password-protected
- Optional biometric unlock
- Owner has full access

### Dual-Key Vaults

- Requires two approvals
- ML-based auto-approval
- Manual approval fallback
- Enhanced security for sensitive data

### Session Management

- **Timeout:** 30 minutes (configurable)
- **Auto-lock:** On app background (optional)
- **Session tracking:** All sessions logged
- **Remote termination:** Can revoke sessions

---

## Access Control

### Role-Based Access

**Owner:**
- Full access (create, read, update, delete)
- Manage nominees
- Configure vault settings

**Nominee:**
- Access granted by owner
- Limited permissions
- Can be revoked

### Request-Based Access

**Dual-Key Requests:**
- Request access to dual-key vault
- ML approval or manual approval
- Temporary session on approval

**Emergency Access:**
- Emergency access requests
- Time-limited access
- Audit trail

---

## Threat Monitoring

### Access Pattern Analysis

**Monitored Patterns:**
- Unusual access times
- Geographic anomalies
- Rapid access/deletion
- Multiple failed attempts

### ML-Based Detection

**Threat Analysis:**
- Pattern recognition
- Anomaly detection
- Risk scoring
- Automated alerts

### Threat Indicators

**High Risk:**
- Access from new location
- Unusual time of access
- Rapid deletion patterns
- Multiple failed unlock attempts

**Medium Risk:**
- Infrequent access patterns
- New device access
- Extended session times

---

## Audit Trail

### Access Logging

Every access is logged:
- **Timestamp** - When access occurred
- **User ID** - Who accessed
- **Access Type** - What action (opened, viewed, modified, deleted)
- **Location** - Geographic coordinates (if available)
- **Device Info** - Device type, OS version
- **IP Address** - Network location (if available)
- **Document ID** - Which document (if applicable)

### Log Storage

- Stored in `vault_access_logs` table
- Immutable (cannot be deleted)
- Queryable for analysis
- Real-time monitoring

---

## Security Features by Platform

### Apple

**Additional Security:**
- Secure Enclave integration (Face ID/Touch ID)
- Keychain Services (hardware-backed key storage)
- App Transport Security (ATS)
- Code signing and notarization

### Android

**Additional Security:**
- Android Keystore (hardware-backed)
- SafetyNet / Play Integrity
- App signing with Play App Signing
- Network Security Config

### Windows

**Additional Security:**
- Windows DPAPI (key protection)
- Windows Hello integration
- Code signing
- Secure storage APIs

---

## Best Practices

### For Developers

1. **Never log encryption keys**
2. **Always use secure storage for keys**
3. **Validate all inputs**
4. **Use HTTPS for all network calls**
5. **Implement proper session management**
6. **Log security events**

### For Users

1. **Use strong passwords**
2. **Enable biometric authentication**
3. **Review access logs regularly**
4. **Use dual-key vaults for sensitive data**
5. **Keep app updated**

---

## Compliance

### Security Standards

- **Encryption:** AES-256 (meets FIPS 140-2 requirements)
- **Key Management:** Hardware-backed where available
- **Data Protection:** Zero-knowledge architecture
- **Audit:** Complete access logging

### Privacy

- **Zero-Knowledge:** Server cannot access decrypted data
- **Local Processing:** AI/ML processing on-device (where possible)
- **Minimal Data Collection:** Only necessary metadata
- **User Control:** Users own and control their data

---

## Security Incident Response

### Detection

- ML threat analysis
- Access log monitoring
- Anomaly alerts

### Response

1. **Alert user** of suspicious activity
2. **Revoke sessions** if needed
3. **Require re-authentication**
4. **Log incident** for investigation

---

**Last Updated:** December 2024

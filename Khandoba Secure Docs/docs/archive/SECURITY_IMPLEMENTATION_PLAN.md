# Secure Information, Evidence, and Intelligence Management - Implementation Plan

## Executive Summary

This plan outlines the phased implementation of the security specification to transform Khandoba into an air-tight, zero-knowledge-aligned system for storing, transporting, and auditing sensitive information.

**Current State Assessment:**
- ✅ Basic encryption (AES-256-GCM) exists but needs enhancement
- ✅ Vault sessions exist (30-min timer) but missing validation gates
- ✅ Document upload flow exists but missing pre-checks
- ✅ Activity/Access logging exists but not cryptographically linked
- ❌ No CAS (Content-Addressed Storage) implementation
- ❌ No device attestation
- ❌ No certificate pinning
- ❌ No dual-key threshold signatures
- ❌ No break-glass workflow
- ❌ No audit ledger with hash chaining
- ❌ No watermarking for sharing
- ❌ No retention/deletion policies
- ❌ Missing validation gates in workflows

**Implementation Phases:**
1. **Phase 0: Audit & Alignment** (1-2 days)
2. **Phase 1: Security Foundations** (3-5 days)
3. **Phase 2: Data Lifecycle Core** (5-7 days)
4. **Phase 3: Workflow Integration** (4-6 days)
5. **Phase 4: Observability & Compliance** (3-4 days)
6. **Phase 5: Governance & Hardening** (3-4 days)
7. **Phase 6: QA & Validation** (2-3 days)

**Total Estimated Time: 21-31 days**

---

## Phase 0: Audit & Alignment

### Objectives
- Map existing code to spec requirements
- Create gap analysis checklist
- Identify refactoring needs
- Set up project tracking

### Tasks

#### 0.1 Code Mapping & Gap Analysis
- [ ] **Audit existing encryption** (`EncryptionService.swift`)
  - Current: Basic AES-256-GCM with master key
  - Gap: No per-object DEK, no KEK wrapping, no key rotation
  - Gap: No HKDF key derivation
  - Gap: No Secure Enclave integration

- [ ] **Audit keychain usage** (`KeychainService.swift`)
  - Current: Basic keychain storage
  - Gap: No Secure Enclave flags
  - Gap: No key rotation support
  - Gap: No key versioning

- [ ] **Audit vault sessions** (`VaultSessionService.swift`)
  - Current: 30-min timer, extension support
  - Gap: No session validation middleware
  - Gap: No pre-operation checks (vault unlocked, session valid)
  - Gap: No device attestation requirement
  - Gap: No dual-key state validation

- [ ] **Audit document upload** (`DocumentUploadService.swift`)
  - Current: scan → index → encrypt → upload
  - Gap: No pre-checks (session active, vault unlocked, quota, role)
  - Gap: No CAS storage (content-addressed)
  - Gap: No deduplication by encrypted hash
  - Gap: No metadata enforcement (geo, device, attestation)

- [ ] **Audit logging** (`ActivityLogService.swift`, `AccessLogService.swift`)
  - Current: Basic Core Data logging
  - Gap: No cryptographic hash chaining
  - Gap: No append-only ledger
  - Gap: No signature requirements
  - Gap: No reason codes

- [ ] **Audit API client** (`APIClient.swift`)
  - Current: Basic HTTP client with auth
  - Gap: No certificate pinning
  - Gap: No request signing (nonce + timestamp)
  - Gap: No mutual TLS for elevated endpoints
  - Gap: No chunked upload with MAC

- [ ] **Audit dual-key service** (`DualKeyService.swift`)
  - Current: Basic dual-key request/approval
  - Gap: No threshold signatures
  - Gap: No two-phase unwrap
  - Gap: No cryptographic proof of co-signature

- [ ] **Audit sharing** (`WhatsAppShareService.swift`, etc.)
  - Current: Basic sharing
  - Gap: No watermarking
  - Gap: No expiring links
  - Gap: No geo/device fingerprinting

#### 0.2 Create Implementation Checklist
- [ ] Create `SECURITY_IMPLEMENTATION_CHECKLIST.md` with all gaps
- [ ] Prioritize by risk (P0: security critical, P1: compliance, P2: UX)
- [ ] Assign estimated effort per item

#### 0.3 Set Up Project Structure
- [ ] Create `Khandoba/Features/Security/` directory structure:
  ```
  Security/
    ├── Cryptography/
    │   ├── KeyManagementService.swift
    │   ├── KeyRotationService.swift
    │   ├── HKDFService.swift
    │   └── SecureEnclaveService.swift
    ├── Attestation/
    │   ├── DeviceAttestationService.swift
    │   └── IntegrityCheckService.swift
    ├── Validation/
    │   ├── SessionValidationMiddleware.swift
    │   ├── VaultAccessValidator.swift
    │   └── RolePermissionValidator.swift
    ├── Storage/
    │   ├── CASStorageService.swift
    │   └── DeduplicationService.swift
    ├── Audit/
    │   ├── AuditLedgerService.swift
    │   └── ChainOfCustodyService.swift
    ├── Sharing/
    │   ├── WatermarkingService.swift
    │   └── ExpiringLinkService.swift
    └── Governance/
        ├── RetentionPolicyService.swift
        ├── DeletionService.swift
        └── BreakGlassService.swift
  ```

### Acceptance Criteria
- [ ] Complete gap analysis document created
- [ ] All existing services mapped to spec requirements
- [ ] Project structure created
- [ ] Implementation checklist prioritized

---

## Phase 1: Security Foundations

### Objectives
- Implement session validation middleware
- Add certificate pinning
- Implement device attestation
- Add request signing
- Enhance key management with HKDF and Secure Enclave

### Tasks

#### 1.1 Session Validation Middleware
**File:** `Khandoba/Features/Security/Validation/SessionValidationMiddleware.swift`

- [ ] Create `SessionValidationMiddleware` protocol
- [ ] Implement pre-operation checks:
  - [ ] Session active and valid
  - [ ] Vault unlocked
  - [ ] Dual-key state satisfied (if required)
  - [ ] Role permission verified
  - [ ] Device attestation passed
- [ ] Create `@propertyWrapper` for automatic validation
- [ ] Integrate into `VaultSessionService`

**Acceptance Criteria:**
- All vault operations require validated session
- Failed validation returns clear error with remediation
- Validation gates logged to audit ledger

#### 1.2 Certificate Pinning
**File:** `Khandoba/Features/Security/Network/CertificatePinningService.swift`

- [ ] Implement certificate pinning for APIClient
- [ ] Add pinned certificates to app bundle
- [ ] Create pinning validation in URLSession delegate
- [ ] Add fallback mechanism for certificate rotation
- [ ] Log pinning failures to security alerts

**Acceptance Criteria:**
- All API calls use certificate pinning
- Pinning failures block requests
- Certificate rotation process documented

#### 1.3 Device Attestation
**File:** `Khandoba/Features/Security/Attestation/DeviceAttestationService.swift`

- [ ] Implement device integrity checks:
  - [ ] Jailbreak detection
  - [ ] Device binding token
  - [ ] Secure Enclave availability
- [ ] Create attestation token generation
- [ ] Add attestation requirement to session validation
- [ ] Block operations on compromised devices

**Acceptance Criteria:**
- Device attestation runs before sensitive operations
- Compromised devices are blocked with clear error
- Attestation tokens stored securely

#### 1.4 Request Signing
**File:** `Khandoba/Features/Security/Network/RequestSigningService.swift`

- [ ] Implement nonce + timestamp signing
- [ ] Add signature to all API requests
- [ ] Server-side validation (backend task)
- [ ] Reject requests with >2min skew
- [ ] Add retry logic for clock skew

**Acceptance Criteria:**
- All API requests include signatures
- Clock skew detection works
- Failed signatures return clear errors

#### 1.5 Enhanced Key Management
**File:** `Khandoba/Features/Security/Cryptography/KeyManagementService.swift`

- [ ] Implement HKDF key derivation
- [ ] Add Secure Enclave integration for key storage
- [ ] Implement per-object DEK generation
- [ ] Add KEK wrapping/unwrapping
- [ ] Create key versioning system
- [ ] Add key rotation hooks

**Acceptance Criteria:**
- Keys derived using HKDF with device secrets
- Sensitive keys stored in Secure Enclave
- Per-document encryption keys
- Key rotation supported

### Acceptance Criteria (Phase 1)
- [ ] Session validation blocks unauthorized operations
- [ ] Certificate pinning active for all API calls
- [ ] Device attestation required for sensitive actions
- [ ] Request signing implemented
- [ ] Enhanced key management operational

---

## Phase 2: Data Lifecycle Core

### Objectives
- Implement CAS (Content-Addressed Storage)
- Add deduplication by encrypted hash
- Enhance metadata enforcement
- Implement audit ledger with hash chaining
- Add chain of custody tracking

### Tasks

#### 2.1 CAS Storage Service
**File:** `Khandoba/Features/Security/Storage/CASStorageService.swift`

- [ ] Implement content-addressed storage:
  - [ ] SHA-256 hash of encrypted content
  - [ ] Store encrypted blob by hash
  - [ ] Maintain pointer graph for multi-vault references
- [ ] Create CAS object model:
  ```swift
  struct CASObject {
      let objectID: UUID
      let encryptedBlob: Data
      let encryptedHash: Data // SHA-256 of encrypted blob
      let metadata: DocumentMetadata
      let classification: DataClassification
      let lineageRefs: [UUID] // References to other objects
  }
  ```
- [ ] Integrate into `DocumentUploadService`
- [ ] Add reference counting for deduplication

**Acceptance Criteria:**
- Documents stored by encrypted hash
- Multi-vault references use pointers
- No duplicate encrypted content stored

#### 2.2 Deduplication Service
**File:** `Khandoba/Features/Security/Storage/DeduplicationService.swift`

- [ ] Implement deduplication by encrypted hash
- [ ] Check hash before upload
- [ ] Create pointer if duplicate found
- [ ] Maintain reference count
- [ ] Prevent deletion if references exist

**Acceptance Criteria:**
- Duplicate encrypted content deduplicated
- Reference counting accurate
- Deletion blocked if references exist

#### 2.3 Metadata Enforcement
**Enhance:** `DocumentUploadService.swift`

- [ ] Add required metadata fields:
  - [ ] Source type (camera, file, import)
  - [ ] Chain-of-custody tags
  - [ ] Geo location (if permitted)
  - [ ] Device fingerprint
  - [ ] Attestation token
  - [ ] Threat score
  - [ ] Retention policy
- [ ] Validate metadata completeness before upload
- [ ] Store metadata in CAS object

**Acceptance Criteria:**
- All uploads include required metadata
- Metadata validation blocks incomplete uploads
- Metadata stored with encrypted content

#### 2.4 Audit Ledger Service
**File:** `Khandoba/Features/Security/Audit/AuditLedgerService.swift`

- [ ] Implement append-only ledger:
  ```swift
  struct AuditEvent {
      let eventID: UUID
      let timestamp: Date
      let actor: UUID
      let action: AuditAction
      let targetType: String
      let targetID: UUID?
      let justification: String?
      let signatures: [Signature]
      let previousHash: Data
      let eventHash: Data // SHA-256 of all fields
  }
  ```
- [ ] Implement hash chaining (prev-hash links events)
- [ ] Add signature requirements for sensitive actions
- [ ] Create ledger query interface
- [ ] Add integrity verification

**Acceptance Criteria:**
- All mutations emit audit events
- Events cryptographically linked
- Ledger integrity verifiable
- Query interface functional

#### 2.5 Chain of Custody Service
**File:** `Khandoba/Features/Security/Audit/ChainOfCustodyService.swift`

- [ ] Implement chain-of-custody tracking:
  - [ ] Notarized timestamps
  - [ ] Location stamps
  - [ ] Device attestation
  - [ ] Dual custody records (client + officer/admin)
  - [ ] Tamper-evident logs
- [ ] Add Evidence-Chain classification handling
- [ ] Create custody transfer workflow
- [ ] Generate custody reports

**Acceptance Criteria:**
- Evidence-Chain documents tracked
- Custody transfers recorded
- Reports exportable with integrity proofs

### Acceptance Criteria (Phase 2)
- [ ] CAS storage operational
- [ ] Deduplication working
- [ ] Metadata enforced
- [ ] Audit ledger recording all mutations
- [ ] Chain of custody tracking functional

---

## Phase 3: Workflow Integration

### Objectives
- Add validation gates to all workflows
- Implement dual-key threshold signatures
- Add break-glass workflow
- Implement watermarking for sharing
- Add vault session timer UI enhancements

### Tasks

#### 3.1 Upload Workflow Validation
**Enhance:** `DocumentUploadService.swift`

- [ ] Add pre-upload validation:
  - [ ] Session active check
  - [ ] Vault unlocked check
  - [ ] Role permission check
  - [ ] Quota available check
  - [ ] Virus scan clear check
- [ ] Integrate with `SessionValidationMiddleware`
- [ ] Add validation gate errors with remediation
- [ ] Emit audit events for validation failures

**Acceptance Criteria:**
- Uploads blocked if validation fails
- Clear error messages with remediation
- Validation logged to audit

#### 3.2 Dual-Key Threshold Signatures
**Enhance:** `DualKeyService.swift`

- [ ] Implement threshold signature scheme
- [ ] Add two-phase unwrap:
  - [ ] Phase 1: Client approval
  - [ ] Phase 2: Officer/Admin co-sign
- [ ] Generate cryptographic proof of co-signature
- [ ] Store signatures in audit ledger
- [ ] Add UI for dual-key approval queue

**Acceptance Criteria:**
- Dual-key requires both signatures
- Cryptographic proof generated
- Approval queue visible to officers/admins

#### 3.3 Break-Glass Workflow
**File:** `Khandoba/Features/Security/Governance/BreakGlassService.swift`

- [ ] Implement break-glass flow:
  - [ ] Admin + compliance officer approval
  - [ ] Mandatory reason code
  - [ ] Time-bound KEK unwrap
  - [ ] Post-event review queue
- [ ] Add break-glass UI to admin dashboard
- [ ] Create review workflow
- [ ] Emit high-priority audit events

**Acceptance Criteria:**
- Break-glass requires dual approval
- Time-bound access enforced
- Review queue functional
- All actions audited

#### 3.4 Watermarking Service
**File:** `Khandoba/Features/Security/Sharing/WatermarkingService.swift`

- [ ] Implement watermarking for shared documents:
  - [ ] User identifier
  - [ ] Timestamp
  - [ ] Expiry date
  - [ ] Classification level
- [ ] Add watermark to images/PDFs
- [ ] Create expiring link service
- [ ] Integrate into sharing workflows

**Acceptance Criteria:**
- Shared documents watermarked
- Expiring links functional
- Watermarks include required metadata

#### 3.5 Vault Session Timer UI
**Enhance:** `VaultSessionView.swift`, `VaultDetailView.swift`

- [ ] Add prominent session timer display
- [ ] Show risk state badges
- [ ] Auto-lock UI on expiry
- [ ] Add session extension with re-auth
- [ ] Display validation state

**Acceptance Criteria:**
- Timer visible in vault views
- Auto-lock works on expiry
- Extension requires re-auth

#### 3.6 Officer Inbox Enhancements
**Enhance:** `OfficerMainView.swift`, `OfficerChatInboxView.swift`

- [ ] Add vault open request queue
- [ ] Add dual-key approval queue
- [ ] Add break-glass review queue
- [ ] Add SLA timers with reminders
- [ ] Add notification system

**Acceptance Criteria:**
- All queues visible to officers
- SLA timers functional
- Notifications work

### Acceptance Criteria (Phase 3)
- [ ] All workflows have validation gates
- [ ] Dual-key threshold signatures working
- [ ] Break-glass workflow operational
- [ ] Watermarking functional
- [ ] Session timer UI enhanced
- [ ] Officer inbox complete

---

## Phase 4: Observability & Compliance

### Objectives
- Implement structured logging
- Add metrics collection
- Create alert rules
- Build audit trail export
- Add compliance reports

### Tasks

#### 4.1 Structured Logging
**File:** `Khandoba/Features/Security/Observability/StructuredLoggingService.swift`

- [ ] Implement structured logging:
  - [ ] Correlation IDs
  - [ ] Privacy filters (no sensitive payloads)
  - [ ] Log levels (debug, info, warn, error)
  - [ ] Contextual metadata
- [ ] Integrate into all services
- [ ] Add log rotation
- [ ] Create log export

**Acceptance Criteria:**
- All logs structured
- Sensitive data filtered
- Correlation IDs track requests

#### 4.2 Metrics Collection
**File:** `Khandoba/Features/Security/Observability/MetricsService.swift`

- [ ] Implement metrics:
  - [ ] Key rotation latency
  - [ ] Approval SLA adherence
  - [ ] Failed attestation rate
  - [ ] Session expiry coverage
  - [ ] Dedupe collisions
- [ ] Add metrics dashboard (admin view)
- [ ] Create alert thresholds

**Acceptance Criteria:**
- Metrics collected for all KPIs
- Dashboard functional
- Alerts configured

#### 4.3 Alert Rules
**File:** `Khandoba/Features/Security/Observability/AlertService.swift`

- [ ] Implement alerts for:
  - [ ] Geo drift anomalies
  - [ ] Repeated break-glass
  - [ ] CAS hash mismatches
  - [ ] Session validation failures
  - [ ] Failed attestation
- [ ] Add alert notification system
- [ ] Create alert dashboard

**Acceptance Criteria:**
- Alerts trigger on anomalies
- Notifications sent
- Dashboard shows active alerts

#### 4.4 Audit Trail Export
**Enhance:** `AuditLedgerService.swift`

- [ ] Implement export:
  - [ ] Signed PDF reports
  - [ ] JSON with integrity proofs
  - [ ] Date range filtering
  - [ ] Actor/action filtering
- [ ] Add export UI to admin dashboard
- [ ] Create daily chain-of-custody digest

**Acceptance Criteria:**
- Exports include integrity proofs
- PDFs signed
- Daily digests generated

### Acceptance Criteria (Phase 4)
- [ ] Structured logging operational
- [ ] Metrics collected
- [ ] Alerts functional
- [ ] Audit exports working
- [ ] Compliance reports generated

---

## Phase 5: Governance & Hardening

### Objectives
- Implement retention policies
- Add deletion service with cryptographic erasure
- Enhance incident response
- Add screenshot prevention
- Implement cache clearing

### Tasks

#### 5.1 Retention Policy Service
**File:** `Khandoba/Features/Security/Governance/RetentionPolicyService.swift`

- [ ] Implement retention policies:
  - [ ] Policy table per classification
  - [ ] Jurisdiction-specific rules
  - [ ] Default 7 years for Evidence-Chain
  - [ ] Policy enforcement
- [ ] Add retention UI to admin dashboard
- [ ] Create policy configuration

**Acceptance Criteria:**
- Policies enforced
- Configuration UI functional
- Jurisdiction rules supported

#### 5.2 Deletion Service
**File:** `Khandoba/Features/Security/Governance/DeletionService.swift`

- [ ] Implement cryptographic erasure:
  - [ ] DEK wipe
  - [ ] Tombstone record
  - [ ] Audit event
  - [ ] Grace window before purge
- [ ] Add deletion UI
- [ ] Create deletion workflow

**Acceptance Criteria:**
- Keys cryptographically erased
- Tombstones created
- Grace window enforced

#### 5.3 Incident Response
**File:** `Khandoba/Features/Security/IncidentResponse/IncidentResponseService.swift`

- [ ] Implement incident triggers:
  - [ ] Anomaly detection
  - [ ] Failed attestation
  - [ ] Repeated auth failures
  - [ ] Geo anomalies
  - [ ] Hash mismatches
- [ ] Add response actions:
  - [ ] Session revocation
  - [ ] Key rotation
  - [ ] Upload quarantine
  - [ ] Compliance notification
  - [ ] Forensic snapshot
- [ ] Create post-incident review workflow

**Acceptance Criteria:**
- Incidents detected automatically
- Response actions triggered
- Review workflow functional

#### 5.4 Screenshot Prevention
**File:** `Khandoba/Features/Security/UI/ScreenshotPreventionModifier.swift`

- [ ] Implement screenshot prevention for sensitive views
- [ ] Add blur overlay on app background
- [ ] Detect screenshot attempts
- [ ] Log screenshot attempts to audit

**Acceptance Criteria:**
- Screenshots prevented for sensitive content
- Attempts logged
- Blur overlay works

#### 5.5 Cache Clearing
**Enhance:** All document preview/view services

- [ ] Clear caches on:
  - [ ] App background
  - [ ] Screen lock
  - [ ] Session expiry
  - [ ] Logout
- [ ] Ensure no plaintext in caches
- [ ] Add cache clearing hooks

**Acceptance Criteria:**
- Caches cleared appropriately
- No plaintext persists
- Clearing logged

### Acceptance Criteria (Phase 5)
- [ ] Retention policies enforced
- [ ] Deletion service operational
- [ ] Incident response functional
- [ ] Screenshot prevention working
- [ ] Cache clearing implemented

---

## Phase 6: QA & Validation

### Objectives
- Create pen-test checklist
- Implement red-team scenarios
- Add chaos tests
- Create regression suite
- Validate all acceptance criteria

### Tasks

#### 6.1 Pen-Test Checklist
**File:** `SECURITY_PEN_TEST_CHECKLIST.md`

- [ ] Create comprehensive pen-test checklist
- [ ] Test all attack vectors:
  - [ ] Key extraction
  - [ ] Session hijacking
  - [ ] Man-in-the-middle
  - [ ] Replay attacks
  - [ ] Privilege escalation
- [ ] Document findings

#### 6.2 Red-Team Scenarios
**File:** `SECURITY_RED_TEAM_SCENARIOS.md`

- [ ] Create red-team scenarios:
  - [ ] Compromised device
  - [ ] Insider threat
  - [ ] Key compromise
  - [ ] Audit tampering
- [ ] Run scenarios
- [ ] Document results

#### 6.3 Chaos Tests
**File:** `Khandoba/Features/Security/Tests/ChaosTests.swift`

- [ ] Implement chaos tests:
  - [ ] Key rotation during active sessions
  - [ ] Session expiry during operations
  - [ ] Network failures during upload
  - [ ] Device attestation failures
- [ ] Run tests
- [ ] Fix issues

#### 6.4 Regression Suite
**File:** `Khandoba/Features/Security/Tests/SecurityRegressionTests.swift`

- [ ] Create regression tests for:
  - [ ] Validation gates
  - [ ] Encryption/decryption
  - [ ] Audit logging
  - [ ] Session management
  - [ ] Dual-key workflows
- [ ] Run suite
- [ ] Fix failures

#### 6.5 Final Validation
- [ ] Review all acceptance criteria
- [ ] Run end-to-end tests
- [ ] Validate against spec
- [ ] Create final report

### Acceptance Criteria (Phase 6)
- [ ] Pen-test checklist complete
- [ ] Red-team scenarios passed
- [ ] Chaos tests stable
- [ ] Regression suite passing
- [ ] All spec requirements met

---

## Risk Mitigation

### Key Compromise
- **Mitigation:** Frequent rotation, hardware-backed storage, anomaly alerts
- **Implementation:** KeyRotationService, SecureEnclaveService, AlertService

### Workflow Drift
- **Mitigation:** Codify policies in configuration, CI lint rules
- **Implementation:** Policy configuration registry, automated validation checks

### Performance Impact
- **Mitigation:** Background queues, streaming uploads, encrypted thumbnails
- **Implementation:** Background task queues, chunked uploads, thumbnail cache

### User Friction
- **Mitigation:** Progressive MFA disclosure, clear error guidance, offline-safe metadata
- **Implementation:** Progressive UI, ErrorBanner enhancements, offline metadata capture

---

## Open Questions (To Resolve)

1. **Jurisdiction-specific retention variances**
   - Need policy input for different jurisdictions
   - Action: Create policy configuration UI with jurisdiction support

2. **External evidence source integration**
   - Email ingest, APIs with attestation guarantees
   - Action: Design integration architecture in Phase 2

3. **Notarized timestamps**
   - Third-party authority vs in-house HSM
   - Action: Evaluate options in Phase 2, implement in Phase 4

---

## Success Metrics

- **Security:** Zero plaintext at rest, all operations validated, cryptographic audit trail
- **Compliance:** Chain of custody complete, retention policies enforced, audit exports functional
- **Performance:** <2s validation overhead, <5s upload time, <1s session checks
- **UX:** Clear error messages, progressive disclosure, offline-safe operations

---

## Next Steps

1. Review and approve this plan
2. Set up project tracking (GitHub Issues/Projects)
3. Begin Phase 0: Audit & Alignment
4. Weekly progress reviews
5. Adjust plan based on findings

---

**Document Version:** 1.0  
**Last Updated:** $(date)  
**Status:** Draft - Awaiting Approval


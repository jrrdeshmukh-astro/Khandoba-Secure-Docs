//
//  Vault.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData
import Combine

@Model
final class Vault {
    var id: UUID = UUID()
    var name: String = ""
    var vaultDescription: String?
    var createdAt: Date = Date()
    var lastAccessedAt: Date?
    var status: String = "locked" // "active", "locked", "archived"
    var keyType: String = "single" // "single", "dual"
    var vaultType: String = "both" // "source", "sink", "both" - DEFAULT VALUE FOR MIGRATION
    var isSystemVault: Bool = false // System vaults (like Intel Reports) are read-only for users
    var isAntiVault: Bool = false // Anti-vaults are special vaults for fraud detection
    var monitoredVaultID: UUID? // For anti-vaults: the vault being monitored
    var isBroadcast: Bool = false // Broadcast vaults are publicly accessible (e.g., "Open Street")
    var accessLevel: String = "private" // "private", "public_read", "public_write", "moderated" - for broadcast vaults
    
    // 1:1 Anti-Vault relationship - each vault has exactly one anti-vault
    // Using UUID to avoid circular dependency, but maintaining 1:1 constraint
    var antiVaultID: UUID? // The anti-vault monitoring this vault (1:1 relationship)
    
    // Anti-vault properties embedded in Vault for 1:1 relationship
    var antiVaultStatus: String = "locked" // "locked", "active", "archived"
    var antiVaultAutoUnlockPolicyData: Data? // JSON encoded AutoUnlockPolicy
    var antiVaultThreatDetectionSettingsData: Data? // JSON encoded ThreatDetectionSettings
    var antiVaultLastIntelReportID: UUID?
    var antiVaultLastUnlockedAt: Date?
    var antiVaultCreatedAt: Date?
    
    // Real-time threat monitoring
    var threatIndex: Double = 0.0 // 0-100 scale, calculated by database triggers
    var threatLevel: String = "low" // "low", "medium", "high", "critical"
    var lastThreatAssessmentAt: Date? // Last time threat index was calculated
    
    // Encryption
    var encryptionKeyData: Data?
    var isEncrypted: Bool = true
    
    // Zero-knowledge architecture
    var isZeroKnowledge: Bool = true
    
    // Relationships
    var owner: User?
    var relationshipOfficerID: UUID? // Admin assigned to this vault
    
    @Relationship(deleteRule: .cascade, inverse: \Document.vault)
    var documents: [Document]?
    
    @Relationship(deleteRule: .cascade, inverse: \VaultSession.vault)
    var sessions: [VaultSession]?
    
    @Relationship(deleteRule: .cascade, inverse: \VaultAccessLog.vault)
    var accessLogs: [VaultAccessLog]?
    
    @Relationship(deleteRule: .cascade, inverse: \DualKeyRequest.vault)
    var dualKeyRequests: [DualKeyRequest]?
    
    @Relationship(deleteRule: .cascade, inverse: \Nominee.vault)
    var nomineeList: [Nominee]?
    
    @Relationship(deleteRule: .cascade, inverse: \EmergencyAccessRequest.vault)
    var emergencyRequests: [EmergencyAccessRequest]?
    
    @Relationship(deleteRule: .cascade, inverse: \VaultTransferRequest.vault)
    var transferRequests: [VaultTransferRequest]?
    
    @Relationship(deleteRule: .cascade, inverse: \VaultAccessRequest.vault)
    var accessRequests: [VaultAccessRequest]?
    
    // Anti-vaults monitoring this vault
    // Note: Relationship removed to avoid circular dependency - use UUID lookup instead
    // var antiVaults: [AntiVault]? // Look up by monitoredVaultID when needed
    
    init(
        id: UUID = UUID(),
        name: String = "",
        vaultDescription: String? = nil,
        createdAt: Date = Date(),
        status: String = "locked",
        keyType: String = "single",
        isEncrypted: Bool = true,
        isZeroKnowledge: Bool = true
    ) {
        self.id = id
        self.name = name.isEmpty ? "New Vault" : name
        self.vaultDescription = vaultDescription
        self.createdAt = createdAt
        self.status = status
        self.keyType = keyType
        self.vaultType = "both" // Default value
        self.isEncrypted = isEncrypted
        self.isZeroKnowledge = isZeroKnowledge
        self.documents = []
        self.sessions = []
        self.accessLogs = []
        self.dualKeyRequests = []
    }
}

@Model
final class VaultSession {
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var expiresAt: Date = Date()
    var isActive: Bool = false
    var wasExtended: Bool = false
    
    var vault: Vault?
    var user: User?
    
    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(30 * 60), // 30 minutes
        isActive: Bool = true,
        wasExtended: Bool = false
    ) {
        self.id = id
        self.startedAt = startedAt
        self.expiresAt = expiresAt
        self.isActive = isActive
        self.wasExtended = wasExtended
    }
}

@Model
final class VaultAccessLog {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var accessType: String = "viewed" // "opened", "closed", "viewed", "modified", "deleted", "previewed", "edited", "renamed", "redacted"
    var userID: UUID?
    var userName: String?
    var deviceInfo: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var ipAddress: String?
    var documentID: UUID? // Track which document was accessed
    var documentName: String? // Document name for easier reference
    
    var vault: Vault?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        accessType: String = "viewed",
        userID: UUID? = nil,
        userName: String? = nil,
        deviceInfo: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.accessType = accessType
        self.userID = userID
        self.userName = userName
        self.deviceInfo = deviceInfo
    }
}

@Model
final class DualKeyRequest {
    var id: UUID = UUID()
    var requestedAt: Date = Date()
    var status: String = "pending" // "pending", "approved", "denied"
    var reason: String?
    var approvedAt: Date?
    var deniedAt: Date?
    var approverID: UUID?
    var mlScore: Double?
    var logicalReasoning: String? // Formal logic explanation
    var decisionMethod: String? // "ml_auto" or "logic_reasoning"
    
    var vault: Vault?
    var requester: User?
    
    init(
        id: UUID = UUID(),
        requestedAt: Date = Date(),
        status: String = "pending",
        reason: String? = nil
    ) {
        self.id = id
        self.requestedAt = requestedAt
        self.status = status
        self.reason = reason
    }
}


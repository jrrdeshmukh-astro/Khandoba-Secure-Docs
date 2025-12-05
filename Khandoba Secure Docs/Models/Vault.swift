//
//  Vault.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData

@Model
final class Vault {
    var id: UUID
    var name: String
    var vaultDescription: String?
    var createdAt: Date
    var lastAccessedAt: Date?
    var status: String = "locked" // "active", "locked", "archived"
    var keyType: String = "single" // "single", "dual"
    var vaultType: String = "both" // "source", "sink", "both" - DEFAULT VALUE FOR MIGRATION
    var isSystemVault: Bool = false // System vaults (like Intel Reports) are read-only for users
    
    // Encryption
    var encryptionKeyData: Data?
    var isEncrypted: Bool
    
    // Zero-knowledge architecture
    var isZeroKnowledge: Bool
    
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
    
    init(
        id: UUID = UUID(),
        name: String,
        vaultDescription: String? = nil,
        createdAt: Date = Date(),
        status: String = "locked",
        keyType: String = "single",
        isEncrypted: Bool = true,
        isZeroKnowledge: Bool = true
    ) {
        self.id = id
        self.name = name
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
    var id: UUID
    var startedAt: Date
    var expiresAt: Date
    var isActive: Bool
    var wasExtended: Bool
    
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
    var id: UUID
    var timestamp: Date
    var accessType: String // "opened", "closed", "viewed", "modified", "deleted"
    var userID: UUID?
    var userName: String?
    var deviceInfo: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var ipAddress: String?
    
    var vault: Vault?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        accessType: String,
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
    var id: UUID
    var requestedAt: Date
    var status: String // "pending", "approved", "denied"
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


//
//  SupabaseVault.swift
//  Khandoba Secure Docs
//
//  Created for Supabase Migration
//

import Foundation

struct SupabaseVault: Codable, Identifiable {
    let id: UUID
    var name: String
    var vaultDescription: String?
    let ownerID: UUID
    let createdAt: Date
    var lastAccessedAt: Date?
    var status: String // "active", "locked", "archived"
    var keyType: String // "single", "dual"
    var vaultType: String // "source", "sink", "both"
    var isSystemVault: Bool
    var encryptionKeyData: Data? // Will be stored as BYTEA in PostgreSQL
    var isEncrypted: Bool
    var isZeroKnowledge: Bool
    var relationshipOfficerID: UUID?
    var isAntiVault: Bool
    var monitoredVaultID: UUID?
    var antiVaultID: UUID? // 1:1 relationship with anti-vault
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case vaultDescription = "vault_description"
        case ownerID = "owner_id"
        case createdAt = "created_at"
        case lastAccessedAt = "last_accessed_at"
        case status
        case keyType = "key_type"
        case vaultType = "vault_type"
        case isSystemVault = "is_system_vault"
        case encryptionKeyData = "encryption_key_data"
        case isEncrypted = "is_encrypted"
        case isZeroKnowledge = "is_zero_knowledge"
        case relationshipOfficerID = "relationship_officer_id"
        case isAntiVault = "is_anti_vault"
        case monitoredVaultID = "monitored_vault_id"
        case antiVaultID = "anti_vault_id"
        case updatedAt = "updated_at"
    }
    
    // Convert from SwiftData Vault model
    init(from vault: Vault) {
        self.id = vault.id
        self.name = vault.name
        self.vaultDescription = vault.vaultDescription
        self.ownerID = vault.owner?.id ?? UUID() // Should always have owner
        self.createdAt = vault.createdAt
        self.lastAccessedAt = vault.lastAccessedAt
        self.status = vault.status
        self.keyType = vault.keyType
        self.vaultType = vault.vaultType
        self.isSystemVault = vault.isSystemVault
        self.encryptionKeyData = vault.encryptionKeyData
        self.isEncrypted = vault.isEncrypted
        self.isZeroKnowledge = vault.isZeroKnowledge
        self.relationshipOfficerID = vault.relationshipOfficerID
        self.isAntiVault = vault.isAntiVault
        self.monitoredVaultID = vault.monitoredVaultID
        self.antiVaultID = vault.antiVaultID
        self.updatedAt = Date()
    }
    
    // Standard init
    init(
        id: UUID = UUID(),
        name: String,
        vaultDescription: String? = nil,
        ownerID: UUID,
        createdAt: Date = Date(),
        lastAccessedAt: Date? = nil,
        status: String = "locked",
        keyType: String = "single",
        vaultType: String = "both",
        isSystemVault: Bool = false,
        encryptionKeyData: Data? = nil,
        isEncrypted: Bool = true,
        isZeroKnowledge: Bool = true,
        relationshipOfficerID: UUID? = nil,
        isAntiVault: Bool = false,
        monitoredVaultID: UUID? = nil,
        antiVaultID: UUID? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.vaultDescription = vaultDescription
        self.ownerID = ownerID
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.status = status
        self.keyType = keyType
        self.vaultType = vaultType
        self.isSystemVault = isSystemVault
        self.encryptionKeyData = encryptionKeyData
        self.isEncrypted = isEncrypted
        self.isZeroKnowledge = isZeroKnowledge
        self.relationshipOfficerID = relationshipOfficerID
        self.isAntiVault = isAntiVault
        self.monitoredVaultID = monitoredVaultID
        self.antiVaultID = antiVaultID
        self.updatedAt = updatedAt
    }
}

struct SupabaseVaultSession: Codable, Identifiable {
    let id: UUID
    let vaultID: UUID
    let userID: UUID
    let startedAt: Date
    let expiresAt: Date
    var isActive: Bool
    var wasExtended: Bool
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vaultID = "vault_id"
        case userID = "user_id"
        case startedAt = "started_at"
        case expiresAt = "expires_at"
        case isActive = "is_active"
        case wasExtended = "was_extended"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        vaultID: UUID,
        userID: UUID,
        startedAt: Date = Date(),
        expiresAt: Date,
        isActive: Bool = true,
        wasExtended: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vaultID = vaultID
        self.userID = userID
        self.startedAt = startedAt
        self.expiresAt = expiresAt
        self.isActive = isActive
        self.wasExtended = wasExtended
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct SupabaseVaultAccessLog: Codable, Identifiable {
    let id: UUID
    let vaultID: UUID
    let timestamp: Date
    var accessType: String // "opened", "closed", "viewed", "modified", etc.
    var userID: UUID?
    var userName: String?
    var deviceInfo: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var ipAddress: String?
    var documentID: UUID?
    var documentName: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vaultID = "vault_id"
        case timestamp
        case accessType = "access_type"
        case userID = "user_id"
        case userName = "user_name"
        case deviceInfo = "device_info"
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
        case ipAddress = "ip_address"
        case documentID = "document_id"
        case documentName = "document_name"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        vaultID: UUID,
        timestamp: Date = Date(),
        accessType: String = "viewed",
        userID: UUID? = nil,
        userName: String? = nil,
        deviceInfo: String? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        ipAddress: String? = nil,
        documentID: UUID? = nil,
        documentName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.vaultID = vaultID
        self.timestamp = timestamp
        self.accessType = accessType
        self.userID = userID
        self.userName = userName
        self.deviceInfo = deviceInfo
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.ipAddress = ipAddress
        self.documentID = documentID
        self.documentName = documentName
        self.createdAt = createdAt
    }
}

struct SupabaseDualKeyRequest: Codable, Identifiable {
    let id: UUID
    let vaultID: UUID
    let requesterID: UUID
    let requestedAt: Date
    var status: String // "pending", "approved", "denied"
    var reason: String?
    var approvedAt: Date?
    var deniedAt: Date?
    var approverID: UUID?
    var mlScore: Double?
    var logicalReasoning: String?
    var decisionMethod: String? // "ml_auto" or "logic_reasoning"
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vaultID = "vault_id"
        case requesterID = "requester_id"
        case requestedAt = "requested_at"
        case status
        case reason
        case approvedAt = "approved_at"
        case deniedAt = "denied_at"
        case approverID = "approver_id"
        case mlScore = "ml_score"
        case logicalReasoning = "logical_reasoning"
        case decisionMethod = "decision_method"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        vaultID: UUID,
        requesterID: UUID,
        requestedAt: Date = Date(),
        status: String = "pending",
        reason: String? = nil,
        approvedAt: Date? = nil,
        deniedAt: Date? = nil,
        approverID: UUID? = nil,
        mlScore: Double? = nil,
        logicalReasoning: String? = nil,
        decisionMethod: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vaultID = vaultID
        self.requesterID = requesterID
        self.requestedAt = requestedAt
        self.status = status
        self.reason = reason
        self.approvedAt = approvedAt
        self.deniedAt = deniedAt
        self.approverID = approverID
        self.mlScore = mlScore
        self.logicalReasoning = logicalReasoning
        self.decisionMethod = decisionMethod
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

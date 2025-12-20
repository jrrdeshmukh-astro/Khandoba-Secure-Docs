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
    var isBroadcast: Bool? // Broadcast vaults are publicly accessible
    var accessLevel: String? // "private", "public_read", "public_write", "moderated"
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
        case isBroadcast = "is_broadcast"
        case accessLevel = "access_level"
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
        self.isBroadcast = vault.isBroadcast
        self.accessLevel = vault.accessLevel
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
        isBroadcast: Bool? = false,
        accessLevel: String? = "private",
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
        self.isBroadcast = isBroadcast
        self.accessLevel = accessLevel
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

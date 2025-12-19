//
//  SupabaseVaultAccessLog.swift
//  Khandoba Secure Docs
//
//  Created for Supabase Migration
//

import Foundation

struct SupabaseVaultAccessLog: Codable, Identifiable {
    let id: UUID
    var vaultID: UUID
    var userID: UUID
    var userName: String?
    var timestamp: Date
    var accessType: String // "opened", "closed", "viewed", "modified", "deleted", "previewed", "edited", "renamed", "redacted"
    var deviceInfo: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var ipAddress: String?
    var documentID: UUID? // Track which document was accessed
    var documentName: String? // Document name for easier reference
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vaultID = "vault_id"
        case userID = "user_id"
        case userName = "user_name"
        case timestamp
        case accessType = "access_type"
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
        userID: UUID,
        userName: String? = nil,
        timestamp: Date = Date(),
        accessType: String = "viewed",
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
        self.userID = userID
        self.userName = userName
        self.timestamp = timestamp
        self.accessType = accessType
        self.deviceInfo = deviceInfo
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.ipAddress = ipAddress
        self.documentID = documentID
        self.documentName = documentName
        self.createdAt = createdAt
    }
    
    // Convert from SwiftData model
    init(from log: VaultAccessLog) {
        self.id = log.id
        self.vaultID = log.vault?.id ?? UUID()
        self.userID = log.userID ?? UUID()
        self.userName = log.userName
        self.timestamp = log.timestamp
        self.accessType = log.accessType
        self.deviceInfo = log.deviceInfo
        self.locationLatitude = log.locationLatitude
        self.locationLongitude = log.locationLongitude
        self.ipAddress = log.ipAddress
        self.documentID = log.documentID
        self.documentName = log.documentName
        self.createdAt = log.timestamp
    }
}

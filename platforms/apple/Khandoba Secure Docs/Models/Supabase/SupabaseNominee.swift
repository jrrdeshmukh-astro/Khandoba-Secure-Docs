//
//  SupabaseNominee.swift
//  Khandoba Secure Docs
//
//  Created for Supabase Migration
//

import Foundation

struct SupabaseNominee: Codable, Identifiable {
    let id: UUID
    let vaultID: UUID
    let userID: UUID
    var invitedByUserID: UUID?
    var status: String // "pending", "accepted", "declined", "revoked"
    let invitedAt: Date
    var acceptedAt: Date?
    var declinedAt: Date?
    var revokedAt: Date?
    var accessLevel: String // "read", "write", "admin"
    var selectedDocumentIDs: [UUID]? // JSON array of document IDs for subset access
    var sessionExpiresAt: Date? // Time-bound access expiration
    var isSubsetAccess: Bool = false // Flag for subset nominations
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vaultID = "vault_id"
        case userID = "user_id"
        case invitedByUserID = "invited_by_user_id"
        case status
        case invitedAt = "invited_at"
        case acceptedAt = "accepted_at"
        case declinedAt = "declined_at"
        case revokedAt = "revoked_at"
        case accessLevel = "access_level"
        case selectedDocumentIDs = "selected_document_ids"
        case sessionExpiresAt = "session_expires_at"
        case isSubsetAccess = "is_subset_access"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom encoding for selectedDocumentIDs (UUID array to JSON)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        vaultID = try container.decode(UUID.self, forKey: .vaultID)
        userID = try container.decode(UUID.self, forKey: .userID)
        invitedByUserID = try container.decodeIfPresent(UUID.self, forKey: .invitedByUserID)
        status = try container.decode(String.self, forKey: .status)
        invitedAt = try container.decode(Date.self, forKey: .invitedAt)
        acceptedAt = try container.decodeIfPresent(Date.self, forKey: .acceptedAt)
        declinedAt = try container.decodeIfPresent(Date.self, forKey: .declinedAt)
        revokedAt = try container.decodeIfPresent(Date.self, forKey: .revokedAt)
        accessLevel = try container.decode(String.self, forKey: .accessLevel)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isSubsetAccess = try container.decodeIfPresent(Bool.self, forKey: .isSubsetAccess) ?? false
        sessionExpiresAt = try container.decodeIfPresent(Date.self, forKey: .sessionExpiresAt)
        
        // Decode selectedDocumentIDs from JSONB (can be array of UUID strings or null)
        if let uuidStrings = try? container.decodeIfPresent([String].self, forKey: .selectedDocumentIDs) {
            selectedDocumentIDs = uuidStrings.compactMap { UUID(uuidString: $0) }
        } else {
            selectedDocumentIDs = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(vaultID, forKey: .vaultID)
        try container.encode(userID, forKey: .userID)
        try container.encodeIfPresent(invitedByUserID, forKey: .invitedByUserID)
        try container.encode(status, forKey: .status)
        try container.encode(invitedAt, forKey: .invitedAt)
        try container.encodeIfPresent(acceptedAt, forKey: .acceptedAt)
        try container.encodeIfPresent(declinedAt, forKey: .declinedAt)
        try container.encodeIfPresent(revokedAt, forKey: .revokedAt)
        try container.encode(accessLevel, forKey: .accessLevel)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(isSubsetAccess, forKey: .isSubsetAccess)
        try container.encodeIfPresent(sessionExpiresAt, forKey: .sessionExpiresAt)
        
        // Encode selectedDocumentIDs as array of UUID strings (PostgREST handles JSONB conversion)
        if let documentIDs = selectedDocumentIDs {
            let uuidStrings = documentIDs.map { $0.uuidString }
            try container.encode(uuidStrings, forKey: .selectedDocumentIDs)
        } else {
            try container.encodeNil(forKey: .selectedDocumentIDs)
        }
    }
    
    var nomineeStatus: NomineeStatus {
        get { NomineeStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        vaultID: UUID,
        userID: UUID,
        invitedByUserID: UUID? = nil,
        status: String = "pending",
        invitedAt: Date = Date(),
        acceptedAt: Date? = nil,
        declinedAt: Date? = nil,
        revokedAt: Date? = nil,
        accessLevel: String = "read",
        selectedDocumentIDs: [UUID]? = nil,
        sessionExpiresAt: Date? = nil,
        isSubsetAccess: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vaultID = vaultID
        self.userID = userID
        self.invitedByUserID = invitedByUserID
        self.status = status
        self.invitedAt = invitedAt
        self.acceptedAt = acceptedAt
        self.declinedAt = declinedAt
        self.revokedAt = revokedAt
        self.accessLevel = accessLevel
        self.selectedDocumentIDs = selectedDocumentIDs
        self.sessionExpiresAt = sessionExpiresAt
        self.isSubsetAccess = isSubsetAccess
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct SupabaseVaultAccessRequest: Codable, Identifiable {
    let id: UUID
    let vaultID: UUID
    let requesterID: UUID
    let requestedAt: Date
    var status: String // "pending", "approved", "denied"
    var requestType: String // "request" or "send"
    var message: String?
    var expiresAt: Date?
    var respondedAt: Date?
    var responseMessage: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vaultID = "vault_id"
        case requesterID = "requester_id"
        case requestedAt = "requested_at"
        case status
        case requestType = "request_type"
        case message
        case expiresAt = "expires_at"
        case respondedAt = "responded_at"
        case responseMessage = "response_message"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        vaultID: UUID,
        requesterID: UUID,
        requestedAt: Date = Date(),
        status: String = "pending",
        requestType: String = "request",
        message: String? = nil,
        expiresAt: Date? = nil,
        respondedAt: Date? = nil,
        responseMessage: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vaultID = vaultID
        self.requesterID = requesterID
        self.requestedAt = requestedAt
        self.status = status
        self.requestType = requestType
        self.message = message
        self.expiresAt = expiresAt
        self.respondedAt = respondedAt
        self.responseMessage = responseMessage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

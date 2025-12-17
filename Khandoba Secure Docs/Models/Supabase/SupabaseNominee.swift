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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct SupabaseVaultTransferRequest: Codable, Identifiable {
    let id: UUID
    let vaultID: UUID
    let fromUserID: UUID
    let toUserID: UUID
    let requestedAt: Date
    var status: String // "pending", "approved", "denied", "cancelled"
    var reason: String?
    var approvedAt: Date?
    var deniedAt: Date?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vaultID = "vault_id"
        case fromUserID = "from_user_id"
        case toUserID = "to_user_id"
        case requestedAt = "requested_at"
        case status
        case reason
        case approvedAt = "approved_at"
        case deniedAt = "denied_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        vaultID: UUID,
        fromUserID: UUID,
        toUserID: UUID,
        requestedAt: Date = Date(),
        status: String = "pending",
        reason: String? = nil,
        approvedAt: Date? = nil,
        deniedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vaultID = vaultID
        self.fromUserID = fromUserID
        self.toUserID = toUserID
        self.requestedAt = requestedAt
        self.status = status
        self.reason = reason
        self.approvedAt = approvedAt
        self.deniedAt = deniedAt
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

struct SupabaseEmergencyAccessRequest: Codable, Identifiable {
    let id: UUID
    let vaultID: UUID
    let requesterID: UUID
    let requestedAt: Date
    var reason: String
    var urgencyLevel: String // "low", "medium", "high", "critical"
    var status: String // "pending", "approved", "denied"
    var approvedAt: Date?
    var deniedAt: Date?
    var approverID: UUID?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vaultID = "vault_id"
        case requesterID = "requester_id"
        case requestedAt = "requested_at"
        case reason
        case urgencyLevel = "urgency_level"
        case status
        case approvedAt = "approved_at"
        case deniedAt = "denied_at"
        case approverID = "approver_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        vaultID: UUID,
        requesterID: UUID,
        requestedAt: Date = Date(),
        reason: String = "",
        urgencyLevel: String = "medium",
        status: String = "pending",
        approvedAt: Date? = nil,
        deniedAt: Date? = nil,
        approverID: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vaultID = vaultID
        self.requesterID = requesterID
        self.requestedAt = requestedAt
        self.reason = reason
        self.urgencyLevel = urgencyLevel
        self.status = status
        self.approvedAt = approvedAt
        self.deniedAt = deniedAt
        self.approverID = approverID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

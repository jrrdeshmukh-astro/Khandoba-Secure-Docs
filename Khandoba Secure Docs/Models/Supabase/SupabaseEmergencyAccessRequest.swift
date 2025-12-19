//
//  SupabaseEmergencyAccessRequest.swift
//  Khandoba Secure Docs
//
//  Created for Supabase Migration
//

import Foundation

struct SupabaseEmergencyAccessRequest: Codable, Identifiable {
    let id: UUID
    var vaultID: UUID
    var requesterID: UUID
    var requestedAt: Date
    var reason: String
    var urgency: String // "low", "medium", "high", "critical"
    var status: String // "pending", "approved", "denied"
    var approvedAt: Date?
    var approverID: UUID?
    var expiresAt: Date? // 24 hours from approval
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vaultID = "vault_id"
        case requesterID = "requester_id"
        case requestedAt = "requested_at"
        case reason
        case urgency
        case status
        case approvedAt = "approved_at"
        case approverID = "approver_id"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        vaultID: UUID,
        requesterID: UUID,
        requestedAt: Date = Date(),
        reason: String = "",
        urgency: String = "medium",
        status: String = "pending",
        approvedAt: Date? = nil,
        approverID: UUID? = nil,
        expiresAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vaultID = vaultID
        self.requesterID = requesterID
        self.requestedAt = requestedAt
        self.reason = reason
        self.urgency = urgency
        self.status = status
        self.approvedAt = approvedAt
        self.approverID = approverID
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Convert from SwiftData model
    init(from request: EmergencyAccessRequest) {
        self.id = request.id
        self.vaultID = request.vault?.id ?? UUID()
        self.requesterID = request.requesterID ?? UUID()
        self.requestedAt = request.requestedAt
        self.reason = request.reason
        self.urgency = request.urgency
        self.status = request.status
        self.approvedAt = request.approvedAt
        self.approverID = request.approverID
        self.expiresAt = request.expiresAt
        self.createdAt = request.requestedAt
        self.updatedAt = Date()
    }
}

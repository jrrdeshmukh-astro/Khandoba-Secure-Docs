//
//  SupabaseVaultTransferRequest.swift
//  Khandoba Secure Docs
//
//  Created for Supabase Migration
//

import Foundation

struct SupabaseVaultTransferRequest: Codable, Identifiable {
    let id: UUID
    var vaultID: UUID
    var requestedByUserID: UUID
    var newOwnerID: UUID?
    var newOwnerName: String?
    var newOwnerPhone: String?
    var newOwnerEmail: String?
    var requestedAt: Date
    var status: String // "pending", "approved", "denied", "completed"
    var reason: String?
    var transferToken: String
    var approvedAt: Date?
    var approverID: UUID?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vaultID = "vault_id"
        case requestedByUserID = "requested_by_user_id"
        case newOwnerID = "new_owner_id"
        case newOwnerName = "new_owner_name"
        case newOwnerPhone = "new_owner_phone"
        case newOwnerEmail = "new_owner_email"
        case requestedAt = "requested_at"
        case status
        case reason
        case transferToken = "transfer_token"
        case approvedAt = "approved_at"
        case approverID = "approver_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        vaultID: UUID,
        requestedByUserID: UUID,
        newOwnerID: UUID? = nil,
        newOwnerName: String? = nil,
        newOwnerPhone: String? = nil,
        newOwnerEmail: String? = nil,
        requestedAt: Date = Date(),
        status: String = "pending",
        reason: String? = nil,
        transferToken: String = UUID().uuidString,
        approvedAt: Date? = nil,
        approverID: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vaultID = vaultID
        self.requestedByUserID = requestedByUserID
        self.newOwnerID = newOwnerID
        self.newOwnerName = newOwnerName
        self.newOwnerPhone = newOwnerPhone
        self.newOwnerEmail = newOwnerEmail
        self.requestedAt = requestedAt
        self.status = status
        self.reason = reason
        self.transferToken = transferToken
        self.approvedAt = approvedAt
        self.approverID = approverID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Convert from SwiftData model
    init(from request: VaultTransferRequest) {
        self.id = request.id
        self.vaultID = request.vault?.id ?? UUID()
        self.requestedByUserID = request.requestedByUserID ?? UUID()
        self.newOwnerID = request.newOwnerID
        self.newOwnerName = request.newOwnerName
        self.newOwnerPhone = request.newOwnerPhone
        self.newOwnerEmail = request.newOwnerEmail
        self.requestedAt = request.requestedAt
        self.status = request.status
        self.reason = request.reason
        self.transferToken = request.transferToken
        self.approvedAt = request.approvedAt
        self.approverID = request.approverID
        self.createdAt = request.requestedAt
        self.updatedAt = Date()
    }
}

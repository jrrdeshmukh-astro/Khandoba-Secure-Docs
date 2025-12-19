//
//  SupabaseDualKeyRequest.swift
//  Khandoba Secure Docs
//
//  Created for Supabase Migration
//

import Foundation

struct SupabaseDualKeyRequest: Codable, Identifiable {
    let id: UUID
    var vaultID: UUID
    var requesterID: UUID
    var requestedAt: Date
    var status: String // "pending", "approved", "denied"
    var reason: String?
    var approvedAt: Date?
    var deniedAt: Date?
    var approverID: UUID?
    var mlScore: Double?
    var logicalReasoning: String? // Formal logic explanation
    var decisionMethod: String? // "ml_auto" or "logic_reasoning"
    var createdAt: Date
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
    
    // Convert from SwiftData model
    init(from request: DualKeyRequest) {
        self.id = request.id
        self.vaultID = request.vault?.id ?? UUID()
        self.requesterID = request.requester?.id ?? UUID()
        self.requestedAt = request.requestedAt
        self.status = request.status
        self.reason = request.reason
        self.approvedAt = request.approvedAt
        self.deniedAt = request.deniedAt
        self.approverID = request.approverID
        self.mlScore = request.mlScore
        self.logicalReasoning = request.logicalReasoning
        self.decisionMethod = request.decisionMethod
        self.createdAt = request.requestedAt
        self.updatedAt = Date()
    }
}

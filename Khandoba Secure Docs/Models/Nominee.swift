//
//  Nominee.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData
import Combine

@Model
final class Nominee {
    var id: UUID = UUID()
    var name: String = ""
    var phoneNumber: String?
    var email: String?
    var status: String = "pending" // "pending", "accepted", "active", "inactive"
    var invitedAt: Date = Date()
    var acceptedAt: Date?
    var inviteToken: String = UUID().uuidString  // Token for CloudKit sync (uniqueness enforced in app logic)
    
    var vault: Vault?
    var invitedByUserID: UUID?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        phoneNumber: String? = nil,
        email: String? = nil,
        status: String = "pending",
        invitedAt: Date = Date(),
        inviteToken: String = UUID().uuidString
    ) {
        self.id = id
        self.name = name.isEmpty ? "Nominee" : name
        self.phoneNumber = phoneNumber
        self.email = email
        self.status = status
        self.invitedAt = invitedAt
        self.inviteToken = inviteToken
    }
}

@Model
final class VaultTransferRequest {
    var id: UUID = UUID()
    var requestedAt: Date = Date()
    var status: String = "pending" // "pending", "approved", "denied", "completed"
    var reason: String?
    var newOwnerID: UUID?
    var approvedAt: Date?
    var approverID: UUID?
    
    @Relationship(inverse: \Vault.transferRequests)
    var vault: Vault?
    var requestedByUserID: UUID?
    
    init(
        id: UUID = UUID(),
        requestedAt: Date = Date(),
        status: String = "pending",
        reason: String? = nil,
        newOwnerID: UUID? = nil
    ) {
        self.id = id
        self.requestedAt = requestedAt
        self.status = status
        self.reason = reason
        self.newOwnerID = newOwnerID
    }
}

@Model
final class EmergencyAccessRequest {
    var id: UUID = UUID()
    var requestedAt: Date = Date()
    var reason: String = ""
    var urgency: String = "medium" // "low", "medium", "high", "critical"
    var status: String = "pending" // "pending", "approved", "denied"
    var approvedAt: Date?
    var approverID: UUID?
    var expiresAt: Date? // 24 hours from approval
    
    @Relationship(inverse: \Vault.emergencyRequests)
    var vault: Vault?
    var requesterID: UUID?
    
    init(
        id: UUID = UUID(),
        requestedAt: Date = Date(),
        reason: String = "",
        urgency: String = "medium",
        status: String = "pending"
    ) {
        self.id = id
        self.requestedAt = requestedAt
        self.reason = reason
        self.urgency = urgency
        self.status = status
    }
}


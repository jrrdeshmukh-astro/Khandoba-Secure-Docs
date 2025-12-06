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
    @Attribute(.unique) var id: UUID
    var name: String
    var phoneNumber: String?
    var email: String?
    var status: String // "pending", "accepted", "active", "inactive"
    var invitedAt: Date
    var acceptedAt: Date?
    @Attribute(.unique) var inviteToken: String  // Unique token for CloudKit sync
    
    var vault: Vault?
    var invitedByUserID: UUID?
    
    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String? = nil,
        email: String? = nil,
        status: String = "pending",
        invitedAt: Date = Date(),
        inviteToken: String = UUID().uuidString
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.status = status
        self.invitedAt = invitedAt
        self.inviteToken = inviteToken
    }
}

@Model
final class VaultTransferRequest {
    var id: UUID
    var requestedAt: Date
    var status: String // "pending", "approved", "denied", "completed"
    var reason: String?
    var newOwnerID: UUID?
    var approvedAt: Date?
    var approverID: UUID?
    
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
    var id: UUID
    var requestedAt: Date
    var reason: String
    var urgency: String // "low", "medium", "high", "critical"
    var status: String // "pending", "approved", "denied"
    var approvedAt: Date?
    var approverID: UUID?
    var expiresAt: Date? // 24 hours from approval
    
    var vault: Vault?
    var requesterID: UUID?
    
    init(
        id: UUID = UUID(),
        requestedAt: Date = Date(),
        reason: String,
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


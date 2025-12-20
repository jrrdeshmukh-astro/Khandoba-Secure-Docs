//
//  Nominee.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData
import Combine
import CloudKit

@Model
final class Nominee {
    var id: UUID = UUID()
    var name: String = ""
    var phoneNumber: String?
    var email: String?
    
    // Type-safe status (stored as String for SwiftData compatibility)
    var statusRaw: String = NomineeStatus.pending.rawValue
    
    // Computed property for type-safe status access
    var status: NomineeStatus {
        get { NomineeStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
    
    // Legacy status property for backwards compatibility (deprecated)
    @available(*, deprecated, message: "Use status computed property instead")
    var statusString: String {
        get { statusRaw }
        set { statusRaw = newValue }
    }
    
    var invitedAt: Date = Date()
    var acceptedAt: Date?
    var lastActiveAt: Date?
    
    // CloudKit integration fields
    var cloudKitShareRecordID: String? // CKShare record ID
    var cloudKitParticipantID: String? // CKShare.Participant ID
    
    // Legacy token field (kept for migration, but CloudKit sharing is primary)
    var inviteToken: String = UUID().uuidString
    
    // Relationships
    var vault: Vault?
    var invitedByUserID: UUID?
    
    // Concurrent access tracking (Bank Vault Model)
    var isCurrentlyActive: Bool = false
    var currentSessionID: UUID?
    
    // Subset access control (session-based nomination)
    var selectedDocumentIDs: [UUID]? // If nil, access to all documents; if set, only selected documents
    var sessionExpiresAt: Date? // Time-bound access expiration
    var isSubsetAccess: Bool = false // Flag for subset nominations
    
    init(
        id: UUID = UUID(),
        name: String = "",
        phoneNumber: String? = nil,
        email: String? = nil,
        status: NomineeStatus = .pending,
        invitedAt: Date = Date()
    ) {
        self.id = id
        self.name = name.isEmpty ? "Nominee" : name
        self.phoneNumber = phoneNumber
        self.email = email
        self.statusRaw = status.rawValue
        self.invitedAt = invitedAt
    }
}

// MARK: - Nominee Status Enum

enum NomineeStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case active = "active"
    case inactive = "inactive"
    case revoked = "revoked"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .active: return "Active"
        case .inactive: return "Inactive"
        case .revoked: return "Revoked"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "warning"
        case .accepted: return "info"
        case .active: return "success"
        case .inactive: return "textTertiary"
        case .revoked: return "error"
        }
    }
}

@Model
final class VaultTransferRequest {
    var id: UUID = UUID()
    var requestedAt: Date = Date()
    var status: String = "pending" // "pending", "approved", "denied", "completed"
    var reason: String?
    var newOwnerID: UUID?
    var newOwnerName: String?
    var newOwnerPhone: String?
    var newOwnerEmail: String?
    var transferToken: String = UUID().uuidString  // Token for sharing and deep linking
    var approvedAt: Date?
    var approverID: UUID?
    
    var vault: Vault?
    var requestedByUserID: UUID?
    
    init(
        id: UUID = UUID(),
        requestedAt: Date = Date(),
        status: String = "pending",
        reason: String? = nil,
        newOwnerID: UUID? = nil,
        newOwnerName: String? = nil,
        newOwnerPhone: String? = nil,
        newOwnerEmail: String? = nil,
        transferToken: String = UUID().uuidString
    ) {
        self.id = id
        self.requestedAt = requestedAt
        self.status = status
        self.reason = reason
        self.newOwnerID = newOwnerID
        self.newOwnerName = newOwnerName
        self.newOwnerPhone = newOwnerPhone
        self.newOwnerEmail = newOwnerEmail
        self.transferToken = transferToken
    }
}

@Model
final class VaultAccessRequest {
    var id: UUID = UUID()
    var requestedAt: Date = Date()
    var status: String = "pending" // "pending", "accepted", "declined", "expired"
    var requestType: String = "request" // "request" (requesting access) or "send" (sending access)
    var message: String? // Optional message from requester/sender
    var expiresAt: Date? // Optional expiration date
    
    // Requester/Sender information
    var requesterUserID: UUID? // User requesting/sending access
    var requesterName: String?
    var requesterEmail: String?
    var requesterPhone: String?
    
    // Recipient information (for send type)
    var recipientUserID: UUID?
    var recipientName: String?
    var recipientEmail: String?
    var recipientPhone: String?
    
    // Vault information
    var vault: Vault?
    var vaultID: UUID?
    var vaultName: String?
    
    // CloudKit integration
    var cloudKitShareRecordID: String?
    var accessToken: String = UUID().uuidString // Token for deep linking
    
    // Response tracking
    var respondedAt: Date?
    var responseMessage: String?
    
    init(
        id: UUID = UUID(),
        requestType: String = "request",
        message: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.requestType = requestType
        self.message = message
        self.expiresAt = expiresAt
        self.requestedAt = Date()
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
    var passCode: String? // Generated identification pass code (UUID string)
    var mlScore: Double? // ML confidence score (0.0 to 1.0)
    var mlRecommendation: String? // ML reasoning/explanation
    
    var vault: Vault?
    var requesterID: UUID?
    
    @Relationship(deleteRule: .cascade, inverse: \EmergencyAccessPass.emergencyRequest)
    var accessPass: EmergencyAccessPass?
    
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


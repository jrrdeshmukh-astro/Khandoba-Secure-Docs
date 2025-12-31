//
//  IDVerification.swift
//  Khandoba Secure Docs
//
//  KYC verification model
//

import Foundation
import SwiftData

/// Verification status
enum VerificationStatus: String, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
    case expired = "Expired"
}

@Model
final class IDVerification {
    var id: UUID = UUID()
    var userID: UUID
    var status: String // VerificationStatus rawValue
    var submittedAt: Date = Date()
    var reviewedAt: Date?
    var reviewerID: UUID?
    var reviewNotes: String?
    
    // Document references (stored as document IDs)
    var idDocumentID: UUID?
    var proofOfAddressID: UUID?
    
    // Verification details
    var fullName: String?
    var dateOfBirth: Date?
    var address: String?
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        userID: UUID,
        status: VerificationStatus = .pending
    ) {
        self.userID = userID
        self.status = status.rawValue
    }
    
    var statusEnum: VerificationStatus? {
        VerificationStatus(rawValue: status)
    }
}


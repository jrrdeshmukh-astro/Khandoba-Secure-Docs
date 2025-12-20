//
//  EmergencyAccessPass.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/20/25.
//

import Foundation
import SwiftData

@Model
final class EmergencyAccessPass {
    var id: UUID = UUID()
    var vaultID: UUID
    var requesterID: UUID
    var passCode: String // UUID string for verification
    var createdAt: Date = Date()
    var expiresAt: Date
    var usedAt: Date?
    var isActive: Bool = true
    var emergencyRequestID: UUID
    
    // Relationship to emergency request
    var emergencyRequest: EmergencyAccessRequest?
    
    init(
        id: UUID = UUID(),
        vaultID: UUID,
        requesterID: UUID,
        emergencyRequestID: UUID,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.vaultID = vaultID
        self.requesterID = requesterID
        self.emergencyRequestID = emergencyRequestID
        self.passCode = UUID().uuidString
        self.expiresAt = expiresAt ?? Date().addingTimeInterval(24 * 60 * 60) // 24 hours default
    }
    
    var isExpired: Bool {
        Date() > expiresAt || !isActive
    }
    
    var isValid: Bool {
        isActive && !isExpired && usedAt == nil
    }
    
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }
}

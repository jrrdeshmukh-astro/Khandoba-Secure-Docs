//
//  DocumentFidelity.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//

import Foundation
import SwiftData

/// Transfer event structure for fidelity tracking
struct TransferEvent: Codable {
    var timestamp: Date
    var fromVaultID: UUID?
    var toVaultID: UUID
    var userID: UUID
    var userName: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var deviceInfo: String?
    var ipAddress: String?
    var reason: String? // Optional reason for transfer
}

/// Edit event structure for fidelity tracking
struct EditEvent: Codable {
    var timestamp: Date
    var userID: UUID
    var userName: String?
    var changeDescription: String?
    var versionNumber: Int
    var locationLatitude: Double?
    var locationLongitude: Double?
    var deviceInfo: String?
    var ipAddress: String?
}

/// Threat indicator structure
struct ThreatIndicator: Codable {
    var type: String // "rapid_transfer", "geographic_anomaly", "device_change", "access_anomaly"
    var severity: String // "low", "medium", "high", "critical"
    var description: String
    var detectedAt: Date
    var details: [String: String]? // Additional context
}

@Model
final class DocumentFidelity {
    var id: UUID = UUID()
    
    // Document reference
    var document: Document?
    
    // Transfer tracking
    var transferCount: Int = 0
    var transferHistoryData: Data? // JSON encoded [TransferEvent]
    
    // Edit tracking
    var editCount: Int = 0
    var editHistoryData: Data? // JSON encoded [EditEvent]
    
    // Computed fidelity score (0-100, where 100 = pristine, 0 = highly suspicious)
    var fidelityScore: Int = 100
    
    // Threat indicators
    var threatIndicatorsData: Data? // JSON encoded [ThreatIndicator]
    
    // Access pattern tracking
    var uniqueDeviceCount: Int = 0
    var uniqueIPCount: Int = 0
    var uniqueLocationCount: Int = 0
    
    // Timestamps
    var lastComputedAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Computed properties for easy access
    var transferHistory: [TransferEvent] {
        get {
            guard let data = transferHistoryData,
                  let decoded = try? JSONDecoder().decode([TransferEvent].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            transferHistoryData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var editHistory: [EditEvent] {
        get {
            guard let data = editHistoryData,
                  let decoded = try? JSONDecoder().decode([EditEvent].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            editHistoryData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var threatIndicators: [ThreatIndicator] {
        get {
            guard let data = threatIndicatorsData,
                  let decoded = try? JSONDecoder().decode([ThreatIndicator].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            threatIndicatorsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(
        id: UUID = UUID(),
        document: Document? = nil,
        transferCount: Int = 0,
        editCount: Int = 0,
        fidelityScore: Int = 100
    ) {
        self.id = id
        self.document = document
        self.transferCount = transferCount
        self.editCount = editCount
        self.fidelityScore = fidelityScore
        self.transferHistory = []
        self.editHistory = []
        self.threatIndicators = []
    }
}

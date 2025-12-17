//
//  SupabaseDocumentFidelity.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//

import Foundation

struct SupabaseDocumentFidelity: Codable {
    var id: UUID
    var documentID: UUID
    var transferCount: Int
    var editCount: Int
    var transferHistory: [TransferEvent]
    var editHistory: [EditEvent]
    var fidelityScore: Int
    var threatIndicators: [ThreatIndicator]
    var uniqueDeviceCount: Int
    var uniqueIPCount: Int
    var uniqueLocationCount: Int
    var lastComputedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case documentID = "document_id"
        case transferCount = "transfer_count"
        case editCount = "edit_count"
        case transferHistory = "transfer_history"
        case editHistory = "edit_history"
        case fidelityScore = "fidelity_score"
        case threatIndicators = "threat_indicators"
        case uniqueDeviceCount = "unique_device_count"
        case uniqueIPCount = "unique_ip_count"
        case uniqueLocationCount = "unique_location_count"
        case lastComputedAt = "last_computed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

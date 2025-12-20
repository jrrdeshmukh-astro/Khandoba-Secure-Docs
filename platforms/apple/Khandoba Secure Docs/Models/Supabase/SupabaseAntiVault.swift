//
//  SupabaseAntiVault.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//

import Foundation

struct SupabaseAntiVault: Codable {
    var id: UUID
    var vaultID: UUID
    var monitoredVaultID: UUID
    var ownerID: UUID
    var status: String
    var autoUnlockPolicy: AutoUnlockPolicy
    var threatDetectionSettings: ThreatDetectionSettings
    var lastIntelReportID: UUID?
    var createdAt: Date
    var updatedAt: Date
    var lastUnlockedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case vaultID = "vault_id"
        case monitoredVaultID = "monitored_vault_id"
        case ownerID = "owner_id"
        case status
        case autoUnlockPolicy = "auto_unlock_policy"
        case threatDetectionSettings = "threat_detection_settings"
        case lastIntelReportID = "last_intel_report_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastUnlockedAt = "last_unlocked_at"
    }
}

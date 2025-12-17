//
//  AntiVault.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//

import Foundation
import SwiftData

/// Auto-unlock policy configuration
struct AutoUnlockPolicy: Codable {
    var unlockOnSessionNomination: Bool = true
    var unlockOnSubsetNomination: Bool = true
    var requireApproval: Bool = false
    var approvalUserIDs: [UUID] = []
}

/// Threat detection settings
struct ThreatDetectionSettings: Codable {
    var detectContentDiscrepancies: Bool = true
    var detectMetadataMismatches: Bool = true
    var detectAccessPatternAnomalies: Bool = true
    var detectGeographicInconsistencies: Bool = true
    var detectEditHistoryDiscrepancies: Bool = true
    var minThreatSeverity: String = "medium" // "low", "medium", "high", "critical"
}

@Model
final class AntiVault: Identifiable {
    var id: UUID = UUID()
    
    // The anti-vault itself (references a Vault with isAntiVault = true)
    var vault: Vault?
    
    // The vault being monitored (many-to-one: multiple anti-vaults can monitor one vault)
    var monitoredVault: Vault?
    
    // Owner (authorized department/user)
    var owner: User?
    
    // Status
    var status: String = "locked" // "locked", "active", "archived"
    
    // Auto-unlock policy
    var autoUnlockPolicyData: Data? // JSON encoded AutoUnlockPolicy
    
    // Threat detection settings
    var threatDetectionSettingsData: Data? // JSON encoded ThreatDetectionSettings
    
    // Last Intel Report reference
    var lastIntelReportID: UUID?
    
    // Timestamps
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var lastUnlockedAt: Date?
    
    // Computed properties
    var autoUnlockPolicy: AutoUnlockPolicy {
        get {
            guard let data = autoUnlockPolicyData else {
                return AutoUnlockPolicy()
            }
            return nonisolatedDecode(data: data) ?? AutoUnlockPolicy()
        }
        set {
            autoUnlockPolicyData = nonisolatedEncode(value: newValue)
        }
    }
    
    var threatDetectionSettings: ThreatDetectionSettings {
        get {
            guard let data = threatDetectionSettingsData else {
                return ThreatDetectionSettings()
            }
            return nonisolatedDecode(data: data) ?? ThreatDetectionSettings()
        }
        set {
            threatDetectionSettingsData = nonisolatedEncode(value: newValue)
        }
    }
    
    // Nonisolated helpers to avoid main actor isolation issues
    nonisolated private func nonisolatedDecode<T: Decodable>(data: Data) -> T? {
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    nonisolated private func nonisolatedEncode<T: Encodable>(value: T) -> Data? {
        return try? JSONEncoder().encode(value)
    }
    
    init(
        id: UUID = UUID(),
        vault: Vault? = nil,
        monitoredVault: Vault? = nil,
        owner: User? = nil,
        status: String = "locked"
    ) {
        self.id = id
        self.vault = vault
        self.monitoredVault = monitoredVault
        self.owner = owner
        self.status = status
        self.autoUnlockPolicy = AutoUnlockPolicy()
        self.threatDetectionSettings = ThreatDetectionSettings()
    }
}

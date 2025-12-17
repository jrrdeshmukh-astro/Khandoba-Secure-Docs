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
    // Using UUID instead of relationship to avoid circular dependency
    var vaultID: UUID?
    
    // The vault being monitored (many-to-one: multiple anti-vaults can monitor one vault)
    // Using UUID instead of relationship to avoid circular dependency
    var monitoredVaultID: UUID?
    
    // Owner (authorized department/user)
    // Using UUID instead of relationship to avoid circular dependency
    var ownerID: UUID?
    
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
            return decodePolicy(data: data) ?? AutoUnlockPolicy()
        }
        set {
            autoUnlockPolicyData = encodePolicy(value: newValue)
        }
    }
    
    var threatDetectionSettings: ThreatDetectionSettings {
        get {
            guard let data = threatDetectionSettingsData else {
                return ThreatDetectionSettings()
            }
            return decodeSettings(data: data) ?? ThreatDetectionSettings()
        }
        set {
            threatDetectionSettingsData = encodeSettings(value: newValue)
        }
    }
    
    // Nonisolated helpers to avoid main actor isolation issues
    // Manual encoding/decoding using JSONSerialization to avoid Codable isolation
    nonisolated private func decodePolicy(data: Data) -> AutoUnlockPolicy? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return AutoUnlockPolicy(
            unlockOnSessionNomination: json["unlockOnSessionNomination"] as? Bool ?? true,
            unlockOnSubsetNomination: json["unlockOnSubsetNomination"] as? Bool ?? true,
            requireApproval: json["requireApproval"] as? Bool ?? false,
            approvalUserIDs: (json["approvalUserIDs"] as? [String])?.compactMap { UUID(uuidString: $0) } ?? []
        )
    }
    
    nonisolated private func encodePolicy(value: AutoUnlockPolicy) -> Data? {
        let json: [String: Any] = [
            "unlockOnSessionNomination": value.unlockOnSessionNomination,
            "unlockOnSubsetNomination": value.unlockOnSubsetNomination,
            "requireApproval": value.requireApproval,
            "approvalUserIDs": value.approvalUserIDs.map { $0.uuidString }
        ]
        return try? JSONSerialization.data(withJSONObject: json)
    }
    
    nonisolated private func decodeSettings(data: Data) -> ThreatDetectionSettings? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return ThreatDetectionSettings(
            detectContentDiscrepancies: json["detectContentDiscrepancies"] as? Bool ?? true,
            detectMetadataMismatches: json["detectMetadataMismatches"] as? Bool ?? true,
            detectAccessPatternAnomalies: json["detectAccessPatternAnomalies"] as? Bool ?? true,
            detectGeographicInconsistencies: json["detectGeographicInconsistencies"] as? Bool ?? true,
            detectEditHistoryDiscrepancies: json["detectEditHistoryDiscrepancies"] as? Bool ?? true,
            minThreatSeverity: json["minThreatSeverity"] as? String ?? "medium"
        )
    }
    
    nonisolated private func encodeSettings(value: ThreatDetectionSettings) -> Data? {
        let json: [String: Any] = [
            "detectContentDiscrepancies": value.detectContentDiscrepancies,
            "detectMetadataMismatches": value.detectMetadataMismatches,
            "detectAccessPatternAnomalies": value.detectAccessPatternAnomalies,
            "detectGeographicInconsistencies": value.detectGeographicInconsistencies,
            "detectEditHistoryDiscrepancies": value.detectEditHistoryDiscrepancies,
            "minThreatSeverity": value.minThreatSeverity
        ]
        return try? JSONSerialization.data(withJSONObject: json)
    }
    
    init(
        id: UUID = UUID(),
        vaultID: UUID? = nil,
        monitoredVaultID: UUID? = nil,
        ownerID: UUID? = nil,
        status: String = "locked"
    ) {
        self.id = id
        self.vaultID = vaultID
        self.monitoredVaultID = monitoredVaultID
        self.ownerID = ownerID
        self.status = status
        self.autoUnlockPolicy = AutoUnlockPolicy()
        self.threatDetectionSettings = ThreatDetectionSettings()
    }
}

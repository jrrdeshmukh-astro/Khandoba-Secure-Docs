//
//  DataMergeService.swift
//  Khandoba Secure Docs
//
//  Data merge service for CloudKit/SwiftData sync
//  iOS-ONLY: Using CloudKit exclusively
//

import Foundation
import SwiftData
import Combine

@MainActor
final class DataMergeService: ObservableObject {
    private var modelContext: ModelContext?
    
    nonisolated init() {}
    
    // iOS-ONLY: Using SwiftData/CloudKit exclusively
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Vault Operations
    
    // iOS-ONLY: Using SwiftData/CloudKit exclusively - no merging needed
    
    // MARK: - Encoding/Decoding Helpers (for anti-vault data)
    
    private func encodeAutoUnlockPolicy(_ policy: AutoUnlockPolicy) -> Data? {
        let json: [String: Any] = [
            "unlockOnSessionNomination": policy.unlockOnSessionNomination,
            "unlockOnSubsetNomination": policy.unlockOnSubsetNomination,
            "requireApproval": policy.requireApproval,
            "approvalUserIDs": policy.approvalUserIDs.map { $0.uuidString }
        ]
        return try? JSONSerialization.data(withJSONObject: json)
    }
    
    private func encodeThreatDetectionSettings(_ settings: ThreatDetectionSettings) -> Data? {
        let json: [String: Any] = [
            "detectContentDiscrepancies": settings.detectContentDiscrepancies,
            "detectMetadataMismatches": settings.detectMetadataMismatches,
            "detectAccessPatternAnomalies": settings.detectAccessPatternAnomalies,
            "detectGeographicInconsistencies": settings.detectGeographicInconsistencies,
            "detectEditHistoryDiscrepancies": settings.detectEditHistoryDiscrepancies,
            "minThreatSeverity": settings.minThreatSeverity
        ]
        return try? JSONSerialization.data(withJSONObject: json)
    }
    
    // MARK: - Sync Operations
    
    /// Sync vault to CloudKit (SwiftData)
    func syncVault(_ vault: Vault) async throws {
        print("🔄 Syncing vault '\(vault.name)' to CloudKit...")
        
        // Sync to CloudKit (SwiftData)
        if let modelContext = modelContext {
            try modelContext.save()
            print("   ✅ Synced to CloudKit")
        }
    }
    
    // MARK: - Decoding Helpers
    
    private func decodeAutoUnlockPolicy(_ data: Data?) -> AutoUnlockPolicy {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return AutoUnlockPolicy()
        }
        return AutoUnlockPolicy(
            unlockOnSessionNomination: json["unlockOnSessionNomination"] as? Bool ?? true,
            unlockOnSubsetNomination: json["unlockOnSubsetNomination"] as? Bool ?? true,
            requireApproval: json["requireApproval"] as? Bool ?? false,
            approvalUserIDs: (json["approvalUserIDs"] as? [String])?.compactMap { UUID(uuidString: $0) } ?? []
        )
    }
    
    private func decodeThreatDetectionSettings(_ data: Data?) -> ThreatDetectionSettings {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ThreatDetectionSettings()
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
}

// MARK: - Errors

enum DataMergeError: LocalizedError {
    case serviceNotConfigured
    case mergeFailed
    
    var errorDescription: String? {
        switch self {
        case .serviceNotConfigured:
            return "Data merge service is not configured"
        case .mergeFailed:
            return "Failed to merge data from multiple sources"
        }
    }
}

//
//  DataMergeService.swift
//  Khandoba Secure Docs
//
//  Intelligent data merging service for CloudKit and Supabase sync
//  Prevents discrepancies by merging data from both sources intelligently
//

import Foundation
import SwiftData
import Combine

@MainActor
final class DataMergeService: ObservableObject {
    private var supabaseService: SupabaseService?
    private var modelContext: ModelContext?
    
    nonisolated init() {}
    
    func configure(supabaseService: SupabaseService?, modelContext: ModelContext?) {
        self.supabaseService = supabaseService
        self.modelContext = modelContext
    }
    
    // MARK: - Vault Merging
    
    /// Merge vault data from CloudKit (SwiftData) and Supabase intelligently
    /// Priority: Most recent update wins, but preserves critical data from both sources
    func mergeVaults(
        cloudKitVaults: [Vault],
        supabaseVaults: [SupabaseVault]
    ) async throws -> [Vault] {
        print("🔄 Merging vaults from CloudKit and Supabase...")
        
        var mergedVaults: [UUID: Vault] = [:]
        
        // First, add all CloudKit vaults
        for vault in cloudKitVaults {
            mergedVaults[vault.id] = vault
        }
        
        // Then merge Supabase vaults
        for supabaseVault in supabaseVaults {
            if let existingVault = mergedVaults[supabaseVault.id] {
                // Merge existing vault - use most recent data
                mergedVaults[supabaseVault.id] = try await mergeVaultData(
                    existing: existingVault,
                    supabase: supabaseVault
                )
            } else {
                // New vault from Supabase - create it
                let newVault = Vault(
                    name: supabaseVault.name,
                    vaultDescription: supabaseVault.vaultDescription,
                    keyType: supabaseVault.keyType
                )
                newVault.id = supabaseVault.id
                newVault.createdAt = supabaseVault.createdAt
                newVault.lastAccessedAt = supabaseVault.lastAccessedAt
                newVault.status = supabaseVault.status
                newVault.vaultType = supabaseVault.vaultType
                newVault.isSystemVault = supabaseVault.isSystemVault
                newVault.isAntiVault = supabaseVault.isAntiVault
                newVault.monitoredVaultID = supabaseVault.monitoredVaultID
                
                // Merge anti-vault properties if available
                if let antiVaultID = supabaseVault.antiVaultID {
                    newVault.antiVaultID = antiVaultID
                    // Load anti-vault data from Supabase if needed
                    if let antiVaultData = try? await loadAntiVaultData(antiVaultID: antiVaultID) {
                        newVault.antiVaultStatus = antiVaultData.status
                        newVault.antiVaultAutoUnlockPolicyData = antiVaultData.autoUnlockPolicyData
                        newVault.antiVaultThreatDetectionSettingsData = antiVaultData.threatDetectionSettingsData
                        newVault.antiVaultLastIntelReportID = antiVaultData.lastIntelReportID
                        newVault.antiVaultLastUnlockedAt = antiVaultData.lastUnlockedAt
                        newVault.antiVaultCreatedAt = antiVaultData.createdAt
                    }
                }
                
                mergedVaults[newVault.id] = newVault
            }
        }
        
        print("✅ Merged \(mergedVaults.count) vault(s)")
        return Array(mergedVaults.values)
    }
    
    /// Merge data from two vault sources intelligently
    private func mergeVaultData(existing: Vault, supabase: SupabaseVault) async throws -> Vault {
        // Use most recent update timestamp
        let existingUpdated = existing.lastAccessedAt ?? existing.createdAt
        let supabaseUpdated = supabase.lastAccessedAt ?? supabase.createdAt
        
        if supabaseUpdated > existingUpdated {
            // Supabase has more recent data - update from Supabase
            existing.name = supabase.name
            existing.vaultDescription = supabase.vaultDescription
            existing.status = supabase.status
            existing.lastAccessedAt = supabase.lastAccessedAt
            existing.vaultType = supabase.vaultType
            existing.isSystemVault = supabase.isSystemVault
            existing.isAntiVault = supabase.isAntiVault
            existing.monitoredVaultID = supabase.monitoredVaultID
            
            // Merge anti-vault properties
            if let antiVaultID = supabase.antiVaultID {
                existing.antiVaultID = antiVaultID
                if let antiVaultData = try? await loadAntiVaultData(antiVaultID: antiVaultID) {
                    existing.antiVaultStatus = antiVaultData.status
                    existing.antiVaultAutoUnlockPolicyData = antiVaultData.autoUnlockPolicyData
                    existing.antiVaultThreatDetectionSettingsData = antiVaultData.threatDetectionSettingsData
                    existing.antiVaultLastIntelReportID = antiVaultData.lastIntelReportID
                    existing.antiVaultLastUnlockedAt = antiVaultData.lastUnlockedAt
                    existing.antiVaultCreatedAt = antiVaultData.createdAt
                }
            }
        } else {
            // CloudKit has more recent data - preserve CloudKit but merge critical Supabase fields
            // Only update if Supabase has data that CloudKit doesn't
            if existing.antiVaultID == nil, let antiVaultID = supabase.antiVaultID {
                existing.antiVaultID = antiVaultID
                if let antiVaultData = try? await loadAntiVaultData(antiVaultID: antiVaultID) {
                    existing.antiVaultStatus = antiVaultData.status
                    existing.antiVaultAutoUnlockPolicyData = antiVaultData.autoUnlockPolicyData
                    existing.antiVaultThreatDetectionSettingsData = antiVaultData.threatDetectionSettingsData
                    existing.antiVaultLastIntelReportID = antiVaultData.lastIntelReportID
                    existing.antiVaultLastUnlockedAt = antiVaultData.lastUnlockedAt
                    existing.antiVaultCreatedAt = antiVaultData.createdAt
                }
            }
        }
        
        return existing
    }
    
    // MARK: - Anti-Vault Data Loading
    
    private func loadAntiVaultData(antiVaultID: UUID) async throws -> (status: String, autoUnlockPolicyData: Data?, threatDetectionSettingsData: Data?, lastIntelReportID: UUID?, lastUnlockedAt: Date?, createdAt: Date?) {
        guard let supabaseService = supabaseService else {
            throw DataMergeError.serviceNotConfigured
        }
        
        // Try to load from Supabase
        if let supabaseAntiVault: SupabaseAntiVault = try? await supabaseService.fetch("anti_vaults", id: antiVaultID) {
            return (
                status: supabaseAntiVault.status,
                autoUnlockPolicyData: encodeAutoUnlockPolicy(supabaseAntiVault.autoUnlockPolicy),
                threatDetectionSettingsData: encodeThreatDetectionSettings(supabaseAntiVault.threatDetectionSettings),
                lastIntelReportID: supabaseAntiVault.lastIntelReportID,
                lastUnlockedAt: supabaseAntiVault.lastUnlockedAt,
                createdAt: supabaseAntiVault.createdAt
            )
        }
        
        // Fallback: try CloudKit/SwiftData
        if let modelContext = modelContext {
            let descriptor = FetchDescriptor<AntiVault>(
                predicate: #Predicate { $0.id == antiVaultID }
            )
            if let antiVault = try? modelContext.fetch(descriptor).first {
                return (
                    status: antiVault.status,
                    autoUnlockPolicyData: antiVault.autoUnlockPolicyData,
                    threatDetectionSettingsData: antiVault.threatDetectionSettingsData,
                    lastIntelReportID: antiVault.lastIntelReportID,
                    lastUnlockedAt: antiVault.lastUnlockedAt,
                    createdAt: antiVault.createdAt
                )
            }
        }
        
        // Default values if not found
        return (
            status: "locked",
            autoUnlockPolicyData: nil,
            threatDetectionSettingsData: nil,
            lastIntelReportID: nil,
            lastUnlockedAt: nil,
            createdAt: nil
        )
    }
    
    // MARK: - Encoding Helpers
    
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
    
    // MARK: - Sync to Both Sources
    
    /// Sync vault to both CloudKit and Supabase to keep them in sync
    func syncVaultToBothSources(_ vault: Vault) async throws {
        print("🔄 Syncing vault '\(vault.name)' to both CloudKit and Supabase...")
        
        // Sync to CloudKit (SwiftData)
        if let modelContext = modelContext {
            try modelContext.save()
            print("   ✅ Synced to CloudKit")
        }
        
        // Sync to Supabase
        if let supabaseService = supabaseService {
            let supabaseVault = SupabaseVault(from: vault)
            _ = try await supabaseService.update("vaults", id: vault.id, values: supabaseVault)
            print("   ✅ Synced to Supabase")
            
            // Also sync anti-vault data if present
            if let antiVaultID = vault.antiVaultID,
               let ownerID = vault.owner?.id {
                let supabaseAntiVault = SupabaseAntiVault(
                    id: antiVaultID,
                    vaultID: antiVaultID,
                    monitoredVaultID: vault.id,
                    ownerID: ownerID,
                    status: vault.antiVaultStatus,
                    autoUnlockPolicy: decodeAutoUnlockPolicy(vault.antiVaultAutoUnlockPolicyData),
                    threatDetectionSettings: decodeThreatDetectionSettings(vault.antiVaultThreatDetectionSettingsData),
                    lastIntelReportID: vault.antiVaultLastIntelReportID,
                    createdAt: vault.antiVaultCreatedAt ?? vault.createdAt,
                    updatedAt: Date(),
                    lastUnlockedAt: vault.antiVaultLastUnlockedAt
                )
                _ = try await supabaseService.update("anti_vaults", id: antiVaultID, values: supabaseAntiVault)
                print("   ✅ Synced anti-vault data to Supabase")
            }
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

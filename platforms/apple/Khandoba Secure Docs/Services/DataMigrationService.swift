//
//  DataMigrationService.swift
//  Khandoba Secure Docs
//
//  Handles migration from version 1.0.0 (build 28) to 1.0.1 (build 30)
//  Migrates existing CloudKit data to Supabase and syncs both sources
//

import Foundation
import SwiftData
import Combine

@MainActor
final class DataMigrationService: ObservableObject {
    @Published var migrationStatus: MigrationStatus = .notStarted
    @Published var migrationProgress: Double = 0.0
    @Published var migrationMessage: String = ""
    
    private var modelContext: ModelContext?
    private var dataMergeService: DataMergeService?
    
    enum MigrationStatus {
        case notStarted
        case inProgress
        case completed
        case failed(Error)
    }
    
    nonisolated init() {}
    
    // iOS-ONLY: Using SwiftData/CloudKit exclusively
    func configure(modelContext: ModelContext?, dataMergeService: DataMergeService?) {
        self.modelContext = modelContext
        self.dataMergeService = dataMergeService
    }
    
    /// Get migration status for UI display
    var isMigrating: Bool {
        if case .inProgress = migrationStatus {
            return true
        }
        return false
    }
    
    /// Check if migration is needed (user coming from version 1.0.0)
    func needsMigration() -> Bool {
        // Check if user has data in CloudKit but not in Supabase
        // This indicates they're upgrading from 1.0.0
        let migrationKey = "data_migration_completed_1.0.1"
        return !UserDefaults.standard.bool(forKey: migrationKey)
    }
    
    /// Perform migration from CloudKit to Supabase
    /// NOTE: This function is deprecated - iOS app uses CloudKit exclusively
    /// Migration to Supabase is not supported in iOS-only app
    func migrateFromCloudKitToSupabase() async throws {
        guard modelContext != nil else {
            throw MigrationError.serviceNotConfigured
        }
        
        // iOS-ONLY: Migration to Supabase is not supported
        // All data is stored in SwiftData/CloudKit
        await MainActor.run {
            migrationStatus = .completed
            migrationProgress = 1.0
            migrationMessage = "No migration needed - using CloudKit exclusively"
        }
        
        // Mark migration as complete (no-op for iOS-only app)
        UserDefaults.standard.set(true, forKey: "data_migration_completed_1.0.1")
        UserDefaults.standard.set(AppConfig.appVersion, forKey: "last_migrated_version")
        UserDefaults.standard.set(AppConfig.appBuildNumber, forKey: "last_migrated_build")
        
        print("✅ Migration check completed - iOS app uses CloudKit exclusively")
    }
    
    // MARK: - Helper Methods
    
    private func updateProgress(_ progress: Double, message: String) async {
        await MainActor.run {
            migrationProgress = progress
            migrationMessage = message
        }
    }
    
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
}

enum MigrationError: LocalizedError {
    case serviceNotConfigured
    case migrationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .serviceNotConfigured:
            return "Migration service is not configured"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        }
    }
}

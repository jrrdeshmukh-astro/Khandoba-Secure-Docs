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
    private var supabaseService: SupabaseService?
    private var dataMergeService: DataMergeService?
    
    enum MigrationStatus {
        case notStarted
        case inProgress
        case completed
        case failed(Error)
    }
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext?, supabaseService: SupabaseService?, dataMergeService: DataMergeService?) {
        self.modelContext = modelContext
        self.supabaseService = supabaseService
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
    func migrateFromCloudKitToSupabase() async throws {
        guard let modelContext = modelContext,
              let supabaseService = supabaseService else {
            throw MigrationError.serviceNotConfigured
        }
        
        await MainActor.run {
            migrationStatus = .inProgress
            migrationProgress = 0.0
            migrationMessage = "Starting migration..."
        }
        
        print("🔄 Starting data migration from CloudKit to Supabase...")
        
        // Step 1: Migrate Users
        await updateProgress(0.1, message: "Migrating users...")
        try await migrateUsers(modelContext: modelContext, supabaseService: supabaseService)
        
        // Step 2: Migrate Vaults
        await updateProgress(0.3, message: "Migrating vaults...")
        try await migrateVaults(modelContext: modelContext, supabaseService: supabaseService)
        
        // Step 3: Migrate Documents
        await updateProgress(0.5, message: "Migrating documents...")
        try await migrateDocuments(modelContext: modelContext, supabaseService: supabaseService)
        
        // Step 4: Migrate Nominees
        await updateProgress(0.7, message: "Migrating nominees...")
        try await migrateNominees(modelContext: modelContext, supabaseService: supabaseService)
        
        // Step 5: Migrate Access Logs
        await updateProgress(0.85, message: "Migrating access logs...")
        try await migrateAccessLogs(modelContext: modelContext, supabaseService: supabaseService)
        
        // Step 6: Create anti-vaults for existing vaults (1:1 relationship)
        await updateProgress(0.9, message: "Creating anti-vaults...")
        try await createAntiVaultsForExistingVaults(modelContext: modelContext, supabaseService: supabaseService)
        
        // Step 7: Sync both sources
        await updateProgress(0.95, message: "Syncing data sources...")
        try await syncBothSources(modelContext: modelContext, supabaseService: supabaseService)
        
        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: "data_migration_completed_1.0.1")
        UserDefaults.standard.set(AppConfig.appVersion, forKey: "last_migrated_version")
        UserDefaults.standard.set(AppConfig.appBuildNumber, forKey: "last_migrated_build")
        
        await updateProgress(1.0, message: "Migration completed!")
        await MainActor.run {
            migrationStatus = .completed
        }
        
        print("✅ Data migration completed successfully")
    }
    
    // MARK: - Migration Steps
    
    private func migrateUsers(modelContext: ModelContext, supabaseService: SupabaseService) async throws {
        let descriptor = FetchDescriptor<User>()
        let users = try modelContext.fetch(descriptor)
        
        for user in users {
            // Check if user already exists in Supabase
            if let _: SupabaseUser = try? await supabaseService.fetch("users", id: user.id) {
                continue // Already migrated
            }
            
            // Create user in Supabase
            let supabaseUser = SupabaseUser(from: user)
            _ = try await supabaseService.insert("users", values: supabaseUser)
            print("   ✅ Migrated user: \(user.fullName)")
        }
    }
    
    private func migrateVaults(modelContext: ModelContext, supabaseService: SupabaseService) async throws {
        let descriptor = FetchDescriptor<Vault>()
        let vaults = try modelContext.fetch(descriptor)
        
        for vault in vaults {
            // Skip system vaults and anti-vaults
            if vault.isSystemVault || vault.isAntiVault {
                continue
            }
            
            // Check if vault already exists in Supabase
            if let _: SupabaseVault = try? await supabaseService.fetch("vaults", id: vault.id) {
                // Update existing vault with anti-vault properties if missing
                if vault.antiVaultID == nil {
                    try await createAntiVaultForVault(vault: vault, supabaseService: supabaseService)
                }
                continue
            }
            
            // Create vault in Supabase
            guard let ownerID = vault.owner?.id else {
                print("   ⚠️ Skipping vault '\(vault.name)' - no owner")
                continue
            }
            
            // Create SupabaseVault with ownerID in initializer
            let supabaseVault = SupabaseVault(
                id: vault.id,
                name: vault.name,
                vaultDescription: vault.vaultDescription,
                ownerID: ownerID,
                createdAt: vault.createdAt,
                lastAccessedAt: vault.lastAccessedAt,
                status: vault.status,
                keyType: vault.keyType,
                vaultType: vault.vaultType,
                isSystemVault: vault.isSystemVault,
                encryptionKeyData: vault.encryptionKeyData,
                isEncrypted: vault.isEncrypted,
                isZeroKnowledge: vault.isZeroKnowledge,
                relationshipOfficerID: vault.relationshipOfficerID,
                isAntiVault: vault.isAntiVault,
                monitoredVaultID: vault.monitoredVaultID,
                antiVaultID: vault.antiVaultID,
                updatedAt: Date()
            )
            let created: SupabaseVault = try await supabaseService.insert("vaults", values: supabaseVault)
            
            // Create anti-vault for this vault (1:1 relationship)
            try await createAntiVaultForVault(vault: vault, supabaseService: supabaseService, createdVaultID: created.id)
            
            print("   ✅ Migrated vault: \(vault.name)")
        }
    }
    
    private func migrateDocuments(modelContext: ModelContext, supabaseService: SupabaseService) async throws {
        let descriptor = FetchDescriptor<Document>()
        let documents = try modelContext.fetch(descriptor)
        
        for document in documents {
            // Check if document already exists in Supabase
            if let _: SupabaseDocument = try? await supabaseService.fetch("documents", id: document.id) {
                continue // Already migrated
            }
            
            // Create document in Supabase
            guard document.vault?.id != nil else {
                print("   ⚠️ Skipping document '\(document.name)' - no vault")
                continue
            }
            
            // Create SupabaseDocument from Document model
            let supabaseDocument = SupabaseDocument(from: document)
            _ = try await supabaseService.insert("documents", values: supabaseDocument)
            print("   ✅ Migrated document: \(document.name)")
        }
    }
    
    private func migrateNominees(modelContext: ModelContext, supabaseService: SupabaseService) async throws {
        let descriptor = FetchDescriptor<Nominee>()
        let nominees = try modelContext.fetch(descriptor)
        
        for nominee in nominees {
            // Check if nominee already exists in Supabase
            if let _: SupabaseNominee = try? await supabaseService.fetch("nominees", id: nominee.id) {
                continue // Already migrated
            }
            
            // Create nominee in Supabase
            guard let vaultID = nominee.vault?.id else {
                print("   ⚠️ Skipping nominee '\(nominee.name)' - no vault")
                continue
            }
            
            // Find user by email or phone for nominee
            var userID: UUID?
            if let email = nominee.email {
                // Try to find user by email
                do {
                    let users: [SupabaseUser] = try await supabaseService.fetchAll("users", filters: ["email": email])
                    userID = users.first?.id
                } catch {
                    print("   ⚠️ Failed to find user by email: \(error.localizedDescription)")
                }
            }
            
            // If not found by email, try phone (if we have phone lookup)
            if userID == nil, nominee.phoneNumber != nil {
                // Note: Phone lookup would need to be implemented in Supabase
                // For now, we'll create a placeholder user or skip
                print("   ⚠️ Nominee '\(nominee.name)' has phone but no matching user found")
            }
            
            // If still no userID, we can't migrate this nominee properly
            guard let finalUserID = userID else {
                print("   ⚠️ Skipping nominee '\(nominee.name)' - no matching user found")
                continue
            }
            
            // Create SupabaseNominee from Nominee model
            // Note: Nominee model doesn't have declinedAt/revokedAt, so we infer from status
            let supabaseNominee = SupabaseNominee(
                id: nominee.id,
                vaultID: vaultID,
                userID: finalUserID,
                invitedByUserID: nominee.invitedByUserID,
                status: nominee.statusRaw,
                invitedAt: nominee.invitedAt,
                acceptedAt: nominee.acceptedAt,
                declinedAt: nominee.statusRaw == "declined" ? nominee.lastActiveAt : nil,
                revokedAt: nominee.statusRaw == "revoked" ? nominee.lastActiveAt : nil,
                accessLevel: "read", // Default access level
                selectedDocumentIDs: nominee.selectedDocumentIDs,
                sessionExpiresAt: nominee.sessionExpiresAt,
                isSubsetAccess: nominee.isSubsetAccess,
                createdAt: nominee.invitedAt ?? Date(),
                updatedAt: Date()
            )
            _ = try await supabaseService.insert("nominees", values: supabaseNominee)
            print("   ✅ Migrated nominee: \(nominee.name)")
        }
    }
    
    private func migrateAccessLogs(modelContext: ModelContext, supabaseService: SupabaseService) async throws {
        let descriptor = FetchDescriptor<VaultAccessLog>()
        let logs = try modelContext.fetch(descriptor)
        
        for log in logs {
            // Check if log already exists in Supabase
            if let _: SupabaseVaultAccessLog = try? await supabaseService.fetch("vault_access_logs", id: log.id) {
                continue // Already migrated
            }
            
            // Create access log in Supabase
            guard let vaultID = log.vault?.id else {
                continue
            }
            
            let supabaseLog = SupabaseVaultAccessLog(
                id: log.id,
                vaultID: vaultID,
                timestamp: log.timestamp,
                accessType: log.accessType,
                userID: log.userID,
                userName: log.userName,
                deviceInfo: log.deviceInfo,
                locationLatitude: log.locationLatitude,
                locationLongitude: log.locationLongitude,
                ipAddress: log.ipAddress,
                documentID: log.documentID,
                documentName: log.documentName
            )
            _ = try await supabaseService.insert("vault_access_logs", values: supabaseLog)
        }
        
        print("   ✅ Migrated \(logs.count) access log(s)")
    }
    
    private func createAntiVaultsForExistingVaults(modelContext: ModelContext, supabaseService: SupabaseService) async throws {
        let descriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { !$0.isSystemVault && !$0.isAntiVault }
        )
        let vaults = try modelContext.fetch(descriptor)
        
        for vault in vaults {
            // Only create if anti-vault doesn't exist
            if vault.antiVaultID == nil {
                try await createAntiVaultForVault(vault: vault, supabaseService: supabaseService)
            }
        }
        
        print("   ✅ Created anti-vaults for \(vaults.count) vault(s)")
    }
    
    private func createAntiVaultForVault(vault: Vault, supabaseService: SupabaseService, createdVaultID: UUID? = nil) async throws {
        let vaultID = createdVaultID ?? vault.id
        guard let ownerID = vault.owner?.id else {
            return
        }
        
        // Create anti-vault
        let antiVaultID = UUID()
        let antiVault = SupabaseAntiVault(
            id: antiVaultID,
            vaultID: antiVaultID,
            monitoredVaultID: vaultID,
            ownerID: ownerID,
            status: "locked",
            autoUnlockPolicy: AutoUnlockPolicy(),
            threatDetectionSettings: ThreatDetectionSettings(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Insert anti-vault in Supabase
        _ = try await supabaseService.insert("anti_vaults", values: antiVault)
        
        // Update vault with anti-vault ID
        var supabaseVault = SupabaseVault(from: vault)
        supabaseVault.antiVaultID = antiVaultID
        _ = try await supabaseService.update("vaults", id: vaultID, values: supabaseVault)
        
        // Update local vault model
        vault.antiVaultID = antiVaultID
        vault.antiVaultStatus = "locked"
        vault.antiVaultCreatedAt = Date()
        vault.antiVaultAutoUnlockPolicyData = encodeAutoUnlockPolicy(AutoUnlockPolicy())
        vault.antiVaultThreatDetectionSettingsData = encodeThreatDetectionSettings(ThreatDetectionSettings())
        
        // Save to SwiftData
        guard let modelContext = modelContext else {
            throw MigrationError.serviceNotConfigured
        }
        try modelContext.save()
    }
    
    private func syncBothSources(modelContext: ModelContext, supabaseService: SupabaseService) async throws {
        // Use DataMergeService to sync both sources
        guard let dataMergeService = dataMergeService else {
            return
        }
        
        // Load vaults from both sources
        let cloudKitVaults = try modelContext.fetch(FetchDescriptor<Vault>())
        let supabaseVaults: [SupabaseVault] = try await supabaseService.fetchAll("vaults", filters: nil)
        
        // Merge intelligently
        let mergedVaults = try await dataMergeService.mergeVaults(
            cloudKitVaults: cloudKitVaults,
            supabaseVaults: supabaseVaults
        )
        
        // Sync each merged vault back to both sources
        for vault in mergedVaults {
            try await dataMergeService.syncVaultToBothSources(vault)
        }
        
        print("   ✅ Synced \(mergedVaults.count) vault(s) to both sources")
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

//
//  AntiVaultService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//

import Foundation
import SwiftData
import Combine
import SwiftUI

@MainActor
final class AntiVaultService: ObservableObject {
    @Published var antiVaults: [AntiVault] = []
    @Published var isLoading = false
    @Published var detectedThreats: [ThreatDetection] = []
    
    private var modelContext: ModelContext?
    private var supabaseService: SupabaseService?
    private var currentUserID: UUID?
    private var intelReportService: IntelReportService?
    private var vaultService: VaultService?
    private var documentService: DocumentService?
    
    nonisolated init() {}
    
    // SwiftData/CloudKit mode
    func configure(modelContext: ModelContext, userID: UUID, intelReportService: IntelReportService? = nil, vaultService: VaultService? = nil, documentService: DocumentService? = nil) {
        self.modelContext = modelContext
        self.supabaseService = nil
        self.currentUserID = userID
        self.intelReportService = intelReportService
        self.vaultService = vaultService
        self.documentService = documentService
    }
    
    // Supabase mode
    func configure(supabaseService: SupabaseService, userID: UUID, intelReportService: IntelReportService? = nil, vaultService: VaultService? = nil, documentService: DocumentService? = nil) {
        self.supabaseService = supabaseService
        self.modelContext = nil
        self.currentUserID = userID
        self.intelReportService = intelReportService
        self.vaultService = vaultService
        self.documentService = documentService
    }
    
    // MARK: - Anti-Vault Management
    
    /// Create a new anti-vault for monitoring a vault
    func createAntiVault(monitoredVault: Vault, ownerID: UUID, settings: ThreatDetectionSettings? = nil) async throws -> AntiVault {
        print("🛡️ Creating anti-vault for monitored vault: \(monitoredVault.name)")
        
        // Create the vault first (with isAntiVault = true)
        let antiVaultVault = Vault(
            name: "Anti-Vault: \(monitoredVault.name)",
            vaultDescription: "Fraud detection vault for \(monitoredVault.name)",
            status: "locked"
        )
        antiVaultVault.isAntiVault = true
        antiVaultVault.monitoredVaultID = monitoredVault.id
        
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            // Create vault in Supabase
            let supabaseVault = SupabaseVault(from: antiVaultVault)
            let createdVault: SupabaseVault = try await supabaseService.insert("vaults", values: supabaseVault)
            antiVaultVault.id = createdVault.id
        } else {
            // Create vault in SwiftData
            guard let modelContext = modelContext else {
                throw AntiVaultError.contextNotAvailable
            }
            modelContext.insert(antiVaultVault)
            try modelContext.save()
        }
        
        // Create anti-vault record
        let antiVault = AntiVault(
            vaultID: antiVaultVault.id,
            monitoredVaultID: monitoredVault.id,
            ownerID: ownerID,
            status: "locked"
        )
        
        if let settings = settings {
            antiVault.threatDetectionSettings = settings
        }
        
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await createAntiVaultInSupabase(antiVault: antiVault, ownerID: ownerID, supabaseService: supabaseService)
        } else {
            guard let modelContext = modelContext else {
                throw AntiVaultError.contextNotAvailable
            }
            
            modelContext.insert(antiVault)
            try modelContext.save()
        }
        
        print("✅ Anti-vault created: \(antiVault.id)")
        return antiVault
    }
    
    private func createAntiVaultInSupabase(antiVault: AntiVault, ownerID: UUID, supabaseService: SupabaseService) async throws {
        guard let vaultID = antiVault.vaultID,
              let monitoredVaultID = antiVault.monitoredVaultID else {
            throw AntiVaultError.invalidData
        }
        
        let supabaseAntiVault = SupabaseAntiVault(
            id: antiVault.id,
            vaultID: vaultID,
            monitoredVaultID: monitoredVaultID,
            ownerID: ownerID,
            status: antiVault.status,
            autoUnlockPolicy: antiVault.autoUnlockPolicy,
            threatDetectionSettings: antiVault.threatDetectionSettings,
            lastIntelReportID: antiVault.lastIntelReportID,
            createdAt: antiVault.createdAt,
            updatedAt: Date(),
            lastUnlockedAt: antiVault.lastUnlockedAt
        )
        
        let _: SupabaseAntiVault = try await supabaseService.insert("anti_vaults", values: supabaseAntiVault)
    }
    
    // MARK: - Session Nomination Monitoring
    
    /// Monitor session nomination and auto-unlock anti-vault if needed
    func monitorSessionNomination(vaultID: UUID, nomineeID: UUID, selectedDocumentIDs: [UUID]? = nil) async throws {
        print("🔍 Monitoring session nomination for vault: \(vaultID)")
        
        // Find anti-vaults monitoring this vault
        let monitoringAntiVaults: [AntiVault]
        
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            let supabaseAntiVaults: [SupabaseAntiVault] = try await supabaseService.fetchAll(
                "anti_vaults",
                filters: ["monitored_vault_id": vaultID.uuidString]
            )
            
            monitoringAntiVaults = try await convertFromSupabaseAntiVaults(supabaseAntiVaults, supabaseService: supabaseService)
        } else {
            guard let modelContext = modelContext else {
                throw AntiVaultError.contextNotAvailable
            }
            
            let descriptor = FetchDescriptor<AntiVault>(
                predicate: #Predicate { $0.monitoredVaultID == vaultID }
            )
            monitoringAntiVaults = try modelContext.fetch(descriptor)
        }
        
        // Check auto-unlock policy for each anti-vault
        for antiVault in monitoringAntiVaults {
            if shouldAutoUnlock(antiVault: antiVault, selectedDocumentIDs: selectedDocumentIDs) {
                try await unlockAntiVault(antiVault: antiVault, vaultID: vaultID, selectedDocumentIDs: selectedDocumentIDs)
            }
        }
    }
    
    private func shouldAutoUnlock(antiVault: AntiVault, selectedDocumentIDs: [UUID]?) -> Bool {
        let policy = antiVault.autoUnlockPolicy
        
        // Check if auto-unlock is enabled
        if !policy.unlockOnSessionNomination {
            return false
        }
        
        // If subset nomination, check if subset unlock is enabled
        if selectedDocumentIDs != nil && !policy.unlockOnSubsetNomination {
            return false
        }
        
        // Check if approval is required
        if policy.requireApproval && !policy.approvalUserIDs.isEmpty {
            // In a real implementation, check if current user is in approval list
            // For now, allow if no approval required
            return false
        }
        
        return true
    }
    
    /// Unlock anti-vault and generate Intel Report
    func unlockAntiVault(antiVault: AntiVault, vaultID: UUID, selectedDocumentIDs: [UUID]? = nil) async throws {
        print("🔓 Unlocking anti-vault: \(antiVault.id)")
        
        // Update status
        antiVault.status = "active"
        antiVault.lastUnlockedAt = Date()
        
        // Update in database
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            let supabaseAntiVault = try await convertToSupabaseAntiVault(antiVault)
            _ = try await supabaseService.update("anti_vaults", id: antiVault.id, values: supabaseAntiVault)
        } else {
            guard let modelContext = modelContext else {
                throw AntiVaultError.contextNotAvailable
            }
            try modelContext.save()
        }
        
        // Unlock the vault itself
        if let vaultID = antiVault.vaultID, let vaultService = vaultService {
            let vault = try await getVault(id: vaultID)
            try await vaultService.openVault(vault)
        }
        
        // Generate cross-reference Intel Report
        try await generateCrossReferenceIntelReport(antiVault: antiVault, sharedVaultID: vaultID, selectedDocumentIDs: selectedDocumentIDs)
    }
    
    // MARK: - Intel Report Cross-Referencing
    
    /// Generate cross-reference Intel Report comparing shared documents with anti-vault documents
    func generateCrossReferenceIntelReport(antiVault: AntiVault, sharedVaultID: UUID, selectedDocumentIDs: [UUID]? = nil) async throws {
        print("📊 Generating cross-reference Intel Report...")
        
        guard let intelReportService = intelReportService,
              let vaultService = vaultService else {
            throw AntiVaultError.serviceNotAvailable
        }
        
        // Load shared vault documents
        let sharedVault = try await getVault(id: sharedVaultID)
        try await vaultService.loadVaults()
        
        guard let documentService = documentService else {
            throw AntiVaultError.serviceNotAvailable
        }
        
        try await documentService.loadDocuments(for: sharedVault)
        
        var sharedDocuments = documentService.documents
        
        // Filter to selected documents if subset nomination
        if let selectedIDs = selectedDocumentIDs {
            sharedDocuments = sharedDocuments.filter { selectedIDs.contains($0.id) }
        }
        
        // Load anti-vault documents
        guard let antiVaultVaultID = antiVault.vaultID else {
            throw AntiVaultError.invalidData
        }
        
        let antiVaultVault = try await getVault(id: antiVaultVaultID)
        try await documentService.loadDocuments(for: antiVaultVault)
        let antiVaultDocuments = documentService.documents
        
        // Generate cross-reference report
        let intelReport = try await intelReportService.generateCrossReferenceReport(
            sharedDocuments: sharedDocuments,
            antiVaultDocuments: antiVaultDocuments,
            settings: antiVault.threatDetectionSettings
        )
        
        // Detect threats from report
        let threats = try await detectThreatsFromIntelReport(intelReport: intelReport, settings: antiVault.threatDetectionSettings)
        
        // Store threats
        await MainActor.run {
            self.detectedThreats.append(contentsOf: threats)
        }
        
        // Update anti-vault with report ID
        antiVault.lastIntelReportID = intelReport.id
        
        // Alert if critical threats found
        if threats.contains(where: { $0.severity == "critical" || $0.severity == "high" }) {
            try await alertAuthorizedDepartment(threats: threats, antiVault: antiVault)
        }
        
        print("✅ Cross-reference Intel Report generated with \(threats.count) threat(s) detected")
    }
    
    /// Detect threats from Intel Report analysis
    func detectThreatsFromIntelReport(intelReport: CrossReferenceIntelReport, settings: ThreatDetectionSettings) async throws -> [ThreatDetection] {
        var threats: [ThreatDetection] = []
        
        // Content discrepancies
        if settings.detectContentDiscrepancies {
            for discrepancy in intelReport.contentDiscrepancies {
                let severity = determineSeverity(discrepancy: discrepancy)
                if severityMeetsThreshold(severity: severity, minSeverity: settings.minThreatSeverity) {
                    threats.append(ThreatDetection(
                        type: "content_discrepancy",
                        severity: severity,
                        description: discrepancy.description,
                        documentID: discrepancy.documentID,
                        details: discrepancy.details,
                        detectedAt: Date()
                    ))
                }
            }
        }
        
        // Metadata mismatches
        if settings.detectMetadataMismatches {
            for mismatch in intelReport.metadataMismatches {
                let severity = determineSeverity(mismatch: mismatch)
                if severityMeetsThreshold(severity: severity, minSeverity: settings.minThreatSeverity) {
                    threats.append(ThreatDetection(
                        type: "metadata_mismatch",
                        severity: severity,
                        description: mismatch.description,
                        documentID: mismatch.documentID,
                        details: mismatch.details,
                        detectedAt: Date()
                    ))
                }
            }
        }
        
        // Access pattern anomalies
        if settings.detectAccessPatternAnomalies {
            for anomaly in intelReport.accessPatternAnomalies {
                let severity = determineSeverity(anomaly: anomaly)
                if severityMeetsThreshold(severity: severity, minSeverity: settings.minThreatSeverity) {
                    threats.append(ThreatDetection(
                        type: "access_pattern_anomaly",
                        severity: severity,
                        description: anomaly.description,
                        documentID: nil,
                        details: anomaly.details,
                        detectedAt: Date()
                    ))
                }
            }
        }
        
        // Geographic inconsistencies
        if settings.detectGeographicInconsistencies {
            for inconsistency in intelReport.geographicInconsistencies {
                let severity = determineSeverity(inconsistency: inconsistency)
                if severityMeetsThreshold(severity: severity, minSeverity: settings.minThreatSeverity) {
                    threats.append(ThreatDetection(
                        type: "geographic_inconsistency",
                        severity: severity,
                        description: inconsistency.description,
                        documentID: nil,
                        details: inconsistency.details,
                        detectedAt: Date()
                    ))
                }
            }
        }
        
        // Edit history discrepancies
        if settings.detectEditHistoryDiscrepancies {
            for discrepancy in intelReport.editHistoryDiscrepancies {
                let severity = determineSeverity(discrepancy: discrepancy)
                if severityMeetsThreshold(severity: severity, minSeverity: settings.minThreatSeverity) {
                    threats.append(ThreatDetection(
                        type: "edit_history_discrepancy",
                        severity: severity,
                        description: discrepancy.description,
                        documentID: discrepancy.documentID,
                        details: discrepancy.details,
                        detectedAt: Date()
                    ))
                }
            }
        }
        
        return threats
    }
    
    private func determineSeverity(discrepancy: ContentDiscrepancy) -> String {
        // Determine severity based on discrepancy type and magnitude
        if discrepancy.type == "complete_mismatch" {
            return "critical"
        } else if discrepancy.type == "significant_difference" {
            return "high"
        } else {
            return "medium"
        }
    }
    
    private func determineSeverity(mismatch: MetadataMismatch) -> String {
        if mismatch.type == "timestamp_manipulation" || mismatch.type == "checksum_mismatch" {
            return "critical"
        } else if mismatch.type == "author_change" {
            return "high"
        } else {
            return "medium"
        }
    }
    
    private func determineSeverity(anomaly: AccessPatternAnomaly) -> String {
        if anomaly.type == "impossible_access" {
            return "critical"
        } else if anomaly.type == "rapid_access" {
            return "high"
        } else {
            return "medium"
        }
    }
    
    private func determineSeverity(inconsistency: GeographicInconsistency) -> String {
        if inconsistency.distance > 10_000_000 { // > 10,000 km
            return "critical"
        } else if inconsistency.distance > 1_000_000 { // > 1,000 km
            return "high"
        } else {
            return "medium"
        }
    }
    
    private func determineSeverity(discrepancy: EditHistoryDiscrepancy) -> String {
        if discrepancy.type == "missing_edits" || discrepancy.type == "extra_edits" {
            return "high"
        } else {
            return "medium"
        }
    }
    
    private func severityMeetsThreshold(severity: String, minSeverity: String) -> Bool {
        let severityLevels = ["low": 1, "medium": 2, "high": 3, "critical": 4]
        let currentLevel = severityLevels[severity] ?? 0
        let minLevel = severityLevels[minSeverity] ?? 0
        return currentLevel >= minLevel
    }
    
    /// Alert authorized department of detected threats
    func alertAuthorizedDepartment(threats: [ThreatDetection], antiVault: AntiVault) async throws {
        print("🚨 Alerting authorized department of \(threats.count) threat(s)")
        
        // In a real implementation, this would:
        // 1. Send push notification to authorized users
        // 2. Create alert record in database
        // 3. Send email notification
        // 4. Log to audit trail
        
        // For now, just log
        for threat in threats {
            print("   ⚠️ \(threat.severity.uppercased()): \(threat.description)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getVault(id: UUID) async throws -> Vault {
        if AppConfig.useSupabase, let vaultService = vaultService {
            try await vaultService.loadVaults()
            if let vault = vaultService.vaults.first(where: { $0.id == id }) {
                return vault
            }
        } else {
            guard let modelContext = modelContext else {
                throw AntiVaultError.contextNotAvailable
            }
            let descriptor = FetchDescriptor<Vault>(
                predicate: #Predicate { $0.id == id }
            )
            if let vault = try? modelContext.fetch(descriptor).first {
                return vault
            }
        }
        throw AntiVaultError.vaultNotFound
    }
    
    private func convertToSupabaseAntiVault(_ antiVault: AntiVault) async throws -> SupabaseAntiVault {
        guard let vaultID = antiVault.vaultID,
              let monitoredVaultID = antiVault.monitoredVaultID,
              let ownerID = antiVault.ownerID else {
            throw AntiVaultError.invalidData
        }
        
        return SupabaseAntiVault(
            id: antiVault.id,
            vaultID: vaultID,
            monitoredVaultID: monitoredVaultID,
            ownerID: ownerID,
            status: antiVault.status,
            autoUnlockPolicy: antiVault.autoUnlockPolicy,
            threatDetectionSettings: antiVault.threatDetectionSettings,
            lastIntelReportID: antiVault.lastIntelReportID,
            createdAt: antiVault.createdAt,
            updatedAt: Date(),
            lastUnlockedAt: antiVault.lastUnlockedAt
        )
    }
    
    private func convertFromSupabaseAntiVaults(_ supabaseAntiVaults: [SupabaseAntiVault], supabaseService: SupabaseService) async throws -> [AntiVault] {
        var antiVaults: [AntiVault] = []
        
        for supabase in supabaseAntiVaults {
            // Fetch vaults
            let vault: SupabaseVault = try await supabaseService.fetch("vaults", id: supabase.vaultID)
            let monitoredVault: SupabaseVault = try await supabaseService.fetch("vaults", id: supabase.monitoredVaultID)
            let owner: SupabaseUser = try await supabaseService.fetch("users", id: supabase.ownerID)
            
            // Convert to models
            let vaultModel = Vault(name: vault.name, vaultDescription: vault.vaultDescription, keyType: vault.keyType)
            vaultModel.id = vault.id
            vaultModel.isAntiVault = true
            vaultModel.monitoredVaultID = monitoredVault.id
            
            let monitoredVaultModel = Vault(name: monitoredVault.name, vaultDescription: monitoredVault.vaultDescription, keyType: monitoredVault.keyType)
            monitoredVaultModel.id = monitoredVault.id
            
            let ownerModel = User(fullName: owner.fullName, email: owner.email)
            ownerModel.id = owner.id
            
            let antiVault = AntiVault(
                id: supabase.id,
                vaultID: vaultModel.id,
                monitoredVaultID: monitoredVaultModel.id,
                ownerID: ownerModel.id,
                status: supabase.status
            )
            antiVault.autoUnlockPolicy = supabase.autoUnlockPolicy
            antiVault.threatDetectionSettings = supabase.threatDetectionSettings
            antiVault.lastIntelReportID = supabase.lastIntelReportID
            antiVault.createdAt = supabase.createdAt
            antiVault.updatedAt = supabase.updatedAt
            antiVault.lastUnlockedAt = supabase.lastUnlockedAt
            
            antiVaults.append(antiVault)
        }
        
        return antiVaults
    }
    
}

// MARK: - Error Types

enum AntiVaultError: LocalizedError {
    case contextNotAvailable
    case vaultNotFound
    case invalidData
    case serviceNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Model context not available"
        case .vaultNotFound:
            return "Vault not found"
        case .invalidData:
            return "Invalid anti-vault data"
        case .serviceNotAvailable:
            return "Required service not available"
        }
    }
}

// MARK: - Threat Detection Structure

struct ThreatDetection {
    var type: String
    var severity: String // "low", "medium", "high", "critical"
    var description: String
    var documentID: UUID?
    var details: [String: String]?
    var detectedAt: Date
}

// MARK: - Cross-Reference Intel Report Structures

struct CrossReferenceIntelReport {
    var id: UUID = UUID()
    var sharedDocuments: [Document]
    var antiVaultDocuments: [Document]
    var contentDiscrepancies: [ContentDiscrepancy]
    var metadataMismatches: [MetadataMismatch]
    var accessPatternAnomalies: [AccessPatternAnomaly]
    var geographicInconsistencies: [GeographicInconsistency]
    var editHistoryDiscrepancies: [EditHistoryDiscrepancy]
    var generatedAt: Date = Date()
}

struct ContentDiscrepancy {
    var documentID: UUID
    var type: String // "complete_mismatch", "significant_difference", "minor_difference"
    var description: String
    var details: [String: String]
}

struct MetadataMismatch {
    var documentID: UUID
    var type: String // "timestamp_manipulation", "checksum_mismatch", "author_change"
    var description: String
    var details: [String: String]
}

struct AccessPatternAnomaly {
    var type: String // "impossible_access", "rapid_access", "unusual_time"
    var description: String
    var details: [String: String]
}

struct GeographicInconsistency {
    var distance: Double // meters
    var timeDifference: TimeInterval // seconds
    var description: String
    var details: [String: String]
}

struct EditHistoryDiscrepancy {
    var documentID: UUID
    var type: String // "missing_edits", "extra_edits", "timestamp_mismatch"
    var description: String
    var details: [String: String]
}

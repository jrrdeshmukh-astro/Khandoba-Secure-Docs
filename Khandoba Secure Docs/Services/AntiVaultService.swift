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
    private var currentUserID: UUID?
    private var intelReportService: IntelReportService?
    private var vaultService: VaultService?
    private var documentService: DocumentService?
    
    nonisolated init() {}
    
    // iOS-ONLY: Using SwiftData/CloudKit exclusively
    func configure(modelContext: ModelContext, userID: UUID, intelReportService: IntelReportService? = nil, vaultService: VaultService? = nil, documentService: DocumentService? = nil) {
        self.modelContext = modelContext
        self.currentUserID = userID
        self.intelReportService = intelReportService
        self.vaultService = vaultService
        self.documentService = documentService
    }
    
    // MARK: - Anti-Vault Management
    
    /// Create/update anti-vault for a vault (1:1 relationship)
    /// With 1:1 structure, anti-vault properties are embedded in the vault
    func createAntiVault(monitoredVault: Vault, ownerID: UUID, settings: ThreatDetectionSettings? = nil) async throws -> AntiVault {
        print("🛡️ Creating/updating anti-vault for vault: \(monitoredVault.name)")
        
        // Check if anti-vault already exists (1:1 relationship)
        if let existingAntiVaultID = monitoredVault.antiVaultID {
            // Update existing anti-vault
            // iOS-ONLY: Using SwiftData/CloudKit exclusively
            guard let modelContext = modelContext else {
                throw AntiVaultError.contextNotAvailable
            }
            let descriptor = FetchDescriptor<AntiVault>(
                predicate: #Predicate { $0.id == existingAntiVaultID }
            )
            if let existingAntiVault = try? modelContext.fetch(descriptor).first {
                if let settings = settings {
                    existingAntiVault.threatDetectionSettings = settings
                }
                existingAntiVault.updatedAt = Date()
                
                // Update vault's embedded properties
                monitoredVault.antiVaultStatus = existingAntiVault.status
                monitoredVault.antiVaultThreatDetectionSettingsData = existingAntiVault.threatDetectionSettingsData
                
                try modelContext.save()
                return existingAntiVault
            }
        }
        
        // Create new anti-vault (1:1 relationship - embedded in vault)
        // Note: vault_id must reference an existing vault (foreign key constraint)
        // For 1:1 relationship, vault_id = monitored_vault_id (the vault being monitored)
        let antiVaultID = UUID()
        let antiVault = AntiVault(
            id: antiVaultID,
            vaultID: monitoredVault.id, // Must reference existing vault (foreign key constraint)
            monitoredVaultID: monitoredVault.id, // Monitors this vault (1:1 relationship)
            ownerID: ownerID,
            status: "locked"
        )
        
        if let settings = settings {
            antiVault.threatDetectionSettings = settings
        }
        
        // Update vault with anti-vault properties (1:1 relationship)
        monitoredVault.antiVaultID = antiVaultID
        monitoredVault.antiVaultStatus = antiVault.status
        monitoredVault.antiVaultCreatedAt = Date()
        monitoredVault.antiVaultAutoUnlockPolicyData = encodeAutoUnlockPolicy(antiVault.autoUnlockPolicy)
        monitoredVault.antiVaultThreatDetectionSettingsData = encodeThreatDetectionSettings(antiVault.threatDetectionSettings)
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw AntiVaultError.contextNotAvailable
        }
        
        modelContext.insert(antiVault)
        try modelContext.save()
        
        print("✅ Anti-vault created/updated: \(antiVault.id)")
        return antiVault
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
    
    // Note: Supabase helper function removed - iOS app uses CloudKit exclusively
    
    // MARK: - Session Nomination Monitoring
    
    /// Monitor session nomination and auto-unlock anti-vault if needed
    func monitorSessionNomination(vaultID: UUID, nomineeID: UUID, selectedDocumentIDs: [UUID]? = nil) async throws {
        print("🔍 Monitoring session nomination for vault: \(vaultID)")
        
        // Find anti-vaults monitoring this vault
        let monitoringAntiVaults: [AntiVault]
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw AntiVaultError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<AntiVault>(
            predicate: #Predicate { $0.monitoredVaultID == vaultID }
        )
        monitoringAntiVaults = try modelContext.fetch(descriptor)
        
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
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw AntiVaultError.contextNotAvailable
        }
        try modelContext.save()
        
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
    
    /// Evaluate logical threats and determine anti-vault actions
    func evaluateLogicalThreats(vault: Vault, result: ThreatInferenceResult) async {
        print("🛡️ Evaluating logical threats for vault: \(vault.name)")
        
        let scores = result.granularScores
        let action = determineAntiVaultAction(granularScores: scores)
        
        // Execute action based on threat level
        switch action {
        case .immediateLock(let reason):
            print("🔒 Immediate lock required: \(reason)")
            // Lock anti-vault immediately
            // iOS-ONLY: Using SwiftData/CloudKit exclusively
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        if let modelContext = modelContext {
                if let antiVaultID = vault.antiVaultID {
                    let descriptor = FetchDescriptor<AntiVault>(
                        predicate: #Predicate { $0.id == antiVaultID }
                    )
                    if let antiVault = try? modelContext.fetch(descriptor).first {
                        antiVault.status = "locked"
                        vault.antiVaultStatus = "locked"
                        try? modelContext.save()
                    }
                }
            }
            
        case .lockWithDualKeyRequirement(let reason):
            print("🔐 Lock with dual-key requirement: \(reason)")
            // Similar lock logic but ensure dual-key is required
            
        case .requireDualKeyForAccess(let reason):
            print("🔑 Require dual-key for access: \(reason)")
            // Ensure dual-key authentication is enabled
            
        case .enableEnhancedMonitoring(let reason):
            print("👁️ Enable enhanced monitoring: \(reason)")
            // Enable additional monitoring
            
        case .monitorClosely(let reason):
            print("🔍 Monitor closely: \(reason)")
            // Just log for now
            
        case .preventiveLock(let reason):
            print("🛡️ Preventive lock: \(reason)")
            // Similar to immediate lock
            
        case .noAction:
            print("✅ No action required")
        }
    }
    
    /// Determine anti-vault action based on granular threat scores
    private func determineAntiVaultAction(granularScores: GranularThreatScores) -> AntiVaultAction {
        let score = granularScores.compositeScore
        let level = GranularThreatLevel(score: score)
        
        switch level {
        case .extreme, .critical:        // 80.1-100.0
            return .immediateLock(reason: "Extreme threat detected: \(String(format: "%.2f", score))")
        
        case .highCritical:              // 70.1-80.0
            return .lockWithDualKeyRequirement(reason: "High-critical threat: \(String(format: "%.2f", score))")
        
        case .high:                      // 60.1-70.0
            return .requireDualKeyForAccess(reason: "High threat level: \(String(format: "%.2f", score))")
        
        case .mediumHigh:                // 50.1-60.0
            return .enableEnhancedMonitoring(reason: "Medium-high threat: \(String(format: "%.2f", score))")
        
        case .medium, .lowMedium:        // 30.1-50.0
            return .monitorClosely(reason: "Elevated threat: \(String(format: "%.2f", score))")
        
        default:                         // 0.0-30.0
            // Check for category-specific high scores
            if granularScores.categoryScores.externalThreatScore > 80 {
                return .immediateLock(reason: "External threat score: \(String(format: "%.2f", granularScores.categoryScores.externalThreatScore))")
            }
            if granularScores.categoryScores.dataExfiltrationScore > 70 {
                return .lockWithDualKeyRequirement(reason: "Data exfiltration risk: \(String(format: "%.2f", granularScores.categoryScores.dataExfiltrationScore))")
            }
            if let velocity = granularScores.scoreVelocity, velocity > 10.0 {
                return .preventiveLock(reason: "Rapid threat escalation: velocity=\(String(format: "%.2f", velocity))")
            }
            return .noAction
        }
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
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw AntiVaultError.contextNotAvailable
        }
        let descriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.id == id }
        )
        if let vault = try? modelContext.fetch(descriptor).first {
            return vault
        }
        throw AntiVaultError.vaultNotFound
    }
    
    // Note: Supabase conversion functions removed - iOS app uses CloudKit exclusively
    
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

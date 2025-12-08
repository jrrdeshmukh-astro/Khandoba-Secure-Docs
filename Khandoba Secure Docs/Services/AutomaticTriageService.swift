//
//  AutomaticTriageService.swift
//  Khandoba Secure Docs
//
//  Automatic threat triage with guided remediation
//

import Foundation
import SwiftData
import Combine
import Network
import UIKit
import SwiftUI

@MainActor
final class AutomaticTriageService: ObservableObject {
    @Published var triageResults: [TriageResult] = []
    @Published var isAnalyzing = false
    @Published var currentRemediationFlow: RemediationFlow?
    
    private var modelContext: ModelContext?
    private var threatService: ThreatMonitoringService
    private var mlService: MLThreatAnalysisService
    private var vaultService: VaultService
    private var documentService: DocumentService
    private var nomineeService: NomineeService
    
    nonisolated init() {
        self.threatService = ThreatMonitoringService()
        self.mlService = MLThreatAnalysisService()
        self.vaultService = VaultService()
        self.documentService = DocumentService()
        self.nomineeService = NomineeService()
    }
    
    func configure(modelContext: ModelContext, userID: UUID) {
        self.modelContext = modelContext
        vaultService.configure(modelContext: modelContext, userID: userID)
        documentService.configure(modelContext: modelContext, userID: userID)
        nomineeService.configure(modelContext: modelContext)
    }
    
    // MARK: - Automatic Triage Analysis
    
    func performAutomaticTriage() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        guard let modelContext = modelContext else { return }
        
        // Load all vaults
        try? await vaultService.loadVaults()
        let vaults = vaultService.vaults
        
        var results: [TriageResult] = []
        
        // Analyze each vault
        for vault in vaults {
            let vaultResults = await analyzeVault(vault)
            results.append(contentsOf: vaultResults)
        }
        
        // Sort by severity and priority
        results.sort { result1, result2 in
            if result1.severity != result2.severity {
                return result1.severity.rawValue > result2.severity.rawValue
            }
            return result1.priority.rawValue > result2.priority.rawValue
        }
        
        self.triageResults = results
        
        // Auto-start remediation for critical issues
        if let criticalResult = results.first(where: { $0.severity == .critical }) {
            await startGuidedRemediation(for: criticalResult)
        }
    }
    
    // MARK: - Vault Analysis
    
    private func analyzeVault(_ vault: Vault) async -> [TriageResult] {
        var results: [TriageResult] = []
        
        // 1. Screen Monitoring Detection
        if UIScreen.main.isCaptured {
            let monitoringIP = await getCurrentIPAddress()
            results.append(TriageResult(
                id: UUID(),
                type: .screenMonitoring,
                severity: .critical,
                priority: .immediate,
                title: "Screen Monitoring Detected",
                description: "Your screen is being recorded or monitored. This is a critical security threat.",
                vaultID: vault.id,
                vaultName: vault.name,
                detectedAt: Date(),
                questions: [
                    "Are you aware that screen recording is active?",
                    "Did you intentionally start screen recording?",
                    "Are you in a secure location?"
                ],
                recommendedActions: [
                    .closeAllVaults,
                    .recordMonitoringIP(monitoringIP ?? "Unknown"),
                    .revokeAllSessions,
                    .changeAllPasswords
                ],
                autoActions: [.closeAllVaults, .recordMonitoringIP(monitoringIP ?? "Unknown")]
            ))
        }
        
        // 2. Compromised Nominees
        if let nominees = vault.nomineeList {
            let suspiciousNominees = await detectCompromisedNominees(nominees, in: vault)
            if !suspiciousNominees.isEmpty {
                results.append(TriageResult(
                    id: UUID(),
                    type: .compromisedNominee,
                    severity: .high,
                    priority: .high,
                    title: "Compromised Nominees Detected",
                    description: "\(suspiciousNominees.count) nominee(s) show suspicious access patterns",
                    vaultID: vault.id,
                    vaultName: vault.name,
                    detectedAt: Date(),
                    affectedEntities: suspiciousNominees.map { $0.name },
                    questions: [
                        "Do you recognize all access locations for these nominees?",
                        "Have you authorized access from these locations?",
                        "Should these nominees still have access?"
                    ],
                    recommendedActions: [
                        .revokeNominees(suspiciousNominees.map { $0.id }),
                        .reviewAccessLogs,
                        .enableDualKeyProtection
                    ]
                ))
            }
        }
        
        // 3. Sensitive Documents Requiring Redaction
        if let documents = vault.documents {
            let sensitiveDocs = await detectSensitiveDocuments(documents, in: vault)
            if !sensitiveDocs.isEmpty {
                results.append(TriageResult(
                    id: UUID(),
                    type: .sensitiveDocuments,
                    severity: .high,
                    priority: .high,
                    title: "Sensitive Documents Requiring Redaction",
                    description: "\(sensitiveDocs.count) document(s) contain sensitive information that should be redacted",
                    vaultID: vault.id,
                    vaultName: vault.name,
                    detectedAt: Date(),
                    affectedEntities: sensitiveDocs.map { $0.name },
                    questions: [
                        "Do these documents contain PHI or sensitive personal information?",
                        "Should these documents be redacted for HIPAA compliance?",
                        "Are these documents shared with nominees?"
                    ],
                    recommendedActions: [
                        .redactDocuments(sensitiveDocs.map { $0.id }),
                        .restrictDocumentAccess(sensitiveDocs.map { $0.id }),
                        .reviewDocumentSharing
                    ]
                ))
            }
        }
        
        // 4. Data Leak Indicators
        let geoMetrics = mlService.analyzeGeoClassification(for: vault)
        let accessMetrics = mlService.analyzeAccessPatterns(for: vault)
        let tagMetrics = mlService.analyzeTagPatterns(for: vault)
        
        if geoMetrics.riskScore > 0.7 || accessMetrics.riskScore > 0.7 || tagMetrics.exfiltrationRisk > 0.6 {
            results.append(TriageResult(
                id: UUID(),
                type: .dataLeak,
                severity: .critical,
                priority: .immediate,
                title: "Potential Data Leak Detected",
                description: "Multiple indicators suggest potential data exfiltration or unauthorized access",
                vaultID: vault.id,
                vaultName: vault.name,
                detectedAt: Date(),
                questions: [
                    "Have you noticed unusual activity in this vault?",
                    "Are all access locations authorized?",
                    "Have you shared vault access with anyone recently?",
                    "Do you recognize all document uploads?"
                ],
                recommendedActions: [
                    .lockVault(vault.id),
                    .reviewAccessLogs,
                    .revokeAllNominees,
                    .enableEnhancedMonitoring,
                    .changeVaultPassword
                ],
                autoActions: [.lockVault(vault.id)]
            ))
        }
        
        // 5. Rapid Access Pattern (Brute Force)
        let threatLevel = await threatService.analyzeThreatLevel(for: vault)
        let threats = threatService.detectThreats(for: vault)
        
        if threatLevel == .high || threatLevel == .critical {
            let rapidAccessThreats = threats.filter {
                if case .rapidAccess = $0.type { return true }
                return false
            }
            
            if !rapidAccessThreats.isEmpty {
                results.append(TriageResult(
                    id: UUID(),
                    type: .bruteForce,
                    severity: .critical,
                    priority: .immediate,
                    title: "Brute Force Attack Detected",
                    description: "Multiple rapid access attempts detected - possible brute force attack",
                    vaultID: vault.id,
                    vaultName: vault.name,
                    detectedAt: Date(),
                    questions: [
                        "Are you making these rapid access attempts?",
                        "Have you shared your vault password?",
                        "Do you recognize the access locations?"
                    ],
                    recommendedActions: [
                        .lockVault(vault.id),
                        .changeVaultPassword,
                        .revokeAllSessions,
                        .enableDualKeyProtection,
                        .reviewAccessLogs
                    ],
                    autoActions: [.lockVault(vault.id), .revokeAllSessions]
                ))
            }
        }
        
        return results
    }
    
    // MARK: - Detection Methods
    
    private func detectCompromisedNominees(_ nominees: [Nominee], in vault: Vault) async -> [Nominee] {
        var suspicious: [Nominee] = []
        
        for nominee in nominees where nominee.status == .accepted || nominee.status == .active {
            // Check access logs for this nominee
            if let logs = vault.accessLogs {
                let nomineeLogs = logs.filter { log in
                    // Match by name or other identifier
                    log.userName?.contains(nominee.name) == true
                }
                
                // Check for suspicious patterns
                if nomineeLogs.count > 0 {
                    let geoMetrics = mlService.analyzeGeoClassification(for: vault)
                    
                    // If nominee has many unique locations, might be compromised
                    if geoMetrics.uniqueLocations > 3 {
                        suspicious.append(nominee)
                    }
                }
            }
        }
        
        return suspicious
    }
    
    private func detectSensitiveDocuments(_ documents: [Document], in vault: Vault) async -> [Document] {
        var sensitive: [Document] = []
        
        for document in documents where document.status == "active" {
            // Check for PHI indicators in tags
            let phiKeywords = ["medical", "health", "patient", "diagnosis", "treatment", "ssn", "social security", "credit card", "bank account"]
            
            let hasPHI = document.aiTags.contains { tag in
                phiKeywords.contains { keyword in
                    tag.lowercased().contains(keyword)
                }
            }
            
            // Check if document is not redacted
            if hasPHI && !document.isRedacted {
                sensitive.append(document)
            }
        }
        
        return sensitive
    }
    
    private func getCurrentIPAddress() async -> String? {
        // Get device's local IP address using Network framework
        // For public IP, would need to make HTTP request to external service
        
        // Simplified approach: Return device identifier or use Network framework
        // In production, you might want to get public IP from a service
        
        // For now, return a placeholder that indicates monitoring was detected
        // The actual IP would be recorded when screen monitoring is detected
        return "Device-\(UIDevice.current.identifierForVendor?.uuidString.prefix(8) ?? "Unknown")"
    }
    
    // MARK: - Guided Remediation
    
    func startGuidedRemediation(for result: TriageResult) async {
        let flow = RemediationFlow(
            id: UUID(),
            triageResult: result,
            currentStep: 0,
            answers: [:],
            recommendedActions: result.recommendedActions,
            completedActions: []
        )
        
        self.currentRemediationFlow = flow
    }
    
    func answerQuestion(_ question: String, answer: String, in flow: RemediationFlow) async {
        var updatedFlow = flow
        updatedFlow.answers[question] = answer
        updatedFlow.currentStep += 1
        
        // Determine next actions based on answers
        let nextActions = await determineNextActions(from: updatedFlow)
        updatedFlow.recommendedActions = nextActions
        
        self.currentRemediationFlow = updatedFlow
    }
    
    func executeAction(_ action: RemediationAction, in flow: RemediationFlow) async throws {
        guard let modelContext = modelContext else { return }
        
        switch action {
        case .closeAllVaults:
            try await closeAllVaults()
            
        case .lockVault(let vaultID):
            try await lockVault(vaultID)
            
        case .revokeNominees(let nomineeIDs):
            try await revokeNominees(nomineeIDs)
            
        case .revokeAllNominees:
            try await revokeAllNominees()
            
        case .revokeAllSessions:
            try await revokeAllSessions()
            
        case .redactDocuments(let documentIDs):
            try await redactDocuments(documentIDs)
            
        case .restrictDocumentAccess(let documentIDs):
            try await restrictDocumentAccess(documentIDs)
            
        case .changeVaultPassword:
            // Would need vault password change implementation
            break
            
        case .changeAllPasswords:
            // Would need all passwords change implementation
            break
            
        case .recordMonitoringIP(let ip):
            await recordMonitoringIP(ip)
            
        case .reviewAccessLogs:
            // Navigation action - handled in UI
            break
            
        case .reviewDocumentSharing:
            // Navigation action - handled in UI
            break
            
        case .enableDualKeyProtection:
            try await enableDualKeyProtection()
            
        case .enableEnhancedMonitoring:
            // Already enabled via TriageView
            break
        }
        
        var updatedFlow = flow
        updatedFlow.completedActions.append(action)
        self.currentRemediationFlow = updatedFlow
    }
    
    private func determineNextActions(from flow: RemediationFlow) async -> [RemediationAction] {
        // Analyze answers to determine next steps
        var actions: [RemediationAction] = []
        
        // Example logic: If user doesn't recognize access, revoke nominees
        if let answer = flow.answers["Do you recognize all access locations for these nominees?"],
           answer.lowercased().contains("no") {
            actions.append(.revokeAllNominees)
        }
        
        // If user confirms PHI in documents, suggest redaction
        if let answer = flow.answers["Do these documents contain PHI or sensitive personal information?"],
           answer.lowercased().contains("yes") {
            if let docIDs = flow.triageResult.affectedEntities?.compactMap({ UUID(uuidString: $0) }) {
                actions.append(.redactDocuments(docIDs))
            }
        }
        
        return actions.isEmpty ? flow.triageResult.recommendedActions : actions
    }
    
    // MARK: - Action Implementations
    
    private func closeAllVaults() async throws {
        guard let modelContext = modelContext else { return }
        
        try? await vaultService.loadVaults()
        for vault in vaultService.vaults {
            vault.status = "locked"
            // End all active sessions
            if let sessions = vault.sessions {
                for session in sessions {
                    session.isActive = false
                }
            }
        }
        try modelContext.save()
        print(" All vaults closed due to security threat")
    }
    
    private func lockVault(_ vaultID: UUID) async throws {
        guard let modelContext = modelContext else { return }
        
        try? await vaultService.loadVaults()
        if let vault = vaultService.vaults.first(where: { $0.id == vaultID }) {
            vault.status = "locked"
            // End active sessions
            if let sessions = vault.sessions {
                for session in sessions {
                    session.isActive = false
                }
            }
            try modelContext.save()
            print(" Vault '\(vault.name)' locked due to security threat")
        }
    }
    
    private func revokeNominees(_ nomineeIDs: [UUID]) async throws {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { nominee in
                nomineeIDs.contains(nominee.id)
            }
        )
        
        let nominees = try modelContext.fetch(descriptor)
        for nominee in nominees {
            nominee.status = .revoked
        }
        try modelContext.save()
        print(" Revoked \(nominees.count) compromised nominee(s)")
    }
    
    private func revokeAllNominees() async throws {
        guard let modelContext = modelContext else { return }
        
        try? await vaultService.loadVaults()
        for vault in vaultService.vaults {
            if let nominees = vault.nomineeList {
                for nominee in nominees {
                    nominee.status = .revoked
                }
            }
        }
        try modelContext.save()
        print(" Revoked all nominees due to security threat")
    }
    
    private func revokeAllSessions() async throws {
        guard let modelContext = modelContext else { return }
        
        try? await vaultService.loadVaults()
        for vault in vaultService.vaults {
            if let sessions = vault.sessions {
                for session in sessions {
                    session.isActive = false
                }
            }
        }
        try modelContext.save()
        print(" Revoked all active sessions")
    }
    
    private func redactDocuments(_ documentIDs: [UUID]) async throws {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { document in
                documentIDs.contains(document.id)
            }
        )
        
        let documents = try modelContext.fetch(descriptor)
        for document in documents {
            document.isRedacted = true
            document.status = "archived" // Archive redacted documents
        }
        try modelContext.save()
        print("🔴 Redacted \(documents.count) sensitive document(s)")
    }
    
    private func restrictDocumentAccess(_ documentIDs: [UUID]) async throws {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { document in
                documentIDs.contains(document.id)
            }
        )
        
        let documents = try modelContext.fetch(descriptor)
        for document in documents {
            document.status = "archived" // Archive to restrict access
        }
        try modelContext.save()
        print(" Restricted access to \(documents.count) document(s)")
    }
    
    private func enableDualKeyProtection() async throws {
        guard let modelContext = modelContext else { return }
        
        try? await vaultService.loadVaults()
        for vault in vaultService.vaults where vault.keyType != "dual" {
            vault.keyType = "dual"
        }
        try modelContext.save()
        print(" Enabled dual-key protection for all vaults")
    }
    
    private func recordMonitoringIP(_ ip: String) async {
        // Record monitoring event in access log
        guard let modelContext = modelContext else { return }
        
        try? await vaultService.loadVaults()
        for vault in vaultService.vaults {
            let log = VaultAccessLog(
                accessType: "security_alert",
                userID: nil,
                userName: "System"
            )
            log.vault = vault
            log.ipAddress = ip
            log.deviceInfo = "Screen monitoring detected - IP: \(ip)"
            
            modelContext.insert(log)
        }
        
        try? modelContext.save()
        print("📝 Recorded monitoring IP: \(ip)")
    }
}

// MARK: - Models

struct TriageResult: Identifiable, Equatable {
    let id: UUID
    let type: TriageResultType
    let severity: ThreatLevel
    let priority: RemediationPriority
    let title: String
    let description: String
    let vaultID: UUID
    let vaultName: String
    let detectedAt: Date
    var affectedEntities: [String]? // Nominee names, document names, etc.
    let questions: [String]
    var recommendedActions: [RemediationAction]
    var autoActions: [RemediationAction] = [] // Actions to take automatically
    
    static func == (lhs: TriageResult, rhs: TriageResult) -> Bool {
        lhs.id == rhs.id
    }
}

enum TriageResultType: Equatable {
    case screenMonitoring
    case compromisedNominee
    case sensitiveDocuments
    case dataLeak
    case bruteForce
    case unauthorizedAccess
    case suspiciousActivity
}

enum RemediationPriority: Int {
    case low = 1
    case medium = 2
    case high = 3
    case immediate = 4
}

enum RemediationAction: Identifiable, Equatable {
    case closeAllVaults
    case lockVault(UUID)
    case revokeNominees([UUID])
    case revokeAllNominees
    case revokeAllSessions
    case redactDocuments([UUID])
    case restrictDocumentAccess([UUID])
    case changeVaultPassword
    case changeAllPasswords
    case recordMonitoringIP(String)
    case reviewAccessLogs
    case reviewDocumentSharing
    case enableDualKeyProtection
    case enableEnhancedMonitoring
    
    var id: String {
        switch self {
        case .closeAllVaults: return "close_all_vaults"
        case .lockVault(let id): return "lock_vault_\(id.uuidString)"
        case .revokeNominees(let ids): return "revoke_nominees_\(ids.map { $0.uuidString }.joined())"
        case .revokeAllNominees: return "revoke_all_nominees"
        case .revokeAllSessions: return "revoke_all_sessions"
        case .redactDocuments(let ids): return "redact_docs_\(ids.map { $0.uuidString }.joined())"
        case .restrictDocumentAccess(let ids): return "restrict_docs_\(ids.map { $0.uuidString }.joined())"
        case .changeVaultPassword: return "change_vault_password"
        case .changeAllPasswords: return "change_all_passwords"
        case .recordMonitoringIP(let ip): return "record_ip_\(ip)"
        case .reviewAccessLogs: return "review_access_logs"
        case .reviewDocumentSharing: return "review_document_sharing"
        case .enableDualKeyProtection: return "enable_dual_key"
        case .enableEnhancedMonitoring: return "enable_enhanced_monitoring"
        }
    }
}

struct RemediationFlow: Identifiable, Equatable {
    let id: UUID
    let triageResult: TriageResult
    var currentStep: Int
    var answers: [String: String]
    var recommendedActions: [RemediationAction]
    var completedActions: [RemediationAction]
    
    static func == (lhs: RemediationFlow, rhs: RemediationFlow) -> Bool {
        lhs.id == rhs.id
    }
}

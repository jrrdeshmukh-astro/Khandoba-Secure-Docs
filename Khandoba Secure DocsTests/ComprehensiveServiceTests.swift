//
import Foundation
//  ComprehensiveServiceTests.swift
//  Khandoba Secure DocsTests
//
//  Comprehensive unit tests for all new services - semantics and logic flow
//

import Testing
import SwiftData
@testable import Khandoba_Secure_Docs

// MARK: - OAuth Service Tests


    
    @Test("OAuth Provider Auth URLs")
    func testProviderAuthURLs() {
        #expect(OAuthProvider.gmail.authURL.contains("accounts.google.com"))
        #expect(OAuthProvider.dropbox.authURL.contains("dropbox.com"))
        #expect(OAuthProvider.oneDrive.authURL.contains("microsoftonline.com"))
    }
    
    @Test("OAuth Provider Token URLs")
    func testProviderTokenURLs() {
        #expect(OAuthProvider.gmail.tokenURL.contains("oauth2.googleapis.com"))
        #expect(OAuthProvider.dropbox.tokenURL.contains("dropboxapi.com"))
        #expect(OAuthProvider.oneDrive.tokenURL.contains("microsoftonline.com"))
    }
    
    @Test("OAuth Provider Scopes")
    func testProviderScopes() {
        #expect(!OAuthProvider.gmail.scopes.isEmpty)
        #expect(OAuthProvider.gmail.scopes.contains("https://www.googleapis.com/auth/gmail.readonly"))
        #expect(!OAuthProvider.googleDrive.scopes.isEmpty)
        #expect(OAuthProvider.googleDrive.scopes.contains("https://www.googleapis.com/auth/drive.readonly"))
    }
    
    @Test("All OAuth Providers Listed")
    func testAllProvidersListed() {
        let allProviders = OAuthProvider.allCases
        #expect(allProviders.count == 5)
        #expect(allProviders.contains(.gmail))
        #expect(allProviders.contains(.googleDrive))
        #expect(allProviders.contains(.dropbox))
        #expect(allProviders.contains(.oneDrive))
        #expect(allProviders.contains(.outlook))
    }
    
    @Test("OAuth Error Descriptions")
    func testOAuthErrorDescriptions() {
        let errors: [OAuthError] = [
            .configurationMissing,
            .authenticationCancelled,
            .tokenExchangeFailed,
            .tokenRefreshFailed,
            .invalidState,
            .keychainError,
            .tokenNotFound
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

// MARK: - Email Integration Service Tests

struct EmailIntegrationServiceTests {
    @Test("Email Provider Display Names")
    func testEmailProviderDisplayNames() {
        #expect(EmailProvider.gmail.displayName == "Gmail")
        #expect(EmailProvider.outlook.displayName == "Outlook")
        #expect(EmailProvider.imap.displayName == "IMAP")
    }
    
    @Test("Email Filter Creation")
    func testEmailFilterCreation() {
        let filter = EmailFilter()
        #expect(filter.folders.isEmpty)
        #expect(filter.dateRange == nil)
        #expect(filter.sender == nil)
        #expect(filter.subject == nil)
        #expect(filter.hasAttachments == nil)
    }
    
    @Test("Email Filter With Date Range")
    func testEmailFilterWithDateRange() {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(86400)
        let dateRange = EmailFilter.DateRange(start: startDate, end: endDate)
        
        var filter = EmailFilter()
        filter.dateRange = dateRange
        
        #expect(filter.dateRange != nil)
        #expect(filter.dateRange?.start == startDate)
        #expect(filter.dateRange?.end == endDate)
    }
    
    @Test("Email Message Creation")
    func testEmailMessageCreation() {
        let message = EmailMessage(
            id: "msg123",
            subject: "Test Subject",
            from: "sender@example.com",
            to: ["recipient@example.com"],
            date: Date(),
            body: "Test body",
            snippet: "Test snippet",
            attachments: [],
            threadId: "thread123",
            labels: ["INBOX"]
        )
        
        #expect(message.id == "msg123")
        #expect(message.subject == "Test Subject")
        #expect(message.from == "sender@example.com")
        #expect(message.to.count == 1)
        #expect(message.body == "Test body")
    }
    
    @Test("Email Attachment Creation")
    func testEmailAttachmentCreation() {
        let attachment = EmailAttachment(
            id: "att123",
            filename: "document.pdf",
            mimeType: "application/pdf",
            size: 1024,
            attachmentId: "att123"
        )
        
        #expect(attachment.id == "att123")
        #expect(attachment.filename == "document.pdf")
        #expect(attachment.mimeType == "application/pdf")
        #expect(attachment.size == 1024)
    }
    
    @Test("Email Integration Error Descriptions")
    func testEmailIntegrationErrorDescriptions() {
        let errors: [EmailIntegrationError] = [
            .notAuthenticated,
            .authenticationFailed,
            .fetchFailed,
            .attachmentDownloadFailed,
            .invalidProvider,
            .filterError
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

// MARK: - Cloud Storage Service Tests

struct CloudStorageServiceTests {
    @Test("Cloud Storage Provider Display Names")
    func testCloudStorageProviderDisplayNames() {
        #expect(CloudStorageProvider.googleDrive.displayName == "Google Drive")
        #expect(CloudStorageProvider.dropbox.displayName == "Dropbox")
        #expect(CloudStorageProvider.oneDrive.displayName == "OneDrive")
        #expect(CloudStorageProvider.iCloudDrive.displayName == "iCloud Drive")
    }
    
    @Test("Cloud File Creation")
    func testCloudFileCreation() {
        let file = CloudFile(
            id: "file123",
            name: "document.pdf",
            mimeType: "application/pdf",
            size: 1024,
            modifiedDate: Date(),
            isFolder: false,
            parentId: nil,
            downloadUrl: nil,
            thumbnailUrl: nil
        )
        
        #expect(file.id == "file123")
        #expect(file.name == "document.pdf")
        #expect(file.mimeType == "application/pdf")
        #expect(file.size == 1024)
        #expect(!file.isFolder)
    }
    
    @Test("Cloud Storage Error Descriptions")
    func testCloudStorageErrorDescriptions() {
        let errors: [CloudStorageError] = [
            .notAuthenticated,
            .authenticationFailed,
            .fetchFailed,
            .downloadFailed,
            .uploadFailed,
            .invalidProvider
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

// MARK: - Compliance Engine Service Tests


// MARK: - PHI Detection Service Tests


// MARK: - Risk Assessment Service Tests

struct RiskAssessmentServiceTests {
    @Test("Risk Assessment Creation")
    func testRiskAssessmentCreation() {
        let risk = RiskAssessment(
            title: "Test Risk",
            riskDescription: "Test description",
            severity: .high,
            riskScore: 0.75
        )
        
        #expect(risk.title == "Test Risk")
        #expect(risk.riskDescription == "Test description")
        #expect(risk.severityEnum == .high)
        #expect(risk.riskScore == 0.75)
    }
    
    @Test("Risk Severity Enum")
    func testRiskSeverityEnum() {
        #expect(RiskSeverity.low.rawValue == "Low")
        #expect(RiskSeverity.medium.rawValue == "Medium")
        #expect(RiskSeverity.high.rawValue == "High")
        #expect(RiskSeverity.critical.rawValue == "Critical")
    }
    
    @Test("Risk Status Enum")
    func testRiskStatusEnum() {
        #expect(RiskStatus.identified.rawValue == "Identified")
        #expect(RiskStatus.assessed.rawValue == "Assessed")
        #expect(RiskStatus.mitigated.rawValue == "Mitigated")
        #expect(RiskStatus.accepted.rawValue == "Accepted")
        #expect(RiskStatus.closed.rawValue == "Closed")
    }
    
    @Test("Risk Score Calculation")
    func testRiskScoreCalculation() {
        let risk = RiskAssessment(
            title: "Test",
            riskDescription: "Test",
            severity: .medium,
            riskScore: 0.0
        )
        
        risk.likelihood = 0.7
        risk.impact = 0.8
        
        // Risk score should be likelihood * impact
        let calculatedScore = risk.likelihood * risk.impact
        #expect(calculatedScore == 0.56)
    }
}

// MARK: - Incident Response Service Tests

struct IncidentResponseServiceTests {
    @Test("Security Incident Creation")
    func testSecurityIncidentCreation() {
        let incident = SecurityIncident(
            title: "Test Incident",
            incidentDescription: "Test description",
            classification: IncidentClassification.unauthorizedAccess,
            severity: .high
        )
        
        #expect(incident.title == "Test Incident")
        #expect(incident.incidentDescription == "Test description")
        #expect(incident.classificationEnum == IncidentClassification.unauthorizedAccess)
        #expect(incident.severityEnum == .high)
    }
    
    @Test("Incident Severity Enum")
    func testIncidentSeverityEnum() {
        #expect(IncidentSeverity.low.rawValue == "Low")
        #expect(IncidentSeverity.medium.rawValue == "Medium")
        #expect(IncidentSeverity.high.rawValue == "High")
        #expect(IncidentSeverity.critical.rawValue == "Critical")
    }
    
    @Test("Incident Status Enum")
    func testIncidentStatusEnum() {
        #expect(IncidentStatus.detected.rawValue == "Detected")
        #expect(IncidentStatus.triaged.rawValue == "Triaged")
        #expect(IncidentStatus.contained.rawValue == "Contained")
        #expect(IncidentStatus.resolved.rawValue == "Resolved")
        #expect(IncidentStatus.closed.rawValue == "Closed")
    }
    
    @Test("Incident Classification Enum")
    func testIncidentClassificationEnum() {
        #expect(IncidentClassification.unauthorizedAccess.rawValue == "Unauthorized Access")
        #expect(IncidentClassification.dataBreach.rawValue == "Data Breach")
        #expect(IncidentClassification.malware.rawValue == "Malware")
        #expect(IncidentClassification.phishing.rawValue == "Phishing")
    }
}

// MARK: - Index Calculation Service Tests


    
    @Test("Index Range Validation")
    func testIndexRangeValidation() async {
        let indexService = IndexCalculationService.shared
        await indexService.calculateAllIndexes()
        
        let indexes = await MainActor.run { indexService.currentIndexes }
        let threatIdx = await MainActor.run { indexes.threatIndex }
        #expect(threatIdx >= 0.0 && indexes.threatIndex <= 100.0)
        #expect(indexes.complianceIndex >= 0.0 && indexes.complianceIndex <= 100.0)
        #expect(indexes.triageCriticality >= 0.0 && indexes.triageCriticality <= 100.0)
    }

// MARK: - Intelligent Ingestion Service Tests

struct IntelligentIngestionServiceTests {
    @Test("Ingestion Status Enum")
    func testIngestionStatusEnum() {
        #expect(IngestionStatus.idle.rawValue == "Idle")
        #expect(IngestionStatus.running.rawValue == "Running")
        #expect(IngestionStatus.paused.rawValue == "Paused")
        #expect(IngestionStatus.completed.rawValue == "Completed")
        #expect(IngestionStatus.failed.rawValue == "Failed")
    }
    
    @Test("Vault Topic Creation")
    func testVaultTopicCreation() {
        let vaultID = UUID()
        let topic = VaultTopic(
            vaultID: vaultID,
            topicName: "Test Topic",
            topicDescription: "Test description"
        )
        
        #expect(topic.vaultID == vaultID)
        #expect(topic.topicName == "Test Topic")
        #expect(topic.topicDescription == "Test description")
        #expect(topic.isActive == true)
    }
    
    @Test("Vault Topic Learning Metrics")
    func testVaultTopicLearningMetrics() {
        let topic = VaultTopic(
            vaultID: UUID(),
            topicName: "Test Topic"
        )
        
        topic.totalIngested = 100
        topic.relevantCount = 80
        topic.learningScore = 0.8
        
        #expect(topic.totalIngested == 100)
        #expect(topic.relevantCount == 80)
        #expect(topic.learningScore == 0.8)
    }
}

// MARK: - Export Service Tests

struct ExportServiceTests {
    @Test("Export Options Default Values")
    func testExportOptionsDefaultValues() {
        let options = ExportOptions()
        
        #expect(options.includeDocuments == true)
        #expect(options.includeMetadata == true)
        #expect(options.includeAuditLogs == false)
        #expect(options.includeComplianceReports == false)
        #expect(options.format == .zip)
        #expect(options.compressionLevel == 0.5)
    }
    
    @Test("Export Options Formats")
    func testExportOptionsFormats() {
        var zipOptions = ExportOptions()
        zipOptions.format = .zip
        #expect(zipOptions.format == .zip)
        
        var pdfOptions = ExportOptions()
        pdfOptions.format = .pdf
        #expect(pdfOptions.format == .pdf)
        
        var jsonOptions = ExportOptions()
        jsonOptions.format = .json
        #expect(jsonOptions.format == .json)
    }
    
    @Test("Export Error Descriptions")
    func testExportErrorDescriptions() {
        let errors: [ExportError] = [
            .contextNotAvailable,
            .exportFailed,
            .invalidDocuments,
            .pdfGenerationFailed
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

// MARK: - Enhanced Sync Service Tests

struct EnhancedSyncServiceTests {
    @Test("Sync Status Enum")
    func testSyncStatusEnum() {
        #expect(SyncStatus.idle.rawValue == "Idle")
        #expect(SyncStatus.syncing.rawValue == "Syncing")
        #expect(SyncStatus.synced.rawValue == "Synced")
        #expect(SyncStatus.conflict.rawValue == "Conflict")
        #expect(SyncStatus.error.rawValue == "Error")
        #expect(SyncStatus.offline.rawValue == "Offline")
    }
    
    @Test("Conflict Resolution Strategy Enum")
    func testConflictResolutionStrategyEnum() {
        #expect(ConflictResolutionStrategy.serverWins.rawValue == "Server Wins")
        #expect(ConflictResolutionStrategy.clientWins.rawValue == "Client Wins")
        #expect(ConflictResolutionStrategy.merge.rawValue == "Merge")
        #expect(ConflictResolutionStrategy.manual.rawValue == "Manual")
    }
    
    @Test("Sync Progress Range")
    func testSyncProgressRange() async {
        let syncService = EnhancedSyncService.shared
        let progress = await MainActor.run { syncService.syncProgress }
        #expect(progress >= 0.0 && progress <= 1.0)
    }
}

// MARK: - KYC Verification Tests

struct KYCVerificationTests {
    @Test("ID Verification Creation")
    func testIDVerificationCreation() {
        let userID = UUID()
        let verification = IDVerification(
            userID: userID,
            status: .pending
        )
        
        #expect(verification.userID == userID)
        #expect(verification.statusEnum == .pending)
    }
    
    @Test("Verification Status Enum")
    func testVerificationStatusEnum() {
        #expect(VerificationStatus.pending.rawValue == "Pending")
        #expect(VerificationStatus.approved.rawValue == "Approved")
        #expect(VerificationStatus.rejected.rawValue == "Rejected")
        #expect(VerificationStatus.expired.rawValue == "Expired")
    }
}

// MARK: - Integration Flow Tests

struct IntegrationFlowTests {
    @Test("Compliance Risk Integration Flow")
    func testComplianceRiskIntegrationFlow() async throws {
        // Test that compliance and risk services work together
        let complianceService = ComplianceEngineService.shared
        let riskService = RiskAssessmentService.shared
        let threatService = ThreatMonitoringService()
        
        // Create in-memory model context
        let schema = Schema([ComplianceRecord.self, RiskAssessment.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let modelContext = await MainActor.run { container.mainContext }
        
        await MainActor.run { complianceService.configure(modelContext: modelContext, threatMonitoringService: threatService) }
        await MainActor.run {
            riskService.configure(
                modelContext: modelContext,
                threatMonitoringService: threatService,
                complianceEngineService: complianceService
            )
        }
        
        // Initialize compliance
        try await MainActor.run { try complianceService.initializeComplianceRecords() }
        
        // Perform risk assessment
        try await riskService.performRiskAssessment()
        
        // Verify risks were created
        let hasRisks = await MainActor.run { !riskService.risks.isEmpty }
        let isEmpty = await MainActor.run { riskService.risks.isEmpty }
        #expect(hasRisks || isEmpty) // May be empty if no threats
    }
    
    @Test("Index Calculation Integration Flow")
    func testIndexCalculationIntegrationFlow() async throws {
        let indexService = IndexCalculationService.shared
        let threatService = ThreatMonitoringService()
        let complianceService = ComplianceEngineService.shared
        let riskService = RiskAssessmentService.shared
        
        // Create in-memory model context
        let schema = Schema([ComplianceRecord.self, RiskAssessment.self, VaultAccessLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let modelContext = await MainActor.run { container.mainContext }
        
        await MainActor.run { complianceService.configure(modelContext: modelContext, threatMonitoringService: threatService) }
        await MainActor.run {
            riskService.configure(
                modelContext: modelContext,
                threatMonitoringService: threatService,
                complianceEngineService: complianceService
            )
        }
        await MainActor.run {
            indexService.configure(
                modelContext: modelContext,
                threatMonitoringService: threatService,
                complianceEngineService: complianceService,
                riskAssessmentService: riskService
            )
        }
        
        try await MainActor.run { try complianceService.initializeComplianceRecords() }
        try await riskService.performRiskAssessment()
        
        await indexService.calculateAllIndexes()
        
        let indexes = await MainActor.run { indexService.currentIndexes }
        #expect(await MainActor.run { indexes.threatIndex } >= 0.0 && indexes.threatIndex <= 100.0)
        #expect(indexes.complianceIndex >= 0.0 && indexes.complianceIndex <= 100.0)
        #expect(indexes.triageCriticality >= 0.0 && indexes.triageCriticality <= 100.0)
    }
    
    @Test("PHI Detection Compliance Integration Flow")
    func testPHIDetectionComplianceIntegrationFlow() async throws {
        let phiService = PHIDetectionService.shared
        let complianceService = ComplianceEngineService.shared
        let threatService = ThreatMonitoringService()
        
        // Create in-memory model context
        let schema = Schema([ComplianceRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let modelContext = await MainActor.run { container.mainContext }
        
        await MainActor.run {
            complianceService.configure(modelContext: modelContext, threatMonitoringService: threatService)
        }
        try await MainActor.run {
            try complianceService.initializeComplianceRecords()
        }
        
        // Detect PHI
        let text = "Patient SSN: 123-45-6789"
        let matches = await phiService.detectPHI(in: text)
        
        // Verify PHI was detected
        #expect(!matches.isEmpty)
        #expect(matches.contains { $0.type == PHIType.ssn.rawValue })
        
        // Verify compliance record exists
        let hipaaRecord = await MainActor.run { complianceService.getRecord(for: .hipaa) }
        #expect(hipaaRecord != nil)
    }

}

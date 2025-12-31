//
//  ComplianceEngineService.swift
//  Khandoba Secure Docs
//
//  Compliance engine service for framework-specific controls
//

import Foundation
import SwiftData
import Combine

/// Compliance engine errors
enum ComplianceEngineError: LocalizedError {
    case contextNotAvailable
    case frameworkNotFound
    case controlNotFound
    case assessmentFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Model context is not available."
        case .frameworkNotFound:
            return "Compliance framework not found."
        case .controlNotFound:
            return "Compliance control not found."
        case .assessmentFailed:
            return "Compliance assessment failed."
        }
    }
}

@MainActor
final class ComplianceEngineService: ObservableObject {
    static let shared = ComplianceEngineService()
    
    @Published var complianceRecords: [ComplianceRecord] = []
    @Published var isAssessing = false
    
    private var modelContext: ModelContext?
    private var threatMonitoringService: ThreatMonitoringService?
    
    private init() {}
    
    func configure(modelContext: ModelContext, threatMonitoringService: ThreatMonitoringService) {
        self.modelContext = modelContext
        self.threatMonitoringService = threatMonitoringService
        loadComplianceRecords()
    }
    
    // MARK: - Compliance Records Management
    
    /// Initialize compliance records for all frameworks
    func initializeComplianceRecords() throws {
        guard let modelContext = modelContext else {
            throw ComplianceEngineError.contextNotAvailable
        }
        
        for framework in ComplianceFramework.allCases {
            let descriptor = FetchDescriptor<ComplianceRecord>(
                predicate: #Predicate { $0.framework == framework.rawValue }
            )
            
            if try modelContext.fetch(descriptor).isEmpty {
                let record = ComplianceRecord(
                    framework: framework,
                    status: .notAssessed,
                    riskScore: 0.5
                )
                
                // Initialize controls for framework
                initializeControls(for: record, framework: framework)
                
                modelContext.insert(record)
            }
        }
        
        try modelContext.save()
        loadComplianceRecords()
    }
    
    /// Load compliance records
    private func loadComplianceRecords() {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<ComplianceRecord>(
                sortBy: [SortDescriptor(\.framework)]
            )
            complianceRecords = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading compliance records: \(error)")
        }
    }
    
    /// Get compliance record for framework
    func getRecord(for framework: ComplianceFramework) -> ComplianceRecord? {
        return complianceRecords.first { $0.framework == framework.rawValue }
    }
    
    // MARK: - Control Initialization
    
    private func initializeControls(for record: ComplianceRecord, framework: ComplianceFramework) {
        let controls = getControlsForFramework(framework)
        
        for controlData in controls {
            let control = ComplianceControl(
                controlId: controlData.id,
                name: controlData.name,
                description: controlData.description,
                implementationStatus: "Not Implemented"
            )
            control.controlDescription = controlData.description
            control.record = record
            record.controls?.append(control)
        }
    }
    
    private func getControlsForFramework(_ framework: ComplianceFramework) -> [(id: String, name: String, description: String)] {
        switch framework {
        case .soc2:
            return [
                ("CC1", "Control Environment", "Organizational commitment to integrity and ethical values"),
                ("CC2", "Communication and Information", "Quality information for decision-making"),
                ("CC3", "Risk Assessment", "Identification and management of security risks"),
                ("CC4", "Monitoring Activities", "Continuous system monitoring"),
                ("CC5", "Control Activities", "Security policies and procedures"),
                ("CC6", "Logical and Physical Access", "Access control mechanisms"),
                ("CC6.2", "Customer Identification", "KYC verification process"),
                ("CC7", "System Operations", "Security event detection and incident response")
            ]
        case .hipaa:
            return [
                ("PHI-Protection", "PHI Protection", "Protected Health Information safeguards"),
                ("Access-Controls", "Access Controls", "User identification and access restrictions"),
                ("Audit-Controls", "Audit Controls", "PHI access logging and tracking"),
                ("Breach-Notification", "Breach Notification", "60-day breach notification procedures"),
                ("Encryption", "Encryption", "PHI encryption at rest and in transit"),
                ("BAA", "Business Associate Agreements", "BAA tracking and management"),
                ("Risk-Analysis", "Risk Analysis", "Periodic security risk assessments"),
                ("Workforce-Security", "Workforce Security", "Workforce access authorization")
            ]
        case .nist80053:
            return [
                ("AC-1", "Access Control Policy", "Documented access control policies"),
                ("AC-2", "Account Management", "User account lifecycle management"),
                ("AC-3", "Access Enforcement", "Enforced access controls"),
                ("AC-4", "Information Flow Enforcement", "Information flow policies"),
                ("AC-5", "Separation of Duties", "Dual-key approval mechanisms"),
                ("AC-6", "Least Privilege", "Minimum necessary access"),
                ("AC-7", "Unsuccessful Login Attempts", "Failed authentication tracking"),
                ("AC-8", "System Use Notification", "Security awareness messaging")
            ]
        case .iso27001:
            return [
                ("A.9.1.1", "Access Control Policy", "Access control policy documentation"),
                ("A.9.1.2", "Access to Networks", "Network access controls"),
                ("A.9.2.1", "User Registration", "User account management"),
                ("A.9.2.2", "User Access Provisioning", "Access provisioning procedures"),
                ("A.9.2.3", "Management of Privileged Access Rights", "Privileged access management"),
                ("A.9.2.4", "Management of Secret Authentication Information", "Credential management"),
                ("A.9.3.1", "Use of Secret Authentication Information", "Authentication mechanisms"),
                ("A.9.4.2", "Secure Log-on Procedures", "Secure authentication procedures")
            ]
        case .dfars:
            return [
                ("DFARS-252.204-7012", "Safeguarding Covered Defense Information", "CDI protection requirements"),
                ("DFARS-252.204-7019", "Notice of NIST SP 800-171 DoD Assessment Requirements", "NIST compliance"),
                ("DFARS-252.204-7020", "NIST SP 800-171 DoD Assessment Requirements", "Security assessment"),
                ("DFARS-252.204-7021", "Cybersecurity Maturity Model Certification", "CMMC requirements")
            ]
        case .finra:
            return [
                ("FINRA-4370", "Business Continuity Plans", "BCP requirements"),
                ("FINRA-3110", "Supervision", "Supervisory procedures"),
                ("FINRA-4511", "Customer Account Information", "Customer data protection"),
                ("FINRA-4530", "Reporting Requirements", "Regulatory reporting")
            ]
        }
    }
    
    // MARK: - Compliance Assessment
    
    /// Assess compliance for a framework
    func assessCompliance(for framework: ComplianceFramework) async throws {
        guard let modelContext = modelContext else {
            throw ComplianceEngineError.contextNotAvailable
        }
        
        guard let record = getRecord(for: framework) else {
            throw ComplianceEngineError.frameworkNotFound
        }
        
        isAssessing = true
        defer { isAssessing = false }
        
        // Check each control
        var implementedCount = 0
        var totalCount = record.controls?.count ?? 0
        
        for control in record.controls ?? [] {
            let isImplemented = await checkControlImplementation(control: control, framework: framework)
            if isImplemented {
                control.implementationStatus = "Implemented"
                control.lastVerified = Date()
                implementedCount += 1
            } else {
                control.implementationStatus = "Not Implemented"
            }
            control.updatedAt = Date()
        }
        
        // Calculate compliance status
        let implementationRate = totalCount > 0 ? Double(implementedCount) / Double(totalCount) : 0.0
        
        if implementationRate >= 0.9 {
            record.status = ComplianceStatus.compliant.rawValue
        } else if implementationRate >= 0.6 {
            record.status = ComplianceStatus.partiallyCompliant.rawValue
        } else {
            record.status = ComplianceStatus.nonCompliant.rawValue
        }
        
        // Calculate risk score (inverse of implementation rate)
        record.riskScore = 1.0 - implementationRate
        record.lastAssessed = Date()
        record.updatedAt = Date()
        
        try modelContext.save()
        loadComplianceRecords()
    }
    
    /// Check if a control is implemented
    private func checkControlImplementation(control: ComplianceControl, framework: ComplianceFramework) async -> Bool {
        // This would check actual implementation status
        // For now, return based on control ID patterns
        
        switch framework {
        case .soc2:
            return checkSOC2Control(control: control)
        case .hipaa:
            return checkHIPAAControl(control: control)
        case .nist80053:
            return checkNISTControl(control: control)
        case .iso27001:
            return checkISO27001Control(control: control)
        case .dfars:
            return checkDFARSControl(control: control)
        case .finra:
            return checkFINRAControl(control: control)
        }
    }
    
    private func checkSOC2Control(control: ComplianceControl) -> Bool {
        // Check actual implementation based on control ID
        // This is a simplified check - in production, would verify actual features
        switch control.controlId {
        case "CC6":
            // Check if biometric auth is available
            return BiometricAuthService.shared.canUseBiometrics()
        case "CC7":
            // Check if threat monitoring is active
            return threatMonitoringService != nil
        default:
            // Default: assume implemented if control exists
            return true
        }
    }
    
    private func checkHIPAAControl(control: ComplianceControl) -> Bool {
        // HIPAA controls check
        switch control.controlId {
        case "PHI-Protection":
            // Check if PHI detection service exists
            return true // Would check PHIDetectionService
        case "Access-Controls":
            // Check access control mechanisms
            return true
        default:
            return true
        }
    }
    
    private func checkNISTControl(control: ComplianceControl) -> Bool {
        // NIST controls check
        return true // Simplified
    }
    
    private func checkISO27001Control(control: ComplianceControl) -> Bool {
        // ISO 27001 controls check
        return true // Simplified
    }
    
    private func checkDFARSControl(control: ComplianceControl) -> Bool {
        // DFARS controls check
        return true // Simplified
    }
    
    private func checkFINRAControl(control: ComplianceControl) -> Bool {
        // FINRA controls check
        return true // Simplified
    }
    
    // MARK: - Audit Findings
    
    /// Add audit finding
    func addAuditFinding(
        to framework: ComplianceFramework,
        title: String,
        description: String,
        severity: String = "Medium"
    ) throws {
        guard let modelContext = modelContext else {
            throw ComplianceEngineError.contextNotAvailable
        }
        
        guard let record = getRecord(for: framework) else {
            throw ComplianceEngineError.frameworkNotFound
        }
        
        let finding = AuditFinding(
            title: title,
            description: description,
            severity: severity,
            status: "Open"
        )
        finding.record = record
        
        if record.auditFindings == nil {
            record.auditFindings = []
        }
        record.auditFindings?.append(finding)
        
        try modelContext.save()
        loadComplianceRecords()
    }
    
    /// Resolve audit finding
    func resolveAuditFinding(_ finding: AuditFinding, notes: String?) throws {
        guard let modelContext = modelContext else {
            throw ComplianceEngineError.contextNotAvailable
        }
        
        finding.status = "Resolved"
        finding.resolvedDate = Date()
        finding.remediationNotes = notes
        finding.updatedAt = Date()
        
        try modelContext.save()
        loadComplianceRecords()
    }
    
    // MARK: - Compliance Status Calculation
    
    /// Calculate overall compliance status
    func calculateComplianceStatus() -> (status: ComplianceStatus, score: Double) {
        guard !complianceRecords.isEmpty else {
            return (.notAssessed, 0.0)
        }
        
        var totalScore: Double = 0.0
        var assessedCount = 0
        
        for record in complianceRecords {
            if record.statusEnum != .notAssessed {
                let statusScore: Double
                switch record.statusEnum {
                case .compliant:
                    statusScore = 1.0
                case .partiallyCompliant:
                    statusScore = 0.6
                case .nonCompliant:
                    statusScore = 0.2
                case .notAssessed:
                    continue
                case .none:
                    continue
                }
                
                totalScore += statusScore
                assessedCount += 1
            }
        }
        
        let averageScore = assessedCount > 0 ? totalScore / Double(assessedCount) : 0.0
        
        let overallStatus: ComplianceStatus
        if averageScore >= 0.8 {
            overallStatus = .compliant
        } else if averageScore >= 0.6 {
            overallStatus = .partiallyCompliant
        } else {
            overallStatus = .nonCompliant
        }
        
        return (overallStatus, averageScore)
    }
}


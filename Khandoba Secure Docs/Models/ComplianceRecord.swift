//
//  ComplianceRecord.swift
//  Khandoba Secure Docs
//
//  Compliance framework tracking model
//

import Foundation
import SwiftData

/// Compliance framework types
enum ComplianceFramework: String, Codable, CaseIterable {
    case soc2 = "SOC 2"
    case hipaa = "HIPAA"
    case nist80053 = "NIST 800-53"
    case iso27001 = "ISO 27001"
    case dfars = "DFARS"
    case finra = "FINRA"
    
    var displayName: String {
        return rawValue
    }
}

/// Compliance status
enum ComplianceStatus: String, Codable {
    case compliant = "Compliant"
    case partiallyCompliant = "Partially Compliant"
    case nonCompliant = "Non-Compliant"
    case notAssessed = "Not Assessed"
}

@Model
final class ComplianceRecord {
    var id: UUID = UUID()
    var framework: String // ComplianceFramework rawValue
    var status: String // ComplianceStatus rawValue
    var riskScore: Double = 0.0 // 0.0 to 1.0
    var lastAssessed: Date = Date()
    var nextAssessment: Date?
    var notes: String?
    
    @Relationship(deleteRule: .cascade, inverse: \ComplianceControl.record)
    var controls: [ComplianceControl]?
    
    @Relationship(deleteRule: .cascade, inverse: \AuditFinding.record)
    var auditFindings: [AuditFinding]?
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        framework: ComplianceFramework,
        status: ComplianceStatus = .notAssessed,
        riskScore: Double = 0.0
    ) {
        self.framework = framework.rawValue
        self.status = status.rawValue
        self.riskScore = riskScore
    }
    
    var frameworkEnum: ComplianceFramework? {
        ComplianceFramework(rawValue: framework)
    }
    
    var statusEnum: ComplianceStatus? {
        ComplianceStatus(rawValue: status)
    }
}

@Model
final class ComplianceControl {
    var id: UUID = UUID()
    var controlId: String // e.g., "CC1", "AC-1", "A.9.1.1"
    var name: String
    var controlDescription: String?
    var implementationStatus: String // "Implemented", "In Progress", "Not Implemented"
    var lastVerified: Date?
    var notes: String?
    
    @Relationship(deleteRule: .nullify)
    var record: ComplianceRecord?
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        controlId: String,
        name: String,
        description: String? = nil,
        implementationStatus: String = "Not Implemented"
    ) {
        self.controlId = controlId
        self.name = name
        self.controlDescription = description
        self.implementationStatus = implementationStatus
    }
}

@Model
final class AuditFinding {
    var id: UUID = UUID()
    var title: String
    var findingDescription: String
    var severity: String // "Low", "Medium", "High", "Critical"
    var status: String // "Open", "In Progress", "Resolved", "Closed"
    var discoveredDate: Date = Date()
    var resolvedDate: Date?
    var remediationNotes: String?
    
    @Relationship(deleteRule: .nullify)
    var record: ComplianceRecord?
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        title: String,
        description: String,
        severity: String = "Medium",
        status: String = "Open"
    ) {
        self.title = title
        self.findingDescription = description
        self.severity = severity
        self.status = status
    }
}


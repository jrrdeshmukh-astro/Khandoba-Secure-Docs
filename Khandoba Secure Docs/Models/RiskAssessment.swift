//
//  RiskAssessment.swift
//  Khandoba Secure Docs
//
//  Risk assessment model
//

import Foundation
import SwiftData

/// Risk severity levels
enum RiskSeverity: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

/// Risk status
enum RiskStatus: String, Codable {
    case identified = "Identified"
    case assessed = "Assessed"
    case mitigated = "Mitigated"
    case accepted = "Accepted"
    case closed = "Closed"
}

@Model
final class RiskAssessment {
    var id: UUID = UUID()
    var title: String
    var riskDescription: String
    var severity: String // RiskSeverity rawValue
    var status: String // RiskStatus rawValue
    var riskScore: Double = 0.0 // 0.0 to 1.0
    var likelihood: Double = 0.0 // 0.0 to 1.0
    var impact: Double = 0.0 // 0.0 to 1.0
    var mitigationPlan: String?
    var mitigationStatus: String? // "Not Started", "In Progress", "Completed"
    var identifiedDate: Date = Date()
    var assessedDate: Date?
    var mitigatedDate: Date?
    var nextReviewDate: Date?
    var notes: String?
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        title: String,
        riskDescription: String,
        severity: RiskSeverity = .medium,
        riskScore: Double = 0.0
    ) {
        self.title = title
        self.riskDescription = riskDescription
        self.severity = severity.rawValue
        self.status = RiskStatus.identified.rawValue
        self.riskScore = riskScore
    }
    
    var severityEnum: RiskSeverity? {
        RiskSeverity(rawValue: severity)
    }
    
    var statusEnum: RiskStatus? {
        RiskStatus(rawValue: status)
    }
}


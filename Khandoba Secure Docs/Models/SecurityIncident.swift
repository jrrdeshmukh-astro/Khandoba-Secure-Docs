//
//  SecurityIncident.swift
//  Khandoba Secure Docs
//
//  Security incident model
//

import Foundation
import SwiftData

/// Incident severity levels
enum IncidentSeverity: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

/// Incident status
enum IncidentStatus: String, Codable {
    case detected = "Detected"
    case triaged = "Triaged"
    case contained = "Contained"
    case resolved = "Resolved"
    case closed = "Closed"
}

/// Incident classification
enum IncidentClassification: String, Codable, CaseIterable {
    case unauthorizedAccess = "Unauthorized Access"
    case dataBreach = "Data Breach"
    case malware = "Malware"
    case phishing = "Phishing"
    case insiderThreat = "Insider Threat"
    case systemCompromise = "System Compromise"
    case other = "Other"
}

@Model
final class SecurityIncident {
    var id: UUID = UUID()
    var title: String
    var incidentDescription: String
    var classification: String // IncidentClassification rawValue
    var severity: String // IncidentSeverity rawValue
    var status: String // IncidentStatus rawValue
    var detectedDate: Date = Date()
    var triagedDate: Date?
    var containedDate: Date?
    var resolvedDate: Date?
    var closedDate: Date?
    var containmentActions: String?
    var recoveryActions: String?
    var postMortemNotes: String?
    var affectedVaults: [UUID] = []
    var affectedUsers: [UUID] = []
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        title: String,
        incidentDescription: String,
        classification: IncidentClassification = .other,
        severity: IncidentSeverity = .medium
    ) {
        self.title = title
        self.incidentDescription = incidentDescription
        self.classification = classification.rawValue
        self.severity = severity.rawValue
        self.status = IncidentStatus.detected.rawValue
    }
    
    var classificationEnum: IncidentClassification? {
        IncidentClassification(rawValue: classification)
    }
    
    var severityEnum: IncidentSeverity? {
        IncidentSeverity(rawValue: severity)
    }
    
    var statusEnum: IncidentStatus? {
        IncidentStatus(rawValue: status)
    }
}


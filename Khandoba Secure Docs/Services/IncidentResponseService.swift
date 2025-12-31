//
//  IncidentResponseService.swift
//  Khandoba Secure Docs
//
//  Incident response service
//

import Foundation
import SwiftData
import Combine

@MainActor
final class IncidentResponseService: ObservableObject {
    static let shared = IncidentResponseService()
    
    @Published var incidents: [SecurityIncident] = []
    @Published var isProcessing = false
    
    private var modelContext: ModelContext?
    private var threatMonitoringService: ThreatMonitoringService?
    
    private init() {}
    
    func configure(modelContext: ModelContext, threatMonitoringService: ThreatMonitoringService) {
        self.modelContext = modelContext
        self.threatMonitoringService = threatMonitoringService
        loadIncidents()
        startMonitoring()
    }
    
    // MARK: - Incident Management
    
    private func loadIncidents() {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<SecurityIncident>(
                sortBy: [SortDescriptor(\.detectedDate, order: .reverse)]
            )
            incidents = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading incidents: \(error)")
        }
    }
    
    /// Start monitoring for security incidents
    private func startMonitoring() {
        // Monitor threat service for automatic incident detection
        Task {
            while true {
                await checkForIncidents()
                try? await Task.sleep(nanoseconds: 30_000_000_000) // Check every 30 seconds
            }
        }
    }
    
    /// Check for new security incidents
    private func checkForIncidents() async {
        guard let threatService = threatMonitoringService,
              let modelContext = modelContext else { return }
        
        // Check for critical threats
        if threatService.anomalyScore > 80 {
            // Check if incident already exists
            let recentIncidents = incidents.filter {
                $0.detectedDate > Date().addingTimeInterval(-3600) // Last hour
            }
            
            if recentIncidents.isEmpty {
                let incident = SecurityIncident(
                    title: "Critical Threat Detected",
                    incidentDescription: "Threat monitoring detected critical security threat (Score: \(Int(threatService.anomalyScore)))",
                    classification: .unauthorizedAccess,
                    severity: .critical
                )
                
                modelContext.insert(incident)
                try? modelContext.save()
                loadIncidents()
                
                // Send notification
                await sendIncidentNotification(incident)
            }
        }
    }
    
    /// Create incident manually
    func createIncident(
        title: String,
        description: String,
        classification: IncidentClassification,
        severity: IncidentSeverity
    ) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        let incident = SecurityIncident(
            title: title,
            incidentDescription: description,
            classification: classification,
            severity: severity
        )
        
        modelContext.insert(incident)
        try modelContext.save()
        loadIncidents()
        
        Task {
            await sendIncidentNotification(incident)
        }
    }
    
    /// Triage incident
    func triageIncident(_ incident: SecurityIncident, classification: IncidentClassification) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        incident.classification = classification.rawValue
        incident.status = IncidentStatus.triaged.rawValue
        incident.triagedDate = Date()
        incident.updatedAt = Date()
        
        try modelContext.save()
        loadIncidents()
    }
    
    /// Contain incident
    func containIncident(_ incident: SecurityIncident, actions: String) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        incident.status = IncidentStatus.contained.rawValue
        incident.containedDate = Date()
        incident.containmentActions = actions
        incident.updatedAt = Date()
        
        try modelContext.save()
        loadIncidents()
    }
    
    /// Resolve incident
    func resolveIncident(_ incident: SecurityIncident, recoveryActions: String) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        incident.status = IncidentStatus.resolved.rawValue
        incident.resolvedDate = Date()
        incident.recoveryActions = recoveryActions
        incident.updatedAt = Date()
        
        try modelContext.save()
        loadIncidents()
    }
    
    /// Close incident with post-mortem
    func closeIncident(_ incident: SecurityIncident, postMortem: String) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        incident.status = IncidentStatus.closed.rawValue
        incident.closedDate = Date()
        incident.postMortemNotes = postMortem
        incident.updatedAt = Date()
        
        try modelContext.save()
        loadIncidents()
    }
    
    // MARK: - Notifications
    
    private func sendIncidentNotification(_ incident: SecurityIncident) async {
        // Send push notification for critical incidents
        if incident.severityEnum == .critical {
            // Use PushNotificationService if available
            // This would integrate with existing notification system
        }
    }
}


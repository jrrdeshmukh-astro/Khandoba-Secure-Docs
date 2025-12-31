//
//  RiskAssessmentService.swift
//  Khandoba Secure Docs
//
//  Risk assessment service
//

import Foundation
import SwiftData
import Combine

@MainActor
final class RiskAssessmentService: ObservableObject {
    static let shared = RiskAssessmentService()
    
    @Published var risks: [RiskAssessment] = []
    @Published var isAssessing = false
    
    private var modelContext: ModelContext?
    private var threatMonitoringService: ThreatMonitoringService?
    private var complianceEngineService: ComplianceEngineService?
    
    private init() {}
    
    func configure(
        modelContext: ModelContext,
        threatMonitoringService: ThreatMonitoringService,
        complianceEngineService: ComplianceEngineService
    ) {
        self.modelContext = modelContext
        self.threatMonitoringService = threatMonitoringService
        self.complianceEngineService = complianceEngineService
        loadRisks()
    }
    
    // MARK: - Risk Management
    
    private func loadRisks() {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<RiskAssessment>(
                sortBy: [SortDescriptor(\.riskScore, order: .reverse)]
            )
            risks = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading risks: \(error)")
        }
    }
    
    /// Perform automated risk assessment
    func performRiskAssessment() async throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        isAssessing = true
        defer { isAssessing = false }
        
        // Assess risks from threat monitoring
        if let threatService = threatMonitoringService {
            await assessThreatRisks(threatService: threatService, modelContext: modelContext)
        }
        
        // Assess risks from compliance
        if let complianceService = complianceEngineService {
            await assessComplianceRisks(complianceService: complianceService, modelContext: modelContext)
        }
        
        try modelContext.save()
        loadRisks()
    }
    
    private func assessThreatRisks(threatService: ThreatMonitoringService, modelContext: ModelContext) async {
        // Check for high threat levels
        if threatService.anomalyScore > 60 {
            let risk = RiskAssessment(
                title: "High Threat Level Detected",
                riskDescription: "System threat monitoring has detected elevated threat levels (Score: \(Int(threatService.anomalyScore)))",
                severity: .high,
                riskScore: threatService.anomalyScore / 100.0
            )
            risk.likelihood = 0.7
            risk.impact = 0.8
            modelContext.insert(risk)
        }
    }
    
    private func assessComplianceRisks(complianceService: ComplianceEngineService, modelContext: ModelContext) async {
        for record in complianceService.complianceRecords {
            if record.riskScore > 0.5 {
                let risk = RiskAssessment(
                    title: "Compliance Risk: \(record.framework)",
                    riskDescription: "\(record.framework) compliance status is \(record.status) with risk score of \(String(format: "%.2f", record.riskScore))",
                    severity: record.riskScore > 0.7 ? .high : .medium,
                    riskScore: record.riskScore
                )
                risk.likelihood = record.riskScore
                risk.impact = 0.6
                modelContext.insert(risk)
            }
        }
    }
    
    /// Add manual risk
    func addRisk(
        title: String,
        description: String,
        severity: RiskSeverity,
        likelihood: Double,
        impact: Double
    ) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        let riskScore = likelihood * impact
        let risk = RiskAssessment(
            title: title,
            riskDescription: description,
            severity: severity,
            riskScore: riskScore
        )
        risk.likelihood = likelihood
        risk.impact = impact
        risk.assessedDate = Date()
        risk.status = RiskStatus.assessed.rawValue
        
        modelContext.insert(risk)
        try modelContext.save()
        loadRisks()
    }
    
    /// Update risk mitigation
    func updateRiskMitigation(_ risk: RiskAssessment, plan: String, status: String) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        risk.mitigationPlan = plan
        risk.mitigationStatus = status
        risk.updatedAt = Date()
        
        if status == "Completed" {
            risk.mitigatedDate = Date()
            risk.status = RiskStatus.mitigated.rawValue
        }
        
        try modelContext.save()
        loadRisks()
    }
}


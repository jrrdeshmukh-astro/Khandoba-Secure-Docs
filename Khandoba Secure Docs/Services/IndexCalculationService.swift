//
//  IndexCalculationService.swift
//  Khandoba Secure Docs
//
//  Real-time index calculation service
//

import Foundation
import SwiftData
import Combine

/// Index calculation result
struct IndexResult {
    let threatIndex: Double // 0-100
    let complianceIndex: Double // 0-100
    let triageCriticality: Double // 0-100
    let calculatedAt: Date
}

@MainActor
final class IndexCalculationService: ObservableObject {
    static let shared = IndexCalculationService()
    
    @Published var currentIndexes = IndexResult(
        threatIndex: 0.0,
        complianceIndex: 0.0,
        triageCriticality: 0.0,
        calculatedAt: Date()
    )
    
    private var modelContext: ModelContext?
    private var threatMonitoringService: ThreatMonitoringService?
    private var complianceEngineService: ComplianceEngineService?
    private var riskAssessmentService: RiskAssessmentService?
    private var timer: Timer?
    
    private init() {
        startPeriodicCalculation()
    }
    
    func configure(
        modelContext: ModelContext,
        threatMonitoringService: ThreatMonitoringService,
        complianceEngineService: ComplianceEngineService,
        riskAssessmentService: RiskAssessmentService
    ) {
        self.modelContext = modelContext
        self.threatMonitoringService = threatMonitoringService
        self.complianceEngineService = complianceEngineService
        self.riskAssessmentService = riskAssessmentService
        
        // Calculate immediately
        Task {
            await calculateAllIndexes()
        }
    }
    
    // MARK: - Index Calculation
    
    /// Calculate all indexes
    func calculateAllIndexes() async {
        let threatIndex = await calculateThreatIndex()
        let complianceIndex = await calculateComplianceIndex()
        let triageCriticality = await calculateTriageCriticality()
        
        await MainActor.run {
            currentIndexes = IndexResult(
                threatIndex: threatIndex,
                complianceIndex: complianceIndex,
                triageCriticality: triageCriticality,
                calculatedAt: Date()
            )
        }
    }
    
    /// Calculate Threat Index (0-100)
    private func calculateThreatIndex() async -> Double {
        guard let threatService = threatMonitoringService,
              let modelContext = modelContext else {
            return 0.0
        }
        
        // Anomaly Score (40% weight)
        let anomalyScore = threatService.anomalyScore
        
        // Recent Threat Events (30% weight)
        let recentThreats = await calculateRecentThreatEvents(modelContext: modelContext)
        
        // Access Pattern Anomalies (20% weight)
        let accessPatternAnomalies = await calculateAccessPatternAnomalies(modelContext: modelContext)
        
        // Failed Authentication (10% weight)
        let failedAuth = await calculateFailedAuthentication(modelContext: modelContext)
        
        // Weighted calculation
        let threatIndex = (anomalyScore * 0.40) + (recentThreats * 0.30) + (accessPatternAnomalies * 0.20) + (failedAuth * 0.10)
        
        return min(100.0, max(0.0, threatIndex))
    }
    
    /// Calculate Compliance Index (0-100)
    private func calculateComplianceIndex() async -> Double {
        guard let complianceService = complianceEngineService else {
            return 0.0
        }
        
        let (status, score) = complianceService.calculateComplianceStatus()
        
        // Framework Status Score (50% weight)
        let frameworkStatusScore: Double
        switch status {
        case .compliant:
            frameworkStatusScore = 100.0
        case .partiallyCompliant:
            frameworkStatusScore = 60.0
        case .nonCompliant:
            frameworkStatusScore = 20.0
        case .notAssessed:
            frameworkStatusScore = 50.0
        }
        
        // Control Implementation Rate (30% weight)
        var totalControls = 0
        var implementedControls = 0
        
        for record in complianceService.complianceRecords {
            let controls = record.controls ?? []
            totalControls += controls.count
            implementedControls += controls.filter { $0.implementationStatus == "Implemented" }.count
        }
        
        let implementationRate = totalControls > 0 ? (Double(implementedControls) / Double(totalControls)) * 100.0 : 0.0
        
        // Risk Score Inverse (10% weight)
        let averageRiskScore = complianceService.complianceRecords.isEmpty ? 0.0 :
            complianceService.complianceRecords.map { $0.riskScore }.reduce(0.0, +) / Double(complianceService.complianceRecords.count)
        let riskScoreInverse = (1.0 - averageRiskScore) * 100.0
        
        // Audit Findings Score (10% weight)
        var totalFindings = 0
        var criticalFindings = 0
        
        for record in complianceService.complianceRecords {
            let findings = record.auditFindings ?? []
            totalFindings += findings.count
            criticalFindings += findings.filter { $0.severity == "Critical" || $0.severity == "High" }.count
        }
        
        let findingsScore = totalFindings > 0 ? max(0.0, 100.0 - (Double(criticalFindings) / Double(totalFindings)) * 100.0) : 100.0
        
        // Weighted calculation
        let complianceIndex = (frameworkStatusScore * 0.50) + (implementationRate * 0.30) + (riskScoreInverse * 0.10) + (findingsScore * 0.10)
        
        return min(100.0, max(0.0, complianceIndex))
    }
    
    /// Calculate Triage Criticality Index (0-100)
    private func calculateTriageCriticality() async -> Double {
        guard let threatService = threatMonitoringService,
              let complianceService = complianceEngineService,
              let riskService = riskAssessmentService else {
            return 0.0
        }
        
        // Threat Criticality (35% weight)
        let threatCriticality = threatService.anomalyScore
        
        // Compliance Violations (30% weight)
        var violationScore = 0.0
        for record in complianceService.complianceRecords {
            if record.statusEnum == .nonCompliant {
                violationScore += 100.0
            } else if record.statusEnum == .partiallyCompliant {
                violationScore += 50.0
            }
        }
        let normalizedViolations = min(100.0, violationScore / Double(max(1, complianceService.complianceRecords.count)))
        
        // Pending Actions (20% weight)
        var pendingActions = 0
        for record in complianceService.complianceRecords {
            let controls = record.controls ?? []
            pendingActions += controls.filter { $0.implementationStatus == "In Progress" || $0.implementationStatus == "Not Implemented" }.count
            if record.statusEnum == .nonCompliant {
                pendingActions += 5
            } else if record.statusEnum == .partiallyCompliant {
                pendingActions += 2
            }
        }
        let pendingActionsScore = min(100.0, (Double(pendingActions) / 50.0) * 100.0)
        
        // Risk Exposure (15% weight)
        let averageRiskScore = riskService.risks.isEmpty ? 0.0 :
            riskService.risks.map { $0.riskScore }.reduce(0.0, +) / Double(riskService.risks.count)
        let riskExposure = averageRiskScore * 100.0
        
        // Weighted calculation
        let triageCriticality = (threatCriticality * 0.35) + (normalizedViolations * 0.30) + (pendingActionsScore * 0.20) + (riskExposure * 0.15)
        
        return min(100.0, max(0.0, triageCriticality))
    }
    
    // MARK: - Helper Calculations
    
    private func calculateRecentThreatEvents(modelContext: ModelContext) async -> Double {
        // This would analyze recent threat events from ThreatMonitoringService
        // For now, return a simplified calculation
        guard let threatService = threatMonitoringService else {
            return 0.0
        }
        
        // Use anomaly score as proxy for recent threats
        return threatService.anomalyScore * 0.3
    }
    
    private func calculateAccessPatternAnomalies(modelContext: ModelContext) async -> Double {
        // Analyze vault access logs for anomalies
        do {
            // Calculate date outside predicate (SwiftData limitation)
            let oneDayAgo = Date().addingTimeInterval(-86400) // Last 24 hours
            let descriptor = FetchDescriptor<VaultAccessLog>(
                sortBy: [SortDescriptor(\.timestamp)]
            )
            // Filter after fetch (SwiftData Predicate doesn't support Date calculations)
            
            let allLogs = try modelContext.fetch(descriptor)
            let logs = allLogs.filter { $0.timestamp > oneDayAgo }
            
            // Check for rapid successive access (potential brute force)
            var rapidAccessCount = 0
            var previousTimestamp: Date?
            for log in logs {
                if let prev = previousTimestamp,
                   log.timestamp.timeIntervalSince(prev) < 60 { // Less than 1 minute
                    rapidAccessCount += 1
                }
                previousTimestamp = log.timestamp
            }
            
            if rapidAccessCount >= 10 {
                return 30.0 // Rapid access anomaly
            }
            
            // Check for unusual time patterns (night access)
            let nightAccessCount = logs.filter { log in
                let hour = Calendar.current.component(.hour, from: log.timestamp)
                return hour >= 22 || hour < 6
            }.count
            
            if Double(nightAccessCount) / Double(max(1, logs.count)) > 0.5 {
                return 20.0 // Unusual time pattern
            }
            
            // Check for unusual deletion patterns
            let deletionCount = logs.filter { $0.accessType == "deleted" }.count
            if Double(deletionCount) / Double(max(1, logs.count)) > 0.3 {
                return 25.0 // Unusual deletion pattern
            }
            
            return 0.0
        } catch {
            return 0.0
        }
    }
    
    private func calculateFailedAuthentication(modelContext: ModelContext) async -> Double {
        // Analyze failed authentication attempts
        // Note: VaultAccessLog doesn't track success/failure, so we'll use access type
        do {
            let oneHourAgo = Date().addingTimeInterval(-3600)
            let descriptor = FetchDescriptor<VaultAccessLog>(
                predicate: #Predicate<VaultAccessLog> { log in
                    log.timestamp > oneHourAgo && log.accessType == "failed"
                }
            )
            
            let failedLogs = try modelContext.fetch(descriptor)
            
            // Recent failures: 20 points each
            let recentFailures = failedLogs.filter { log in
                log.timestamp > Date().addingTimeInterval(-3600)
            }.count
            
            let score = min(100.0, Double(recentFailures) * 20.0)
            return score
        } catch {
            return 0.0
        }
    }
    
    // MARK: - Periodic Updates
    
    private func startPeriodicCalculation() {
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.calculateAllIndexes()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}


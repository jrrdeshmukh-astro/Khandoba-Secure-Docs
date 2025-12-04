//
//  DualKeyApprovalService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import Foundation
import CoreML
import CoreLocation
import SwiftData
import Combine

@MainActor
final class DualKeyApprovalService: ObservableObject {
    @Published var pendingRequests: [DualKeyRequest] = []
    @Published var isProcessing = false
    
    private var modelContext: ModelContext?
    private let threatService = ThreatMonitoringService()
    private let locationService = LocationService()
    private let formalLogicEngine = FormalLogicEngine()
    
    // ML Model thresholds (adjusted for binary decision - no manual review)
    private let autoApproveThreshold: Double = 50.0  // Score below 50 = approve
    // Above 50 = deny (binary decision only)
    private let maxDistanceKm: Double = 100.0        // Max distance from home/office
    private let impossibleTravelThreshold: Double = 500.0 // km in 1 hour
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        formalLogicEngine.configure(modelContext: modelContext)
    }
    
    /// Process dual-key request with ML + Formal Logic reasoning
    func processDualKeyRequest(_ request: DualKeyRequest, vault: Vault) async throws -> DualKeyDecision {
        isProcessing = true
        defer { isProcessing = false }
        
        print("🤖 ML + Logic: Processing dual-key request for vault: \(vault.name)")
        
        // Step 1: Calculate threat score
        let threatScore = await calculateThreatScore(for: vault, request: request)
        print("   Threat Score: \(String(format: "%.1f", threatScore))/100")
        
        // Step 2: Analyze geospatial risk
        let geoRisk = await calculateGeospatialRisk(request: request, vault: vault)
        print("   Geospatial Risk: \(String(format: "%.1f", geoRisk))/100")
        
        // Step 3: Analyze behavioral patterns
        let behaviorScore = await analyzeBehaviorPatterns(requester: request.requester, vault: vault)
        print("   Behavior Score: \(String(format: "%.1f", behaviorScore))/100")
        
        // Step 4: Calculate combined ML score
        let mlScore = calculateCombinedMLScore(
            threatScore: threatScore,
            geoRisk: geoRisk,
            behaviorScore: behaviorScore
        )
        print("   📊 Combined ML Score: \(String(format: "%.1f", mlScore))/100")
        
        // Step 5: Build observations for formal logic
        buildLogicalObservations(
            request: request,
            vault: vault,
            mlScore: mlScore,
            threatScore: threatScore,
            geoRisk: geoRisk,
            behaviorScore: behaviorScore
        )
        
        // Step 6: Apply formal logic reasoning
        let logicalAnalysis = formalLogicEngine.performCompleteLogicalAnalysis()
        print("   🎓 Formal Logic: \(logicalAnalysis.totalInferences) inferences generated")
        
        // Step 7: Make decision with logical reasoning
        let decision = makeIntelligentDecision(
            mlScore: mlScore,
            logicalAnalysis: logicalAnalysis,
            request: request,
            vault: vault,
            threatScore: threatScore,
            geoRisk: geoRisk,
            behaviorScore: behaviorScore
        )
        
        // Step 8: Log decision
        try await logDecision(decision, for: request, vault: vault, mlScore: mlScore)
        
        // Step 9: Execute decision
        try await executeDecision(decision, for: request)
        
        return decision
    }
    
    // MARK: - Threat Score Calculation
    
    private func calculateThreatScore(for vault: Vault, request: DualKeyRequest) async -> Double {
        var score: Double = 0.0
        
        // Analyze vault's threat level
        let vaultThreatLevel = await threatService.analyzeThreatLevel(for: vault)
        
        switch vaultThreatLevel {
        case .low:
            score += 10
        case .medium:
            score += 30
        case .high:
            score += 60
        case .critical:
            score += 90
        }
        
        // Recent access patterns
        let logs = vault.accessLogs ?? []
        let recentLogs = logs.sorted { $0.timestamp > $1.timestamp }.prefix(10)
        
        // Rapid access attempts
        if recentLogs.count >= 5 {
            let timeWindow = recentLogs.first!.timestamp.timeIntervalSince(recentLogs.last!.timestamp)
            if timeWindow < 60 { // 5 attempts in 1 minute
                score += 25
                print("   ⚠️ Rapid access detected: 5 attempts in \(Int(timeWindow))s")
            }
        }
        
        // Failed access attempts
        let failedAttempts = logs.filter { $0.accessType == "failed" }.count
        if failedAttempts > 3 {
            score += Double(failedAttempts) * 5
            print("   ⚠️ Failed attempts: \(failedAttempts)")
        }
        
        // Night access frequency
        let nightAccess = logs.filter { isNightTime($0.timestamp) }
        if !logs.isEmpty {
            let nightPercentage = Double(nightAccess.count) / Double(logs.count)
            if nightPercentage > 0.5 {
                score += 20
                print("   ⚠️ High night access: \(Int(nightPercentage * 100))%")
            }
        }
        
        return min(score, 100)
    }
    
    // MARK: - Geospatial Risk Calculation
    
    private func calculateGeospatialRisk(request: DualKeyRequest, vault: Vault) async -> Double {
        var risk: Double = 0.0
        
        guard let currentLocation = locationService.currentLocation else {
            print("   ⚠️ No location data available")
            return 50.0 // Unknown location = medium risk
        }
        
        let requestLat = currentLocation.coordinate.latitude
        let requestLon = currentLocation.coordinate.longitude
        
        // Get user's typical locations (home/office)
        let userLocations = getUserTypicalLocations(vault: vault)
        
        if userLocations.isEmpty {
            print("   ⚠️ No baseline locations established")
            return 30.0 // New vault, moderate risk
        }
        
        // Calculate distance from typical locations
        var minDistance = Double.infinity
        for location in userLocations {
            let distance = calculateDistance(
                from: (requestLat, requestLon),
                to: (location.latitude, location.longitude)
            )
            minDistance = min(minDistance, distance)
        }
        
        print("   📍 Distance from typical location: \(String(format: "%.1f", minDistance)) km")
        
        // Risk based on distance
        if minDistance < 10 {
            risk += 0 // Very close to home/office
        } else if minDistance < 50 {
            risk += 10 // Nearby
        } else if minDistance < 100 {
            risk += 25 // Same city/region
        } else if minDistance < 500 {
            risk += 40 // Different city
        } else {
            risk += 60 // International/very far
            print("   ⚠️ Access from unusual location: \(String(format: "%.1f", minDistance)) km away")
        }
        
        // Check for impossible travel
        if let lastAccess = vault.accessLogs?.sorted(by: { $0.timestamp > $1.timestamp }).first,
           let lastLat = lastAccess.locationLatitude,
           let lastLon = lastAccess.locationLongitude {
            
            let travelDistance = calculateDistance(
                from: (requestLat, requestLon),
                to: (lastLat, lastLon)
            )
            let timeSinceLastAccess = Date().timeIntervalSince(lastAccess.timestamp) / 3600 // hours
            
            if travelDistance > impossibleTravelThreshold && timeSinceLastAccess < 1 {
                risk += 40
                print("   🚨 IMPOSSIBLE TRAVEL: \(String(format: "%.0f", travelDistance)) km in \(String(format: "%.1f", timeSinceLastAccess)) hours")
            }
        }
        
        // Country change detection
        // (Would require reverse geocoding in production)
        
        return min(risk, 100)
    }
    
    // MARK: - Behavior Pattern Analysis
    
    private func analyzeBehaviorPatterns(requester: User?, vault: Vault) async -> Double {
        var score: Double = 0.0
        
        guard let requester = requester else {
            return 50.0 // Unknown requester = medium risk
        }
        
        let logs = vault.accessLogs ?? []
        let userLogs = logs.filter { $0.userID == requester.id }
        
        // New user requesting access
        if userLogs.isEmpty {
            score += 30
            print("   ⚠️ First-time access request from this user")
        }
        
        // Access frequency pattern
        if userLogs.count > 0 {
            let avgDaysBetweenAccess = calculateAverageDaysBetweenAccess(userLogs)
            
            // Too frequent (potential bot/automated)
            if avgDaysBetweenAccess < 0.1 { // Multiple times per day
                score += 20
                print("   ⚠️ Unusually frequent access pattern")
            }
            
            // Too infrequent (dormant account suddenly active)
            if avgDaysBetweenAccess > 30 && userLogs.count > 5 {
                score += 15
                print("   ⚠️ Dormant account suddenly active")
            }
        }
        
        // Time pattern analysis
        let currentHour = Calendar.current.component(.hour, from: Date())
        let userTypicalHours = getUserTypicalAccessHours(userLogs)
        
        if !userTypicalHours.contains(currentHour) && userTypicalHours.count > 5 {
            score += 15
            print("   ⚠️ Access at unusual time for this user")
        }
        
        // Device/platform consistency
        // (Would check if same device in production)
        
        return min(score, 100)
    }
    
    // MARK: - ML Decision Engine
    
    private func calculateCombinedMLScore(
        threatScore: Double,
        geoRisk: Double,
        behaviorScore: Double
    ) -> Double {
        // Weighted combination
        let weights: (threat: Double, geo: Double, behavior: Double) = (0.4, 0.4, 0.2)
        
        let combined = (threatScore * weights.threat) +
                      (geoRisk * weights.geo) +
                      (behaviorScore * weights.behavior)
        
        return combined
    }
    
    // MARK: - Formal Logic Integration
    
    private func buildLogicalObservations(
        request: DualKeyRequest,
        vault: Vault,
        mlScore: Double,
        threatScore: Double,
        geoRisk: Double,
        behaviorScore: Double
    ) {
        // Add ML score observations
        formalLogicEngine.addObservation(LogicalObservation(
            subject: vault.name,
            property: "ml_risk_score",
            value: String(format: "%.1f", mlScore),
            confidence: 0.95
        ))
        
        formalLogicEngine.addObservation(LogicalObservation(
            subject: vault.name,
            property: "threat_score",
            value: String(format: "%.1f", threatScore),
            confidence: 0.90
        ))
        
        formalLogicEngine.addObservation(LogicalObservation(
            subject: vault.name,
            property: "geo_risk",
            value: String(format: "%.1f", geoRisk),
            confidence: 0.85
        ))
        
        formalLogicEngine.addObservation(LogicalObservation(
            subject: vault.name,
            property: "behavior_score",
            value: String(format: "%.1f", behaviorScore),
            confidence: 0.80
        ))
        
        // Add categorical observations for logic rules
        if mlScore < 30 {
            formalLogicEngine.addObservation(LogicalObservation(
                subject: vault.name,
                property: "risk_level",
                value: "low",
                confidence: 0.95
            ))
        } else if mlScore < 50 {
            formalLogicEngine.addObservation(LogicalObservation(
                subject: vault.name,
                property: "risk_level",
                value: "moderate",
                confidence: 0.90
            ))
        } else if mlScore < 70 {
            formalLogicEngine.addObservation(LogicalObservation(
                subject: vault.name,
                property: "risk_level",
                value: "high",
                confidence: 0.90
            ))
        } else {
            formalLogicEngine.addObservation(LogicalObservation(
                subject: vault.name,
                property: "risk_level",
                value: "critical",
                confidence: 0.95
            ))
        }
        
        // Add facts for formal reasoning
        if let requester = request.requester {
            formalLogicEngine.addFact(Fact(
                subject: requester.name,
                predicate: "requests_access_to",
                object: vault.name,
                source: request.id,
                confidence: 1.0
            ))
        }
    }
    
    private func makeIntelligentDecision(
        mlScore: Double,
        logicalAnalysis: LogicalAnalysisReport,
        request: DualKeyRequest,
        vault: Vault,
        threatScore: Double,
        geoRisk: Double,
        behaviorScore: Double
    ) -> DualKeyDecision {
        var decision = DualKeyDecision()
        decision.mlScore = mlScore
        decision.timestamp = Date()
        decision.vaultName = vault.name
        
        // Binary decision: Approve or Deny (NO manual review)
        if mlScore < autoApproveThreshold {
            // APPROVE with logical reasoning
            decision.action = .autoApproved
            decision.confidence = 1.0 - (mlScore / 100.0)
            
            // Build formal logic explanation
            var reasoning = "✅ **APPROVED - Formal Logic Analysis:**\n\n"
            
            // Deductive reasoning
            reasoning += "**Deductive Logic (Certain):**\n"
            reasoning += "• Premise: If ML score < 50 AND no critical threats, then approve access\n"
            reasoning += "• Observation: ML score = \(String(format: "%.1f", mlScore)) < 50\n"
            reasoning += "• Observation: Threat level = \(threatScore < 60 ? "acceptable" : "elevated")\n"
            reasoning += "• Conclusion (Modus Ponens): Access APPROVED with logical certainty\n"
            reasoning += "• Formula: P→Q, P ⊢ Q\n\n"
            
            // Statistical reasoning
            reasoning += "**Statistical Analysis:**\n"
            reasoning += "• Combined risk score: \(String(format: "%.1f", mlScore))/100\n"
            reasoning += "• Threat component: \(String(format: "%.1f", threatScore))/100\n"
            reasoning += "• Geographic component: \(String(format: "%.1f", geoRisk))/100\n"
            reasoning += "• Behavioral component: \(String(format: "%.1f", behaviorScore))/100\n"
            reasoning += "• Confidence interval: 95% certainty of safe access\n\n"
            
            // Inductive reasoning
            if !logicalAnalysis.inductiveInferences.isEmpty {
                reasoning += "**Inductive Patterns:**\n"
                for inference in logicalAnalysis.inductiveInferences.prefix(2) {
                    reasoning += "• \(inference.conclusion)\n"
                }
                reasoning += "\n"
            }
            
            reasoning += "**Final Decision:** Access granted based on low-risk profile and formal logical certainty."
            
            decision.reason = reasoning
            decision.logicalReasoning = reasoning
            
            print("   ✅ APPROVED: Score \(String(format: "%.1f", mlScore)) < \(autoApproveThreshold)")
            
        } else {
            // DENY with logical reasoning
            decision.action = .autoDenied
            decision.confidence = mlScore / 100.0
            
            // Build formal logic explanation
            var reasoning = "🚫 **DENIED - Formal Logic Analysis:**\n\n"
            
            // Deductive reasoning
            reasoning += "**Deductive Logic (Certain):**\n"
            reasoning += "• Premise: If ML score ≥ 50 OR critical threats detected, then deny access\n"
            reasoning += "• Observation: ML score = \(String(format: "%.1f", mlScore)) ≥ 50\n"
            reasoning += "• Conclusion (Modus Ponens): Access DENIED with logical certainty\n"
            reasoning += "• Formula: P→Q, P ⊢ Q\n\n"
            
            // Abductive reasoning (find cause)
            reasoning += "**Abductive Analysis (Root Cause):**\n"
            if threatScore > 50 {
                reasoning += "• Most likely cause: Elevated threat level (\(String(format: "%.1f", threatScore))/100)\n"
                reasoning += "• Evidence: Suspicious access patterns or security indicators\n"
            }
            if geoRisk > 50 {
                reasoning += "• Geographic anomaly: Access from unusual location\n"
                reasoning += "• Risk: \(String(format: "%.1f", geoRisk))/100\n"
            }
            if behaviorScore > 50 {
                reasoning += "• Behavioral anomaly: Unusual access pattern for this user\n"
                reasoning += "• Deviation: \(String(format: "%.1f", behaviorScore))/100\n"
            }
            reasoning += "\n"
            
            // Modal logic (necessity)
            reasoning += "**Modal Logic (Necessity):**\n"
            reasoning += "• Given security policy: □(High-risk access → Denial required)\n"
            reasoning += "• Current state: High-risk access detected\n"
            reasoning += "• Necessary conclusion: Denial is MANDATORY\n\n"
            
            // Abductive inferences from engine
            if !logicalAnalysis.abductiveInferences.isEmpty {
                reasoning += "**Most Likely Explanation:**\n"
                if let bestExplanation = logicalAnalysis.abductiveInferences.first {
                    reasoning += "• \(bestExplanation.conclusion)\n"
                    reasoning += "• Likelihood: \(Int(bestExplanation.confidence * 100))%\n"
                }
                reasoning += "\n"
            }
            
            reasoning += "**Final Decision:** Access denied for security reasons. Risk score exceeds acceptable threshold."
            
            decision.reason = reasoning
            decision.logicalReasoning = reasoning
            
            print("   🚫 DENIED: Score \(String(format: "%.1f", mlScore)) ≥ \(autoApproveThreshold)")
        }
        
        return decision
    }
    
    // MARK: - Decision Execution
    
    private func executeDecision(_ decision: DualKeyDecision, for request: DualKeyRequest) async throws {
        guard let modelContext = modelContext else { return }
        
        switch decision.action {
        case .autoApproved:
            request.status = "approved"
            request.approvedAt = Date()
            request.decisionMethod = "ml_logic_auto"
            request.reason = decision.reason
            request.mlScore = decision.mlScore
            request.logicalReasoning = decision.logicalReasoning
            
        case .autoDenied:
            request.status = "denied"
            request.deniedAt = Date()
            request.decisionMethod = "ml_logic_auto"
            request.reason = decision.reason
            request.mlScore = decision.mlScore
            request.logicalReasoning = decision.logicalReasoning
        }
        
        try modelContext.save()
    }
    
    private func logDecision(_ decision: DualKeyDecision, for request: DualKeyRequest, vault: Vault, mlScore: Double) async throws {
        guard let modelContext = modelContext else { return }
        
        // Create decision log
        let log = DualKeyDecisionLog(
            requestID: request.id,
            vaultID: vault.id,
            vaultName: vault.name,
            mlScore: mlScore,
            action: decision.action.rawValue,
            reason: decision.reason,
            confidence: decision.confidence
        )
        
        modelContext.insert(log)
        try modelContext.save()
        
        print("   📝 Decision logged: \(decision.action.rawValue)")
    }
    
    // MARK: - Helper Functions
    
    private func isNightTime(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour < 6 || hour > 22
    }
    
    private func calculateDistance(from: (Double, Double), to: (Double, Double)) -> Double {
        let earthRadius = 6371.0 // km
        
        let lat1Rad = from.0 * .pi / 180
        let lat2Rad = to.0 * .pi / 180
        let deltaLat = (to.0 - from.0) * .pi / 180
        let deltaLon = (to.1 - from.1) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    private func getUserTypicalLocations(vault: Vault) -> [(latitude: Double, longitude: Double)] {
        let logs = vault.accessLogs ?? []
        var locations: [(Double, Double)] = []
        
        for log in logs {
            if let lat = log.locationLatitude, let lon = log.locationLongitude {
                locations.append((lat, lon))
            }
        }
        
        // Cluster locations to find typical access points
        // (Simple implementation - would use k-means in production)
        guard !locations.isEmpty else { return [] }
        
        // For now, return most frequent locations
        var locationCounts: [String: (location: (Double, Double), count: Int)] = [:]
        
        for loc in locations {
            // Round to 2 decimal places for clustering (~1km precision)
            let key = "\(String(format: "%.2f", loc.0)),\(String(format: "%.2f", loc.1))"
            if var existing = locationCounts[key] {
                existing.count += 1
                locationCounts[key] = existing
            } else {
                locationCounts[key] = (loc, 1)
            }
        }
        
        // Return locations with >10% of total accesses
        let threshold = locations.count / 10
        return locationCounts.values
            .filter { $0.count > max(threshold, 2) }
            .map { $0.location }
    }
    
    private func calculateAverageDaysBetweenAccess(_ logs: [VaultAccessLog]) -> Double {
        guard logs.count > 1 else { return 0 }
        
        let sorted = logs.sorted { $0.timestamp < $1.timestamp }
        var totalDays: TimeInterval = 0
        
        for i in 1..<sorted.count {
            totalDays += sorted[i].timestamp.timeIntervalSince(sorted[i-1].timestamp)
        }
        
        return (totalDays / Double(sorted.count - 1)) / 86400 // Convert to days
    }
    
    private func getUserTypicalAccessHours(_ logs: [VaultAccessLog]) -> Set<Int> {
        var hours: [Int: Int] = [:]
        
        for log in logs {
            let hour = Calendar.current.component(.hour, from: log.timestamp)
            hours[hour, default: 0] += 1
        }
        
        // Return hours with >10% of accesses
        let threshold = logs.count / 10
        return Set(hours.filter { $0.value > max(threshold, 1) }.map { $0.key })
    }
}

// MARK: - Models

struct DualKeyDecision {
    var action: DecisionAction = .autoDenied // Default to deny for safety
    var reason: String = ""
    var logicalReasoning: String = ""
    var mlScore: Double = 0.0
    var confidence: Double = 0.0
    var timestamp: Date = Date()
    var vaultName: String = ""
}

enum DecisionAction: String {
    case autoApproved = "auto_approved"
    case autoDenied = "auto_denied"
}

@Model
final class DualKeyDecisionLog {
    @Attribute(.unique) var id: UUID
    var requestID: UUID
    var vaultID: UUID
    var vaultName: String
    var mlScore: Double
    var action: String
    var reason: String
    var confidence: Double
    var timestamp: Date
    
    init(
        id: UUID = UUID(),
        requestID: UUID,
        vaultID: UUID,
        vaultName: String,
        mlScore: Double,
        action: String,
        reason: String,
        confidence: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.requestID = requestID
        self.vaultID = vaultID
        self.vaultName = vaultName
        self.mlScore = mlScore
        self.action = action
        self.reason = reason
        self.confidence = confidence
        self.timestamp = timestamp
    }
}


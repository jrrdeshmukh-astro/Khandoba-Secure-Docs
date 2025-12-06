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
    }
    
    /// Process dual-key request with ML including geospatial analysis
    func processDualKeyRequest(_ request: DualKeyRequest, vault: Vault) async throws -> DualKeyDecision {
        isProcessing = true
        defer { isProcessing = false }
        
        print("ML: Processing dual-key request for vault: \(vault.name)")
        
        // Calculate threat score
        let threatScore = await calculateThreatScoreOptimized(for: vault)
        
        // GEOSPATIAL RISK ANALYSIS with actual location
        let geoRisk = await calculateGeospatialRiskOptimized(vault: vault)
        
        // Behavioral analysis
        let behaviorScore = await analyzeBehaviorOptimized(vault: vault)
        
        // Calculate combined ML score
        let mlScore = calculateCombinedMLScore(
            threatScore: threatScore,
            geoRisk: geoRisk,
            behaviorScore: behaviorScore
        )
        print("   Threat: \(String(format: "%.0f", threatScore))% | Geo: \(String(format: "%.0f", geoRisk))% | Behavior: \(String(format: "%.0f", behaviorScore))%")
        print("   Combined ML Score: \(String(format: "%.1f", mlScore))/100")
        
        // OPTIMIZATION: Skip formal logic engine for performance
        // Make direct decision based on ML score
        let decision = makeQuickDecision(
            mlScore: mlScore,
            request: request,
            vault: vault,
            threatScore: threatScore,
            geoRisk: geoRisk,
            behaviorScore: behaviorScore
        )
        
        // Execute decision (fast)
        try await executeDecision(decision, for: request)
        
        return decision
    }
    
    // OPTIMIZED: Lightweight threat calculation
    private func calculateThreatScoreOptimized(for vault: Vault) async -> Double {
        // Quick check without heavy analysis
        let logs = vault.accessLogs ?? []
        
        if logs.isEmpty {
            return 10.0 // New vault, low risk
        }
        
        // Check for recent failed attempts only
        let recentLogs = logs.suffix(10)
        let failedCount = recentLogs.filter { $0.accessType == "failed" }.count
        
        return Double(failedCount * 10) // Simple scoring
    }
    
    // GEOSPATIAL RISK: Analyze location patterns
    private func calculateGeospatialRiskOptimized(vault: Vault) async -> Double {
        let locationService = LocationService()
        
        guard let currentLocation = locationService.currentLocation else {
            print("   Geo: No location available")
            return 30.0 // Unknown location = moderate risk
        }
        
        let currentLat = currentLocation.coordinate.latitude
        let currentLon = currentLocation.coordinate.longitude
        print("   Current location: \(currentLat), \(currentLon)")
        
        // Get historical locations from logs
        let logs = vault.accessLogs ?? []
        let logsWithLocation = logs.filter { $0.locationLatitude != nil && $0.locationLongitude != nil }
        
        if logsWithLocation.isEmpty {
            print("   Geo: First access from this location")
            return 25.0 // New location, moderate risk
        }
        
        // Calculate distance from typical locations
        var minDistance = Double.infinity
        
        for log in logsWithLocation.suffix(20) { // Check last 20 locations
            if let logLat = log.locationLatitude, let logLon = log.locationLongitude {
                let distance = calculateDistanceKm(
                    from: (currentLat, currentLon),
                    to: (logLat, logLon)
                )
                minDistance = min(minDistance, distance)
            }
        }
        
        print("   Distance from familiar location: \(String(format: "%.1f", minDistance)) km")
        
        // Risk based on distance
        if minDistance < 1 {
            return 5.0 // Very close to known location
        } else if minDistance < 10 {
            return 10.0 // Nearby
        } else if minDistance < 50 {
            return 20.0 // Same city
        } else if minDistance < 200 {
            return 40.0 // Different city
        } else {
            print("   Warning: Access from distant location")
            return 60.0 // Far away, higher risk
        }
    }
    
    // BEHAVIORAL ANALYSIS: Access patterns
    private func analyzeBehaviorOptimized(vault: Vault) async -> Double {
        let logs = vault.accessLogs ?? []
        
        if logs.count < 3 {
            return 20.0 // Not enough data, moderate risk
        }
        
        let recentLogs = logs.suffix(10)
        
        // Check access frequency
        if recentLogs.count >= 5 {
            let timeSpan = recentLogs.first!.timestamp.timeIntervalSince(recentLogs.last!.timestamp)
            if timeSpan < 300 { // 5 accesses in 5 minutes
                print("   Behavior: Rapid access detected")
                return 35.0
            }
        }
        
        return 15.0 // Normal behavior
    }
    
    // Helper: Calculate distance between coordinates
    private func calculateDistanceKm(from: (Double, Double), to: (Double, Double)) -> Double {
        let earthRadius = 6371.0 // km
        
        let lat1 = from.0 * .pi / 180
        let lat2 = to.0 * .pi / 180
        let deltaLat = (to.0 - from.0) * .pi / 180
        let deltaLon = (to.1 - from.1) * .pi / 180
        
        let a = sin(deltaLat / 2) * sin(deltaLat / 2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon / 2) * sin(deltaLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    // OPTIMIZED: Quick decision without formal logic
    private func makeQuickDecision(
        mlScore: Double,
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
        
        if mlScore < autoApproveThreshold {
            decision.action = .autoApproved
            decision.confidence = 1.0 - (mlScore / 100.0)
            decision.reason = "ACCESS APPROVED\n\nSecurity check passed. Your request looks safe.\n\nSafety Score: \(String(format: "%.0f", mlScore))% (Low Risk)\n\nYour vault access is approved."
            
        } else {
            decision.action = .autoDenied
            decision.confidence = mlScore / 100.0
            decision.reason = "ACCESS DENIED\n\nSecurity check flagged some concerns.\n\nRisk Level: \(String(format: "%.0f", mlScore))% (High Risk)\n\nTry again later or contact support."
        }
        
        decision.logicalReasoning = decision.reason
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
                print("    Rapid access detected: 5 attempts in \(Int(timeWindow))s")
            }
        }
        
        // Failed access attempts
        let failedAttempts = logs.filter { $0.accessType == "failed" }.count
        if failedAttempts > 3 {
            score += Double(failedAttempts) * 5
            print("    Failed attempts: \(failedAttempts)")
        }
        
        // Night access frequency
        let nightAccess = logs.filter { isNightTime($0.timestamp) }
        if !logs.isEmpty {
            let nightPercentage = Double(nightAccess.count) / Double(logs.count)
            if nightPercentage > 0.5 {
                score += 20
                print("    High night access: \(Int(nightPercentage * 100))%")
            }
        }
        
        return min(score, 100)
    }
    
    // MARK: - Geospatial Risk Calculation
    
    private func calculateGeospatialRisk(request: DualKeyRequest, vault: Vault) async -> Double {
        var risk: Double = 0.0
        
        guard let currentLocation = locationService.currentLocation else {
            print("    No location data available")
            return 50.0 // Unknown location = medium risk
        }
        
        let requestLat = currentLocation.coordinate.latitude
        let requestLon = currentLocation.coordinate.longitude
        
        // Get user's typical locations (home/office)
        let userLocations = getUserTypicalLocations(vault: vault)
        
        if userLocations.isEmpty {
            print("    No baseline locations established")
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
        
        print("    Distance from typical location: \(String(format: "%.1f", minDistance)) km")
        
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
            print("    Access from unusual location: \(String(format: "%.1f", minDistance)) km away")
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
                print("    IMPOSSIBLE TRAVEL: \(String(format: "%.0f", travelDistance)) km in \(String(format: "%.1f", timeSinceLastAccess)) hours")
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
            print("    First-time access request from this user")
        }
        
        // Access frequency pattern
        if userLogs.count > 0 {
            let avgDaysBetweenAccess = calculateAverageDaysBetweenAccess(userLogs)
            
            // Too frequent (potential bot/automated)
            if avgDaysBetweenAccess < 0.1 { // Multiple times per day
                score += 20
                print("    Unusually frequent access pattern")
            }
            
            // Too infrequent (dormant account suddenly active)
            if avgDaysBetweenAccess > 30 && userLogs.count > 5 {
                score += 15
                print("    Dormant account suddenly active")
            }
        }
        
        // Time pattern analysis
        let currentHour = Calendar.current.component(.hour, from: Date())
        let userTypicalHours = getUserTypicalAccessHours(userLogs)
        
        if !userTypicalHours.contains(currentHour) && userTypicalHours.count > 5 {
            score += 15
            print("    Access at unusual time for this user")
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
                subject: requester.fullName,
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
            // APPROVE with simple explanation
            decision.action = .autoApproved
            decision.confidence = 1.0 - (mlScore / 100.0)
            
            // Build simple, clear explanation
            var reasoning = "ACCESS APPROVED\n\n"
            
            reasoning += "Why was this approved?\n"
            reasoning += "We checked your security profile and everything looks good. Here's what we found:\n\n"
            
            reasoning += "Security Check Results:\n"
            reasoning += "Overall Safety Score: \(String(format: "%.0f", mlScore))% (Low Risk)\n"
            reasoning += "Threat Level: \(threatScore < 30 ? "Safe" : threatScore < 60 ? "Normal" : "Elevated")\n"
            reasoning += "Your Location: \(geoRisk < 30 ? "Recognized" : geoRisk < 60 ? "Familiar" : "Unusual")\n"
            reasoning += "Behavior Pattern: \(behaviorScore < 30 ? "Typical" : behaviorScore < 60 ? "Normal" : "Different than usual")\n\n"
            
            reasoning += "What this means:\n"
            reasoning += "Everything about this access request appears safe. Your location and behavior match your normal patterns, and we haven't detected any security concerns.\n\n"
            
            // Add patterns if available
            if !logicalAnalysis.inductiveInferences.isEmpty {
                reasoning += "Additional Notes:\n"
                for inference in logicalAnalysis.inductiveInferences.prefix(2) {
                    let simplified = simplifyInference(inference.conclusion)
                    reasoning += "\(simplified)\n"
                }
                reasoning += "\n"
            }
            
            reasoning += "Bottom Line: Your vault access is approved. You're good to go!"
            
            decision.reason = reasoning
            decision.logicalReasoning = reasoning
            
            print("    APPROVED: Score \(String(format: "%.1f", mlScore)) < \(autoApproveThreshold)")
            
        } else {
            // DENY with simple explanation
            decision.action = .autoDenied
            decision.confidence = mlScore / 100.0
            
            // Build simple, clear explanation
            var reasoning = "ACCESS DENIED\n\n"
            
            reasoning += "Why was this blocked?\n"
            reasoning += "We detected some security concerns with this access attempt. For your protection, we're denying access.\n\n"
            
            reasoning += "Security Check Results:\n"
            reasoning += "Overall Risk Level: \(String(format: "%.0f", mlScore))% (High Risk)\n"
            reasoning += "Threat Level: \(threatScore < 30 ? "Safe" : threatScore < 60 ? "Moderate" : "High")\n"
            reasoning += "Your Location: \(geoRisk < 30 ? "Recognized" : geoRisk < 60 ? "Familiar" : "Unusual or far from home")\n"
            reasoning += "Behavior Pattern: \(behaviorScore < 30 ? "Normal" : behaviorScore < 60 ? "Slightly different" : "Very different than usual")\n\n"
            
            reasoning += "What triggered this:\n"
            var reasons: [String] = []
            if threatScore > 50 {
                reasons.append("We detected some suspicious activity or security warnings")
            }
            if geoRisk > 50 {
                reasons.append("You're trying to access from an unfamiliar or distant location")
            }
            if behaviorScore > 50 {
                reasons.append("Your access pattern is different from your normal behavior")
            }
            
            if reasons.isEmpty {
                reasoning += "Overall risk score is too high for automatic approval\n"
            } else {
                for reason in reasons {
                    reasoning += "\(reason)\n"
                }
            }
            reasoning += "\n"
            
            // Add best explanation if available
            if !logicalAnalysis.abductiveInferences.isEmpty {
                reasoning += "Most likely reason:\n"
                if let bestExplanation = logicalAnalysis.abductiveInferences.first {
                    let simplified = simplifyInference(bestExplanation.conclusion)
                    reasoning += "\(simplified)\n\n"
                }
            }
            
            reasoning += "What to do:\n"
            reasoning += "This is a security precaution. If this is really you, try again later when you're in your usual location. Contact support if you believe this is an error."
            
            decision.reason = reasoning
            decision.logicalReasoning = reasoning
            
            print("    DENIED: Score \(String(format: "%.1f", mlScore)) ≥ \(autoApproveThreshold)")
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
    
    // Helper to simplify technical inference conclusions into plain English
    private func simplifyInference(_ technical: String) -> String {
        // Convert technical language to plain English
        let simplified = technical
            .replacingOccurrences(of: "Pattern:", with: "We noticed:")
            .replacingOccurrences(of: "typically", with: "usually")
            .replacingOccurrences(of: "documents", with: "files")
            .replacingOccurrences(of: "property:", with: "")
        
        return simplified
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


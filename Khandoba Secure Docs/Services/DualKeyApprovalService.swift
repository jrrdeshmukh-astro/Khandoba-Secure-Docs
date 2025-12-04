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
    
    // ML Model thresholds
    private let autoApproveThreshold: Double = 30.0  // Score below 30 = auto-approve
    private let autoDenyThreshold: Double = 70.0     // Score above 70 = auto-deny
    private let maxDistanceKm: Double = 100.0        // Max distance from home/office
    private let impossibleTravelThreshold: Double = 500.0 // km in 1 hour
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Process dual-key request with ML-based auto-approval/denial
    func processDualKeyRequest(_ request: DualKeyRequest, vault: Vault) async throws -> DualKeyDecision {
        isProcessing = true
        defer { isProcessing = false }
        
        print("🤖 ML: Processing dual-key request for vault: \(vault.name)")
        
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
        
        // Step 5: Make decision
        let decision = makeMLDecision(mlScore: mlScore, request: request, vault: vault)
        
        // Step 6: Log decision
        try await logDecision(decision, for: request, vault: vault, mlScore: mlScore)
        
        // Step 7: Execute decision
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
    
    private func makeMLDecision(mlScore: Double, request: DualKeyRequest, vault: Vault) -> DualKeyDecision {
        var decision = DualKeyDecision()
        decision.mlScore = mlScore
        decision.timestamp = Date()
        decision.vaultName = vault.name
        
        if mlScore < autoApproveThreshold {
            // AUTO-APPROVE: Low risk
            decision.action = .autoApproved
            decision.reason = "✅ AUTO-APPROVED: Low risk score (\(String(format: "%.1f", mlScore))/100). All security metrics within safe thresholds."
            decision.confidence = 1.0 - (mlScore / 100.0)
            
            print("   ✅ AUTO-APPROVE: Score \(String(format: "%.1f", mlScore)) < \(autoApproveThreshold)")
            
        } else if mlScore > autoDenyThreshold {
            // AUTO-DENY: High risk
            decision.action = .autoDenied
            decision.reason = "🚫 AUTO-DENIED: High risk score (\(String(format: "%.1f", mlScore))/100). Suspicious activity detected. Review security logs immediately."
            decision.confidence = mlScore / 100.0
            
            print("   🚫 AUTO-DENY: Score \(String(format: "%.1f", mlScore)) > \(autoDenyThreshold)")
            
        } else {
            // MANUAL REVIEW: Medium risk
            decision.action = .requiresManualReview
            decision.reason = "⚠️ MANUAL REVIEW REQUIRED: Moderate risk score (\(String(format: "%.1f", mlScore))/100). Please review the access details before approving."
            decision.confidence = 0.5
            
            print("   ⚠️ MANUAL REVIEW: Score \(String(format: "%.1f", mlScore)) between thresholds")
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
            request.approvalMethod = "ml_auto"
            
        case .autoDenied:
            request.status = "denied"
            request.deniedAt = Date()
            request.denialReason = decision.reason
            
        case .requiresManualReview:
            request.status = "pending_review"
            request.requiresManualReview = true
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
    var action: DecisionAction = .requiresManualReview
    var reason: String = ""
    var mlScore: Double = 0.0
    var confidence: Double = 0.0
    var timestamp: Date = Date()
    var vaultName: String = ""
}

enum DecisionAction: String {
    case autoApproved = "auto_approved"
    case autoDenied = "auto_denied"
    case requiresManualReview = "manual_review"
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


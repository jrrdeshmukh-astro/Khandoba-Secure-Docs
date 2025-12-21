//
//  ThreatMonitoringService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import CoreML
import SwiftData
import Combine
import SwiftUI

@MainActor
final class ThreatMonitoringService: ObservableObject {
    @Published var threatLevel: ThreatLevel = .low
    @Published var anomalyScore: Double = 0.0
    @Published var recentThreats: [ThreatEvent] = []
    
    private var vaultService: VaultService?
    private var supabaseService: SupabaseService?
    
    nonisolated init() {}
    
    func configure(vaultService: VaultService, supabaseService: SupabaseService? = nil) {
        self.vaultService = vaultService
        self.supabaseService = supabaseService
    }
    
    /// Incorporate logical threat inferences into threat analysis
    func incorporateLogicalThreats(vault: Vault, logicalThreats: [LogicalInference]) async -> ThreatLevel {
        // Enhance threat detection with formal logic inferences
        // High-confidence logical inferences can override or augment existing threat detection
        
        var threatScore = 0.0
        
        // Check for critical logical threats
        for inference in logicalThreats {
            if inference.confidence >= 0.9 {
                // Critical threat from formal logic
                if inference.conclusion.contains("compromise") || inference.conclusion.contains("breach") {
                    threatScore += 30
                } else if inference.conclusion.contains("unauthorized") || inference.conclusion.contains("attack") {
                    threatScore += 20
                } else {
                    threatScore += 10
                }
            } else if inference.confidence >= 0.7 {
                threatScore += 5
            }
        }
        
        // Combine with existing threat analysis
        let existingLevel = await analyzeThreatLevel(for: vault)
        
        // If logical threats push score high, escalate threat level
        if threatScore >= 30 && existingLevel != .critical {
            return .critical
        } else if threatScore >= 20 && existingLevel != .high && existingLevel != .critical {
            return .high
        } else if threatScore >= 10 && existingLevel == .low {
            return .medium
        }
        
        return existingLevel
    }
    
    /// Analyze vault access patterns for threats
    func analyzeThreatLevel(for vault: Vault) async -> ThreatLevel {
        // Load access logs (from Supabase or SwiftData)
        let logs: [VaultAccessLog]
        if AppConfig.useSupabase, let vaultService = vaultService {
            do {
                logs = try await vaultService.loadAccessLogs(for: vault)
            } catch {
                print("⚠️ Failed to load access logs for threat analysis: \(error)")
                logs = []
            }
        } else {
            logs = vault.accessLogs ?? []
        }
        
        let sortedLogs = logs.sorted { $0.timestamp > $1.timestamp }
        
        var suspiciousActivities = 0
        var anomalyPoints = 0.0
        
        // Check for rapid successive access (brute force indicator)
        if sortedLogs.count > 10 {
            let recentLogs = sortedLogs.prefix(10)
            let timeWindow = recentLogs.first!.timestamp.timeIntervalSince(recentLogs.last!.timestamp)
            
            if timeWindow < 60 { // 10 accesses in less than 1 minute
                suspiciousActivities += 1
                anomalyPoints += 20
            }
        }
        
        // Check for unusual time patterns
        let nightAccessCount = sortedLogs.filter { isNightTime($0.timestamp) }.count
        if Double(nightAccessCount) / Double(sortedLogs.count) > 0.5 {
            anomalyPoints += 15
        }
        
        // Check for geographic anomalies
        if hasGeographicAnomalies(sortedLogs) {
            suspiciousActivities += 1
            anomalyPoints += 25
        }
        
        // Check for unusual deletion patterns
        let deletionCount = sortedLogs.filter { $0.accessType == "deleted" }.count
        if Double(deletionCount) / Double(max(sortedLogs.count, 1)) > 0.3 {
            anomalyPoints += 30
        }
        
        self.anomalyScore = anomalyPoints
        
        // Determine threat level
        if anomalyPoints > 50 || suspiciousActivities > 2 {
            threatLevel = .high
            return .high
        } else if anomalyPoints > 25 || suspiciousActivities > 0 {
            threatLevel = .medium
            return .medium
        } else {
            threatLevel = .low
            return .low
        }
    }
    
    /// Generate threat metrics over time
    func generateThreatMetrics(for vault: Vault) async -> [ThreatMetric] {
        // Load access logs (from Supabase or SwiftData)
        let logs: [VaultAccessLog]
        if AppConfig.useSupabase, let vaultService = vaultService {
            do {
                logs = try await vaultService.loadAccessLogs(for: vault)
            } catch {
                print("⚠️ Failed to load access logs for metrics: \(error)")
                logs = []
            }
        } else {
            logs = vault.accessLogs ?? []
        }
        
        let sortedLogs = logs.sorted { $0.timestamp < $1.timestamp }
        var metrics: [ThreatMetric] = []
        
        // Group by day
        let calendar = Calendar.current
        var dailyGroups: [Date: [VaultAccessLog]] = [:]
        
        for log in sortedLogs {
            let day = calendar.startOfDay(for: log.timestamp)
            if dailyGroups[day] == nil {
                dailyGroups[day] = []
            }
            dailyGroups[day]?.append(log)
        }
        
        // Calculate threat score for each day
        for (date, dayLogs) in dailyGroups.sorted(by: { $0.key < $1.key }) {
            let accessCount = dayLogs.count
            let nightAccess = dayLogs.filter { isNightTime($0.timestamp) }.count
            let deletions = dayLogs.filter { $0.accessType == "deleted" }.count
            
            var score = 0.0
            score += Double(accessCount) * 0.5 // More access = slight increase
            score += Double(nightAccess) * 5.0 // Night access is suspicious
            score += Double(deletions) * 10.0 // Deletions are very suspicious
            
            let metric = ThreatMetric(
                date: date,
                threatScore: min(score, 100),
                accessCount: accessCount,
                anomalyCount: nightAccess + deletions
            )
            metrics.append(metric)
        }
        
        return metrics
    }
    
    /// Detect specific threat patterns
    func detectThreats(for vault: Vault) async -> [ThreatEvent] {
        var threats: [ThreatEvent] = []
        
        // Load access logs (from Supabase or SwiftData)
        let logs: [VaultAccessLog]
        if AppConfig.useSupabase, let vaultService = vaultService {
            do {
                logs = try await vaultService.loadAccessLogs(for: vault)
            } catch {
                print("⚠️ Failed to load access logs for threat detection: \(error)")
                logs = []
            }
        } else {
            logs = vault.accessLogs ?? []
        }
        
        let sortedLogs = logs.sorted { $0.timestamp > $1.timestamp }
        
        // Detect rapid access pattern
        if sortedLogs.count >= 5 {
            let recent = sortedLogs.prefix(5)
            let timeSpan = recent.first!.timestamp.timeIntervalSince(recent.last!.timestamp)
            
            if timeSpan < 30 {
                threats.append(ThreatEvent(
                    type: .rapidAccess,
                    severity: .high,
                    description: "5 accesses in \(Int(timeSpan)) seconds",
                    timestamp: Date()
                ))
            }
        }
        
        // Detect unusual location
        if let recentLog = sortedLogs.first,
           let lat = recentLog.locationLatitude,
           let lon = recentLog.locationLongitude {
            
            // Check if location is far from previous accesses
            let previousLogs = sortedLogs.dropFirst().prefix(10)
            var averageLat = 0.0
            var averageLon = 0.0
            var count = 0
            
            for log in previousLogs {
                if let prevLat = log.locationLatitude, let prevLon = log.locationLongitude {
                    averageLat += prevLat
                    averageLon += prevLon
                    count += 1
                }
            }
            
            if count > 0 {
                averageLat /= Double(count)
                averageLon /= Double(count)
                
                let distance = calculateDistance(
                    from: (averageLat, averageLon),
                    to: (lat, lon)
                )
                
                if distance > 1000 { // More than 1000 km from usual location
                    threats.append(ThreatEvent(
                        type: .unusualLocation,
                        severity: .medium,
                        description: "Access from unusual location (\(Int(distance)) km away)",
                        timestamp: Date()
                    ))
                }
            }
        }
        
        self.recentThreats = threats
        return threats
    }
    
    // MARK: - Helpers
    
    private func isNightTime(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour < 6 || hour > 22 // 10 PM to 6 AM
    }
    
    private func hasGeographicAnomalies(_ logs: [VaultAccessLog]) -> Bool {
        guard logs.count >= 2 else { return false }
        
        let recentLogs = logs.prefix(10)
        var locations: [(Double, Double)] = []
        
        for log in recentLogs {
            if let lat = log.locationLatitude, let lon = log.locationLongitude {
                locations.append((lat, lon))
            }
        }
        
        guard locations.count >= 2 else { return false }
        
        // Check if consecutive locations are impossibly far apart
        for i in 0..<(locations.count - 1) {
            let distance = calculateDistance(from: locations[i], to: locations[i + 1])
            
            // Get time difference
            let timeDiff = recentLogs[recentLogs.startIndex + i].timestamp.timeIntervalSince(
                recentLogs[recentLogs.startIndex + i + 1].timestamp
            )
            
            // If distance > 500km and time < 1 hour, it's suspicious
            if distance > 500 && abs(timeDiff) < 3600 {
                return true
            }
        }
        
        return false
    }
    
    private func calculateDistance(from: (Double, Double), to: (Double, Double)) -> Double {
        // Haversine formula for distance between two lat/lon points
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
}

// MARK: - Models

enum ThreatLevel: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct ThreatEvent: Identifiable {
    let id = UUID()
    let type: ThreatType
    let severity: ThreatLevel
    let description: String
    let timestamp: Date
}

enum ThreatType {
    case rapidAccess
    case unusualLocation
    case suspiciousDeletion
    case bruteForce
    case unauthorizedAccess
}

struct ThreatMetric: Identifiable {
    let id = UUID()
    let date: Date
    let threatScore: Double
    let accessCount: Int
    let anomalyCount: Int
}

//
//  MLThreatAnalysisService.swift
//  Khandoba Secure Docs
//
//  ML-powered threat analysis with zero-knowledge architecture

import Foundation
import CoreML
import NaturalLanguage
import CoreLocation
import Combine

@MainActor
final class MLThreatAnalysisService: ObservableObject {
    @Published var threatMetrics: ThreatMetrics?
    @Published var isAnalyzing = false
    
    nonisolated init() {}
    
    // MARK: - Geo-Classification Analysis
    
    private var vaultService: VaultService?
    
    func configure(vaultService: VaultService) {
        self.vaultService = vaultService
    }
    
    /// Analyze access patterns by geographic clustering (zero-knowledge)
    func analyzeGeoClassification(for vault: Vault) async -> GeoThreatMetrics {
        // Load access logs (from Supabase or SwiftData)
        let accessLogs: [VaultAccessLog]
        if AppConfig.useSupabase, let vaultService = vaultService {
            do {
                accessLogs = try await vaultService.loadAccessLogs(for: vault)
            } catch {
                print("⚠️ Failed to load access logs for geo analysis: \(error)")
                accessLogs = []
            }
        } else {
            accessLogs = vault.accessLogs ?? []
        }
        
        // Extract coordinates (metadata only, no document content)
        let coordinates = accessLogs.compactMap { log -> CLLocationCoordinate2D? in
            guard let lat = log.locationLatitude,
                  let lon = log.locationLongitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        guard !coordinates.isEmpty else {
            return GeoThreatMetrics(
                accessLocations: 0,
                uniqueLocations: 0,
                locationSpread: 0,
                suspiciousLocations: [],
                riskScore: 0
            )
        }
        
        // Cluster locations
        let clusters = clusterLocations(coordinates)
        
        // Detect anomalies
        let suspiciousLocations = detectGeoAnomalies(coordinates, clusters: clusters)
        
        // Calculate spread (variance)
        let spread = calculateLocationSpread(coordinates)
        
        // Risk score based on:
        // - Too many locations (account compromise?)
        // - Locations too far apart (impossible travel?)
        // - Access from high-risk regions
        let riskScore = calculateGeoRiskScore(
            locations: coordinates,
            clusters: clusters,
            spread: spread
        )
        
        return GeoThreatMetrics(
            accessLocations: coordinates.count,
            uniqueLocations: clusters.count,
            locationSpread: spread,
            suspiciousLocations: suspiciousLocations,
            riskScore: riskScore
        )
    }
    
    // MARK: - Access Pattern Analysis
    
    /// Detect anomalous access patterns using ML (zero-knowledge)
    func analyzeAccessPatterns(for vault: Vault) async -> AccessPatternMetrics {
        // Load access logs (from Supabase or SwiftData)
        let accessLogs: [VaultAccessLog]
        if AppConfig.useSupabase, let vaultService = vaultService {
            do {
                accessLogs = try await vaultService.loadAccessLogs(for: vault)
            } catch {
                print("⚠️ Failed to load access logs for access pattern analysis: \(error)")
                accessLogs = []
            }
        } else {
            accessLogs = vault.accessLogs ?? []
        }
        
        // Temporal analysis
        let timestamps = accessLogs.map { $0.timestamp }
        let temporalPatterns = detectTemporalAnomalies(timestamps)
        
        // Access type distribution
        let typeDistribution = Dictionary(grouping: accessLogs, by: { $0.accessType })
            .mapValues { $0.count }
        
        // Frequency analysis
        let accessFrequency = analyzeAccessFrequency(timestamps)
        
        // Unusual times (e.g., 3 AM accesses)
        let unusualTimeAccesses = detectUnusualAccessTimes(timestamps)
        
        // Burst detection (many accesses in short time)
        let burstDetected = detectAccessBursts(timestamps)
        
        let riskScore = calculateAccessPatternRisk(
            temporalAnomalies: temporalPatterns,
            unusualTimes: unusualTimeAccesses,
            bursts: burstDetected
        )
        
        return AccessPatternMetrics(
            totalAccesses: accessLogs.count,
            accessTypes: typeDistribution,
            frequency: accessFrequency,
            unusualTimeCount: unusualTimeAccesses,
            burstsDetected: burstDetected,
            riskScore: riskScore
        )
    }
    
    // MARK: - Tag-Based Threat Analysis
    
    /// Analyze document tags for potential threats (zero-knowledge)
    func analyzeTagPatterns(for vault: Vault) -> TagThreatMetrics {
        let documents = vault.documents ?? []
        
        // Collect all tags (metadata only, not content)
        let allTags = documents.flatMap { $0.aiTags }
        
        // Tag frequency
        let tagFrequency = Dictionary(grouping: allTags, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        // Detect suspicious patterns
        let suspiciousTags = detectSuspiciousTags(tagFrequency)
        
        // Check for data exfiltration indicators
        let exfiltrationRisk = detectExfiltrationPatterns(documents)
        
        // Check for unusual document types
        let unusualTypes = detectUnusualDocumentTypes(documents)
        
        let riskScore = calculateTagRiskScore(
            suspiciousTags: suspiciousTags,
            exfiltration: exfiltrationRisk,
            unusualTypes: unusualTypes
        )
        
        return TagThreatMetrics(
            totalTags: allTags.count,
            uniqueTags: Set(allTags).count,
            topTags: Array(tagFrequency.prefix(10)),
            suspiciousTags: suspiciousTags,
            exfiltrationRisk: exfiltrationRisk,
            riskScore: riskScore
        )
    }
    
    // MARK: - Cross-User ML Analysis (Zero-Knowledge)
    
    /// ML prediction across users without accessing actual data
    func analyzeAcrossUsers(vaults: [Vault]) -> CrossUserThreatMetrics {
        // Aggregate ONLY metadata (never content)
        var totalAccesses = 0
        var allCoordinates: [CLLocationCoordinate2D] = []
        var allTags: [String] = []
        var accessTypeDistribution: [String: Int] = [:]
        
        for vault in vaults {
            // Access logs (location metadata)
            if let logs = vault.accessLogs {
                totalAccesses += logs.count
                
                let coords = logs.compactMap { log -> CLLocationCoordinate2D? in
                    guard let lat = log.locationLatitude,
                          let lon = log.locationLongitude else { return nil }
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
                allCoordinates.append(contentsOf: coords)
                
                for log in logs {
                    accessTypeDistribution[log.accessType, default: 0] += 1
                }
            }
            
            // Document tags (metadata)
            if let documents = vault.documents {
                let tags = documents.flatMap { $0.aiTags }
                allTags.append(contentsOf: tags)
            }
        }
        
        // ML Analysis on aggregated metadata
        let geoPatterns = analyzeGlobalGeoPatterns(allCoordinates)
        let tagPatterns = analyzeGlobalTagPatterns(allTags)
        let accessPatterns = analyzeGlobalAccessPatterns(accessTypeDistribution)
        
        // Predict potential threats
        let threatPredictions = predictThreats(
            geoPatterns: geoPatterns,
            tagPatterns: tagPatterns,
            accessPatterns: accessPatterns
        )
        
        return CrossUserThreatMetrics(
            totalVaultsAnalyzed: vaults.count,
            totalAccessEvents: totalAccesses,
            globalGeoPatterns: geoPatterns,
            globalTagPatterns: tagPatterns,
            threatPredictions: threatPredictions,
            confidenceScore: calculateConfidence(vaults.count)
        )
    }
    
    // MARK: - Integration with Formal Logic Threat Inference
    
    /// Combine ML threat analysis with logical threat scores
    /// This method integrates formal logic inferences with ML-based analysis
    func combineWithLogicalThreatScores(
        vault: Vault,
        logicalScores: GranularThreatScores
    ) async -> ThreatMetrics {
        // Get ML-based threat metrics
        let geoMetrics = await analyzeGeoClassification(for: vault)
        let accessMetrics = await analyzeAccessPatterns(for: vault)
        let tagMetrics = analyzeTagPatterns(for: vault)
        
        // Extract ML composite score from component metrics
        let mlCompositeScore = (geoMetrics.riskScore + accessMetrics.riskScore + tagMetrics.riskScore) / 3.0
        
        // Combine ML score with logical score using weighted average
        // The combination is done in FormalLogicThreatInferenceService.augmentThreatIndex()
        // This method provides the ML component for that combination
        
        // Determine overall risk level based on combined score
        let overallRiskScore = mlCompositeScore // This will be combined with logical score by caller
        let riskLevel: ThreatMetrics.ThreatLevel
        if overallRiskScore >= 75 {
            riskLevel = .critical
        } else if overallRiskScore >= 50 {
            riskLevel = .high
        } else if overallRiskScore >= 25 {
            riskLevel = .medium
        } else {
            riskLevel = .low
        }
        
        let metrics = ThreatMetrics(
            geoMetrics: geoMetrics,
            accessMetrics: accessMetrics,
            tagMetrics: tagMetrics,
            overallRiskScore: mlCompositeScore,
            riskLevel: riskLevel
        )
        
        self.threatMetrics = metrics
        return metrics
    }
    
    /// Calculate composite ML threat score for integration with formal logic
    func calculateMLCompositeScore(for vault: Vault) async -> Double {
        let geoMetrics = await analyzeGeoClassification(for: vault)
        let accessMetrics = await analyzeAccessPatterns(for: vault)
        let tagMetrics = analyzeTagPatterns(for: vault)
        
        // Weighted average of component scores
        // Geographic and access patterns are more indicative of active threats
        let composite = (geoMetrics.riskScore * 0.4) +
                       (accessMetrics.riskScore * 0.4) +
                       (tagMetrics.riskScore * 0.2)
        
        return min(100.0, max(0.0, composite))
    }
    
    // MARK: - Private Helpers
    
    private func clusterLocations(_ coordinates: [CLLocationCoordinate2D]) -> [[CLLocationCoordinate2D]] {
        // Simple DBSCAN-like clustering
        var clusters: [[CLLocationCoordinate2D]] = []
        var visited = Set<Int>()
        let epsilon = 0.01 // ~1km radius
        
        for i in 0..<coordinates.count {
            if visited.contains(i) { continue }
            
            var cluster = [coordinates[i]]
            visited.insert(i)
            
            for j in 0..<coordinates.count {
                if i == j || visited.contains(j) { continue }
                
                let distance = calculateDistance(coordinates[i], coordinates[j])
                if distance < epsilon {
                    cluster.append(coordinates[j])
                    visited.insert(j)
                }
            }
            
            clusters.append(cluster)
        }
        
        return clusters
    }
    
    private func calculateDistance(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
        let lat1 = coord1.latitude * .pi / 180
        let lat2 = coord2.latitude * .pi / 180
        let dLat = lat2 - lat1
        let dLon = (coord2.longitude - coord1.longitude) * .pi / 180
        
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1) * cos(lat2) *
                sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return 6371 * c // Earth radius in km
    }
    
    private func detectGeoAnomalies(_ coordinates: [CLLocationCoordinate2D], clusters: [[CLLocationCoordinate2D]]) -> [CLLocationCoordinate2D] {
        var suspicious: [CLLocationCoordinate2D] = []
        
        // Detect impossible travel (> 1000 km/hour)
        for i in 1..<coordinates.count {
            let distance = calculateDistance(coordinates[i-1], coordinates[i])
            if distance > 1000 { // More than 1000km between accesses (likely impossible)
                suspicious.append(coordinates[i])
            }
        }
        
        // Detect outlier locations (far from all clusters)
        for coord in coordinates {
            let minDistanceToCluster = clusters.map { cluster in
                cluster.map { calculateDistance(coord, $0) }.min() ?? Double.infinity
            }.min() ?? 0
            
            if minDistanceToCluster > 100 { // > 100km from any cluster
                suspicious.append(coord)
            }
        }
        
        return suspicious
    }
    
    private func calculateLocationSpread(_ coordinates: [CLLocationCoordinate2D]) -> Double {
        guard coordinates.count > 1 else { return 0 }
        
        let avgLat = coordinates.map { $0.latitude }.reduce(0, +) / Double(coordinates.count)
        let avgLon = coordinates.map { $0.longitude }.reduce(0, +) / Double(coordinates.count)
        
        let variance = coordinates.map { coord in
            pow(coord.latitude - avgLat, 2) + pow(coord.longitude - avgLon, 2)
        }.reduce(0, +) / Double(coordinates.count)
        
        return sqrt(variance)
    }
    
    private func calculateGeoRiskScore(locations: [CLLocationCoordinate2D], clusters: [[CLLocationCoordinate2D]], spread: Double) -> Double {
        var risk: Double = 0
        
        // Too many clusters (account sharing?)
        if clusters.count > 5 {
            risk += 0.3
        }
        
        // Large spread (accessed from many distant locations)
        if spread > 1.0 { // > 100km variance
            risk += 0.4
        }
        
        // Too many total locations
        if locations.count > 50 {
            risk += 0.3
        }
        
        return min(risk, 1.0)
    }
    
    private func detectTemporalAnomalies(_ timestamps: [Date]) -> Int {
        guard timestamps.count > 2 else { return 0 }
        
        let sorted = timestamps.sorted()
        var anomalies = 0
        
        for i in 1..<sorted.count {
            let interval = sorted[i].timeIntervalSince(sorted[i-1])
            
            // Access within 10 seconds (automated script?)
            if interval < 10 {
                anomalies += 1
            }
            
            // Huge gap (> 30 days) then sudden activity
            if interval > 30 * 24 * 3600 {
                anomalies += 1
            }
        }
        
        return anomalies
    }
    
    private func analyzeAccessFrequency(_ timestamps: [Date]) -> Double {
        guard timestamps.count > 1 else { return 0 }
        
        let sorted = timestamps.sorted()
        let timeSpan = sorted.last!.timeIntervalSince(sorted.first!)
        
        guard timeSpan > 0 else { return 0 }
        
        // Accesses per day
        return Double(timestamps.count) / (timeSpan / 86400)
    }
    
    private func detectUnusualAccessTimes(_ timestamps: [Date]) -> Int {
        let calendar = Calendar.current
        var unusualCount = 0
        
        for timestamp in timestamps {
            let hour = calendar.component(.hour, from: timestamp)
            
            // 1 AM - 5 AM is unusual
            if hour >= 1 && hour <= 5 {
                unusualCount += 1
            }
        }
        
        return unusualCount
    }
    
    private func detectAccessBursts(_ timestamps: [Date]) -> Int {
        guard timestamps.count > 5 else { return 0 }
        
        let sorted = timestamps.sorted()
        var bursts = 0
        
        for i in 5..<sorted.count {
            let recentFive = sorted[(i-5)...i]
            let timeSpan = recentFive.last!.timeIntervalSince(recentFive.first!)
            
            // 5 accesses within 1 minute
            if timeSpan < 60 {
                bursts += 1
            }
        }
        
        return bursts
    }
    
    private func calculateAccessPatternRisk(temporalAnomalies: Int, unusualTimes: Int, bursts: Int) -> Double {
        var risk: Double = 0
        
        risk += min(Double(temporalAnomalies) * 0.1, 0.3)
        risk += min(Double(unusualTimes) * 0.05, 0.3)
        risk += min(Double(bursts) * 0.2, 0.4)
        
        return min(risk, 1.0)
    }
    
    private func detectSuspiciousTags(_ tagFrequency: [(String, Int)]) -> [String] {
        let suspiciousKeywords = [
            "password", "secret", "confidential", "classified",
            "hack", "exploit", "vulnerability", "breach",
            "stolen", "leaked", "unauthorized"
        ]
        
        return tagFrequency
            .filter { tag, _ in
                suspiciousKeywords.contains(where: { tag.lowercased().contains($0) })
            }
            .map { $0.0 }
    }
    
    private func detectExfiltrationPatterns(_ documents: [Document]) -> Double {
        var risk: Double = 0
        
        // Sudden large uploads (data dump?)
        let last24h = documents.filter {
            $0.uploadedAt > Date().addingTimeInterval(-86400)
        }
        
        if last24h.count > 20 {
            risk += 0.5
        }
        
        // Large number of sink documents (receiving lots of external data)
        let sinkCount = documents.filter { $0.sourceSinkType == "sink" }.count
        if Double(sinkCount) / Double(max(documents.count, 1)) > 0.8 {
            risk += 0.3
        }
        
        return min(risk, 1.0)
    }
    
    private func detectUnusualDocumentTypes(_ documents: [Document]) -> [String] {
        let typeDistribution = Dictionary(grouping: documents, by: { $0.documentType })
            .mapValues { $0.count }
        
        // Detect types that are < 5% of total (outliers)
        let threshold = Double(documents.count) * 0.05
        
        return typeDistribution
            .filter { Double($0.value) < threshold && $0.value < 3 }
            .map { $0.key }
    }
    
    private func calculateTagRiskScore(suspiciousTags: [String], exfiltration: Double, unusualTypes: [String]) -> Double {
        var risk: Double = 0
        
        risk += min(Double(suspiciousTags.count) * 0.2, 0.4)
        risk += exfiltration * 0.4
        risk += min(Double(unusualTypes.count) * 0.1, 0.2)
        
        return min(risk, 1.0)
    }
    
    // MARK: - Cross-User ML (Zero-Knowledge)
    
    private func analyzeGlobalGeoPatterns(_ coordinates: [CLLocationCoordinate2D]) -> String {
        let clusters = clusterLocations(coordinates)
        
        if clusters.count > 10 {
            return "High geographic diversity detected across users"
        } else if clusters.count > 5 {
            return "Moderate geographic spread"
        } else {
            return "Concentrated geographic usage"
        }
    }
    
    private func analyzeGlobalTagPatterns(_ tags: [String]) -> String {
        let uniqueTags = Set(tags)
        
        if uniqueTags.count > 100 {
            return "Highly diverse document types across users"
        } else if uniqueTags.count > 50 {
            return "Moderate document diversity"
        } else {
            return "Focused document usage"
        }
    }
    
    private func analyzeGlobalAccessPatterns(_ distribution: [String: Int]) -> String {
        let total = distribution.values.reduce(0, +)
        
        if let mostCommon = distribution.max(by: { $0.value < $1.value }) {
            let percentage = Double(mostCommon.value) / Double(total) * 100
            return "Most common: \(mostCommon.key) (\(Int(percentage))%)"
        }
        
        return "Balanced access patterns"
    }
    
    private func predictThreats(geoPatterns: String, tagPatterns: String, accessPatterns: String) -> [String] {
        var predictions: [String] = []
        
        // ML-style prediction based on patterns
        if geoPatterns.contains("High geographic diversity") {
            predictions.append("Potential account sharing detected (multiple locations)")
        }
        
        if tagPatterns.contains("Highly diverse") {
            predictions.append("Normal usage: Wide variety of document types")
        }
        
        if accessPatterns.contains("viewed") && accessPatterns.contains("80") {
            predictions.append("Read-heavy usage pattern (low risk)")
        }
        
        // Default: No immediate threats
        if predictions.isEmpty {
            predictions.append("No anomalous patterns detected")
        }
        
        return predictions
    }
    
    private func calculateConfidence(_ vaultCount: Int) -> Double {
        // More vaults = more data = higher confidence
        return min(Double(vaultCount) / 10.0, 1.0)
    }
}

// MARK: - Models

struct GeoThreatMetrics {
    let accessLocations: Int
    let uniqueLocations: Int
    let locationSpread: Double
    let suspiciousLocations: [CLLocationCoordinate2D]
    let riskScore: Double
}

struct AccessPatternMetrics {
    let totalAccesses: Int
    let accessTypes: [String: Int]
    let frequency: Double // Accesses per day
    let unusualTimeCount: Int
    let burstsDetected: Int
    let riskScore: Double
}

struct TagThreatMetrics {
    let totalTags: Int
    let uniqueTags: Int
    let topTags: [(String, Int)]
    let suspiciousTags: [String]
    let exfiltrationRisk: Double
    let riskScore: Double
}

struct CrossUserThreatMetrics {
    let totalVaultsAnalyzed: Int
    let totalAccessEvents: Int
    let globalGeoPatterns: String
    let globalTagPatterns: String
    let threatPredictions: [String]
    let confidenceScore: Double
}

struct ThreatMetrics {
    let geoMetrics: GeoThreatMetrics
    let accessMetrics: AccessPatternMetrics
    let tagMetrics: TagThreatMetrics
    let overallRiskScore: Double
    let riskLevel: ThreatLevel
    
    enum ThreatLevel: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
}


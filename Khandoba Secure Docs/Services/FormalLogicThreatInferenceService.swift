//
//  FormalLogicThreatInferenceService.swift
//  Khandoba Secure Docs
//
//  Formal logic-based threat inference service with granular scoring
//

import Foundation
import SwiftData
import Combine
import CoreLocation

@MainActor
final class FormalLogicThreatInferenceService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var lastAnalysisResult: ThreatInferenceResult?
    
    private var modelContext: ModelContext?
    private var formalLogicEngine: FormalLogicEngine?
    private var threatMonitoringService: ThreatMonitoringService?
    private var mlThreatAnalysisService: MLThreatAnalysisService?
    private var vaultService: VaultService?
    private var documentService: DocumentService?
    private var antiVaultService: AntiVaultService?
    
    // Store historical scores for trend analysis
    private var scoreHistory: [UUID: [ThreatScoreSnapshot]] = [:]
    
    nonisolated init() {}
    
    func configure(
        modelContext: ModelContext,
        formalLogicEngine: FormalLogicEngine,
        threatMonitoringService: ThreatMonitoringService? = nil,
        mlThreatAnalysisService: MLThreatAnalysisService? = nil,
        vaultService: VaultService? = nil,
        documentService: DocumentService? = nil,
        antiVaultService: AntiVaultService? = nil
    ) {
        self.modelContext = modelContext
        self.formalLogicEngine = formalLogicEngine
        self.threatMonitoringService = threatMonitoringService
        self.mlThreatAnalysisService = mlThreatAnalysisService
        self.vaultService = vaultService
        self.documentService = documentService
        self.antiVaultService = antiVaultService
    }
    
    // MARK: - Main Analysis Method
    
    /// Analyze vault for threats using formal logic inference
    func analyzeVaultForThreats(vault: Vault) async -> ThreatInferenceResult {
        print("🔍 FormalLogicThreatInference: Analyzing vault '\(vault.name)' for threats")
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        guard let formalLogicEngine = formalLogicEngine else {
            print("⚠️ FormalLogicEngine not configured")
            return createEmptyResult(for: vault)
        }
        
        // Step 1: Collect observations from vault data
        let observations = await collectObservations(from: vault)
        
        // Step 2: Build knowledge base
        let knowledgeBase = buildKnowledgeBase(from: vault)
        
        // Step 3: Add observations and facts to logic engine
        for obs in observations {
            formalLogicEngine.addObservation(obs)
        }
        for fact in knowledgeBase {
            formalLogicEngine.addFact(fact)
        }
        
        // Step 4: Run formal logic analysis
        let analysisReport = formalLogicEngine.performCompleteLogicalAnalysis()
        let allInferences = analysisReport.allInferences
        
        // Step 5: Calculate granular threat scores
        let granularScores = calculateGranularThreatScores(inferences: allInferences, vault: vault)
        
        // Step 6: Determine threat level
        let threatLevel = GranularThreatLevel(score: granularScores.compositeScore)
        
        // Step 7: Generate recommendations
        let recommendations = generateRecommendations(
            granularScores: granularScores,
            inferences: allInferences
        )
        
        // Step 8: Update score history
        updateScoreHistory(for: vault.id, scores: granularScores)
        
        // Step 9: Calculate trends
        let (delta, velocity) = calculateScoreTrends(vaultID: vault.id, currentScore: granularScores.compositeScore)
        let scoresWithTrends = GranularThreatScores(
            compositeScore: granularScores.compositeScore,
            logicScores: granularScores.logicScores,
            categoryScores: granularScores.categoryScores,
            inferenceContributions: granularScores.inferenceContributions,
            scoreDelta: delta,
            scoreVelocity: velocity
        )
        
        let result = ThreatInferenceResult(
            vaultID: vault.id,
            granularScores: scoresWithTrends,
            threatLevel: threatLevel,
            threatInferences: allInferences,
            categoryBreakdown: granularScores.categoryScores,
            logicBreakdown: granularScores.logicScores,
            inferenceContributions: granularScores.inferenceContributions,
            recommendations: recommendations,
            calculatedAt: Date(),
            scoreHistory: scoreHistory[vault.id]
        )
        
        lastAnalysisResult = result
        
        print("✅ FormalLogicThreatInference: Analysis complete")
        print("   Composite Score: \(String(format: "%.2f", granularScores.compositeScore))")
        print("   Threat Level: \(threatLevel.rawValue)")
        print("   Inferences: \(allInferences.count)")
        
        return result
    }
    
    // MARK: - Observation Collection
    
    /// Collect observations from vault data for formal logic analysis
    func collectObservations(from vault: Vault) async -> [LogicalObservation] {
        var observations: [LogicalObservation] = []
        
        // Access Log Observations
        let accessLogs = vault.accessLogs ?? []
        for log in accessLogs {
            // Night access observation
            let hour = Calendar.current.component(.hour, from: log.timestamp)
            if hour >= 1 && hour <= 5 {
                observations.append(LogicalObservation(
                    subject: vault.id.uuidString,
                    property: "night_access",
                    value: "true",
                    timestamp: log.timestamp,
                    confidence: 1.0
                ))
            }
            
            // Impossible travel (geographic anomaly)
            if let lat = log.locationLatitude, let lon = log.locationLongitude {
                if hasGeographicAnomaly(for: log, in: accessLogs) {
                    observations.append(LogicalObservation(
                        subject: vault.id.uuidString,
                        property: "impossible_travel",
                        value: "true",
                        timestamp: log.timestamp,
                        confidence: 0.85
                    ))
                }
                
                // Unusual location
                if isUnusualLocation(lat: lat, lon: lon, in: accessLogs) {
                    observations.append(LogicalObservation(
                        subject: vault.id.uuidString,
                        property: "unusual_location",
                        value: "\(lat),\(lon)",
                        timestamp: log.timestamp,
                        confidence: 0.7
                    ))
                }
            }
            
            // Rapid access
            if hasRapidAccess(for: log, in: accessLogs) {
                observations.append(LogicalObservation(
                    subject: vault.id.uuidString,
                    property: "rapid_access",
                    value: "true",
                    timestamp: log.timestamp,
                    confidence: 0.8
                ))
            }
            
            // Access hour for temporal analysis
            observations.append(LogicalObservation(
                subject: vault.id.uuidString,
                property: "access_hour",
                value: "\(hour)",
                timestamp: log.timestamp,
                confidence: 1.0
            ))
        }
        
        // Document Observations
        let documents = vault.documents ?? []
        for document in documents {
            // Malicious hash check (if implemented)
            if let hash = document.fileHash, await isMaliciousHash(hash) {
                observations.append(LogicalObservation(
                    subject: document.id.uuidString,
                    property: "malicious_hash",
                    value: "true",
                    timestamp: document.uploadedAt,
                    confidence: 0.95
                ))
            }
            
            // Suspicious tags
            for tag in document.aiTags {
                if isSuspiciousTag(tag) {
                    observations.append(LogicalObservation(
                        subject: document.id.uuidString,
                        property: "suspicious_tags",
                        value: tag,
                        timestamp: document.uploadedAt,
                        confidence: 0.6
                    ))
                }
            }
            
            // Document type for compliance analysis
            if document.documentType == "medical" {
                observations.append(LogicalObservation(
                    subject: document.id.uuidString,
                    property: "topic",
                    value: "medical",
                    timestamp: document.uploadedAt,
                    confidence: 1.0
                ))
            }
            
            // Confidential documents
            if document.aiTags.contains("confidential") || document.aiTags.contains("classified") {
                observations.append(LogicalObservation(
                    subject: document.id.uuidString,
                    property: "is_confidential",
                    value: "true",
                    timestamp: document.uploadedAt,
                    confidence: 0.9
                ))
            }
        }
        
        // Vault Metadata Observations
        let confidentialCount = documents.filter { doc in
            doc.aiTags.contains("confidential") || doc.aiTags.contains("classified")
        }.count
        
        if confidentialCount >= 3 {
            observations.append(LogicalObservation(
                subject: vault.id.uuidString,
                property: "high_value_content",
                value: "\(confidentialCount)",
                timestamp: Date(),
                confidence: 0.85
            ))
        }
        
        // Check for breach detection from ThreatMonitoringService
        if let threatService = threatMonitoringService {
            let threatLevel = await threatService.analyzeThreatLevel(for: vault)
            if threatLevel == .high || threatLevel == .critical {
                observations.append(LogicalObservation(
                    subject: vault.id.uuidString,
                    property: "breach_detected",
                    value: "true",
                    timestamp: Date(),
                    confidence: 0.8
                ))
            }
        }
        
        // Check for compliance requirements
        let hasMedical = documents.contains { $0.documentType == "medical" || $0.aiTags.contains("medical") }
        let hasLegal = documents.contains { $0.aiTags.contains("legal") }
        if hasMedical && hasLegal {
            observations.append(LogicalObservation(
                subject: vault.id.uuidString,
                property: "compliance_required",
                value: "HIPAA",
                timestamp: Date(),
                confidence: 1.0
            ))
        }
        
        print("📊 Collected \(observations.count) observations from vault")
        return observations
    }
    
    // MARK: - Knowledge Base Construction
    
    /// Build knowledge base from vault data
    func buildKnowledgeBase(from vault: Vault) -> [Fact] {
        var facts: [Fact] = []
        
        let documents = vault.documents ?? []
        
        // Extract entity facts from documents
        for document in documents {
            // Document type facts
            facts.append(Fact(
                subject: document.id.uuidString,
                predicate: "is_a",
                object: document.documentType,
                source: document.id,
                confidence: 1.0
            ))
            
            // Tag facts
            for tag in document.aiTags {
                facts.append(Fact(
                    subject: document.id.uuidString,
                    predicate: "has_topic",
                    object: tag,
                    source: document.id,
                    confidence: 0.9
                ))
            }
        }
        
        return facts
    }
    
    // MARK: - Granular Score Calculation
    
    /// Calculate granular threat scores from inferences
    func calculateGranularThreatScores(inferences: [LogicalInference], vault: Vault) -> GranularThreatScores {
        // Calculate component scores
        let (logicScores, categoryScores) = calculateComponentScores(inferences: inferences, vault: vault)
        
        // Calculate composite score
        let compositeScore = calculateCompositeLogicalScore(
            logicScores: logicScores,
            categoryScores: categoryScores
        )
        
        // Calculate inference contributions
        let contributions = calculateInferenceContributions(
            inferences: inferences,
            logicScores: logicScores,
            categoryScores: categoryScores
        )
        
        return GranularThreatScores(
            compositeScore: compositeScore,
            logicScores: logicScores,
            categoryScores: categoryScores,
            inferenceContributions: contributions,
            scoreDelta: nil,
            scoreVelocity: nil
        )
    }
    
    /// Calculate component scores by logic type and category
    func calculateComponentScores(inferences: [LogicalInference], vault: Vault) -> (LogicComponentScores, ThreatCategoryScores) {
        // Logic type scores
        var deductiveScore: Double = 0.0
        var inductiveScore: Double = 0.0
        var abductiveScore: Double = 0.0
        var statisticalScore: Double = 0.0
        var analogicalScore: Double = 0.0
        var temporalScore: Double = 0.0
        var modalScore: Double = 0.0
        
        // Category scores
        var accessPatternScore: Double = 0.0
        var geographicScore: Double = 0.0
        var documentContentScore: Double = 0.0
        var behavioralScore: Double = 0.0
        var externalThreatScore: Double = 0.0
        var complianceScore: Double = 0.0
        var dataExfiltrationScore: Double = 0.0
        
        for inference in inferences {
            // Logic type contribution
            let threatContribution = inference.confidence * 100.0
            
            switch inference.type {
            case .deductive:
                deductiveScore = max(deductiveScore, threatContribution)
            case .inductive:
                inductiveScore = max(inductiveScore, threatContribution)
            case .abductive:
                abductiveScore = max(abductiveScore, threatContribution)
            case .statistical:
                statisticalScore = max(statisticalScore, threatContribution)
            case .analogical:
                analogicalScore = max(analogicalScore, threatContribution)
            case .temporal:
                temporalScore = max(temporalScore, threatContribution)
            case .modal:
                modalScore = max(modalScore, threatContribution)
            }
            
            // Category contribution (map inference conclusion/observations to categories)
            let category = categorizeInference(inference)
            let categoryContribution = threatContribution * 0.3 // Category gets portion of contribution
            
            switch category {
            case .accessPattern:
                accessPatternScore += categoryContribution
            case .geographic:
                geographicScore += categoryContribution
            case .documentContent:
                documentContentScore += categoryContribution
            case .behavioral:
                behavioralScore += categoryContribution
            case .externalThreat:
                externalThreatScore += categoryContribution
            case .compliance:
                complianceScore += categoryContribution
            case .dataExfiltration:
                dataExfiltrationScore += categoryContribution
            }
        }
        
        // Normalize category scores to 0-100
        accessPatternScore = min(100.0, accessPatternScore)
        geographicScore = min(100.0, geographicScore)
        documentContentScore = min(100.0, documentContentScore)
        behavioralScore = min(100.0, behavioralScore)
        externalThreatScore = min(100.0, externalThreatScore)
        complianceScore = min(100.0, complianceScore)
        dataExfiltrationScore = min(100.0, dataExfiltrationScore)
        
        let logicScores = LogicComponentScores(
            deductiveScore: deductiveScore,
            inductiveScore: inductiveScore,
            abductiveScore: abductiveScore,
            statisticalScore: statisticalScore,
            analogicalScore: analogicalScore,
            temporalScore: temporalScore,
            modalScore: modalScore
        )
        
        let categoryScores = ThreatCategoryScores(
            accessPatternScore: accessPatternScore,
            geographicScore: geographicScore,
            documentContentScore: documentContentScore,
            behavioralScore: behavioralScore,
            externalThreatScore: externalThreatScore,
            complianceScore: complianceScore,
            dataExfiltrationScore: dataExfiltrationScore
        )
        
        return (logicScores, categoryScores)
    }
    
    /// Calculate composite logical threat score from component scores
    func calculateCompositeLogicalScore(
        logicScores: LogicComponentScores,
        categoryScores: ThreatCategoryScores
    ) -> Double {
        // Logic scores: Weighted by certainty
        let logicComposite =
            (logicScores.deductiveScore * 1.0) +      // 100% weight (certain)
            (logicScores.inductiveScore * 0.8) +      // 80% weight
            (logicScores.abductiveScore * 0.7) +      // 70% weight
            (logicScores.statisticalScore * 0.9) +    // 90% weight (probability-based)
            (logicScores.analogicalScore * 0.6) +     // 60% weight
            (logicScores.temporalScore * 0.75) +      // 75% weight
            (logicScores.modalScore * 0.65)           // 65% weight
        
        let logicNormalized = logicComposite / 5.4 // Normalize by sum of weights
        
        // Category scores: Maximum of all categories
        let categoryComposite = max(
            categoryScores.accessPatternScore,
            categoryScores.geographicScore,
            categoryScores.documentContentScore,
            categoryScores.behavioralScore,
            categoryScores.externalThreatScore,
            categoryScores.complianceScore,
            categoryScores.dataExfiltrationScore
        )
        
        // Combined: 60% logic-based, 40% category-based
        let composite = (logicNormalized * 0.6) + (categoryComposite * 0.4)
        
        return min(100.0, max(0.0, composite))
    }
    
    /// Calculate individual inference contributions
    func calculateInferenceContributions(
        inferences: [LogicalInference],
        logicScores: LogicComponentScores,
        categoryScores: ThreatCategoryScores
    ) -> [InferenceContribution] {
        var contributions: [InferenceContribution] = []
        
        for inference in inferences {
            let category = categorizeInference(inference)
            
            // Calculate contribution based on confidence and logic type weight
            let baseContribution = inference.confidence * 100.0
            let weight = getLogicTypeWeight(inference.type)
            let contributionScore = baseContribution * weight
            
            // Determine impact level
            let impact: ThreatImpact
            if contributionScore >= 76 {
                impact = .critical
            } else if contributionScore >= 51 {
                impact = .high
            } else if contributionScore >= 26 {
                impact = .medium
            } else {
                impact = .low
            }
            
            contributions.append(InferenceContribution(
                inferenceID: inference.id,
                inference: inference,
                logicType: inference.type,
                category: category,
                contributionScore: contributionScore,
                confidence: inference.confidence,
                impact: impact
            ))
        }
        
        // Sort by contribution score descending
        return contributions.sorted { $0.contributionScore > $1.contributionScore }
    }
    
    // MARK: - Threat Index Augmentation
    
    /// Augment existing threat index with granular logical scores
    func augmentThreatIndex(
        vault: Vault,
        granularScores: GranularThreatScores,
        existingScore: Double,
        mlScores: ThreatMetrics?
    ) -> (augmentedScore: Double, breakdown: ThreatScoreBreakdown) {
        
        // Extract ML composite score
        let mlComposite = mlScores?.overallRiskScore ?? 0.0
        
        // Weighted combination: 40% logical, 40% ML, 20% existing
        let augmented = (granularScores.compositeScore * 0.4) +
                        (mlComposite * 0.4) +
                        (existingScore * 0.2)
        
        // Get top 5 contributing inferences
        let topThreats = Array(granularScores.inferenceContributions.prefix(5))
        
        let breakdown = ThreatScoreBreakdown(
            logicalComponent: granularScores.compositeScore,
            mlComponent: mlComposite,
            existingComponent: existingScore,
            finalScore: min(100.0, max(0.0, augmented)),
            contributions: granularScores.inferenceContributions,
            topThreats: topThreats
        )
        
        return (min(100.0, max(0.0, augmented)), breakdown)
    }
    
    /// Update vault threat metrics with analysis result
    func updateVaultThreatMetrics(vault: Vault, result: ThreatInferenceResult) async throws {
        guard let modelContext = modelContext else {
            throw ThreatInferenceError.contextNotAvailable
        }
        
        // Get existing scores
        let existingScore = vault.threatIndex
        
        // Get ML threat metrics if available
        var mlMetrics: ThreatMetrics?
        if let mlService = mlThreatAnalysisService {
            // MLThreatAnalysisService doesn't have a single method that returns ThreatMetrics
            // We'll calculate a composite from available metrics
            let geoMetrics = await mlService.analyzeGeoClassification(for: vault)
            let accessMetrics = await mlService.analyzeAccessPatterns(for: vault)
            let tagMetrics = mlService.analyzeTagPatterns(for: vault)
            
            // Calculate overall risk score from components
            let overallRiskScore = (geoMetrics.riskScore + accessMetrics.riskScore + tagMetrics.riskScore) / 3.0
            
            let threatLevel: ThreatMetrics.ThreatLevel
            if overallRiskScore >= 75 {
                threatLevel = .critical
            } else if overallRiskScore >= 50 {
                threatLevel = .high
            } else if overallRiskScore >= 25 {
                threatLevel = .medium
            } else {
                threatLevel = .low
            }
            
            mlMetrics = ThreatMetrics(
                geoMetrics: geoMetrics,
                accessMetrics: accessMetrics,
                tagMetrics: tagMetrics,
                overallRiskScore: overallRiskScore,
                riskLevel: threatLevel
            )
        }
        
        // Augment threat index
        let (augmentedScore, _) = augmentThreatIndex(
            vault: vault,
            granularScores: result.granularScores,
            existingScore: existingScore,
            mlScores: mlMetrics
        )
        
        // Update vault properties
        vault.threatIndex = round(augmentedScore * 100) / 100 // Round to 2 decimals
        vault.threatLevel = mapGranularToLegacyLevel(result.threatLevel)
        vault.lastThreatAssessmentAt = Date()
        
        try modelContext.save()
        
        print("✅ Updated vault threat metrics: score=\(String(format: "%.2f", augmentedScore)), level=\(vault.threatLevel)")
    }
    
    // MARK: - Helper Methods
    
    private func hasGeographicAnomaly(for log: VaultAccessLog, in logs: [VaultAccessLog]) -> Bool {
        guard let lat = log.locationLatitude, let lon = log.locationLongitude else { return false }
        
        let previousLogs = logs.filter { $0.timestamp < log.timestamp }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(10)
        
        for prevLog in previousLogs {
            if let prevLat = prevLog.locationLatitude, let prevLon = prevLog.locationLongitude {
                let distance = calculateDistance(
                    from: (prevLat, prevLon),
                    to: (lat, lon)
                )
                let timeDiff = abs(log.timestamp.timeIntervalSince(prevLog.timestamp))
                
                // If distance > 500km and time < 1 hour, it's impossible travel
                if distance > 500 && timeDiff < 3600 {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func isUnusualLocation(lat: Double, lon: Double, in logs: [VaultAccessLog]) -> Bool {
        let locations = logs.compactMap { log -> (Double, Double)? in
            guard let logLat = log.locationLatitude, let logLon = log.locationLongitude else { return nil }
            return (logLat, logLon)
        }
        
        guard locations.count >= 3 else { return false }
        
        // Check if location is far from all other locations
        for (otherLat, otherLon) in locations {
            let distance = calculateDistance(from: (lat, lon), to: (otherLat, otherLon))
            if distance < 100 { // Within 100km of known location
                return false
            }
        }
        
        return true
    }
    
    private func hasRapidAccess(for log: VaultAccessLog, in logs: [VaultAccessLog]) -> Bool {
        let recentLogs = logs.filter { abs($0.timestamp.timeIntervalSince(log.timestamp)) < 60 }
            .filter { $0.id != log.id }
        
        return recentLogs.count >= 5 // 5+ accesses within 1 minute
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
    
    private func isMaliciousHash(_ hash: String) async -> Bool {
        // TODO: Implement hash checking against threat databases
        // For now, return false
        return false
    }
    
    private func isSuspiciousTag(_ tag: String) -> Bool {
        let suspiciousKeywords = [
            "password", "secret", "confidential", "classified",
            "hack", "exploit", "vulnerability", "breach",
            "stolen", "leaked", "unauthorized"
        ]
        
        return suspiciousKeywords.contains { tag.lowercased().contains($0) }
    }
    
    private func categorizeInference(_ inference: LogicalInference) -> ThreatCategory {
        let conclusion = inference.conclusion.lowercased()
        let observation = inference.observation.lowercased()
        
        if conclusion.contains("location") || conclusion.contains("geographic") || observation.contains("travel") {
            return .geographic
        } else if conclusion.contains("access") || conclusion.contains("brute force") || observation.contains("rapid") {
            return .accessPattern
        } else if conclusion.contains("malware") || conclusion.contains("file") || conclusion.contains("document") {
            return .documentContent
        } else if conclusion.contains("compliance") || conclusion.contains("hipaa") || conclusion.contains("legal") {
            return .compliance
        } else if conclusion.contains("exfiltration") || conclusion.contains("data flow") || observation.contains("sink") {
            return .dataExfiltration
        } else if conclusion.contains("behavior") || conclusion.contains("pattern") || observation.contains("unusual") {
            return .behavioral
        } else if conclusion.contains("malicious") || conclusion.contains("blacklist") || observation.contains("ip") {
            return .externalThreat
        }
        
        return .behavioral // Default
    }
    
    private func getLogicTypeWeight(_ type: LogicType) -> Double {
        switch type {
        case .deductive: return 1.0
        case .statistical: return 0.9
        case .inductive: return 0.8
        case .temporal: return 0.75
        case .abductive: return 0.7
        case .modal: return 0.65
        case .analogical: return 0.6
        }
    }
    
    private func generateRecommendations(
        granularScores: GranularThreatScores,
        inferences: [LogicalInference]
    ) -> [ThreatRecommendation] {
        var recommendations: [ThreatRecommendation] = []
        var priority = 1
        
        // Check for critical threats
        if granularScores.compositeScore >= 80 {
            recommendations.append(ThreatRecommendation(
                priority: priority,
                category: .accessPattern,
                action: "Immediately lock vault and require dual-key authentication",
                rationale: "Extreme threat level detected",
                expectedImpact: 30.0,
                urgency: .immediate
            ))
            priority += 1
        }
        
        // Category-specific recommendations
        if granularScores.categoryScores.externalThreatScore > 80 {
            recommendations.append(ThreatRecommendation(
                priority: priority,
                category: .externalThreat,
                action: "Block access from known malicious IP addresses",
                rationale: "External threat indicators detected",
                expectedImpact: 25.0,
                urgency: .immediate
            ))
            priority += 1
        }
        
        if granularScores.categoryScores.complianceScore > 60 {
            recommendations.append(ThreatRecommendation(
                priority: priority,
                category: .compliance,
                action: "Enable compliance review and audit logging",
                rationale: "Compliance requirements detected",
                expectedImpact: 15.0,
                urgency: .urgent
            ))
            priority += 1
        }
        
        if granularScores.categoryScores.geographicScore > 75 {
            recommendations.append(ThreatRecommendation(
                priority: priority,
                category: .geographic,
                action: "Enable geofencing restrictions",
                rationale: "Unusual geographic access patterns detected",
                expectedImpact: 20.0,
                urgency: .urgent
            ))
            priority += 1
        }
        
        // Add actionable recommendations from inferences
        for inference in inferences.prefix(5) {
            if let actionable = inference.actionable {
                recommendations.append(ThreatRecommendation(
                    priority: priority,
                    category: categorizeInference(inference),
                    action: actionable,
                    rationale: inference.conclusion,
                    expectedImpact: inference.confidence * 10.0,
                    urgency: inference.confidence > 0.8 ? .urgent : .important
                ))
                priority += 1
            }
        }
        
        return recommendations.sorted { $0.priority < $1.priority }
    }
    
    private func updateScoreHistory(for vaultID: UUID, scores: GranularThreatScores) {
        if scoreHistory[vaultID] == nil {
            scoreHistory[vaultID] = []
        }
        
        let snapshot = ThreatScoreSnapshot(
            timestamp: Date(),
            compositeScore: scores.compositeScore,
            categoryScores: scores.categoryScores,
            logicScores: scores.logicScores
        )
        
        scoreHistory[vaultID]?.append(snapshot)
        
        // Keep only last 100 snapshots
        if let history = scoreHistory[vaultID], history.count > 100 {
            scoreHistory[vaultID] = Array(history.suffix(100))
        }
    }
    
    private func calculateScoreTrends(vaultID: UUID, currentScore: Double) -> (delta: Double?, velocity: Double?) {
        guard let history = scoreHistory[vaultID], history.count >= 2 else {
            return (nil, nil)
        }
        
        let previousScore = history[history.count - 2].compositeScore
        let delta = currentScore - previousScore
        
        // Calculate velocity (score change per hour)
        let timeDiff = history.last!.timestamp.timeIntervalSince(history[history.count - 2].timestamp)
        let velocity = timeDiff > 0 ? delta / (timeDiff / 3600) : nil
        
        return (delta, velocity)
    }
    
    private func createEmptyResult(for vault: Vault) -> ThreatInferenceResult {
        let emptyLogicScores = LogicComponentScores(
            deductiveScore: 0, inductiveScore: 0, abductiveScore: 0,
            statisticalScore: 0, analogicalScore: 0, temporalScore: 0, modalScore: 0
        )
        let emptyCategoryScores = ThreatCategoryScores(
            accessPatternScore: 0, geographicScore: 0, documentContentScore: 0,
            behavioralScore: 0, externalThreatScore: 0, complianceScore: 0, dataExfiltrationScore: 0
        )
        let emptyGranularScores = GranularThreatScores(
            compositeScore: 0,
            logicScores: emptyLogicScores,
            categoryScores: emptyCategoryScores,
            inferenceContributions: [],
            scoreDelta: nil,
            scoreVelocity: nil
        )
        
        return ThreatInferenceResult(
            vaultID: vault.id,
            granularScores: emptyGranularScores,
            threatLevel: .minimal,
            threatInferences: [],
            categoryBreakdown: emptyCategoryScores,
            logicBreakdown: emptyLogicScores,
            inferenceContributions: [],
            recommendations: [],
            calculatedAt: Date(),
            scoreHistory: nil
        )
    }
    
    private func mapGranularToLegacyLevel(_ granular: GranularThreatLevel) -> String {
        switch granular {
        case .minimal, .veryLow, .low:
            return "low"
        case .lowMedium, .medium:
            return "medium"
        case .mediumHigh, .high:
            return "high"
        case .highCritical, .critical, .extreme:
            return "critical"
        }
    }
}

// MARK: - Models

struct LogicComponentScores {
    let deductiveScore: Double      // 0-100
    let inductiveScore: Double      // 0-100
    let abductiveScore: Double      // 0-100
    let statisticalScore: Double    // 0-100
    let analogicalScore: Double     // 0-100
    let temporalScore: Double       // 0-100
    let modalScore: Double          // 0-100
}

struct ThreatCategoryScores {
    let accessPatternScore: Double      // 0-100
    let geographicScore: Double         // 0-100
    let documentContentScore: Double    // 0-100
    let behavioralScore: Double         // 0-100
    let externalThreatScore: Double     // 0-100
    let complianceScore: Double         // 0-100
    let dataExfiltrationScore: Double   // 0-100
}

struct GranularThreatScores {
    let compositeScore: Double              // 0-100 (primary metric)
    let logicScores: LogicComponentScores
    let categoryScores: ThreatCategoryScores
    let inferenceContributions: [InferenceContribution]
    let scoreDelta: Double?                 // Change from last assessment
    let scoreVelocity: Double?              // Rate of change
}

struct InferenceContribution {
    let inferenceID: UUID
    let inference: LogicalInference
    let logicType: LogicType
    let category: ThreatCategory
    let contributionScore: Double        // 0-100
    let confidence: Double
    let impact: ThreatImpact
}

enum ThreatCategory {
    case accessPattern
    case geographic
    case documentContent
    case behavioral
    case externalThreat
    case compliance
    case dataExfiltration
}

enum ThreatImpact {
    case low       // 0-25 contribution
    case medium    // 26-50 contribution
    case high      // 51-75 contribution
    case critical  // 76-100 contribution
}

enum GranularThreatLevel: String, CaseIterable {
    case minimal = "Minimal"           // 0.0-10.0
    case veryLow = "Very Low"          // 10.1-20.0
    case low = "Low"                   // 20.1-30.0
    case lowMedium = "Low-Medium"      // 30.1-40.0
    case medium = "Medium"             // 40.1-50.0
    case mediumHigh = "Medium-High"    // 50.1-60.0
    case high = "High"                 // 60.1-70.0
    case highCritical = "High-Critical" // 70.1-80.0
    case critical = "Critical"         // 80.1-90.0
    case extreme = "Extreme"           // 90.1-100.0
    
    init(score: Double) {
        switch score {
        case 0.0..<10.1: self = .minimal
        case 10.1..<20.1: self = .veryLow
        case 20.1..<30.1: self = .low
        case 30.1..<40.1: self = .lowMedium
        case 40.1..<50.1: self = .medium
        case 50.1..<60.1: self = .mediumHigh
        case 60.1..<70.1: self = .high
        case 70.1..<80.1: self = .highCritical
        case 80.1..<90.1: self = .critical
        default: self = .extreme
        }
    }
    
    var numericValue: Int {
        switch self {
        case .minimal: return 1
        case .veryLow: return 2
        case .low: return 3
        case .lowMedium: return 4
        case .medium: return 5
        case .mediumHigh: return 6
        case .high: return 7
        case .highCritical: return 8
        case .critical: return 9
        case .extreme: return 10
        }
    }
    
    var requiresAction: Bool {
        return numericValue >= 6 // Medium-High and above
    }
    
    var requiresImmediateAction: Bool {
        return numericValue >= 8 // High-Critical and above
    }
}

struct ThreatInferenceResult {
    let vaultID: UUID
    let granularScores: GranularThreatScores
    let threatLevel: GranularThreatLevel
    let threatInferences: [LogicalInference]
    let categoryBreakdown: ThreatCategoryScores
    let logicBreakdown: LogicComponentScores
    let inferenceContributions: [InferenceContribution]
    let recommendations: [ThreatRecommendation]
    let calculatedAt: Date
    let scoreHistory: [ThreatScoreSnapshot]?
}

struct ThreatRecommendation {
    let priority: Int
    let category: ThreatCategory
    let action: String
    let rationale: String
    let expectedImpact: Double
    let urgency: UrgencyLevel
}

enum UrgencyLevel {
    case immediate      // Act within 1 hour
    case urgent         // Act within 24 hours
    case important      // Act within 1 week
    case routine        // Act within 1 month
}

struct ThreatScoreSnapshot {
    let timestamp: Date
    let compositeScore: Double
    let categoryScores: ThreatCategoryScores
    let logicScores: LogicComponentScores
}

struct ThreatScoreBreakdown {
    let logicalComponent: Double
    let mlComponent: Double
    let existingComponent: Double
    let finalScore: Double
    let contributions: [InferenceContribution]
    let topThreats: [InferenceContribution] // Top 5 contributing inferences
}

enum AntiVaultAction {
    case noAction
    case monitorClosely(reason: String)
    case enableEnhancedMonitoring(reason: String)
    case requireDualKeyForAccess(reason: String)
    case lockWithDualKeyRequirement(reason: String)
    case immediateLock(reason: String)
    case preventiveLock(reason: String)
}

enum ThreatInferenceError: LocalizedError {
    case contextNotAvailable
    case engineNotConfigured
    case vaultNotFound
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Model context not available"
        case .engineNotConfigured:
            return "Formal logic engine not configured"
        case .vaultNotFound:
            return "Vault not found"
        }
    }
}


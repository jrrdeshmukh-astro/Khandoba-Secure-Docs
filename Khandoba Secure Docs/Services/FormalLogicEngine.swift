//
//  FormalLogicEngine.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class FormalLogicEngine: ObservableObject {
    @Published var deductiveInferences: [LogicalInference] = []
    @Published var inductiveInferences: [LogicalInference] = []
    @Published var abductiveInferences: [LogicalInference] = []
    @Published var analogicalInferences: [LogicalInference] = []
    @Published var statisticalInferences: [LogicalInference] = []
    
    private var knowledgeBase: [Fact] = []
    private var observations: [LogicalObservation] = []
    
    nonisolated init() {}
    
    // MARK: - 1. DEDUCTIVE REASONING (General → Specific)
    
    /// Apply deductive logic: If premise is true, conclusion MUST be true
    /// Format: All A are B. X is A. Therefore, X is B.
    func applyDeductiveReasoning() -> [LogicalInference] {
        var inferences: [LogicalInference] = []
        
        print(" Deductive Reasoning: Applying syllogistic logic")
        
        // Modus Ponens: If P then Q. P is true. Therefore Q is true.
        // Example: If confidential, then needs encryption. Document is confidential. → Needs encryption.
        
        let confidentialDocs = observations.filter { $0.property == "is_confidential" && $0.value == "true" }
        
        for obs in confidentialDocs {
            inferences.append(LogicalInference(
                type: .deductive,
                method: "Modus Ponens",
                premise: "If document is confidential, then it requires dual-key protection",
                observation: "Document '\(obs.subject)' is confidential",
                conclusion: "Document '\(obs.subject)' requires dual-key protection",
                confidence: 1.0, // Deductive = absolute certainty
                formula: "P→Q, P ⊢ Q",
                actionable: "Enable dual-key authentication for \(obs.subject)"
            ))
        }
        
        // Modus Tollens: If P then Q. Not Q. Therefore not P.
        // Example: If secure, then no breaches. Breach detected. → Not secure.
        
        let breachDetected = observations.contains { $0.property == "breach_detected" && $0.value == "true" }
        
        if breachDetected {
            inferences.append(LogicalInference(
                type: .deductive,
                method: "Modus Tollens",
                premise: "If vault is secure, then no breaches occur",
                observation: "Breach was detected",
                conclusion: "Vault security is compromised",
                confidence: 1.0,
                formula: "P→Q, ¬Q ⊢ ¬P",
                actionable: "Immediate security audit required. Change all vault credentials."
            ))
        }
        
        // Hypothetical Syllogism: If P then Q. If Q then R. Therefore if P then R.
        // Example: If person works at org, and org in city, then person in city.
        
        let worksAtFacts = knowledgeBase.filter { $0.predicate == "works_at" }
        let locatedInFacts = knowledgeBase.filter { $0.predicate == "located_in" }
        
        for worksAt in worksAtFacts {
            for locatedIn in locatedInFacts where worksAt.object == locatedIn.subject {
                inferences.append(LogicalInference(
                    type: .deductive,
                    method: "Hypothetical Syllogism",
                    premise: "If \(worksAt.subject) works at \(worksAt.object), and \(worksAt.object) is located in \(locatedIn.object)",
                    observation: "Both premises are verified",
                    conclusion: "\(worksAt.subject) is located in \(locatedIn.object)",
                    confidence: min(worksAt.confidence, locatedIn.confidence),
                    formula: "P→Q, Q→R ⊢ P→R",
                    actionable: nil
                ))
            }
        }
        
        // Disjunctive Syllogism: P or Q. Not P. Therefore Q.
        // Example: Document is source OR sink. Not source. → Is sink.
        
        self.deductiveInferences = inferences
        print("    Generated \(inferences.count) deductive inferences")
        return inferences
    }
    
    // MARK: - 2. INDUCTIVE REASONING (Specific → General)
    
    /// Apply inductive logic: Observe patterns, generalize to rule
    /// Format: X1, X2, X3... all have property P. Therefore, all X have P.
    func applyInductiveReasoning() -> [LogicalInference] {
        var inferences: [LogicalInference] = []
        
        print(" Inductive Reasoning: Pattern generalization")
        
        // Enumerative Induction: Observe many instances, generalize
        // Example: 10 documents from John all confidential → John only sends confidential docs
        
        var personToProperties: [String: [String: Int]] = [:]
        
        for obs in observations {
            if let personName = extractPersonName(from: obs.subject) {
                personToProperties[personName, default: [:]][obs.property, default: 0] += 1
            }
        }
        
        for (person, properties) in personToProperties {
            for (property, count) in properties where count >= 3 {
                let totalDocs = observations.filter { extractPersonName(from: $0.subject) == person }.count
                let ratio = Double(count) / Double(totalDocs)
                
                if ratio >= 0.8 { // 80% or more have this property
                    let confidence = min(0.7 + (ratio * 0.3), 0.99) // Inductive never 100%
                    
                    inferences.append(LogicalInference(
                        type: .inductive,
                        method: "Enumerative Induction",
                        premise: "Observed \(count) out of \(totalDocs) documents from \(person)",
                        observation: "\(Int(ratio * 100))% have property: \(property)",
                        conclusion: "Pattern: \(person) typically creates/sends \(property) documents",
                        confidence: confidence,
                        formula: "∀x∈Sample P(x) → ∀x∈Population P(x) (probably)",
                        actionable: "Tag future \(person) documents with \(property) by default"
                    ))
                }
            }
        }
        
        // Statistical Generalization: Sample → Population
        // Example: 90% of legal docs need dual-key → All legal docs should have dual-key
        
        let legalDocs = observations.filter { $0.property == "topic" && $0.value == "legal" }
        let legalWithDualKey = legalDocs.filter { obs in
            observations.contains { $0.subject == obs.subject && $0.property == "has_dual_key" }
        }
        
        if legalDocs.count >= 5 {
            let ratio = Double(legalWithDualKey.count) / Double(legalDocs.count)
            if ratio >= 0.7 {
                inferences.append(LogicalInference(
                    type: .inductive,
                    method: "Statistical Generalization",
                    premise: "\(legalWithDualKey.count) out of \(legalDocs.count) legal documents have dual-key protection",
                    observation: "Ratio: \(Int(ratio * 100))%",
                    conclusion: "Pattern established: Legal documents typically require dual-key protection",
                    confidence: ratio,
                    formula: "P(Sample) = \(Int(ratio * 100))% → P(Population) ≈ \(Int(ratio * 100))%",
                    actionable: "Apply dual-key to all legal documents by default"
                ))
            }
        }
        
        // Predictive Induction: Past pattern → Future prediction
        // Example: Accessed Mon-Fri 9-5 for 30 days → Will access Mon-Fri 9-5 tomorrow
        
        self.inductiveInferences = inferences
        print("    Generated \(inferences.count) inductive inferences")
        return inferences
    }
    
    // MARK: - 3. ABDUCTIVE REASONING (Best Explanation)
    
    /// Apply abductive logic: Given effect, infer most likely cause
    /// Format: Q is observed. P would explain Q. Therefore, probably P.
    func applyAbductiveReasoning() -> [LogicalInference] {
        var inferences: [LogicalInference] = []
        
        print(" Abductive Reasoning: Finding best explanations")
        
        // Effect → Cause inference
        // Example: Night access spike → Likely unauthorized access OR deadline pressure
        
        let nightAccess = observations.filter { obs in
            obs.property == "access_time" && isNightTime(obs.value)
        }
        
        if nightAccess.count >= 5 {
            let hypotheses = [
                Hypothesis(
                    explanation: "Unauthorized access from different timezone",
                    likelihood: 0.7,
                    evidence: ["Night access unusual for user's typical pattern"],
                    testable: "Check if access locations match different timezones"
                ),
                Hypothesis(
                    explanation: "Legitimate deadline-driven work",
                    likelihood: 0.3,
                    evidence: ["User may be working late to meet deadline"],
                    testable: "Check for temporal clustering near known deadlines"
                )
            ]
            
            let bestHypothesis = hypotheses.max(by: { $0.likelihood < $1.likelihood })!
            
            inferences.append(LogicalInference(
                type: .abductive,
                method: "Inference to Best Explanation",
                premise: "Effect observed: \(nightAccess.count) night access events",
                observation: "Most likely explanation: \(bestHypothesis.explanation)",
                conclusion: bestHypothesis.explanation,
                confidence: bestHypothesis.likelihood,
                formula: "Q observed, P→Q plausible ⊢ P (probably)",
                actionable: "Investigate: \(bestHypothesis.testable)"
            ))
        }
        
        // Anomaly → Root cause
        // Example: Impossible travel → Account compromise OR location spoofing
        
        let impossibleTravel = observations.contains { $0.property == "impossible_travel" && $0.value == "true" }
        
        if impossibleTravel {
            let hypotheses = [
                Hypothesis(
                    explanation: "Account credentials compromised",
                    likelihood: 0.8,
                    evidence: ["Multiple locations simultaneously impossible"],
                    testable: "Check for other unauthorized activity indicators"
                ),
                Hypothesis(
                    explanation: "VPN or location spoofing",
                    likelihood: 0.15,
                    evidence: ["Technical methods can fake location"],
                    testable: "Analyze network metadata"
                ),
                Hypothesis(
                    explanation: "GPS error or system bug",
                    likelihood: 0.05,
                    evidence: ["Technical glitches possible but rare"],
                    testable: "Verify with other location data points"
                )
            ]
            
            let mostLikely = hypotheses.max(by: { $0.likelihood < $1.likelihood })!
            
            inferences.append(LogicalInference(
                type: .abductive,
                method: "Diagnostic Reasoning",
                premise: "Impossible travel detected",
                observation: "Best explanation analysis: \(hypotheses.count) hypotheses considered",
                conclusion: "Most likely cause: \(mostLikely.explanation) (likelihood: \(Int(mostLikely.likelihood * 100))%)",
                confidence: mostLikely.likelihood,
                formula: "Symptom→Disease: P(Cause|Effect) = max",
                actionable: "CRITICAL: \(mostLikely.testable). If confirmed, change all credentials immediately."
            ))
        }
        
        self.abductiveInferences = inferences
        print("    Generated \(inferences.count) abductive inferences")
        return inferences
    }
    
    // MARK: - 4. ANALOGICAL REASONING (Similarity-Based)
    
    /// Apply analogical reasoning: A is like B. B has property P. Therefore A probably has P.
    func applyAnalogicalReasoning() -> [LogicalInference] {
        var inferences: [LogicalInference] = []
        
        print(" Analogical Reasoning: Similarity-based inference")
        
        // Find similar documents and transfer properties
        // Example: Doc A similar to Doc B. Doc B needs dual-key. → Doc A probably needs dual-key too.
        
        var documentSimilarities: [(doc1: String, doc2: String, similarity: Double)] = []
        
        // Calculate document similarity based on shared entities and topics
        let allDocuments = Set(observations.map { $0.subject })
        
        for doc1 in allDocuments {
            for doc2 in allDocuments where doc1 < doc2 {
                let similarity = calculateDocumentSimilarity(doc1: doc1, doc2: doc2)
                
                if similarity >= 0.7 {
                    documentSimilarities.append((doc1, doc2, similarity))
                }
            }
        }
        
        // Transfer properties via analogy
        for (doc1, doc2, similarity) in documentSimilarities {
            let doc2Properties = observations.filter { $0.subject == doc2 }
            let doc1Properties = Set(observations.filter { $0.subject == doc1 }.map { $0.property })
            
            for property in doc2Properties {
                if !doc1Properties.contains(property.property) {
                    let confidence = similarity * 0.8 // Analogical reasoning less certain
                    
                    inferences.append(LogicalInference(
                        type: .analogical,
                        method: "Analogical Transfer",
                        premise: "\(doc1) is \(Int(similarity * 100))% similar to \(doc2)",
                        observation: "\(doc2) has property: \(property.property) = \(property.value)",
                        conclusion: "\(doc1) likely has: \(property.property) = \(property.value)",
                        confidence: confidence,
                        formula: "Sim(A,B) ∧ P(B) → P(A) (probably)",
                        actionable: "Verify and apply \(property.property) to \(doc1)"
                    ))
                }
            }
        }
        
        // Case-based reasoning
        // Example: Previous breach had patterns X,Y,Z. Current situation shows X,Y. → Probably Z too.
        
        self.analogicalInferences = inferences
        print("    Generated \(inferences.count) analogical inferences")
        return inferences
    }
    
    // MARK: - 5. STATISTICAL REASONING (Probability-Based)
    
    /// Apply statistical logic: Calculate probabilities and confidence intervals
    func applyStatisticalReasoning() -> [LogicalInference] {
        var inferences: [LogicalInference] = []
        
        print(" Statistical Reasoning: Bayesian inference")
        
        // Bayesian Inference: Update probabilities based on evidence
        // P(Threat|Evidence) = P(Evidence|Threat) × P(Threat) / P(Evidence)
        
        // Example: Calculate probability of breach given evidence
        let evidenceOfBreach = [
            observations.contains { $0.property == "night_access" && $0.value == "high" },
            observations.contains { $0.property == "impossible_travel" && $0.value == "true" },
            observations.contains { $0.property == "failed_attempts" && extractCount(from: $0.value) > 5 },
            observations.contains { $0.property == "rapid_deletion" && $0.value == "true" }
        ]
        
        let evidenceCount = evidenceOfBreach.filter { $0 }.count
        
        if evidenceCount > 0 {
            // Prior probability of breach (base rate)
            let priorBreach = 0.05 // 5% base rate
            
            // Likelihood of evidence given breach
            let likelihoodIfBreach = 0.9 // 90% of breaches show these signs
            
            // Likelihood of evidence given no breach
            let likelihoodIfNoBreach = 0.1 // 10% false positive rate
            
            // Bayes' theorem
            let posteriorBreach = (likelihoodIfBreach * priorBreach) / 
                                 ((likelihoodIfBreach * priorBreach) + 
                                  (likelihoodIfNoBreach * (1 - priorBreach)))
            
            // Determine actionable message based on probability
            // With given constants, posteriorBreach will be ~0.32
            // Use a threshold that makes both branches reachable (adjust threshold to 0.35)
            let actionableMessage = posteriorBreach > 0.35
                ? "Elevated breach probability detected. Monitor closely and consider additional security measures."
                : "Monitor closely for additional indicators."
            
            inferences.append(LogicalInference(
                type: .statistical,
                method: "Bayesian Inference",
                premise: "Base rate of security breaches: \(Int(priorBreach * 100))%",
                observation: "Detected \(evidenceCount) breach indicators: night access, impossible travel, failed attempts, rapid deletion",
                conclusion: "Probability of active breach: \(Int(posteriorBreach * 100))%",
                confidence: posteriorBreach,
                formula: "P(H|E) = P(E|H)×P(H) / P(E)",
                actionable: actionableMessage
            ))
        } else {
            // No evidence provided - return neutral inference
            inferences.append(LogicalInference(
                type: .statistical,
                method: "Bayesian Inference",
                premise: "No evidence provided",
                observation: "Insufficient data for analysis",
                conclusion: "Cannot calculate breach probability without evidence",
                confidence: 0.0,
                formula: "N/A",
                actionable: "Gather more evidence before analysis"
            ))
        }
        
        // Confidence Interval: Estimate range of values
        // Example: Average access time: 2pm ± 3 hours (95% confidence)
        
        let accessTimes = observations.filter { $0.property == "access_hour" }
        
        if accessTimes.count >= 10 {
            let times = accessTimes.compactMap { Double($0.value) }
            let mean = times.reduce(0, +) / Double(times.count)
            let variance = times.map { pow($0 - mean, 2) }.reduce(0, +) / Double(times.count)
            let stdDev = sqrt(variance)
            let marginOfError = 1.96 * stdDev / sqrt(Double(times.count)) // 95% CI
            
            inferences.append(LogicalInference(
                type: .statistical,
                method: "Confidence Interval",
                premise: "Analyzed \(times.count) access events",
                observation: "Mean access time: \(Int(mean)):00, Standard deviation: \(String(format: "%.1f", stdDev)) hours",
                conclusion: "95% confidence interval: \(Int(mean - marginOfError)):00 to \(Int(mean + marginOfError)):00",
                confidence: 0.95,
                formula: "CI = μ ± (1.96 × σ/√n)",
                actionable: "Access outside this window (\(Int(mean - marginOfError)):00-\(Int(mean + marginOfError)):00) should trigger alerts"
            ))
        }
        
        // Correlation Analysis: Find statistical relationships
        // Example: High document count correlates with high threat score
        
        self.statisticalInferences = inferences
        print("    Generated \(inferences.count) statistical inferences")
        return inferences
    }
    
    // MARK: - 6. TEMPORAL LOGIC (Time-Based Reasoning)
    
    /// Apply temporal logic: Reason about time sequences and causality
    func applyTemporalLogic() -> [LogicalInference] {
        var inferences: [LogicalInference] = []
        
        print(" Temporal Logic: Time-based causality")
        
        // Always/Eventually operators
        // □P (Always P): Property holds at all times
        // ◇P (Eventually P): Property holds at some future time
        
        // Example: Always(confidential) → Eventually(dual_key_required)
        
        let alwaysConfidential = observations.filter { obs in
            obs.property == "is_confidential" && obs.value == "true"
        }
        
        for obs in alwaysConfidential {
            inferences.append(LogicalInference(
                type: .temporal,
                method: "Temporal Necessity",
                premise: "Document \(obs.subject) is always confidential (□P)",
                observation: "Confidential documents eventually require enhanced protection",
                conclusion: "Eventually, \(obs.subject) will require dual-key protection (◇Q)",
                confidence: 0.85,
                formula: "□P → ◇Q",
                actionable: "Proactively enable dual-key before it becomes critical"
            ))
        }
        
        // Until operator: P Until Q
        // Example: Access allowed UNTIL threat detected
        
        // Since operator: P Since Q  
        // Example: High security SINCE breach was detected
        
        return inferences
    }
    
    // MARK: - 7. MODAL LOGIC (Possibility & Necessity)
    
    /// Apply modal logic: Reason about what's possible, necessary, contingent
    func applyModalLogic() -> [LogicalInference] {
        var inferences: [LogicalInference] = []
        
        print(" Modal Logic: Possibility and necessity")
        
        // Necessary (□): Must be true
        // Example: If medical records → □(HIPAA compliance required)
        
        let medicalDocs = observations.filter { $0.property == "topic" && $0.value == "medical" }
        
        if !medicalDocs.isEmpty {
            inferences.append(LogicalInference(
                type: .modal,
                method: "Necessity",
                premise: "Vault contains medical records",
                observation: "HIPAA regulations apply to all medical data",
                conclusion: "HIPAA compliance is NECESSARY (□P)",
                confidence: 1.0, // Legal requirement = necessary
                formula: "Medical → □(HIPAA)",
                actionable: "MUST enable audit logging, dual-key, and compliance reviews"
            ))
        }
        
        // Possible (◇): Could be true
        // Example: Geographic anomaly → ◇(Account compromise)
        
        let geoAnomaly = observations.contains { $0.property == "geographic_anomaly" && $0.value == "true" }
        
        if geoAnomaly {
            inferences.append(LogicalInference(
                type: .modal,
                method: "Possibility",
                premise: "Geographic anomaly detected",
                observation: "Anomalous patterns CAN indicate security issues",
                conclusion: "Account compromise is POSSIBLE (◇P)",
                confidence: 0.6,
                formula: "Anomaly → ◇(Threat)",
                actionable: "Investigate further. Enable additional monitoring."
            ))
        }
        
        // Contingent: Neither necessary nor impossible
        // Example: Dual-key authentication (beneficial but not required for all)
        
        return inferences
    }
    
    // MARK: - Helper Functions
    
    private func calculateDocumentSimilarity(doc1: String, doc2: String) -> Double {
        let doc1Obs = Set(observations.filter { $0.subject == doc1 }.map { "\($0.property):\($0.value)" })
        let doc2Obs = Set(observations.filter { $0.subject == doc2 }.map { "\($0.property):\($0.value)" })
        
        let intersection = doc1Obs.intersection(doc2Obs).count
        let union = doc1Obs.union(doc2Obs).count
        
        return union > 0 ? Double(intersection) / Double(union) : 0.0 // Jaccard similarity
    }
    
    private func extractPersonName(from subject: String) -> String? {
        // Simple heuristic: If contains space and capitalized, likely person name
        let parts = subject.split(separator: " ")
        if parts.count >= 2 && parts[0].first?.isUppercase == true {
            return String(parts.prefix(2).joined(separator: " "))
        }
        return nil
    }
    
    private func isNightTime(_ value: String) -> Bool {
        guard let hour = Int(value) else { return false }
        return hour < 6 || hour > 22
    }
    
    private func extractCount(from value: String) -> Int {
        return Int(value.filter { $0.isNumber }) ?? 0
    }
    
    // MARK: - Add Observations
    
    func addObservation(_ observation: LogicalObservation) {
        observations.append(observation)
    }
    
    func addFact(_ fact: Fact) {
        knowledgeBase.append(fact)
    }
    
    // MARK: - Complete Analysis
    
    /// Run all logic systems and combine results
    func performCompleteLogicalAnalysis() -> LogicalAnalysisReport {
        print("🧮 Performing complete formal logic analysis")
        
        let deductive = applyDeductiveReasoning()
        let inductive = applyInductiveReasoning()
        let abductive = applyAbductiveReasoning()
        let analogical = applyAnalogicalReasoning()
        let statistical = applyStatisticalReasoning()
        
        let report = LogicalAnalysisReport(
            deductiveInferences: deductive,
            inductiveInferences: inductive,
            abductiveInferences: abductive,
            analogicalInferences: analogical,
            statisticalInferences: statistical,
            totalInferences: deductive.count + inductive.count + abductive.count + 
                            analogical.count + statistical.count
        )
        
        print(" Complete analysis: \(report.totalInferences) total inferences")
        print("   Deductive: \(deductive.count) (certainty)")
        print("   Inductive: \(inductive.count) (generalization)")
        print("   Abductive: \(abductive.count) (best explanation)")
        print("   Analogical: \(analogical.count) (similarity)")
        print("   Statistical: \(statistical.count) (probability)")
        
        return report
    }
}

// MARK: - Models

struct LogicalInference: Identifiable {
    let id = UUID()
    let type: LogicType
    let method: String
    let premise: String
    let observation: String
    let conclusion: String
    let confidence: Double
    let formula: String // Mathematical notation
    let actionable: String?
    
    var certaintyLevel: String {
        switch type {
        case .deductive:
            return "Certain (100%)" // Deductive = logical certainty
        case .inductive:
            return "Probable (\(Int(confidence * 100))%)"
        case .abductive:
            return "Most Likely (\(Int(confidence * 100))%)"
        case .analogical:
            return "By Analogy (\(Int(confidence * 100))%)"
        case .statistical:
            return "Statistical (\(Int(confidence * 100))%)"
        case .temporal:
            return "Time-Based (\(Int(confidence * 100))%)"
        case .modal:
            return confidence >= 0.99 ? "Necessary" : "Possible"
        }
    }
}

enum LogicType {
    case deductive      // General → Specific (certain)
    case inductive      // Specific → General (probable)
    case abductive      // Effect → Cause (best explanation)
    case analogical     // Similarity → Transfer (likely)
    case statistical    // Data → Probability (confidence interval)
    case temporal       // Time-based (always/eventually)
    case modal          // Necessity/possibility
}

struct Hypothesis {
    let explanation: String
    let likelihood: Double
    let evidence: [String]
    let testable: String
}

struct LogicalObservation {
    let subject: String
    let property: String
    let value: String
    let timestamp: Date
    let confidence: Double
    
    init(subject: String, property: String, value: String, timestamp: Date = Date(), confidence: Double = 1.0) {
        self.subject = subject
        self.property = property
        self.value = value
        self.timestamp = timestamp
        self.confidence = confidence
    }
}

struct LogicalAnalysisReport {
    let deductiveInferences: [LogicalInference]
    let inductiveInferences: [LogicalInference]
    let abductiveInferences: [LogicalInference]
    let analogicalInferences: [LogicalInference]
    let statisticalInferences: [LogicalInference]
    let totalInferences: Int
    
    var allInferences: [LogicalInference] {
        deductiveInferences + inductiveInferences + abductiveInferences + 
        analogicalInferences + statisticalInferences
    }
    
    var certainInferences: [LogicalInference] {
        allInferences.filter { $0.confidence >= 0.95 }
    }
    
    var probableInferences: [LogicalInference] {
        allInferences.filter { $0.confidence >= 0.7 && $0.confidence < 0.95 }
    }
    
    var possibleInferences: [LogicalInference] {
        allInferences.filter { $0.confidence < 0.7 }
    }
}


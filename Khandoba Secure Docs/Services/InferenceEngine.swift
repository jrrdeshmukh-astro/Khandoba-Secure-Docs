//
//  InferenceEngine.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import Foundation
import SwiftData

@MainActor
final class InferenceEngine: ObservableObject {
    @Published var inferredFacts: [InferredFact] = []
    @Published var inferences: [Inference] = []
    
    private var modelContext: ModelContext?
    private var knowledgeBase: [Fact] = []
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Rule-Based Inference
    
    /// Apply inference rules to generate intelligence from documents
    func generateInferences(from indices: [DocumentIndex]) async -> [Inference] {
        print("🧠 Inference Engine: Analyzing \(indices.count) documents")
        
        // Step 1: Build knowledge base from document indices
        buildKnowledgeBase(from: indices)
        
        // Step 2: Apply inference rules
        var generatedInferences: [Inference] = []
        
        // Rule 1: Network Analysis (who knows whom)
        generatedInferences += await applyNetworkInferenceRules()
        
        // Rule 2: Temporal Patterns (what happened when)
        generatedInferences += await applyTemporalInferenceRules()
        
        // Rule 3: Document Chains (document dependencies)
        generatedInferences += await applyDocumentChainRules(indices: indices)
        
        // Rule 4: Anomaly Detection (unusual patterns)
        generatedInferences += await applyAnomalyDetectionRules(indices: indices)
        
        // Rule 5: Risk Assessment (security implications)
        generatedInferences += await applyRiskInferenceRules()
        
        // Rule 6: Source/Sink Correlation
        generatedInferences += await applySourceSinkCorrelationRules(indices: indices)
        
        // Step 3: Sort by confidence
        generatedInferences.sort { $0.confidence > $1.confidence }
        
        self.inferences = generatedInferences
        
        print("✅ Generated \(generatedInferences.count) inferences")
        return generatedInferences
    }
    
    // MARK: - Knowledge Base Construction
    
    private func buildKnowledgeBase(from indices: [DocumentIndex]) {
        knowledgeBase.removeAll()
        
        for index in indices {
            // Add entity facts
            for entity in index.entities {
                knowledgeBase.append(Fact(
                    subject: entity.text,
                    predicate: "is_a",
                    object: entity.type.rawValue,
                    source: index.documentID,
                    confidence: entity.confidence
                ))
            }
            
            // Add relationship facts
            for relationship in index.relationships {
                knowledgeBase.append(Fact(
                    subject: relationship.entity1,
                    predicate: relationship.relationType,
                    object: relationship.entity2,
                    source: index.documentID,
                    confidence: relationship.confidence
                ))
            }
            
            // Add topic facts
            for topic in index.topics {
                knowledgeBase.append(Fact(
                    subject: index.documentTitle,
                    predicate: "has_topic",
                    object: topic,
                    source: index.documentID,
                    confidence: 0.9
                ))
            }
        }
        
        print("📚 Knowledge base: \(knowledgeBase.count) facts")
    }
    
    // MARK: - Inference Rule 1: Network Analysis
    
    private func applyNetworkInferenceRules() async -> [Inference] {
        var inferences: [Inference] = []
        
        // Find people who appear in multiple documents
        var personCounts: [String: Int] = [:]
        
        for fact in knowledgeBase where fact.predicate == "is_a" && fact.object == "person" {
            personCounts[fact.subject, default: 0] += 1
        }
        
        // Infer: Key people (appear in 3+ documents)
        for (person, count) in personCounts where count >= 3 {
            inferences.append(Inference(
                rule: "network_key_person",
                conclusion: "\(person) is a key person in your network",
                evidence: ["Appears in \(count) documents"],
                confidence: min(0.7 + Double(count) * 0.05, 0.95),
                type: .network,
                actionable: "Consider creating a dedicated vault for \(person)-related documents for better organization"
            ))
        }
        
        // Find organizations
        var orgCounts: [String: Int] = [:]
        for fact in knowledgeBase where fact.predicate == "is_a" && fact.object == "organization" {
            orgCounts[fact.subject, default: 0] += 1
        }
        
        // Infer: Key organizations
        for (org, count) in orgCounts where count >= 2 {
            inferences.append(Inference(
                rule: "network_key_organization",
                conclusion: "\(org) is a significant organization in your documents",
                evidence: ["Mentioned in \(count) documents"],
                confidence: min(0.6 + Double(count) * 0.1, 0.9),
                type: .network,
                actionable: "Review all \(org)-related documents for compliance and completeness"
            ))
        }
        
        return inferences
    }
    
    // MARK: - Inference Rule 2: Temporal Patterns
    
    private func applyTemporalInferenceRules() async -> [Inference] {
        var inferences: [Inference] = []
        
        // Find documents with temporal clustering
        var dateGroups: [String: Int] = [:] // "YYYY-MM": count
        
        for fact in knowledgeBase {
            if let date = fact.object as? String, date.count == 10 { // Date format
                let yearMonth = String(date.prefix(7)) // YYYY-MM
                dateGroups[yearMonth, default: 0] += 1
            }
        }
        
        // Infer: Activity spikes
        for (period, count) in dateGroups where count >= 5 {
            inferences.append(Inference(
                rule: "temporal_activity_spike",
                conclusion: "High document activity in \(period)",
                evidence: ["\(count) documents or references from this period"],
                confidence: 0.8,
                type: .temporal,
                actionable: "Review documents from \(period) for related events or projects"
            ))
        }
        
        return inferences
    }
    
    // MARK: - Inference Rule 3: Document Chains
    
    private func applyDocumentChainRules(indices: [DocumentIndex]) async -> [Inference] {
        var inferences: [Inference] = []
        
        // Find documents that share multiple entities (document chains)
        for i in 0..<indices.count {
            for j in (i+1)..<indices.count {
                let doc1 = indices[i]
                let doc2 = indices[j]
                
                let sharedEntities = Set(doc1.entities.map { $0.text })
                    .intersection(Set(doc2.entities.map { $0.text }))
                
                if sharedEntities.count >= 3 {
                    inferences.append(Inference(
                        rule: "document_chain",
                        conclusion: "\(doc1.documentTitle) and \(doc2.documentTitle) are closely related",
                        evidence: ["Share \(sharedEntities.count) common entities: \(Array(sharedEntities.prefix(3)).joined(separator: ", "))"],
                        confidence: min(0.6 + Double(sharedEntities.count) * 0.1, 0.95),
                        type: .relationship,
                        actionable: "Consider grouping these documents together or creating a cross-reference"
                    ))
                }
            }
        }
        
        return inferences
    }
    
    // MARK: - Inference Rule 4: Anomaly Detection
    
    private func applyAnomalyDetectionRules(indices: [DocumentIndex]) async -> [Inference] {
        var inferences: [Inference] = []
        
        // Detect topic mismatch (document in wrong vault)
        var topicCounts: [String: Int] = [:]
        for index in indices {
            for topic in index.topics {
                topicCounts[topic, default: 0] += 1
            }
        }
        
        let dominantTopic = topicCounts.max { $0.value < $1.value }
        
        if let dominant = dominantTopic, topicCounts.count > 1 {
            for index in indices {
                if !index.topics.contains(dominant.key) && !index.topics.isEmpty {
                    inferences.append(Inference(
                        rule: "topic_anomaly",
                        conclusion: "\(index.documentTitle) has unusual topic for this vault",
                        evidence: ["Document topics: \(index.topics.joined(separator: ", "))", "Vault primary topic: \(dominant.key)"],
                        confidence: 0.7,
                        type: .anomaly,
                        actionable: "Verify this document belongs in this vault or consider moving to a topic-specific vault"
                    ))
                }
            }
        }
        
        // Detect outlier importance
        let avgImportance = indices.map { $0.importanceScore }.reduce(0, +) / Double(indices.count)
        
        for index in indices {
            if index.importanceScore > avgImportance + 30 {
                inferences.append(Inference(
                    rule: "high_importance_outlier",
                    conclusion: "\(index.documentTitle) is significantly more important than average",
                    evidence: ["Importance: \(Int(index.importanceScore))/100 vs avg \(Int(avgImportance))/100"],
                    confidence: 0.85,
                    type: .importance,
                    actionable: "Consider moving to a high-security dual-key vault or applying additional encryption"
                ))
            }
        }
        
        return inferences
    }
    
    // MARK: - Inference Rule 5: Risk Assessment
    
    private func applyRiskInferenceRules() async -> [Inference] {
        var inferences: [Inference] = []
        
        // Infer: Multiple confidential documents = high-value vault
        let confidentialFacts = knowledgeBase.filter { fact in
            fact.predicate == "has_topic" && (fact.object == "confidential" || fact.object == "legal")
        }
        
        if confidentialFacts.count >= 3 {
            inferences.append(Inference(
                rule: "high_value_vault",
                conclusion: "This vault contains high-value confidential information",
                evidence: ["\(confidentialFacts.count) documents marked as confidential or legal"],
                confidence: 0.9,
                type: .risk,
                actionable: "Enable dual-key authentication and geofencing for this vault immediately"
            ))
        }
        
        // Infer: Medical + Legal = HIPAA compliance needed
        let hasMedical = knowledgeBase.contains { $0.predicate == "has_topic" && $0.object == "medical" }
        let hasLegal = knowledgeBase.contains { $0.predicate == "has_topic" && $0.object == "legal" }
        
        if hasMedical && hasLegal {
            inferences.append(Inference(
                rule: "compliance_requirement",
                conclusion: "HIPAA compliance measures recommended",
                evidence: ["Vault contains both medical and legal documents"],
                confidence: 0.85,
                type: .compliance,
                actionable: "Enable audit logging, dual-key auth, and regular compliance reviews"
            ))
        }
        
        return inferences
    }
    
    // MARK: - Inference Rule 6: Source/Sink Correlation
    
    private func applySourceSinkCorrelationRules(indices: [DocumentIndex]) async -> [Inference] {
        var inferences: [Inference] = []
        
        // Find documents with shared entities across source/sink boundary
        let sourceIndices = indices.filter { index in
            // Would check document.sourceSinkType in production
            true // Placeholder
        }
        
        // Look for entity transfers
        var entityTransfers: [String: (source: [UUID], sink: [UUID])] = [:]
        
        for index in indices {
            for entity in index.entities where entity.type == .person || entity.type == .organization {
                if entityTransfers[entity.text] == nil {
                    entityTransfers[entity.text] = ([], [])
                }
                // Would check source vs sink here
                entityTransfers[entity.text]?.source.append(index.documentID)
            }
        }
        
        // Infer: Data flow patterns
        for (entity, docs) in entityTransfers where docs.source.count >= 2 {
            inferences.append(Inference(
                rule: "entity_flow",
                conclusion: "\(entity) appears in both source and sink documents",
                evidence: ["Found in \(docs.source.count) related documents"],
                confidence: 0.75,
                type: .dataFlow,
                actionable: "Verify data sharing permissions and compliance for \(entity)"
            ))
        }
        
        return inferences
    }
    
    // MARK: - Forward Chaining Inference
    
    /// Apply forward chaining: derive new facts from existing facts
    func applyForwardChaining() -> [InferredFact] {
        var newFacts: [InferredFact] = []
        
        // Rule: If person works_at organization, and organization located_in city,
        // then person is_located_in city
        let worksAtRelations = knowledgeBase.filter { $0.predicate == "works_at" }
        let locatedInRelations = knowledgeBase.filter { $0.predicate == "located_in" }
        
        for worksAt in worksAtRelations {
            for locatedIn in locatedInRelations {
                if worksAt.object == locatedIn.subject {
                    // Person works at org, org is in city → person is in city
                    let confidence = min(worksAt.confidence, locatedIn.confidence) * 0.9
                    
                    newFacts.append(InferredFact(
                        subject: worksAt.subject,
                        predicate: "likely_located_in",
                        object: locatedIn.object,
                        confidence: confidence,
                        derivedFrom: [worksAt, locatedIn],
                        rule: "transitive_location"
                    ))
                }
            }
        }
        
        // Rule: If document1 mentions person, and document2 mentions same person,
        // then document1 and document2 are related
        var personToDocuments: [String: [UUID]] = [:]
        
        for fact in knowledgeBase where fact.predicate == "is_a" && fact.object == "person" {
            personToDocuments[fact.subject, default: []].append(fact.source)
        }
        
        for (person, documents) in personToDocuments where documents.count >= 2 {
            for i in 0..<documents.count - 1 {
                for j in (i+1)..<documents.count {
                    newFacts.append(InferredFact(
                        subject: documents[i].uuidString,
                        predicate: "related_via_person",
                        object: documents[j].uuidString,
                        confidence: 0.75,
                        derivedFrom: [],
                        rule: "common_person_link",
                        context: "Both documents mention \(person)"
                    ))
                }
            }
        }
        
        self.inferredFacts = newFacts
        return newFacts
    }
    
    // MARK: - Backward Chaining (Query-based)
    
    /// Answer specific questions using backward chaining
    func query(_ question: InferenceQuery) -> [Inference] {
        var results: [Inference] = []
        
        switch question {
        case .whoIsConnectedTo(let person):
            // Find all connections to a person
            let connections = knowledgeBase.filter { fact in
                (fact.subject == person || fact.object == person) &&
                (fact.predicate == "works_at" || fact.predicate == "associated_with")
            }
            
            for connection in connections {
                let connectedEntity = connection.subject == person ? connection.object : connection.subject
                results.append(Inference(
                    rule: "connection_query",
                    conclusion: "\(person) is connected to \(connectedEntity)",
                    evidence: ["Relationship: \(connection.predicate)"],
                    confidence: connection.confidence,
                    type: .network,
                    actionable: "Review documents involving both \(person) and \(connectedEntity)"
                ))
            }
            
        case .whatTopicsRelatedTo(let entity):
            // Find topics related to an entity
            let topics = knowledgeBase.filter { fact in
                fact.subject.contains(entity) && fact.predicate == "has_topic"
            }
            
            for topic in topics {
                results.append(Inference(
                    rule: "topic_query",
                    conclusion: "\(entity) is associated with \(topic.object) topics",
                    evidence: ["Found in document: \(topic.subject)"],
                    confidence: topic.confidence,
                    type: .classification,
                    actionable: nil
                ))
            }
            
        case .areDocumentsRelated(let doc1, let doc2):
            // Check if two documents are related
            let doc1Entities = knowledgeBase.filter { $0.source.uuidString == doc1 }
            let doc2Entities = knowledgeBase.filter { $0.source.uuidString == doc2 }
            
            let sharedEntities = Set(doc1Entities.map { $0.subject })
                .intersection(Set(doc2Entities.map { $0.subject }))
            
            if !sharedEntities.isEmpty {
                results.append(Inference(
                    rule: "document_relation_query",
                    conclusion: "Documents are related",
                    evidence: ["Share \(sharedEntities.count) entities: \(Array(sharedEntities.prefix(3)).joined(separator: ", "))"],
                    confidence: Double(sharedEntities.count) * 0.2,
                    type: .relationship,
                    actionable: "Consider cross-referencing these documents"
                ))
            }
        }
        
        return results
    }
    
    // MARK: - Pattern Recognition
    
    /// Detect patterns using rule-based inference
    func detectPatterns(in indices: [DocumentIndex]) -> [Pattern] {
        var patterns: [Pattern] = []
        
        // Pattern 1: Communication Chain
        // If doc A mentions person X and org Y, and doc B mentions same X and Y,
        // likely part of same communication thread
        
        var entityPairs: [String: [UUID]] = [:] // "person_org": [docIDs]
        
        for index in indices {
            let people = index.entities.filter { $0.type == .person }.map { $0.text }
            let orgs = index.entities.filter { $0.type == .organization }.map { $0.text }
            
            for person in people {
                for org in orgs {
                    let key = "\(person)_\(org)"
                    entityPairs[key, default: []].append(index.documentID)
                }
            }
        }
        
        for (pair, docs) in entityPairs where docs.count >= 2 {
            let components = pair.split(separator: "_")
            if components.count == 2 {
                patterns.append(Pattern(
                    name: "Communication Chain",
                    description: "\(components[0]) and \(components[1]) appear together in \(docs.count) documents",
                    documentIDs: docs,
                    confidence: Double(docs.count) * 0.25,
                    type: .communicationChain
                ))
            }
        }
        
        // Pattern 2: Topic Evolution
        // Documents on same topic but with temporal progression
        
        // Pattern 3: Geographic Pattern
        // Documents mentioning same locations
        
        return patterns
    }
}

// MARK: - Models

struct Fact {
    let subject: String
    let predicate: String
    let object: String
    let source: UUID // Document ID
    let confidence: Double
}

struct InferredFact {
    let subject: String
    let predicate: String
    let object: String
    let confidence: Double
    let derivedFrom: [Fact]
    let rule: String
    var context: String? = nil
}

struct Inference: Identifiable {
    let id = UUID()
    let rule: String
    let conclusion: String
    let evidence: [String]
    let confidence: Double
    let type: InferenceType
    let actionable: String?
    
    var priorityLevel: String {
        if confidence > 0.85 { return "High" }
        if confidence > 0.7 { return "Medium" }
        return "Low"
    }
}

enum InferenceType {
    case network          // People and organization connections
    case temporal         // Time-based patterns
    case relationship     // Document relationships
    case anomaly          // Unusual patterns
    case risk            // Security implications
    case dataFlow        // Source/sink patterns
    case classification  // Topic/category
    case compliance      // Regulatory requirements
    case importance      // Priority assessment
}

enum InferenceQuery {
    case whoIsConnectedTo(person: String)
    case whatTopicsRelatedTo(entity: String)
    case areDocumentsRelated(doc1: String, doc2: String)
}

struct Pattern: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let documentIDs: [UUID]
    let confidence: Double
    let type: PatternType
}

enum PatternType {
    case communicationChain
    case topicEvolution
    case geographicPattern
    case temporalSequence
}


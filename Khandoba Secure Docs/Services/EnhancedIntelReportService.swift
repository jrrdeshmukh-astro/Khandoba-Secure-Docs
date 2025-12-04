//
//  EnhancedIntelReportService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import Foundation
import NaturalLanguage
import SwiftData

@MainActor
final class EnhancedIntelReportService: ObservableObject {
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    
    private var modelContext: ModelContext?
    private let indexingService = DocumentIndexingService()
    private let inferenceEngine = InferenceEngine()
    private let formalLogicEngine = FormalLogicEngine()
    private let transcriptionService = TranscriptionService()
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        indexingService.configure(modelContext: modelContext)
        inferenceEngine.configure(modelContext: modelContext)
        transcriptionService.configure(modelContext: modelContext)
    }
    
    // MARK: - Generate Comprehensive Intel Report
    
    /// Generate enhanced intel report using ML, inference, and generative AI
    func generateComprehensiveReport(for vaults: [Vault]) async throws -> ComprehensiveIntelReport {
        isGenerating = true
        defer { isGenerating = false }
        
        print("🧠 Enhanced Intel: Generating comprehensive report")
        
        var allDocuments: [Document] = []
        for vault in vaults {
            allDocuments.append(contentsOf: vault.documents ?? [])
        }
        
        // Step 1: Index all documents (10% progress)
        generationProgress = 0.1
        print("   Step 1/7: Indexing documents...")
        let indices = try await indexDocuments(allDocuments)
        
        // Step 2: Transcribe audio documents (20% progress)
        generationProgress = 0.2
        print("   Step 2/7: Transcribing audio...")
        let audioTranscriptions = try await transcribeAudioDocuments(allDocuments)
        
        // Step 3: Build knowledge graph (30% progress)
        generationProgress = 0.3
        print("   Step 3/7: Building knowledge graph...")
        let knowledgeGraph = await buildKnowledgeGraph(from: indices)
        
        // Step 4: Build observations for formal logic
        generationProgress = 0.4
        print("   Step 4/8: Building observations...")
        buildObservationsFromIndices(indices)
        
        // Step 5: Apply inference rules (50% progress)
        generationProgress = 0.5
        print("   Step 5/8: Applying inference rules...")
        let inferences = await inferenceEngine.generateInferences(from: indices)
        let patterns = inferenceEngine.detectPatterns(in: indices)
        
        // Step 5.5: Apply formal logic systems (60% progress)
        generationProgress = 0.6
        print("   Step 5.5/8: Applying formal logic...")
        let logicalAnalysis = formalLogicEngine.performCompleteLogicalAnalysis()
        
        // Step 6: Generate AI narrative (70% progress)
        generationProgress = 0.7
        print("   Step 6/8: Generating AI narrative...")
        let narrative = await generateEnhancedNarrative(
            indices: indices,
            inferences: inferences,
            logicalAnalysis: logicalAnalysis,
            patterns: patterns,
            knowledgeGraph: knowledgeGraph,
            transcriptions: audioTranscriptions
        )
        
        // Step 7: Extract actionable insights (85% progress)
        generationProgress = 0.85
        print("   Step 7/8: Extracting insights...")
        let insights = await extractDeepInsights(
            indices: indices,
            inferences: inferences,
            logicalAnalysis: logicalAnalysis,
            patterns: patterns
        )
        
        // Step 8: Compile final report (100% progress)
        generationProgress = 1.0
        print("   Step 8/8: Compiling report...")
        let report = ComprehensiveIntelReport(
            vaultNames: vaults.map { $0.name },
            totalDocuments: allDocuments.count,
            indices: indices,
            transcriptions: audioTranscriptions,
            knowledgeGraph: knowledgeGraph,
            inferences: inferences,
            logicalAnalysis: logicalAnalysis,
            patterns: patterns,
            narrative: narrative,
            insights: insights,
            generatedAt: Date()
        )
        
        print("✅ Enhanced intel report generated!")
        return report
    }
    
    // MARK: - Document Indexing
    
    private func indexDocuments(_ documents: [Document]) async throws -> [DocumentIndex] {
        var indices: [DocumentIndex] = []
        
        for (idx, document) in documents.enumerated() {
            let progress = Double(idx) / Double(documents.count) * 0.1
            generationProgress = progress
            
            let index = try await indexingService.indexDocument(document)
            indices.append(index)
        }
        
        return indices
    }
    
    // MARK: - Audio Transcription
    
    private func transcribeAudioDocuments(_ documents: [Document]) async throws -> [UUID: Transcription] {
        let audioDocuments = documents.filter { $0.fileType.contains("audio") }
        
        if audioDocuments.isEmpty {
            return [:]
        }
        
        return try await transcriptionService.batchTranscribe(documents: audioDocuments)
    }
    
    // MARK: - Knowledge Graph Construction
    
    private func buildKnowledgeGraph(from indices: [DocumentIndex]) async -> KnowledgeGraph {
        var graph = KnowledgeGraph()
        
        // Add all entities as nodes
        for index in indices {
            for entity in index.entities {
                graph.addNode(Node(
                    id: entity.text,
                    type: entity.type.rawValue,
                    properties: ["documentID": index.documentID.uuidString]
                ))
            }
            
            // Add relationships as edges
            for relationship in index.relationships {
                graph.addEdge(Edge(
                    from: relationship.entity1,
                    to: relationship.entity2,
                    type: relationship.relationType,
                    weight: relationship.confidence
                ))
            }
        }
        
        return graph
    }
    
    // MARK: - Enhanced Narrative Generation
    
    // MARK: - Build Observations
    
    private func buildObservationsFromIndices(_ indices: [DocumentIndex]) {
        for index in indices {
            // Add topic observations
            for topic in index.topics {
                formalLogicEngine.addObservation(Observation(
                    subject: index.documentTitle,
                    property: "topic",
                    value: topic,
                    confidence: 0.9
                ))
            }
            
            // Add confidential marker if in topics
            if index.topics.contains("confidential") {
                formalLogicEngine.addObservation(Observation(
                    subject: index.documentTitle,
                    property: "is_confidential",
                    value: "true",
                    confidence: 0.95
                ))
            }
            
            // Add entity observations
            for entity in index.entities {
                formalLogicEngine.addFact(Fact(
                    subject: entity.text,
                    predicate: "is_a",
                    object: entity.type.rawValue,
                    source: index.documentID,
                    confidence: entity.confidence
                ))
            }
            
            // Add relationship facts
            for relationship in index.relationships {
                formalLogicEngine.addFact(Fact(
                    subject: relationship.entity1,
                    predicate: relationship.relationType,
                    object: relationship.entity2,
                    source: index.documentID,
                    confidence: relationship.confidence
                ))
            }
        }
    }
    
    private func generateEnhancedNarrative(
        indices: [DocumentIndex],
        inferences: [Inference],
        logicalAnalysis: LogicalAnalysisReport,
        patterns: [Pattern],
        knowledgeGraph: KnowledgeGraph,
        transcriptions: [UUID: Transcription]
    ) async -> String {
        var narrative = ""
        
        // Opening with generative AI context
        narrative += "📊 **Comprehensive Intelligence Analysis**\n\n"
        narrative += "This report combines ML-powered document analysis, rule-based inference, and knowledge graph reasoning to provide deep insights into your vault ecosystem.\n\n"
        
        // Document Overview with ML insights
        narrative += "## Document Intelligence\n\n"
        narrative += "Analyzed \(indices.count) documents using natural language processing and machine learning.\n\n"
        
        // Language distribution
        let languages = Dictionary(grouping: indices, by: { $0.language })
        narrative += "**Languages Detected:** "
        narrative += languages.map { "\($0.key): \($0.value.count)" }.joined(separator: ", ")
        narrative += "\n\n"
        
        // Topic distribution
        var topicCounts: [String: Int] = [:]
        for index in indices {
            for topic in index.topics {
                topicCounts[topic, default: 0] += 1
            }
        }
        
        if !topicCounts.isEmpty {
            narrative += "**Primary Topics:**\n"
            for (topic, count) in topicCounts.sorted(by: { $0.value > $1.value }).prefix(5) {
                narrative += "- \(topic.capitalized): \(count) documents\n"
            }
            narrative += "\n"
        }
        
        // Entity Network Analysis
        narrative += "## Entity Network Intelligence\n\n"
        let allEntities = indices.flatMap { $0.entities }
        let uniquePeople = Set(allEntities.filter { $0.type == .person }.map { $0.text })
        let uniqueOrgs = Set(allEntities.filter { $0.type == .organization }.map { $0.text })
        let uniqueLocations = Set(allEntities.filter { $0.type == .location }.map { $0.text })
        
        narrative += "Your documents contain a network of:\n"
        narrative += "- \(uniquePeople.count) unique individuals\n"
        narrative += "- \(uniqueOrgs.count) organizations\n"
        narrative += "- \(uniqueLocations.count) locations\n\n"
        
        // Key entities (most connected)
        let nodeConnections = knowledgeGraph.getNodeConnections()
        let keyEntities = nodeConnections.sorted { $0.value > $1.value }.prefix(5)
        
        if !keyEntities.isEmpty {
            narrative += "**Key Entities (Most Connected):**\n"
            for (entity, connections) in keyEntities {
                narrative += "- \(entity): \(connections) connections\n"
            }
            narrative += "\n"
        }
        
        // Formal Logic Analysis
        narrative += "## Formal Mathematical Reasoning\n\n"
        narrative += "Applied \(logicalAnalysis.totalInferences) formal logic inferences across 5 reasoning systems:\n\n"
        
        // Deductive inferences (certainty)
        if !logicalAnalysis.deductiveInferences.isEmpty {
            narrative += "**Deductive Logic (Certain Conclusions):**\n"
            narrative += "Using modus ponens, modus tollens, and syllogistic reasoning:\n"
            for inference in logicalAnalysis.deductiveInferences.prefix(3) {
                narrative += "- \(inference.conclusion)\n"
                narrative += "  Formula: \(inference.formula)\n"
                if let action = inference.actionable {
                    narrative += "  → \(action)\n"
                }
            }
            narrative += "\n"
        }
        
        // Inductive inferences (generalization)
        if !logicalAnalysis.inductiveInferences.isEmpty {
            narrative += "**Inductive Logic (Pattern Generalization):**\n"
            for inference in logicalAnalysis.inductiveInferences.prefix(2) {
                narrative += "- \(inference.conclusion) (confidence: \(Int(inference.confidence * 100))%)\n"
                if let action = inference.actionable {
                    narrative += "  → \(action)\n"
                }
            }
            narrative += "\n"
        }
        
        // Abductive inferences (best explanation)
        if !logicalAnalysis.abductiveInferences.isEmpty {
            narrative += "**Abductive Logic (Best Explanation):**\n"
            for inference in logicalAnalysis.abductiveInferences.prefix(2) {
                narrative += "- \(inference.conclusion) (likelihood: \(Int(inference.confidence * 100))%)\n"
                if let action = inference.actionable {
                    narrative += "  → \(action)\n"
                }
            }
            narrative += "\n"
        }
        
        // Statistical inferences (probability)
        if !logicalAnalysis.statisticalInferences.isEmpty {
            narrative += "**Statistical Reasoning (Bayesian Analysis):**\n"
            for inference in logicalAnalysis.statisticalInferences {
                narrative += "- \(inference.conclusion)\n"
                narrative += "  Formula: \(inference.formula)\n"
            }
            narrative += "\n"
        }
        
        // Rule-based inferences
        narrative += "**Rule-Based Inference:**\n"
        narrative += "Generated \(inferences.count) insights using pattern matching:\n\n"
        
        let groupedInferences = Dictionary(grouping: inferences, by: { $0.type })
        
        for (type, typeInferences) in groupedInferences.sorted(by: { $0.value.count > $1.value.count }).prefix(3) {
            narrative += "**\(type) (\(typeInferences.count)):**\n"
            for inference in typeInferences.prefix(2) {
                narrative += "- \(inference.conclusion)\n"
            }
            narrative += "\n"
        }
        
        // Pattern Recognition
        if !patterns.isEmpty {
            narrative += "## Detected Patterns\n\n"
            
            for pattern in patterns.prefix(5) {
                narrative += "**\(pattern.name):**\n"
                narrative += "\(pattern.description)\n"
                narrative += "Confidence: \(Int(pattern.confidence * 100))%\n\n"
            }
        }
        
        // Transcription Insights
        if !transcriptions.isEmpty {
            narrative += "## Audio Intelligence\n\n"
            narrative += "\(transcriptions.count) audio documents transcribed and analyzed.\n\n"
            
            for (docID, transcription) in transcriptions.prefix(3) {
                let summary = await generateSummary(from: transcription)
                narrative += "**Audio Summary:** \(summary)\n\n"
            }
        }
        
        // Knowledge Graph Insights
        narrative += "## Knowledge Graph Analysis\n\n"
        narrative += "The knowledge graph contains \(knowledgeGraph.nodes.count) entities and \(knowledgeGraph.edges.count) relationships.\n\n"
        
        // Find central nodes (most connected)
        if let centralNode = nodeConnections.max(by: { $0.value < $1.value }) {
            narrative += "**Central Entity:** \(centralNode.key) is the most connected entity with \(centralNode.value) relationships. This entity is likely a key figure or topic in your vault.\n\n"
        }
        
        // Find isolated nodes
        let isolatedNodes = knowledgeGraph.nodes.filter { node in
            knowledgeGraph.edges.filter { $0.from == node.id || $0.to == node.id }.isEmpty
        }
        
        if !isolatedNodes.isEmpty {
            narrative += "**Isolated Entities:** \(isolatedNodes.count) entities have no connections. These may be standalone documents or require further categorization.\n\n"
        }
        
        return narrative
    }
    
    // MARK: - Deep Insights Extraction
    
    private func extractDeepInsights(
        indices: [DocumentIndex],
        inferences: [Inference],
        logicalAnalysis: LogicalAnalysisReport,
        patterns: [Pattern]
    ) async -> [DeepInsight] {
        var insights: [DeepInsight] = []
        
        // Insight 1: Most important document
        if let mostImportant = indices.max(by: { $0.importanceScore < $1.importanceScore }) {
            insights.append(DeepInsight(
                category: "Document Priority",
                insight: "\(mostImportant.documentTitle) is the most important document (score: \(Int(mostImportant.importanceScore))/100)",
                reasoning: "High entity count, confidential topics, or complex relationships",
                actionItems: [
                    "Ensure this document has the highest security level",
                    "Consider dual-key vault protection",
                    "Regular access audits recommended"
                ],
                confidence: 0.9
            ))
        }
        
        // Insight 2: Network hub
        let peopleFrequency = indices.flatMap { $0.entities.filter { $0.type == .person } }
        let personCounts = Dictionary(grouping: peopleFrequency, by: { $0.text })
            .mapValues { $0.count }
        
        if let keyPerson = personCounts.max(by: { $0.value < $1.value }), keyPerson.value >= 3 {
            insights.append(DeepInsight(
                category: "Network Analysis",
                insight: "\(keyPerson.key) is a central figure in your document network",
                reasoning: "Appears in \(keyPerson.value) documents, suggesting significant role",
                actionItems: [
                    "Review all \(keyPerson.key)-related documents for completeness",
                    "Ensure proper access controls for sensitive \(keyPerson.key) information",
                    "Consider creating a dedicated vault or tag group"
                ],
                confidence: 0.85
            ))
        }
        
        // Insight 3: Compliance requirements
        let complianceInferences = inferences.filter { $0.type == .compliance }
        if !complianceInferences.isEmpty {
            let requirements = complianceInferences.map { $0.conclusion }.joined(separator: "; ")
            insights.append(DeepInsight(
                category: "Compliance & Regulatory",
                insight: "Your vault requires compliance attention",
                reasoning: requirements,
                actionItems: [
                    "Enable complete audit logging",
                    "Implement dual-key authentication",
                    "Schedule quarterly compliance reviews",
                    "Export audit reports for compliance officers"
                ],
                confidence: 0.95
            ))
        }
        
        // Insight 4: Communication patterns
        let commPatterns = patterns.filter { $0.type == .communicationChain }
        if !commPatterns.isEmpty {
            insights.append(DeepInsight(
                category: "Communication Intelligence",
                insight: "Detected \(commPatterns.count) communication chains in your documents",
                reasoning: "Related documents with shared entities and context",
                actionItems: [
                    "Create document links to preserve chain of communication",
                    "Tag documents with project or case numbers",
                    "Ensure chronological organization"
                ],
                confidence: 0.8
            ))
        }
        
        // Insight 5: Risk assessment from inferences
        let riskInferences = inferences.filter { $0.type == .risk }
        if !riskInferences.isEmpty {
            let highConfidenceRisks = riskInferences.filter { $0.confidence > 0.8 }
            insights.append(DeepInsight(
                category: "Security Risk Assessment",
                insight: "Identified \(highConfidenceRisks.count) high-confidence security concerns",
                reasoning: highConfidenceRisks.map { $0.conclusion }.joined(separator: "; "),
                actionItems: highConfidenceRisks.compactMap { $0.actionable },
                confidence: 0.9
            ))
        }
        
        // Insight 6: Deductive certainties
        let certainInferences = logicalAnalysis.certainInferences
        if !certainInferences.isEmpty {
            insights.append(DeepInsight(
                category: "Logical Certainties (Deductive)",
                insight: "\(certainInferences.count) conclusions derived with logical certainty",
                reasoning: "Formal deductive reasoning provides absolute conclusions",
                actionItems: certainInferences.compactMap { $0.actionable },
                confidence: 1.0
            ))
        }
        
        // Insight 7: Abductive hypotheses
        let abductiveHypotheses = logicalAnalysis.abductiveInferences
        if !abductiveHypotheses.isEmpty {
            let bestExplanation = abductiveHypotheses.max(by: { $0.confidence < $1.confidence })
            if let best = bestExplanation {
                insights.append(DeepInsight(
                    category: "Most Likely Explanation (Abductive)",
                    insight: best.conclusion,
                    reasoning: "Best explanation for observed anomalies: \(best.observation)",
                    actionItems: best.actionable.map { [$0] } ?? [],
                    confidence: best.confidence
                ))
            }
        }
        
        return insights
    }
    
    // MARK: - Generate Voice Script
    
    /// Create comprehensive voice script for narration
    func generateVoiceScript(report: ComprehensiveIntelReport) -> String {
        var script = ""
        
        // Opening
        script += "Khandoba Enhanced Intelligence Report. "
        script += "This is a comprehensive AI-generated analysis combining machine learning, formal mathematical reasoning, rule-based inference, and knowledge graph analysis. "
        script += "Report generated on \(Date().formatted(date: .long, time: .shortened)). "
        script += "\n\n"
        
        // Logic systems summary
        script += "Reasoning Systems Employed: "
        script += "Deductive logic for certain conclusions. "
        script += "Inductive logic for pattern generalization. "
        script += "Abductive logic for best explanations. "
        script += "Statistical reasoning for probability assessment. "
        script += "Total: \(report.logicalAnalysis.totalInferences) formal logic inferences generated. "
        script += "\n\n"
        
        // Document overview
        script += "Document Analysis: "
        script += "Processed \(report.totalDocuments) documents across \(report.vaultNames.count) vaults. "
        script += "Successfully indexed \(report.indices.count) documents using natural language processing. "
        
        if !report.transcriptions.isEmpty {
            script += "Transcribed \(report.transcriptions.count) audio documents to text for analysis. "
        }
        script += "\n\n"
        
        // Knowledge graph insights
        script += "Knowledge Graph Intelligence: "
        script += "Constructed a knowledge graph with \(report.knowledgeGraph.nodes.count) entities and \(report.knowledgeGraph.edges.count) relationships. "
        
        let connections = report.knowledgeGraph.getNodeConnections()
        if let mostConnected = connections.max(by: { $0.value < $1.value }) {
            script += "The most connected entity is \(mostConnected.key) with \(mostConnected.value) relationships, indicating central importance in your document network. "
        }
        script += "\n\n"
        
        // Formal Logic Analysis - Deductive (Certain)
        if !report.logicalAnalysis.deductiveInferences.isEmpty {
            script += "Deductive Logic Analysis: "
            script += "Generated \(report.logicalAnalysis.deductiveInferences.count) logically certain conclusions using formal deductive reasoning. "
            script += "\n\n"
            
            for (index, inference) in report.logicalAnalysis.deductiveInferences.prefix(3).enumerated() {
                script += "Certain Conclusion \(index + 1): \(inference.conclusion). "
                script += "Method: \(inference.method). "
                script += "Logical formula: \(inference.formula). "
                script += "Certainty: 100 percent. "
                if let action = inference.actionable {
                    script += "Required action: \(action). "
                }
                script += "\n\n"
            }
        }
        
        // Inductive (Probable)
        if !report.logicalAnalysis.inductiveInferences.isEmpty {
            script += "Inductive Reasoning: "
            script += "Generalized \(report.logicalAnalysis.inductiveInferences.count) patterns from observed data. "
            script += "\n\n"
            
            for (index, inference) in report.logicalAnalysis.inductiveInferences.prefix(2).enumerated() {
                script += "Pattern \(index + 1): \(inference.conclusion). "
                script += "Confidence: \(Int(inference.confidence * 100)) percent. "
                script += "\n\n"
            }
        }
        
        // Abductive (Best Explanation)
        if !report.logicalAnalysis.abductiveInferences.isEmpty {
            script += "Abductive Analysis - Best Explanations: "
            script += "\n\n"
            
            for (index, inference) in report.logicalAnalysis.abductiveInferences.enumerated() {
                script += "Hypothesis \(index + 1): \(inference.conclusion). "
                script += "This is the most likely explanation with \(Int(inference.confidence * 100)) percent probability. "
                if let action = inference.actionable {
                    script += "Recommended action: \(action). "
                }
                script += "\n\n"
            }
        }
        
        // Statistical (Probability)
        if !report.logicalAnalysis.statisticalInferences.isEmpty {
            script += "Statistical Analysis: "
            script += "Bayesian inference and probability calculations reveal: "
            script += "\n\n"
            
            for inference in report.logicalAnalysis.statisticalInferences {
                script += "\(inference.conclusion). "
                script += "Mathematical formula: \(inference.formula). "
                script += "\n\n"
            }
        }
        
        // Rule-based inferences
        script += "Rule-Based Inference: "
        script += "Applied \(InferenceRuleCount.total) inference rules and generated \(report.inferences.count) deductions. "
        script += "\n\n"
        
        // High-confidence rule-based inferences
        let highConfidence = report.inferences.filter { $0.confidence > 0.8 }.prefix(3)
        if !highConfidence.isEmpty {
            script += "Key Findings from Pattern Matching: "
            for (index, inference) in highConfidence.enumerated() {
                script += "\n\nFinding \(index + 1): \(inference.conclusion). "
                script += "Evidence: \(inference.evidence.joined(separator: ". ")). "
                script += "Confidence: \(Int(inference.confidence * 100)) percent. "
                
                if let actionable = inference.actionable {
                    script += "Recommended action: \(actionable). "
                }
            }
            script += "\n\n"
        }
        
        // Pattern recognition
        if !report.patterns.isEmpty {
            script += "Pattern Recognition: "
            script += "Detected \(report.patterns.count) significant patterns in your documents. "
            
            for pattern in report.patterns.prefix(3) {
                script += "\n\nPattern: \(pattern.name). "
                script += "\(pattern.description). "
                script += "This pattern spans \(pattern.documentIDs.count) documents with \(Int(pattern.confidence * 100)) percent confidence. "
            }
            script += "\n\n"
        }
        
        // Deep insights
        if !report.insights.isEmpty {
            script += "Deep Insights and Recommendations: "
            
            for (index, insight) in report.insights.enumerated() {
                script += "\n\nInsight \(index + 1) - \(insight.category): "
                script += "\(insight.insight). "
                script += "Reasoning: \(insight.reasoning). "
                
                if !insight.actionItems.isEmpty {
                    script += "Action items: "
                    for (actionIndex, action) in insight.actionItems.enumerated() {
                        script += "\(actionIndex + 1), \(action). "
                    }
                }
            }
            script += "\n\n"
        }
        
        // Closing
        script += "This concludes the comprehensive intelligence analysis. "
        script += "For detailed visualizations and interactive knowledge graphs, please review the written report in your Intel Vault. "
        script += "All findings are based on machine learning analysis and logical inference with confidence scores provided. "
        script += "Stay informed. Stay secure. "
        
        return script
    }
}

// MARK: - Models

struct ComprehensiveIntelReport {
    let vaultNames: [String]
    let totalDocuments: Int
    let indices: [DocumentIndex]
    let transcriptions: [UUID: Transcription]
    let knowledgeGraph: KnowledgeGraph
    let inferences: [Inference]
    let logicalAnalysis: LogicalAnalysisReport
    let patterns: [Pattern]
    let narrative: String
    let insights: [DeepInsight]
    let generatedAt: Date
}

struct DeepInsight: Identifiable {
    let id = UUID()
    let category: String
    let insight: String
    let reasoning: String
    let actionItems: [String]
    let confidence: Double
}

struct KnowledgeGraph {
    var nodes: [Node] = []
    var edges: [Edge] = []
    
    mutating func addNode(_ node: Node) {
        if !nodes.contains(where: { $0.id == node.id }) {
            nodes.append(node)
        }
    }
    
    mutating func addEdge(_ edge: Edge) {
        edges.append(edge)
    }
    
    func getNodeConnections() -> [String: Int] {
        var connections: [String: Int] = [:]
        
        for node in nodes {
            let edgeCount = edges.filter { $0.from == node.id || $0.to == node.id }.count
            connections[node.id] = edgeCount
        }
        
        return connections
    }
    
    func findShortestPath(from: String, to: String) -> [String]? {
        // Breadth-first search for shortest path
        var queue: [(node: String, path: [String])] = [(from, [from])]
        var visited = Set<String>()
        
        while !queue.isEmpty {
            let (current, path) = queue.removeFirst()
            
            if current == to {
                return path
            }
            
            if visited.contains(current) {
                continue
            }
            visited.insert(current)
            
            // Find neighbors
            let neighbors = edges
                .filter { $0.from == current }
                .map { $0.to }
            
            for neighbor in neighbors {
                queue.append((neighbor, path + [neighbor]))
            }
        }
        
        return nil // No path found
    }
}

struct Node {
    let id: String
    let type: String
    var properties: [String: String] = [:]
}

struct Edge {
    let from: String
    let to: String
    let type: String
    let weight: Double
}

enum InferenceRuleCount {
    static let total = 6 // Number of inference rule categories
}


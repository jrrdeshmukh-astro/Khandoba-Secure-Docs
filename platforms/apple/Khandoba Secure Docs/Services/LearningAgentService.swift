//
//  LearningAgentService.swift
//  Khandoba Secure Docs
//
//  Seek Agent with full lifecycle - Case-based reasoning, learning from outcomes
//

import Foundation
import SwiftData
import Combine

/// Learning case structure for case-based reasoning
struct LearningCase: Codable {
    let id: UUID
    let topicName: String
    let keywords: [String]
    let categories: [String]
    let successfulSources: [String]
    let relevanceScore: Double
    let outcome: String // "successful", "unsuccessful"
    let createdAt: Date
}

/// Seek Agent Service - Full lifecycle implementation
/// Case-based reasoning, learning from outcomes, recommendation engine
@MainActor
final class LearningAgentService: ObservableObject {
    static let shared = LearningAgentService()
    
    @Published var recommendations: [String: [String]] = [:] // vaultID: [recommended sources]
    @Published var seekQueries: [SeekQuery] = []
    
    private var modelContext: ModelContext?
    private var formalLogicEngine: FormalLogicEngine?
    private var inferenceEngine: InferenceEngine?
    private var caseBase: [LearningCase] = []
    
    private init() {
        loadCaseBase()
    }
    
    func configure(
        modelContext: ModelContext,
        formalLogicEngine: FormalLogicEngine? = nil,
        inferenceEngine: InferenceEngine? = nil
    ) {
        self.modelContext = modelContext
        self.formalLogicEngine = formalLogicEngine
        self.inferenceEngine = inferenceEngine
    }
    
    // MARK: - Relevance Calculation (Full Lifecycle)
    
    /// Calculate relevance of content to topic using case-based reasoning
    func calculateRelevance(content: String, topic: VaultTopic) async -> Double {
        // Step 1: Case-based reasoning (40% weight)
        let caseBasedScore = calculateCaseBasedRelevance(content: content, topic: topic)
        
        // Step 2: Formal logic application (40% weight)
        let logicScore = await calculateLogicBasedRelevance(content: content, topic: topic)
        
        // Step 3: Generate and test (20% weight)
        let generateTestScore = calculateGenerateTestRelevance(content: content, topic: topic)
        
        // Weighted average
        let relevance = (caseBasedScore * 0.4) + (logicScore * 0.4) + (generateTestScore * 0.2)
        
        return min(1.0, max(0.0, relevance))
    }
    
    // MARK: - Case-Based Reasoning (CBR)
    
    private func calculateCaseBasedRelevance(content: String, topic: VaultTopic) -> Double {
        // Find similar cases from case base
        let similarCases = caseBase.filter { case_ in
            // Check keyword overlap
            let keywordOverlap = Set(case_.keywords).intersection(Set(topic.keywords)).count
            return keywordOverlap > 0 || case_.topicName.lowercased().contains(topic.topicName.lowercased())
        }
        
        guard !similarCases.isEmpty else {
            return 0.5 // Default relevance if no cases
        }
        
        // Calculate average relevance from similar cases
        let avgRelevance = similarCases.map { $0.relevanceScore }.reduce(0.0, +) / Double(similarCases.count)
        return avgRelevance
    }
    
    // MARK: - Formal Logic Application
    
    private func calculateLogicBasedRelevance(content: String, topic: VaultTopic) async -> Double {
        guard let logicEngine = formalLogicEngine else {
            return 0.5
        }
        
        // Apply deductive reasoning
        // If topic keywords match content, high relevance
        let keywordMatches = topic.keywords.filter { keyword in
            content.lowercased().contains(keyword.lowercased())
        }.count
        
        let keywordScore = topic.keywords.isEmpty ? 0.5 : Double(keywordMatches) / Double(topic.keywords.count)
        
        // Apply inductive reasoning
        // If content patterns match topic categories, higher relevance
        var categoryScore = 0.5
        for category in topic.categories {
            if content.lowercased().contains(category.lowercased()) {
                categoryScore += 0.1
            }
        }
        categoryScore = min(1.0, categoryScore)
        
        return (keywordScore * 0.7) + (categoryScore * 0.3)
    }
    
    // MARK: - Generate and Test
    
    private func calculateGenerateTestRelevance(content: String, topic: VaultTopic) -> Double {
        // Generate hypothesis: "Is this content relevant to the topic?"
        // Test hypothesis by checking multiple factors
        
        var score = 0.0
        var factors = 0
        
        // Factor 1: Keyword presence
        let keywordCount = topic.keywords.filter { content.lowercased().contains($0.lowercased()) }.count
        if !topic.keywords.isEmpty {
            score += Double(keywordCount) / Double(topic.keywords.count)
            factors += 1
        }
        
        // Factor 2: Category match
        let categoryMatches = topic.categories.filter { content.lowercased().contains($0.lowercased()) }.count
        if !topic.categories.isEmpty {
            score += Double(categoryMatches) / Double(topic.categories.count)
            factors += 1
        }
        
        // Factor 3: Topic name match
        if content.lowercased().contains(topic.topicName.lowercased()) {
            score += 0.5
            factors += 1
        }
        
        return factors > 0 ? score / Double(factors) : 0.5
    }
    
    // MARK: - Source Recommendations
    
    /// Get recommended sources for vault topic using case-based reasoning
    func getRecommendedSources(for vaultID: UUID) async -> [String] {
        guard let topic = try? await getTopic(for: vaultID) else {
            return []
        }
        
        // Find similar successful cases
        let similarCases = caseBase.filter { case_ in
            let keywordOverlap = Set(case_.keywords).intersection(Set(topic.keywords)).count
            return keywordOverlap >= 2 || case_.topicName.lowercased() == topic.topicName.lowercased()
        }
        .filter { $0.outcome == "successful" }
        
        // Extract successful sources from similar cases
        var sourceFrequency: [String: Int] = [:]
        for case_ in similarCases {
            for source in case_.successfulSources {
                sourceFrequency[source, default: 0] += 1
            }
        }
        
        // Sort by frequency and return top sources
        let recommended = sourceFrequency.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        
        recommendations[vaultID.uuidString] = recommended
        return recommended
    }
    
    // MARK: - Learning (Full Lifecycle)
    
    /// Learn from ingestion outcome - Complete lifecycle
    func learnFromIngestion(vaultID: UUID, topic: VaultTopic) async {
        guard let topic = try? await getTopic(for: vaultID) else {
            return
        }
        
        // Calculate learning score
        let learningScore = topic.totalIngested > 0 ?
            Double(topic.relevantCount) / Double(topic.totalIngested) : 0.0
        topic.learningScore = learningScore
        
        // Create learning case
        let case_ = LearningCase(
            id: UUID(),
            topicName: topic.topicName,
            keywords: topic.keywords,
            categories: topic.categories,
            successfulSources: topic.dataSources,
            relevanceScore: learningScore,
            outcome: learningScore > 0.6 ? "successful" : "unsuccessful",
            createdAt: Date()
        )
        
        caseBase.append(case_)
        saveCaseBase()
    }
    
    // MARK: - Seek Agent - Query Processing
    
    /// Process seek query with case-based reasoning
    func processSeekQuery(_ query: String, vaultID: UUID) async -> SeekResponse {
        // Transform query using case-based reasoning
        let transformedQuery = await transformQuery(query, vaultID: vaultID)
        
        // Find similar past queries
        let similarQueries = findSimilarQueries(query: query, vaultID: vaultID)
        
        // Generate response using inference engine
        let response = await generateResponse(
            query: transformedQuery,
            similarQueries: similarQueries,
            vaultID: vaultID
        )
        
        // Store query for learning
        let seekQuery = SeekQuery(
            id: UUID(),
            vaultID: vaultID,
            originalQuery: query,
            transformedQuery: transformedQuery.transformed,
            category: transformedQuery.category,
            response: response,
            createdAt: Date()
        )
        seekQueries.append(seekQuery)
        saveSeekQueries()
        
        // Learn from outcome (will be updated when user provides feedback)
        return response
    }
    
    private func transformQuery(_ query: String, vaultID: UUID) async -> QueryTransformation {
        // Use case-based reasoning to transform query
        let similarCases = caseBase.filter { case_ in
            // Find cases with similar queries
            query.lowercased().contains(case_.topicName.lowercased()) ||
            case_.keywords.contains(where: { query.lowercased().contains($0.lowercased()) })
        }
        
        // Determine query category
        let category = determineQueryCategory(query: query, similarCases: similarCases)
        
        // Transform query based on category
        let transformed = transformQueryByCategory(query: query, category: category)
        
        return QueryTransformation(
            original: query,
            transformed: transformed,
            category: category,
            similarCasesUsed: similarCases.count
        )
    }
    
    private func determineQueryCategory(query: String, similarCases: [LearningCase]) -> String {
        let lowercased = query.lowercased()
        
        if lowercased.contains("find") || lowercased.contains("search") || lowercased.contains("where") {
            return "SEARCH"
        } else if lowercased.contains("summarize") || lowercased.contains("summary") {
            return "SUMMARIZE"
        } else if lowercased.contains("compare") || lowercased.contains("difference") {
            return "COMPARE"
        } else if lowercased.contains("analyze") || lowercased.contains("analysis") {
            return "ANALYZE"
        } else if lowercased.contains("explain") || lowercased.contains("what") || lowercased.contains("why") {
            return "EXPLAIN"
        } else if lowercased.contains("list") || lowercased.contains("show") {
            return "LIST"
        } else if lowercased.contains("verify") || lowercased.contains("check") {
            return "VERIFY"
        }
        
        return "SEARCH" // Default
    }
    
    private func transformQueryByCategory(query: String, category: String) -> String {
        // Transform query to be more specific based on category
        switch category {
        case "SEARCH":
            return "Find documents containing: \(query)"
        case "SUMMARIZE":
            return "Provide summary of: \(query)"
        case "COMPARE":
            return "Compare: \(query)"
        case "ANALYZE":
            return "Analyze: \(query)"
        case "EXPLAIN":
            return "Explain: \(query)"
        case "LIST":
            return "List: \(query)"
        case "VERIFY":
            return "Verify: \(query)"
        default:
            return query
        }
    }
    
    private func findSimilarQueries(query: String, vaultID: UUID) -> [SeekQuery] {
        return seekQueries.filter { seekQuery in
            seekQuery.vaultID == vaultID &&
            (seekQuery.originalQuery.lowercased().contains(query.lowercased()) ||
             query.lowercased().contains(seekQuery.originalQuery.lowercased()))
        }
    }
    
    private func generateResponse(
        query: String,
        similarQueries: [SeekQuery],
        vaultID: UUID
    ) async -> SeekResponse {
        // Use inference engine to generate response
        // This would integrate with document search and analysis
        return SeekResponse(
            answer: "Response to: \(query)",
            sources: [],
            confidence: 0.8
        )
    }
    
    // MARK: - Case Base Management
    
    private func loadCaseBase() {
        // Load from UserDefaults (could be migrated to SwiftData)
        if let data = UserDefaults.standard.data(forKey: "learning_case_base"),
           let cases = try? JSONDecoder().decode([LearningCase].self, from: data) {
            caseBase = cases
        }
    }
    
    private func saveCaseBase() {
        if let data = try? JSONEncoder().encode(caseBase) {
            UserDefaults.standard.set(data, forKey: "learning_case_base")
        }
    }
    
    private func saveSeekQueries() {
        if let data = try? JSONEncoder().encode(seekQueries) {
            UserDefaults.standard.set(data, forKey: "seek_queries")
        }
    }
    
    private func getTopic(for vaultID: UUID) async throws -> VaultTopic? {
        guard let modelContext = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<VaultTopic>(
            predicate: #Predicate { $0.vaultID == vaultID }
        )
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Supporting Types

struct SeekQuery: Codable, Identifiable {
    let id: UUID
    let vaultID: UUID
    let originalQuery: String
    let transformedQuery: String
    let category: String
    let response: SeekResponse
    let createdAt: Date
}

struct QueryTransformation {
    let original: String
    let transformed: String
    let category: String
    let similarCasesUsed: Int
}

struct SeekResponse: Codable {
    let answer: String
    let sources: [String] // Document IDs
    let confidence: Double
}


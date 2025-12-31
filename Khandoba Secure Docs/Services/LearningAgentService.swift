//
//  LearningAgentService.swift
//  Khandoba Secure Docs
//
//  Learning agent service for intelligent source recommendations
//

import Foundation
import SwiftData
import Combine

/// Learning case structure
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

@MainActor
final class LearningAgentService: ObservableObject {
    static let shared = LearningAgentService()
    
    @Published var recommendations: [String: [String]] = [:] // vaultID: [recommended sources]
    
    private var modelContext: ModelContext?
    private var formalLogicEngine: FormalLogicEngine?
    private var inferenceEngine: InferenceEngine?
    private var caseBase: [LearningCase] = []
    
    private init() {
        loadCaseBase()
    }
    
    func configure(
        modelContext: ModelContext,
        formalLogicEngine: FormalLogicEngine,
        inferenceEngine: InferenceEngine
    ) {
        self.modelContext = modelContext
        self.formalLogicEngine = formalLogicEngine
        self.inferenceEngine = inferenceEngine
    }
    
    // MARK: - Relevance Calculation
    
    /// Calculate relevance of content to topic
    func calculateRelevance(content: String, topic: VaultTopic) async -> Double {
        // Case-based reasoning
        let caseBasedScore = calculateCaseBasedRelevance(content: content, topic: topic)
        
        // Formal logic application
        let logicScore = await calculateLogicBasedRelevance(content: content, topic: topic)
        
        // Generate and test
        let generateTestScore = calculateGenerateTestRelevance(content: content, topic: topic)
        
        // Weighted average
        let relevance = (caseBasedScore * 0.4) + (logicScore * 0.4) + (generateTestScore * 0.2)
        
        return min(1.0, max(0.0, relevance))
    }
    
    // MARK: - Case-Based Reasoning
    
    private func calculateCaseBasedRelevance(content: String, topic: VaultTopic) -> Double {
        // Find similar cases
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
    
    /// Get recommended sources for vault topic
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
    
    // MARK: - Learning
    
    /// Learn from ingestion outcome
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
    
    private func getTopic(for vaultID: UUID) async throws -> VaultTopic? {
        guard let modelContext = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<VaultTopic>(
            predicate: #Predicate { $0.vaultID == vaultID }
        )
        return try modelContext.fetch(descriptor).first
    }
}


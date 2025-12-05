//
//  IntelChatService.swift
//  Khandoba Secure Docs
//
//  Created by AI Assistant on 12/5/25.
//
//  Chat-based Intel Report using Apple Foundation Models
//

import Foundation
import Combine
import SwiftData

@MainActor
final class IntelChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    @Published var intelContext: String = ""
    
    private var modelContext: ModelContext?
    private let intelReportService = IntelReportService()
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let role: Role
        let content: String
        let timestamp: Date
        
        enum Role {
            case user
            case assistant
            case system
        }
    }
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext, vaultService: VaultService? = nil) {
        self.modelContext = modelContext
        intelReportService.configure(modelContext: modelContext, vaultService: vaultService)
    }
    
    /// Initialize chat with Intel Report context
    func loadIntelContext(for vaults: [Vault]) async {
        isProcessing = true
        defer { isProcessing = false }
        
        print("🧠 Loading Intel context...")
        
        // Generate Intel Report to get context
        let report = await intelReportService.generateIntelReport(for: vaults)
        
        // Build comprehensive context
        var context = "INTELLIGENCE CONTEXT:\n\n"
        
        // Add narrative
        context += "OVERVIEW:\n\(report.narrative)\n\n"
        
        // Add insights
        if !report.insights.isEmpty {
            context += "KEY INSIGHTS:\n"
            for (index, insight) in report.insights.enumerated() {
                context += "\(index + 1). \(insight)\n"
            }
            context += "\n"
        }
        
        // Add document stats
        context += "DOCUMENT ANALYSIS:\n"
        context += "Source documents: \(report.sourceAnalysis.count)\n"
        context += "Sink documents: \(report.sinkAnalysis.count)\n"
        
        if !report.sourceAnalysis.topTags.isEmpty {
            context += "Source topics: \(report.sourceAnalysis.topTags.prefix(5).joined(separator: ", "))\n"
        }
        
        if !report.sinkAnalysis.topTags.isEmpty {
            context += "Sink topics: \(report.sinkAnalysis.topTags.prefix(5).joined(separator: ", "))\n"
        }
        
        // Add entities
        let allEntities = Set(report.sourceAnalysis.entities + report.sinkAnalysis.entities)
        if !allEntities.isEmpty {
            context += "Key entities: \(allEntities.prefix(10).joined(separator: ", "))\n"
        }
        
        self.intelContext = context
        
        // Add system message
        messages.append(ChatMessage(
            role: .system,
            content: "Intelligence analysis loaded. Ask me anything about your documents.",
            timestamp: Date()
        ))
        
        print("✅ Intel context loaded (\(context.count) characters)")
    }
    
    /// Send a message and get AI response
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(
            role: .user,
            content: text,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Generate AI response (using context)
        let response = await generateResponse(to: text)
        
        // Add assistant message
        let assistantMessage = ChatMessage(
            role: .assistant,
            content: response,
            timestamp: Date()
        )
        messages.append(assistantMessage)
    }
    
    /// Generate AI response using Foundation Models (simulated for now)
    private func generateResponse(to query: String) async -> String {
        print("🤖 Generating response for: \(query)")
        
        // FUTURE: Use Foundation Models framework
        // For now, use rule-based responses with intel context
        
        let lowercaseQuery = query.lowercased()
        
        // Pattern matching for common questions
        if lowercaseQuery.contains("summary") || lowercaseQuery.contains("overview") {
            return generateSummary()
        } else if lowercaseQuery.contains("risk") || lowercaseQuery.contains("threat") {
            return generateRiskAssessment()
        } else if lowercaseQuery.contains("document") && lowercaseQuery.contains("important") {
            return generateImportantDocuments()
        } else if lowercaseQuery.contains("missing") || lowercaseQuery.contains("need") {
            return generateMissingAnalysis()
        } else if lowercaseQuery.contains("timeline") || lowercaseQuery.contains("when") {
            return generateTimeline()
        } else if lowercaseQuery.contains("who") || lowercaseQuery.contains("person") {
            return generatePeopleAnalysis()
        } else if lowercaseQuery.contains("where") || lowercaseQuery.contains("location") {
            return generateLocationAnalysis()
        } else if lowercaseQuery.contains("recommend") || lowercaseQuery.contains("should") {
            return generateRecommendations()
        } else {
            return generateContextualResponse(query)
        }
    }
    
    private func generateSummary() -> String {
        guard let report = intelReportService.currentReport else {
            return "No intelligence data available. Please generate an Intel Report first."
        }
        
        var summary = "Here's a summary of your documents:\n\n"
        summary += report.narrative
        
        if !report.insights.isEmpty {
            summary += "\n\nKey takeaways:\n"
            for insight in report.insights.prefix(3) {
                summary += "• \(insight)\n"
            }
        }
        
        return summary
    }
    
    private func generateRiskAssessment() -> String {
        guard let report = intelReportService.currentReport else {
            return "No data to assess risk."
        }
        
        let sourceCount = report.sourceAnalysis.count
        let sinkCount = report.sinkAnalysis.count
        
        var response = "Risk Assessment:\n\n"
        
        if sinkCount > sourceCount * 2 {
            response += "⚠️ ELEVATED RISK: You're receiving significantly more documents than you're creating. "
            response += "This could indicate:\n"
            response += "• Active legal or medical case\n"
            response += "• Multiple parties sharing information\n"
            response += "• Potential information overload\n\n"
            response += "Recommendation: Review all incoming documents carefully and organize by priority."
        } else {
            response += "✅ NORMAL RISK: Balanced document flow detected.\n"
        }
        
        return response
    }
    
    private func generateImportantDocuments() -> String {
        guard let report = intelReportService.currentReport else {
            return "No document data available."
        }
        
        var response = "Most Important Documents:\n\n"
        
        // Use top tags to identify important themes
        let topTags = report.sourceAnalysis.topTags + report.sinkAnalysis.topTags
        let uniqueTags = Array(Set(topTags)).prefix(5)
        
        response += "Based on frequency analysis, focus on documents tagged:\n"
        for tag in uniqueTags {
            response += "• \(tag)\n"
        }
        
        response += "\nThese appear most frequently in your vault and likely contain critical information."
        
        return response
    }
    
    private func generateMissingAnalysis() -> String {
        "Based on the documents I've analyzed, I can't definitively say what's missing, but here are common gaps to check:\n\n" +
        "• Supporting evidence for claims made\n" +
        "• Signatures on agreements\n" +
        "• Counter-party responses\n" +
        "• Timeline documentation\n" +
        "• Witness statements\n\n" +
        "Would you like me to analyze a specific document type?"
    }
    
    private func generateTimeline() -> String {
        guard let report = intelReportService.currentReport else {
            return "No timeline data available."
        }
        
        return "Timeline analysis would show document creation and receipt patterns. " +
        "You have \(report.sourceAnalysis.count) source documents and \(report.sinkAnalysis.count) sink documents. " +
        "Check individual documents for specific dates."
    }
    
    private func generatePeopleAnalysis() -> String {
        guard let report = intelReportService.currentReport else {
            return "No entity data available."
        }
        
        let people = report.sourceAnalysis.entities.filter { $0.hasPrefix("Person:") } +
                    report.sinkAnalysis.entities.filter { $0.hasPrefix("Person:") }
        let uniquePeople = Array(Set(people)).prefix(10)
        
        if uniquePeople.isEmpty {
            return "No people detected in document tags. This could mean:\n" +
            "• Documents don't mention specific individuals\n" +
            "• Content is more procedural/technical\n" +
            "• Entity extraction needs improvement"
        }
        
        var response = "Key people mentioned in your documents:\n\n"
        for person in uniquePeople {
            response += "• \(person.replacingOccurrences(of: "Person:", with: ""))\n"
        }
        
        return response
    }
    
    private func generateLocationAnalysis() -> String {
        guard let report = intelReportService.currentReport else {
            return "No location data available."
        }
        
        let locations = report.sourceAnalysis.entities.filter { $0.hasPrefix("Location:") } +
                       report.sinkAnalysis.entities.filter { $0.hasPrefix("Location:") }
        let uniqueLocations = Array(Set(locations)).prefix(10)
        
        if uniqueLocations.isEmpty {
            return "No locations detected in document tags."
        }
        
        var response = "Locations mentioned:\n\n"
        for location in uniqueLocations {
            response += "• \(location.replacingOccurrences(of: "Location:", with: ""))\n"
        }
        
        return response
    }
    
    private func generateRecommendations() -> String {
        guard let report = intelReportService.currentReport else {
            return "Generate an Intel Report first to get recommendations."
        }
        
        var recommendations: [String] = []
        
        if report.sinkAnalysis.count > report.sourceAnalysis.count * 2 {
            recommendations.append("Organize incoming documents by sender and date for easier tracking")
        }
        
        if report.sourceAnalysis.count > 10 {
            recommendations.append("Consider creating topic-based sub-vaults for better organization")
        }
        
        if !report.insights.isEmpty {
            recommendations.append("Review the key insights for patterns you might have missed")
        }
        
        recommendations.append("Enable dual-key protection for sensitive documents")
        recommendations.append("Set up automated security reviews using the scheduler")
        
        var response = "Recommendations:\n\n"
        for (index, rec) in recommendations.enumerated() {
            response += "\(index + 1). \(rec)\n"
        }
        
        return response
    }
    
    private func generateContextualResponse(_ query: String) -> String {
        // Generic contextual response
        "I understand you're asking: '\(query)'\n\n" +
        "Based on your documents, I can help with:\n" +
        "• Summarizing content\n" +
        "• Risk assessment\n" +
        "• Finding important documents\n" +
        "• Identifying gaps\n" +
        "• Timeline analysis\n" +
        "• People and location mentions\n" +
        "• Recommendations\n\n" +
        "Try asking: 'Give me a summary' or 'What are the risks?'"
    }
    
    /// Clear chat history
    func clearChat() {
        messages.removeAll()
    }
}


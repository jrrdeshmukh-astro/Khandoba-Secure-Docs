//
//  IntelChatService.swift
//  Khandoba Secure Docs
//
//  Interactive Chat for Intel Reports with Privilege-Based Access
//

import Foundation
import SwiftData
import Combine

enum UserPrivilege {
    case owner
    case nominee
    case viewer
    case emergency
    
    var canQueryGraph: Bool {
        switch self {
        case .owner, .nominee: return true
        case .viewer, .emergency: return false
        }
    }
    
    var canModifyInsights: Bool {
        switch self {
        case .owner: return true
        case .nominee, .viewer, .emergency: return false
        }
    }
    
    var maxQueryDepth: Int {
        switch self {
        case .owner: return 5
        case .nominee: return 3
        case .viewer: return 2
        case .emergency: return 1
        }
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    let relatedNodes: [UUID]? // Nodes in graph related to this message
}

@MainActor
final class IntelChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing = false
    
    private var graph: ReasoningGraph?
    private var intelligence: IntelligenceData?
    private var privilege: UserPrivilege = .viewer
    private var modelContext: ModelContext?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext, graph: ReasoningGraph, intelligence: IntelligenceData, privilege: UserPrivilege) {
        self.modelContext = modelContext
        self.graph = graph
        self.intelligence = intelligence
        self.privilege = privilege
    }
    
    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(
            id: UUID(),
            text: text,
            isUser: true,
            timestamp: Date(),
            relatedNodes: nil
        )
        messages.append(userMessage)
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Process query based on privilege
        let response = await processQuery(text)
        
        let botMessage = ChatMessage(
            id: UUID(),
            text: response.text,
            isUser: false,
            timestamp: Date(),
            relatedNodes: response.relatedNodes
        )
        messages.append(botMessage)
    }
    
    private func processQuery(_ query: String) async -> (text: String, relatedNodes: [UUID]?) {
        guard let graph = graph, let intelligence = intelligence else {
            return ("I need access to the reasoning graph to answer questions.", nil)
        }
        
        let lowerQuery = query.lowercased()
        var relatedNodes: [UUID] = []
        
        // Graph queries (privilege-based)
        if privilege.canQueryGraph {
            if lowerQuery.contains("graph") || lowerQuery.contains("connection") || lowerQuery.contains("relationship") {
                let centrality = graph.calculateCentrality()
                let topNodes = centrality.sorted { $0.value > $1.value }.prefix(3)
                relatedNodes = Array(topNodes.map { $0.key })
                
                let nodeNames = topNodes.compactMap { nodeID in
                    graph.nodes.first { $0.id == nodeID }?.label
                }
                
                return ("The most important nodes in the reasoning graph are: \(nodeNames.joined(separator: ", ")). These have the highest centrality scores.", relatedNodes)
            }
            
            if lowerQuery.contains("path") || lowerQuery.contains("connect") {
                // Find path between entities
                let entityNodes = graph.nodes.filter { $0.type == .entity }
                if entityNodes.count >= 2 {
                    let source = entityNodes[0].id
                    let target = entityNodes[1].id
                    
                    if let path = graph.shortestPath(from: source, to: target) {
                        relatedNodes = path
                        let pathLabels = path.compactMap { nodeID in
                            graph.nodes.first { $0.id == nodeID }?.label
                        }
                        return ("Path found: \(pathLabels.joined(separator: " → "))", relatedNodes)
                    }
                }
            }
        }
        
        // Entity queries
        if lowerQuery.contains("who") || lowerQuery.contains("person") {
            let people = intelligence.entities.filter { $0.count > 0 }
            if !people.isEmpty {
                return ("People mentioned: \(people.prefix(5).joined(separator: ", "))", nil)
            }
        }
        
        if lowerQuery.contains("where") || lowerQuery.contains("location") {
            let locations = intelligence.locations
            if !locations.isEmpty {
                return ("Locations: \(locations.prefix(5).joined(separator: ", "))", nil)
            }
        }
        
        if lowerQuery.contains("when") || lowerQuery.contains("timeline") {
            if let first = intelligence.timeline.first, let last = intelligence.timeline.last {
                let days = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 0
                return ("Timeline spans \(days) days from \(first.date.formatted(date: .abbreviated, time: .omitted)) to \(last.date.formatted(date: .abbreviated, time: .omitted))", nil)
            }
        }
        
        if lowerQuery.contains("topic") || lowerQuery.contains("theme") {
            if !intelligence.topics.isEmpty {
                return ("Main topics: \(intelligence.topics.prefix(7).joined(separator: ", "))", nil)
            }
        }
        
        // Default response
        return ("I can help you explore the intelligence report. Try asking about entities, locations, timeline, topics, or graph relationships.", nil)
    }
}


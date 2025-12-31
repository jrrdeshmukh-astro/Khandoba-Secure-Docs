//
//  ReasoningGraphService.swift
//  Khandoba Secure Docs
//
//  Graph Theory-based Reasoning Graph for Intel Reports
//

import Foundation
import SwiftData
import Combine

/// Node in the reasoning graph representing a concept, entity, or inference
struct ReasoningNode: Identifiable, Hashable {
    let id: UUID
    let label: String
    let type: NodeType
    let confidence: Double // 0.0 to 1.0
    let metadata: [String: String]
    
    enum NodeType: String, CaseIterable {
        case entity = "Entity"
        case concept = "Concept"
        case inference = "Inference"
        case document = "Document"
        case action = "Action"
        
        var color: String {
            switch self {
            case .entity: return "blue"
            case .concept: return "green"
            case .inference: return "orange"
            case .document: return "purple"
            case .action: return "red"
            }
        }
    }
}

/// Edge in the reasoning graph representing relationships
struct ReasoningEdge: Identifiable, Hashable {
    let id: UUID
    let source: UUID
    let target: UUID
    let relationship: RelationshipType
    let strength: Double // 0.0 to 1.0
    let reasoning: String // Explanation of the relationship
    
    enum RelationshipType: String, CaseIterable {
        case contains = "contains"
        case implies = "implies"
        case related = "related"
        case contradicts = "contradicts"
        case supports = "supports"
        case precedes = "precedes"
        
        var color: String {
            switch self {
            case .contains: return "blue"
            case .implies: return "green"
            case .related: return "gray"
            case .contradicts: return "red"
            case .supports: return "orange"
            case .precedes: return "purple"
            }
        }
    }
}

/// Complete reasoning graph structure
struct ReasoningGraph {
    var nodes: [ReasoningNode]
    var edges: [ReasoningEdge]
    
    /// Find all nodes connected to a given node
    func neighbors(of nodeID: UUID) -> [UUID] {
        edges.filter { $0.source == nodeID }.map { $0.target } +
        edges.filter { $0.target == nodeID }.map { $0.source }
    }
    
    /// Calculate graph centrality (importance) for each node
    func calculateCentrality() -> [UUID: Double] {
        var centrality: [UUID: Double] = [:]
        
        // Simple degree centrality: number of connections
        for node in nodes {
            let degree = neighbors(of: node.id).count
            centrality[node.id] = Double(degree) / Double(nodes.count - 1)
        }
        
        return centrality
    }
    
    /// Find shortest path between two nodes (Dijkstra's algorithm)
    func shortestPath(from source: UUID, to target: UUID) -> [UUID]? {
        var distances: [UUID: Double] = [:]
        var previous: [UUID: UUID?] = [:]
        var unvisited = Set(nodes.map { $0.id })
        
        // Initialize distances
        for node in nodes {
            distances[node.id] = node.id == source ? 0 : Double.infinity
            previous[node.id] = nil
        }
        
        while !unvisited.isEmpty {
            // Find unvisited node with minimum distance
            let current = unvisited.min { distances[$0] ?? Double.infinity < distances[$1] ?? Double.infinity }!
            
            if current == target {
                // Reconstruct path
                var path: [UUID] = []
                var current: UUID? = target
                while let node = current {
                    path.insert(node, at: 0)
                    current = previous[node] ?? nil
                }
                return path
            }
            
            unvisited.remove(current)
            
            // Update distances to neighbors
            for neighborID in neighbors(of: current) {
                if unvisited.contains(neighborID) {
                    let edge = edges.first { ($0.source == current && $0.target == neighborID) || ($0.source == neighborID && $0.target == current) }
                    let alt = (distances[current] ?? Double.infinity) + (1.0 - (edge?.strength ?? 0.5))
                    
                    if alt < (distances[neighborID] ?? Double.infinity) {
                        distances[neighborID] = alt
                        previous[neighborID] = current
                    }
                }
            }
        }
        
        return nil // No path found
    }
}

@MainActor
final class ReasoningGraphService: ObservableObject {
    @Published var graph: ReasoningGraph?
    @Published var isGenerating = false
    
    private var modelContext: ModelContext?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Generate reasoning graph from intelligence data
    func generateGraph(from intelligence: GraphIntelligenceData) async -> ReasoningGraph {
        isGenerating = true
        defer { isGenerating = false }
        
        var nodes: [ReasoningNode] = []
        var edges: [ReasoningEdge] = []
        
        // Create document nodes
        for doc in intelligence.documents {
            let node = ReasoningNode(
                id: UUID(),
                label: doc.name,
                type: .document,
                confidence: 1.0,
                metadata: [
                    "type": doc.type,
                    "date": doc.date.formatted()
                ]
            )
            nodes.append(node)
        }
        
        // Create entity nodes
        for entity in intelligence.entities {
            let node = ReasoningNode(
                id: UUID(),
                label: entity,
                type: .entity,
                confidence: 0.9,
                metadata: [:]
            )
            nodes.append(node)
        }
        
        // Create concept nodes from topics
        for topic in intelligence.topics {
            let node = ReasoningNode(
                id: UUID(),
                label: topic,
                type: .concept,
                confidence: 0.8,
                metadata: [:]
            )
            nodes.append(node)
        }
        
        // Create inference nodes from logical insights
        for (index, insight) in intelligence.insights.enumerated() {
            let node = ReasoningNode(
                id: UUID(),
                label: "Inference \(index + 1)",
                type: .inference,
                confidence: insight.confidence,
                metadata: [
                    "type": insight.type.rawValue,
                    "description": insight.description
                ]
            )
            nodes.append(node)
        }
        
        // Create edges: documents → entities
        let documentNodes = nodes.filter { $0.type == .document }
        let entityNodes = nodes.filter { $0.type == .entity }
        
        for docNode in documentNodes {
            for entityNode in entityNodes {
                // Check if entity appears in document
                if let doc = intelligence.documents.first(where: { $0.name == docNode.label }),
                   doc.entities.contains(entityNode.label) {
                    let edge = ReasoningEdge(
                        id: UUID(),
                        source: docNode.id,
                        target: entityNode.id,
                        relationship: .contains,
                        strength: 0.8,
                        reasoning: "\(entityNode.label) appears in \(docNode.label)"
                    )
                    edges.append(edge)
                }
            }
        }
        
        // Create edges: entities → concepts
        for entityNode in entityNodes {
            for conceptNode in nodes.filter({ $0.type == .concept }) {
                // Simple semantic similarity (in real app, use NLP)
                if entityNode.label.lowercased().contains(conceptNode.label.lowercased()) ||
                   conceptNode.label.lowercased().contains(entityNode.label.lowercased()) {
                    let edge = ReasoningEdge(
                        id: UUID(),
                        source: entityNode.id,
                        target: conceptNode.id,
                        relationship: .related,
                        strength: 0.6,
                        reasoning: "\(entityNode.label) relates to \(conceptNode.label)"
                    )
                    edges.append(edge)
                }
            }
        }
        
        // Create edges: concepts → inferences
        let inferenceNodes = nodes.filter { $0.type == .inference }
        for conceptNode in nodes.filter({ $0.type == .concept }) {
            for inferenceNode in inferenceNodes {
                if let insight = intelligence.insights.first(where: { $0.description.contains(conceptNode.label) }) {
                    let edge = ReasoningEdge(
                        id: UUID(),
                        source: conceptNode.id,
                        target: inferenceNode.id,
                        relationship: .supports,
                        strength: insight.confidence,
                        reasoning: "\(conceptNode.label) supports \(inferenceNode.label)"
                    )
                    edges.append(edge)
                }
            }
        }
        
        // Create temporal edges (precedes)
        let sortedDocs = intelligence.documents.sorted { $0.date < $1.date }
        for i in 0..<sortedDocs.count - 1 {
            if let sourceNode = nodes.first(where: { $0.label == sortedDocs[i].name && $0.type == .document }),
               let targetNode = nodes.first(where: { $0.label == sortedDocs[i + 1].name && $0.type == .document }) {
                let edge = ReasoningEdge(
                    id: UUID(),
                    source: sourceNode.id,
                    target: targetNode.id,
                    relationship: .precedes,
                    strength: 1.0,
                    reasoning: "\(sourceNode.label) precedes \(targetNode.label) in time"
                )
                edges.append(edge)
            }
        }
        
        let graph = ReasoningGraph(nodes: nodes, edges: edges)
        self.graph = graph
        
        return graph
    }
}

// MARK: - Intelligence Data Structures (for Graph Generation)

struct GraphIntelligenceData {
    var documents: [DocumentData]
    var entities: [String]
    var topics: [String]
    var insights: [LogicalInsight]
    var timeline: [GraphTimelineEvent]
}

struct DocumentData {
    let name: String
    let type: String
    let date: Date
    let entities: [String]
    let text: String
}

struct LogicalInsight {
    let type: InsightType
    let description: String
    let confidence: Double
    
    enum InsightType: String {
        case deductive = "Deductive"
        case inductive = "Inductive"
        case abductive = "Abductive"
        case temporal = "Temporal"
    }
}

struct GraphTimelineEvent {
    let date: Date
    let description: String
    let documentName: String
}


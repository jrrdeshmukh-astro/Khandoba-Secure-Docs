//
//  ReasoningGraphView.swift
//  Khandoba Secure Docs
//
//  Graph Theory Visualization for Intel Reasoning
//

import SwiftUI
import SwiftData

struct ReasoningGraphView: View {
    let graph: ReasoningGraph
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedNode: ReasoningNode?
    @State private var layout: GraphLayout = .forceDirected
    
    enum GraphLayout {
        case forceDirected
        case hierarchical
        case circular
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.md) {
            // Graph visualization
            GeometryReader { geometry in
                ZStack {
                    // Draw edges
                    ForEach(graph.edges) { edge in
                        if let sourcePos = nodePosition(edge.source, in: geometry.size),
                           let targetPos = nodePosition(edge.target, in: geometry.size) {
                            Path { path in
                                path.move(to: sourcePos)
                                path.addLine(to: targetPos)
                            }
                            .stroke(edgeColor(edge), lineWidth: CGFloat(edge.strength * 3))
                            .opacity(0.6)
                        }
                    }
                    
                    // Draw nodes
                    ForEach(graph.nodes) { node in
                        if let pos = nodePosition(node.id, in: geometry.size) {
                            NodeView(node: node, isSelected: selectedNode?.id == node.id, colors: colors, theme: theme)
                                .position(pos)
                                .onTapGesture {
                                    selectedNode = node
                                }
                        }
                    }
                }
            }
            .frame(height: 400)
            .background(colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
            
            // Node details
            if let node = selectedNode {
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        HStack {
                            Text(node.label)
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Spacer()
                            
                            Text(node.type.rawValue)
                                .font(.caption)
                                .foregroundColor(typeColor(node.type, colors: colors))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(typeColor(node.type, colors: colors).opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Text("Confidence: \(Int(node.confidence * 100))%")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        // Show connected nodes
                        let neighbors = graph.neighbors(of: node.id)
                        if !neighbors.isEmpty {
                            Text("Connected to \(neighbors.count) node\(neighbors.count == 1 ? "" : "s")")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func nodePosition(_ nodeID: UUID, in size: CGSize) -> CGPoint? {
        guard graph.nodes.contains(where: { $0.id == nodeID }) else { return nil }
        
        // Simple circular layout
        let nodeCount = graph.nodes.count
        guard let index = graph.nodes.firstIndex(where: { $0.id == nodeID }) else { return nil }
        let angle = 2 * Double.pi * Double(index) / Double(nodeCount)
        let radius = min(size.width, size.height) * 0.35
        
        return CGPoint(
            x: size.width / 2 + radius * Foundation.cos(angle),
            y: size.height / 2 + radius * Foundation.sin(angle)
        )
    }
    
    private func edgeColor(_ edge: ReasoningEdge) -> Color {
        let colors = theme.colors(for: colorScheme)
        switch edge.relationship {
        case .contains: return colors.info
        case .implies: return colors.success
        case .related: return colors.textSecondary
        case .contradicts: return colors.error
        case .supports: return colors.warning
        case .precedes: return colors.primary
        }
    }
    
    private func typeColor(_ type: ReasoningNode.NodeType, colors: UnifiedTheme.Colors) -> Color {
        switch type {
        case .entity: return colors.info
        case .concept: return colors.success
        case .inference: return colors.warning
        case .document: return colors.primary
        case .action: return colors.error
        }
    }
}

struct NodeView: View {
    let node: ReasoningNode
    let isSelected: Bool
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        ZStack {
            Circle()
                .fill(typeColor(node.type).opacity(0.8))
                .frame(width: isSelected ? 60 : 50, height: isSelected ? 60 : 50)
                .overlay(
                    Circle()
                        .stroke(isSelected ? colors.primary : Color.clear, lineWidth: 3)
                )
            
            Text(String(node.label.prefix(1)))
                .font(.caption)
                .foregroundColor(.white)
                .fontWeight(.bold)
        }
        .shadow(radius: isSelected ? 8 : 4)
    }
    
    private func typeColor(_ type: ReasoningNode.NodeType) -> Color {
        switch type {
        case .entity: return colors.info
        case .concept: return colors.success
        case .inference: return colors.warning
        case .document: return colors.primary
        case .action: return colors.error
        }
    }
}


//
//  MarkdownTextView.swift
//  Khandoba Secure Docs
//
//  Beautiful Markdown Renderer for Intel Reports
//

import SwiftUI

struct MarkdownTextView: View {
    let markdown: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ScrollView {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                ForEach(parseMarkdown(markdown), id: \.id) { element in
                    renderElement(element, colors: colors)
                }
            }
            .padding()
        }
    }
    
    private func renderElement(_ element: MarkdownElement, colors: UnifiedTheme.Colors) -> some View {
        switch element {
        case .heading(let level, let text):
            return AnyView(
                Text(text)
                    .font(level == 1 ? theme.typography.title : theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                    .fontWeight(.bold)
                    .padding(.top, level == 1 ? 0 : UnifiedTheme.Spacing.md)
            )
            
        case .paragraph(let text):
            return AnyView(
                Text(text)
                    .font(theme.typography.body)
                    .foregroundColor(colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            )
            
        case .list(let items, let ordered):
            return AnyView(
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: UnifiedTheme.Spacing.sm) {
                            Text(ordered ? "\(index + 1)." : "•")
                                .font(theme.typography.body)
                                .foregroundColor(colors.primary)
                            
                            Text(item)
                                .font(theme.typography.body)
                                .foregroundColor(colors.textPrimary)
                        }
                    }
                }
            )
            
        case .bold(let text):
            return AnyView(
                Text(text)
                    .font(theme.typography.body)
                    .foregroundColor(colors.textPrimary)
                    .fontWeight(.bold)
            )
            
        case .code(let text):
            return AnyView(
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(colors.primary)
                    .padding(8)
                    .background(colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.sm)
            )
        }
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        
        var currentParagraph = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                continue
            }
            
            // Heading
            if trimmed.hasPrefix("# ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                elements.append(.heading(1, String(trimmed.dropFirst(2))))
                continue
            }
            
            if trimmed.hasPrefix("## ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                elements.append(.heading(2, String(trimmed.dropFirst(3))))
                continue
            }
            
            // List item
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                // Simple list parsing
                let item = String(trimmed.dropFirst(2))
                if case .list(let items, let ordered) = elements.last {
                    var newItems = items
                    newItems.append(item)
                    elements.removeLast()
                    elements.append(.list(newItems, ordered))
                } else {
                    elements.append(.list([item], false))
                }
                continue
            }
            
            // Bold
            if trimmed.contains("**") {
                let parts = trimmed.components(separatedBy: "**")
                for (index, part) in parts.enumerated() {
                    if index % 2 == 1 {
                        currentParagraph += part
                    } else {
                        currentParagraph += part
                    }
                }
                continue
            }
            
            // Regular paragraph
            currentParagraph += (currentParagraph.isEmpty ? "" : " ") + trimmed
        }
        
        if !currentParagraph.isEmpty {
            elements.append(.paragraph(currentParagraph))
        }
        
        return elements
    }
}

enum MarkdownElement: Identifiable {
    case heading(Int, String)
    case paragraph(String)
    case list([String], Bool)
    case bold(String)
    case code(String)
    
    var id: UUID {
        UUID()
    }
}


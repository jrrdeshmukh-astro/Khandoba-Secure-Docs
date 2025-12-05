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
            let fontSize: Font = {
                switch level {
                case 1: return theme.typography.title
                case 2: return theme.typography.headline
                default: return theme.typography.subheadline
                }
            }()
            return AnyView(
                parseBoldText(text, colors: colors)
                    .font(fontSize)
                    .foregroundColor(colors.textPrimary)
                    .fontWeight(.bold)
                    .padding(.top, level == 1 ? 0 : UnifiedTheme.Spacing.md)
            )
            
        case .paragraph(let text):
            return AnyView(
                parseBoldText(text, colors: colors)
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
                            
                            parseBoldText(item, colors: colors)
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
            
            if trimmed.hasPrefix("### ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                elements.append(.heading(3, String(trimmed.dropFirst(4))))
                continue
            }
            
            // Numbered list item (e.g., "1. ", "2. ")
            if let numberMatch = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                let item = String(trimmed[numberMatch.upperBound...])
                if case .list(let items, let ordered) = elements.last, ordered {
                    var newItems = items
                    newItems.append(item)
                    elements.removeLast()
                    elements.append(.list(newItems, true))
                } else {
                    elements.append(.list([item], true))
                }
                continue
            }
            
            // Bullet list item
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                if !currentParagraph.isEmpty {
                    elements.append(.paragraph(currentParagraph))
                    currentParagraph = ""
                }
                let item = String(trimmed.dropFirst(2))
                if case .list(let items, let ordered) = elements.last, !ordered {
                    var newItems = items
                    newItems.append(item)
                    elements.removeLast()
                    elements.append(.list(newItems, false))
                } else {
                    elements.append(.list([item], false))
                }
                continue
            }
            
            // Regular paragraph (with bold support)
            if trimmed.contains("**") {
                currentParagraph += (currentParagraph.isEmpty ? "" : " ") + trimmed
            } else {
                currentParagraph += (currentParagraph.isEmpty ? "" : " ") + trimmed
            }
        }
        
        if !currentParagraph.isEmpty {
            elements.append(.paragraph(currentParagraph))
        }
        
        return elements
    }
    
    // Helper to parse bold text (**text**)
    @ViewBuilder
    private func parseBoldText(_ text: String, colors: UnifiedTheme.Colors) -> some View {
        let parts = text.components(separatedBy: "**")
        if parts.count == 1 {
            Text(text)
        } else {
            HStack(spacing: 0) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    if index % 2 == 1 {
                        Text(part)
                            .fontWeight(.bold)
                    } else {
                        Text(part)
                    }
                }
            }
        }
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


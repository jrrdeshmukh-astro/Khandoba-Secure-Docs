//
//  DocumentFilterView.swift
//  Khandoba Secure Docs
//
//  Advanced document filtering

import SwiftUI

struct DocumentFilterView: View {
    @Binding var filterType: DocumentFilterType
    @Binding var selectedTags: Set<String>
    @Binding var searchText: String
    
    let allTags: [String]
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                        // Document Type Filter
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Document Type")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            ForEach(DocumentFilterType.allCases, id: \.self) { type in
                                FilterOptionRow(
                                    title: type.displayName,
                                    icon: type.icon,
                                    isSelected: filterType == type,
                                    action: {
                                        filterType = type
                                    }
                                )
                            }
                        }
                        
                        Divider()
                        
                        // Tags Filter
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Filter by Tags")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            if allTags.isEmpty {
                                Text("No tags available")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textSecondary)
                                    .padding()
                            } else {
                                FlowLayout(spacing: 8) {
                                    ForEach(allTags, id: \.self) { tag in
                                        TagChip(
                                            tag: tag,
                                            isSelected: selectedTags.contains(tag),
                                            action: {
                                                if selectedTags.contains(tag) {
                                                    selectedTags.remove(tag)
                                                } else {
                                                    selectedTags.insert(tag)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Clear All
                        Button {
                            filterType = .all
                            selectedTags.removeAll()
                            searchText = ""
                        } label: {
                            Text("Clear All Filters")
                                .font(theme.typography.body)
                                .foregroundColor(colors.error)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

enum DocumentFilterType: String, CaseIterable {
    case all = "all"
    case source = "source"
    case sink = "sink"
    case text = "text"
    case image = "image"
    case video = "video"
    case audio = "audio"
    case pdf = "pdf"
    
    var displayName: String {
        switch self {
        case .all: return "All Documents"
        case .source: return "Source (Live Recordings)"
        case .sink: return "Sink (External Uploads)"
        case .text: return "Text Documents"
        case .image: return "Images"
        case .video: return "Videos"
        case .audio: return "Audio"
        case .pdf: return "PDFs"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "doc.fill"
        case .source: return "camera.fill"
        case .sink: return "arrow.down.circle.fill"
        case .text: return "doc.text.fill"
        case .image: return "photo.fill"
        case .video: return "video.fill"
        case .audio: return "waveform"
        case .pdf: return "doc.richtext.fill"
        }
    }
}

struct FilterOptionRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(colors.primary)
                    .frame(width: 30)
                
                Text(title)
                    .font(theme.typography.body)
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(colors.primary)
                }
            }
            .padding()
            .background(isSelected ? colors.primary.opacity(0.1) : colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
        }
    }
}

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: action) {
            Text(tag)
                .font(theme.typography.caption)
                .foregroundColor(isSelected ? .white : colors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? colors.primary : colors.surface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colors.primary, lineWidth: isSelected ? 0 : 1)
                )
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size = CGSize.zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}


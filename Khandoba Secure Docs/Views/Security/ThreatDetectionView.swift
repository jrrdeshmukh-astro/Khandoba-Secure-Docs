//
//  ThreatDetectionView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//

import SwiftUI

struct ThreatDetectionView: View {
    let threats: [ThreatDetection]
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedThreat: ThreatDetection?
    @State private var showThreatDetails = false
    @State private var filterSeverity: String? = nil
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if threats.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.shield.fill",
                        title: "No Threats Detected",
                        message: "All documents appear authentic and untampered"
                    )
                } else {
                    VStack(spacing: 0) {
                        // Filter Bar
                        if !threats.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: UnifiedTheme.Spacing.sm) {
                                    FilterButton(
                                        title: "All",
                                        isSelected: filterSeverity == nil,
                                        action: { filterSeverity = nil },
                                        colors: colors,
                                        theme: theme
                                    )
                                    
                                    FilterButton(
                                        title: "Critical",
                                        isSelected: filterSeverity == "critical",
                                        action: { filterSeverity = "critical" },
                                        colors: colors,
                                        theme: theme
                                    )
                                    
                                    FilterButton(
                                        title: "High",
                                        isSelected: filterSeverity == "high",
                                        action: { filterSeverity = "high" },
                                        colors: colors,
                                        theme: theme
                                    )
                                    
                                    FilterButton(
                                        title: "Medium",
                                        isSelected: filterSeverity == "medium",
                                        action: { filterSeverity = "medium" },
                                        colors: colors,
                                        theme: theme
                                    )
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical, UnifiedTheme.Spacing.sm)
                        }
                        
                        // Threats List
                        List {
                            ForEach(filteredThreats, id: \.detectedAt) { threat in
                                Button {
                                    selectedThreat = threat
                                    showThreatDetails = true
                                } label: {
                                    ThreatDetectionRow(threat: threat, colors: colors, theme: theme)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .background(colors.background)
                    }
                }
            }
            .navigationTitle("Threat Detection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showThreatDetails) {
                if let threat = selectedThreat {
                    ThreatDetailView(threat: threat)
                }
            }
        }
    }
    
    private var filteredThreats: [ThreatDetection] {
        if let severity = filterSeverity {
            return threats.filter { $0.severity == severity }
        }
        return threats
    }
}

struct ThreatDetectionRow: View {
    let threat: ThreatDetection
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.md) {
            // Severity Indicator
            ZStack {
                Circle()
                    .fill(severityColor(threat.severity).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: severityIcon(threat.severity))
                    .foregroundColor(severityColor(threat.severity))
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(threat.type.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    Text(threat.severity.uppercased())
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(severityColor(threat.severity))
                        .cornerRadius(4)
                }
                
                Text(threat.description)
                    .font(theme.typography.body)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(2)
                
                Text("Detected: \(threat.detectedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textTertiary)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(colors.textTertiary)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
    
    private func severityIcon(_ severity: String) -> String {
        switch severity {
        case "critical": return "exclamationmark.triangle.fill"
        case "high": return "exclamationmark.circle.fill"
        case "medium": return "info.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        default: return .green
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.subheadline)
                .foregroundColor(isSelected ? .white : colors.textPrimary)
                .padding(.horizontal, UnifiedTheme.Spacing.md)
                .padding(.vertical, UnifiedTheme.Spacing.sm)
                .background(isSelected ? colors.primary : colors.surface)
                .cornerRadius(UnifiedTheme.CornerRadius.md)
        }
    }
}

struct ThreatDetailView: View {
    let threat: ThreatDetection
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(severityColor(threat.severity).opacity(0.2))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: severityIcon(threat.severity))
                                    .foregroundColor(severityColor(threat.severity))
                                    .font(.title)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(threat.type.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(theme.typography.title2)
                                    .foregroundColor(colors.textPrimary)
                                
                                Text(threat.severity.uppercased())
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(severityColor(threat.severity))
                                    .cornerRadius(6)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    
                    // Description
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Description")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Text(threat.description)
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Details
                    if let details = threat.details, !details.isEmpty {
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                Text("Details")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                ForEach(Array(details.keys.sorted()), id: \.self) { key in
                                    if let value = details[key] {
                                        HStack {
                                            Text(key.replacingOccurrences(of: "_", with: " ").capitalized + ":")
                                                .font(theme.typography.subheadline)
                                                .foregroundColor(colors.textPrimary)
                                            
                                            Spacer()
                                            
                                            Text(value)
                                                .font(theme.typography.body)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Timestamp
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Detection Time")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Text(threat.detectedAt.formatted(date: .complete, time: .complete))
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recommended Actions
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Recommended Actions")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            ForEach(recommendedActions(for: threat.severity), id: \.self) { action in
                                HStack(alignment: .top, spacing: UnifiedTheme.Spacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(colors.primary)
                                        .font(.caption)
                                    
                                    Text(action)
                                        .font(theme.typography.body)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(colors.background)
            .navigationTitle("Threat Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func severityIcon(_ severity: String) -> String {
        switch severity {
        case "critical": return "exclamationmark.triangle.fill"
        case "high": return "exclamationmark.circle.fill"
        case "medium": return "info.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        default: return .green
        }
    }
    
    private func recommendedActions(for severity: String) -> [String] {
        switch severity {
        case "critical":
            return [
                "Immediately revoke document access",
                "Notify authorized department",
                "Review document integrity",
                "Check for unauthorized modifications"
            ]
        case "high":
            return [
                "Review document access logs",
                "Verify document authenticity",
                "Notify document owner",
                "Consider revoking access"
            ]
        case "medium":
            return [
                "Monitor document activity",
                "Review access patterns",
                "Verify with document owner"
            ]
        default:
            return [
                "Continue monitoring",
                "Review periodically"
            ]
        }
    }
}

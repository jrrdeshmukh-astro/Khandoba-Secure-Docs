//
//  IncidentListView.swift
//  Khandoba Secure Docs
//
//  Security incident list view
//

import SwiftUI

struct IncidentListView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var incidentService = IncidentResponseService.shared
    
    @State private var filterSeverity: IncidentSeverity?
    @State private var filterStatus: IncidentStatus?
    
    var filteredIncidents: [SecurityIncident] {
        var incidents = incidentService.incidents
        
        if let severity = filterSeverity {
            incidents = incidents.filter { $0.severityEnum == severity }
        }
        
        if let status = filterStatus {
            incidents = incidents.filter { $0.statusEnum == status }
        }
        
        return incidents
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack {
                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            IncidentFilterChip(title: "All", isSelected: filterSeverity == nil && filterStatus == nil) {
                                filterSeverity = nil
                                filterStatus = nil
                            }
                            
                            ForEach(IncidentSeverity.allCases, id: \.self) { severity in
                                IncidentFilterChip(title: severity.rawValue, isSelected: filterSeverity == severity) {
                                    filterSeverity = severity
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, UnifiedTheme.Spacing.sm)
                    
                    // Incident List
                    List {
                        ForEach(filteredIncidents, id: \.id) { incident in
                            NavigationLink {
                                IncidentDetailView(incident: incident)
                            } label: {
                                IncidentRow(incident: incident)
                            }
                        }
                    }
                }
                .navigationTitle("Security Incidents")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .onAppear {
            configureService()
        }
    }
    
    private func configureService() {
        incidentService.configure(
            modelContext: modelContext,
            threatMonitoringService: ThreatMonitoringService()
        )
    }
}

private struct IncidentFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: action) {
            Text(title)
                .font(theme.typography.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? colors.primary : colors.surface)
                .foregroundColor(isSelected ? .white : colors.textPrimary)
                .cornerRadius(UnifiedTheme.CornerRadius.full)
        }
    }
}

private struct IncidentRow: View {
    let incident: SecurityIncident
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(incident.title)
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                Text(incident.incidentDescription)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(2)
                
                Text(DateFormatter.localizedString(from: incident.detectedDate, dateStyle: .medium, timeStyle: .short))
                    .font(theme.typography.caption2)
                    .foregroundColor(colors.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(incident.severity)
                    .font(theme.typography.caption)
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.2))
                    .cornerRadius(UnifiedTheme.CornerRadius.sm)
                
                Text(incident.status)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var severityColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch incident.severityEnum {
        case .critical:
            return colors.error
        case .high:
            return colors.error.opacity(0.8)
        case .medium:
            return colors.warning
        case .low:
            return colors.info
        case .none:
            return colors.textTertiary
        }
    }
}


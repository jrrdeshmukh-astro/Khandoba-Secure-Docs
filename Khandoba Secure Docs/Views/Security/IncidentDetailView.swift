//
//  IncidentDetailView.swift
//  Khandoba Secure Docs
//
//  Security incident detail view
//

import SwiftUI

struct IncidentDetailView: View {
    let incident: SecurityIncident
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var incidentService = IncidentResponseService.shared
    
    @State private var showTriageSheet = false
    @State private var showContainmentSheet = false
    @State private var showResolutionSheet = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ScrollView {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                // Incident Info
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text(incident.title)
                            .font(theme.typography.title2)
                        
                        Text(incident.incidentDescription)
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                        
                        HStack {
                            Label(incident.severity, systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(severityColor)
                            Spacer()
                            Label(incident.status, systemImage: "circle.fill")
                                .foregroundColor(statusColor)
                        }
                        .font(theme.typography.subheadline)
                    }
                    .padding()
                }
                
                // Timeline
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text("Timeline")
                            .font(theme.typography.headline)
                        
                        TimelineItem(label: "Detected", date: incident.detectedDate)
                        
                        if let triagedDate = incident.triagedDate {
                            TimelineItem(label: "Triaged", date: triagedDate)
                        }
                        
                        if let containedDate = incident.containedDate {
                            TimelineItem(label: "Contained", date: containedDate)
                        }
                        
                        if let resolvedDate = incident.resolvedDate {
                            TimelineItem(label: "Resolved", date: resolvedDate)
                        }
                    }
                    .padding()
                }
                
                // Actions
                if incident.statusEnum == .detected {
                    StandardCard {
                        Button("Triage Incident") {
                            showTriageSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                
                if incident.statusEnum == .triaged {
                    StandardCard {
                        Button("Contain Incident") {
                            showContainmentSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                
                if incident.statusEnum == .contained {
                    StandardCard {
                        Button("Resolve Incident") {
                            showResolutionSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                
                // Containment Actions
                if let actions = incident.containmentActions {
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Containment Actions")
                                .font(theme.typography.headline)
                            Text(actions)
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding()
                    }
                }
                
                // Recovery Actions
                if let actions = incident.recoveryActions {
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Recovery Actions")
                                .font(theme.typography.headline)
                            Text(actions)
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Incident Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTriageSheet) {
            IncidentTriageSheet(incident: incident)
        }
        .sheet(isPresented: $showContainmentSheet) {
            IncidentContainmentSheet(incident: incident)
        }
        .sheet(isPresented: $showResolutionSheet) {
            IncidentResolutionSheet(incident: incident)
        }
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
    
    private var statusColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch incident.statusEnum {
        case .detected:
            return colors.warning
        case .triaged:
            return colors.info
        case .contained:
            return colors.info.opacity(0.8)
        case .resolved:
            return colors.success
        case .closed:
            return colors.textTertiary
        case .none:
            return colors.textTertiary
        }
    }
}

private struct TimelineItem: View {
    let label: String
    let date: Date
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack {
            Circle()
                .fill(colors.primary)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(theme.typography.subheadline)
            
            Spacer()
            
            Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short))
                .font(theme.typography.caption)
                .foregroundColor(colors.textSecondary)
        }
    }
}

private struct IncidentTriageSheet: View {
    let incident: SecurityIncident
    @Environment(\.dismiss) var dismiss
    @StateObject private var incidentService = IncidentResponseService.shared
    @State private var selectedClassification: IncidentClassification = .other
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Classification", selection: $selectedClassification) {
                    ForEach(IncidentClassification.allCases, id: \.self) { classification in
                        Text(classification.rawValue).tag(classification)
                    }
                }
            }
            .navigationTitle("Triage Incident")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        try? incidentService.triageIncident(incident, classification: selectedClassification)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct IncidentContainmentSheet: View {
    let incident: SecurityIncident
    @Environment(\.dismiss) var dismiss
    @StateObject private var incidentService = IncidentResponseService.shared
    @State private var actions: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Containment Actions", text: $actions, axis: .vertical)
                    .lineLimit(5...10)
            }
            .navigationTitle("Contain Incident")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        try? incidentService.containIncident(incident, actions: actions)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct IncidentResolutionSheet: View {
    let incident: SecurityIncident
    @Environment(\.dismiss) var dismiss
    @StateObject private var incidentService = IncidentResponseService.shared
    @State private var actions: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Recovery Actions", text: $actions, axis: .vertical)
                    .lineLimit(5...10)
            }
            .navigationTitle("Resolve Incident")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        try? incidentService.resolveIncident(incident, recoveryActions: actions)
                        dismiss()
                    }
                }
            }
        }
    }
}


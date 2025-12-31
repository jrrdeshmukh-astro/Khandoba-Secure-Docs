//
//  RiskRegisterView.swift
//  Khandoba Secure Docs
//
//  Risk register view (list of all risks)
//

import SwiftUI

struct RiskRegisterView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var riskService = RiskAssessmentService.shared
    
    @State private var filterSeverity: RiskSeverity?
    @State private var filterStatus: RiskStatus?
    
    var filteredRisks: [RiskAssessment] {
        var risks = riskService.risks
        
        if let severity = filterSeverity {
            risks = risks.filter { $0.severityEnum == severity }
        }
        
        if let status = filterStatus {
            risks = risks.filter { $0.statusEnum == status }
        }
        
        return risks
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
                            RiskFilterChip(title: "All Severities", isSelected: filterSeverity == nil) {
                                filterSeverity = nil
                            }
                            
                            ForEach(RiskSeverity.allCases, id: \.self) { severity in
                                RiskFilterChip(title: severity.rawValue, isSelected: filterSeverity == severity) {
                                    filterSeverity = severity
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, UnifiedTheme.Spacing.sm)
                    
                    // Risk List
                    List {
                        ForEach(filteredRisks, id: \.id) { risk in
                            NavigationLink {
                                RiskAssessmentDetailView(risk: risk)
                            } label: {
                                RiskAssessmentRow(risk: risk)
                            }
                        }
                    }
                }
                .navigationTitle("Risk Register")
                .navigationBarTitleDisplayMode(.large)
            }
        }
    }
}

private struct RiskFilterChip: View {
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


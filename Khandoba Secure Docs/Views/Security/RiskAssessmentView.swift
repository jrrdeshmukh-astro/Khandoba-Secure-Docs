//
//  RiskAssessmentView.swift
//  Khandoba Secure Docs
//
//  Risk assessment view
//

import SwiftUI

struct RiskAssessmentView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var riskService = RiskAssessmentService.shared
    
    @State private var isAssessing = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                List {
                    ForEach(riskService.risks, id: \.id) { risk in
                        NavigationLink {
                            RiskAssessmentDetailView(risk: risk)
                        } label: {
                            RiskAssessmentRow(risk: risk)
                        }
                    }
                }
                .navigationTitle("Risk Assessment")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task {
                                await performAssessment()
                            }
                        } label: {
                            if isAssessing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(isAssessing)
                    }
                }
            }
        }
        .onAppear {
            configureService()
        }
    }
    
    private func configureService() {
        riskService.configure(
            modelContext: modelContext,
            threatMonitoringService: ThreatMonitoringService(),
            complianceEngineService: ComplianceEngineService.shared
        )
    }
    
    private func performAssessment() async {
        isAssessing = true
        defer { isAssessing = false }
        
        try? await riskService.performRiskAssessment()
    }
}

struct RiskAssessmentRow: View {
    let risk: RiskAssessment
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(risk.title)
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                Text(risk.riskDescription)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(risk.severity)
                    .font(theme.typography.caption)
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.2))
                    .cornerRadius(UnifiedTheme.CornerRadius.sm)
                
                Text("\(Int(risk.riskScore * 100))%")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var severityColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch risk.severityEnum {
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

struct RiskAssessmentDetailView: View {
    let risk: RiskAssessment
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ScrollView {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text(risk.title)
                            .font(theme.typography.title2)
                        
                        Text(risk.riskDescription)
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                    }
                    .padding()
                }
                
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text("Risk Metrics")
                            .font(theme.typography.headline)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Risk Score")
                                Text("\(Int(risk.riskScore * 100))%")
                                    .font(theme.typography.title2)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Likelihood")
                                Text("\(Int(risk.likelihood * 100))%")
                                    .font(theme.typography.title2)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Impact")
                                Text("\(Int(risk.impact * 100))%")
                                    .font(theme.typography.title2)
                            }
                        }
                    }
                    .padding()
                }
                
                if let plan = risk.mitigationPlan {
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Mitigation Plan")
                                .font(theme.typography.headline)
                            Text(plan)
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Risk Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}


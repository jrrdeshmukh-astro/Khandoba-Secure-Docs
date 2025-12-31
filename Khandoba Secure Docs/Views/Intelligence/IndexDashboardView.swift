//
//  IndexDashboardView.swift
//  Khandoba Secure Docs
//
//  Real-time index dashboard view
//

import SwiftUI

struct IndexDashboardView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var indexService = IndexCalculationService.shared
    @StateObject private var threatService = ThreatMonitoringService()
    @StateObject private var complianceService = ComplianceEngineService.shared
    @StateObject private var riskService = RiskAssessmentService.shared
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Threat Index Card
                        IndexCard(
                            title: "Threat Index",
                            value: indexService.currentIndexes.threatIndex,
                            threshold: 60.0,
                            colors: colors
                        )
                        
                        // Compliance Index Card
                        IndexCard(
                            title: "Compliance Index",
                            value: indexService.currentIndexes.complianceIndex,
                            threshold: 80.0,
                            colors: colors
                        )
                        
                        // Triage Criticality Card
                        IndexCard(
                            title: "Triage Criticality",
                            value: indexService.currentIndexes.triageCriticality,
                            threshold: 60.0,
                            colors: colors
                        )
                        
                        // Last Updated
                        Text("Last updated: \(DateFormatter.localizedString(from: indexService.currentIndexes.calculatedAt, dateStyle: .none, timeStyle: .medium))")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textTertiary)
                    }
                    .padding()
                }
                .navigationTitle("Index Dashboard")
                .navigationBarTitleDisplayMode(.large)
                .refreshable {
                    await indexService.calculateAllIndexes()
                }
            }
        }
        .onAppear {
            configureServices()
        }
    }
    
    private func configureServices() {
        indexService.configure(
            modelContext: modelContext,
            threatMonitoringService: threatService,
            complianceEngineService: complianceService,
            riskAssessmentService: riskService
        )
    }
}

private struct IndexCard: View {
    let title: String
    let value: Double
    let threshold: Double
    let colors: UnifiedTheme.Colors
    
    @Environment(\.unifiedTheme) var theme
    
    var body: some View {
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                Text(title)
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                HStack {
                    Text("\(Int(value))")
                        .font(theme.typography.largeTitle)
                        .foregroundColor(indexColor)
                    
                    Spacer()
                    
                    Text(statusText)
                        .font(theme.typography.subheadline)
                        .foregroundColor(indexColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(indexColor.opacity(0.2))
                        .cornerRadius(UnifiedTheme.CornerRadius.full)
                }
                
                ProgressView(value: value, total: 100)
                    .tint(indexColor)
            }
            .padding()
        }
    }
    
    private var indexColor: Color {
        if value >= threshold {
            return colors.error
        } else if value >= threshold * 0.5 {
            return colors.warning
        } else {
            return colors.success
        }
    }
    
    private var statusText: String {
        if value >= threshold {
            return "Critical"
        } else if value >= threshold * 0.5 {
            return "Warning"
        } else {
            return "Good"
        }
    }
}


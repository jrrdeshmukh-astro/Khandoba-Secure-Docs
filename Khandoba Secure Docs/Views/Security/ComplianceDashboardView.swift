//
//  ComplianceDashboardView.swift
//  Khandoba Secure Docs
//
//  Compliance dashboard view
//

import SwiftUI

struct ComplianceDashboardView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var complianceService = ComplianceEngineService.shared
    @StateObject private var indexService = IndexCalculationService.shared
    @StateObject private var detectionService = ComplianceDetectionService.shared
    
    @State private var isAssessing = false
    @State private var showRecommendations = false
    @State private var isDetecting = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Recommendations Card
                        if !detectionService.recommendations.isEmpty {
                            RecommendationsCard(
                                recommendations: detectionService.recommendations,
                                industry: detectionService.detectedIndustry,
                                onDetect: {
                                    Task {
                                        isDetecting = true
                                        try? await detectionService.detectComplianceRegime()
                                        isDetecting = false
                                    }
                                },
                                isDetecting: isDetecting
                            )
                        } else {
                            // Detection Prompt
                            StandardCard {
                                VStack(spacing: UnifiedTheme.Spacing.md) {
                                    Image(systemName: "sparkles.rectangle.stack.fill")
                                        .font(.title)
                                        .foregroundColor(colors.primary)
                                    
                                    Text("Auto-Detect Compliance Regime")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Text("Analyze your data to automatically determine which compliance frameworks you need")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Button {
                                        Task {
                                            isDetecting = true
                                            try? await detectionService.detectComplianceRegime()
                                            isDetecting = false
                                        }
                                    } label: {
                                        HStack {
                                            if isDetecting {
                                                ProgressView()
                                                    .tint(.white)
                                            } else {
                                                Image(systemName: "magnifyingglass")
                                            }
                                            Text(isDetecting ? "Analyzing..." : "Detect Compliance Needs")
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PrimaryButtonStyle())
                                    .disabled(isDetecting)
                                }
                                .padding()
                            }
                        }
                        
                        // Overall Status Card
                        OverallComplianceCard(
                            status: complianceService.calculateComplianceStatus(),
                            complianceIndex: indexService.currentIndexes.complianceIndex
                        )
                        
                        // Framework Cards
                        ForEach(ComplianceFramework.allCases, id: \.self) { framework in
                            if let record = complianceService.getRecord(for: framework) {
                                FrameworkCard(record: record)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Compliance")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task {
                                await assessAllFrameworks()
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
            configureServices()
        }
    }
    
    private func configureServices() {
        complianceService.configure(
            modelContext: modelContext,
            threatMonitoringService: ThreatMonitoringService()
        )
        detectionService.configure(modelContext: modelContext)
    }
    
    private func assessAllFrameworks() async {
        isAssessing = true
        defer { isAssessing = false }
        
        for framework in ComplianceFramework.allCases {
            try? await complianceService.assessCompliance(for: framework)
        }
    }
}

private struct OverallComplianceCard: View {
    let status: (status: ComplianceStatus, score: Double)
    let complianceIndex: Double
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                Text("Overall Compliance")
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Status")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        Text(status.status.rawValue)
                            .font(theme.typography.title2)
                            .foregroundColor(statusColor(for: status.status, colors: colors))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Index")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        Text("\(Int(complianceIndex))")
                            .font(theme.typography.title2)
                            .foregroundColor(colors.textPrimary)
                    }
                }
                
                // Progress bar
                ProgressView(value: complianceIndex, total: 100)
                    .tint(statusColor(for: status.status, colors: colors))
            }
            .padding()
        }
    }
    
    private func statusColor(for status: ComplianceStatus, colors: UnifiedTheme.Colors) -> Color {
        switch status {
        case .compliant:
            return colors.success
        case .partiallyCompliant:
            return colors.warning
        case .nonCompliant:
            return colors.error
        case .notAssessed:
            return colors.textTertiary
        }
    }
}

private struct RecommendationsCard: View {
    let recommendations: [ComplianceRecommendation]
    let industry: IndustryIndicator?
    let onDetect: () -> Void
    let isDetecting: Bool
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommended Frameworks")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        if let industry = industry {
                            Text("Detected Industry: \(industry.rawValue)")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        onDetect()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(colors.primary)
                    }
                    .disabled(isDetecting)
                }
                
                ForEach(recommendations.prefix(5)) { recommendation in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(recommendation.framework.displayName)
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textPrimary)
                                
                                if recommendation.priority == .required {
                                    Text("Required")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(colors.error.opacity(0.2))
                                        .foregroundColor(colors.error)
                                        .cornerRadius(4)
                                }
                            }
                            
                            Text(recommendation.reason)
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(Int(recommendation.confidence * 100))%")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.primary)
                            
                            Text("confidence")
                                .font(theme.typography.caption2)
                                .foregroundColor(colors.textTertiary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if recommendation.id != recommendations.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
            .padding()
        }
    }
}

private struct FrameworkCard: View {
    let record: ComplianceRecord
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationLink {
            ComplianceFrameworkDetailView(record: record)
        } label: {
            StandardCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.framework)
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text(record.status)
                            .font(theme.typography.subheadline)
                            .foregroundColor(statusColor(for: record.statusEnum ?? .notAssessed, colors: colors))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Risk Score")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        Text("\(Int(record.riskScore * 100))%")
                            .font(theme.typography.title2)
                            .foregroundColor(colors.textPrimary)
                    }
                }
                .padding()
            }
        }
        .buttonStyle(.plain)
    }
    
    private func statusColor(for status: ComplianceStatus, colors: UnifiedTheme.Colors) -> Color {
        switch status {
        case .compliant:
            return colors.success
        case .partiallyCompliant:
            return colors.warning
        case .nonCompliant:
            return colors.error
        case .notAssessed:
            return colors.textTertiary
        }
    }
}


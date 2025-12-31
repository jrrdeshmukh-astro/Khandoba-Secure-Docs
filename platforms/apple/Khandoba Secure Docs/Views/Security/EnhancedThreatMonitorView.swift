//
//  EnhancedThreatMonitorView.swift
//  Khandoba Secure Docs
//
//  ML-powered threat monitoring with geo-classification, access patterns, and tag analysis

import SwiftUI
import Charts
import MapKit

struct EnhancedThreatMonitorView: View {
    let vault: Vault
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @StateObject private var mlService = MLThreatAnalysisService()
    @EnvironmentObject var vaultService: VaultService
    @StateObject private var threatService = ThreatMonitoringService()
    @StateObject private var formalLogicService = FormalLogicThreatInferenceService()
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var documentService: DocumentService
    
    @State private var geoMetrics: GeoThreatMetrics?
    @State private var accessMetrics: AccessPatternMetrics?
    @State private var tagMetrics: TagThreatMetrics?
    @State private var overallRiskScore: Double = 0
    @State private var isAnalyzing = false
    @State private var threatInferenceResult: ThreatInferenceResult?
    @State private var showGranularDetails = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    // Overall Risk Score with Granular Display
                    if let result = threatInferenceResult {
                        GranularThreatScoreCard(
                            result: result,
                            showDetails: $showGranularDetails
                        )
                        .padding(.horizontal)
                    } else {
                        OverallRiskCard(
                            riskScore: overallRiskScore,
                            level: riskLevel(for: overallRiskScore)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Geo-Classification Metrics
                    if let geo = geoMetrics {
                        GeoThreatCard(metrics: geo)
                            .padding(.horizontal)
                    }
                    
                    // Access Pattern Metrics
                    if let access = accessMetrics {
                        AccessPatternCard(metrics: access)
                            .padding(.horizontal)
                    }
                    
                    // Tag-Based Metrics
                    if let tag = tagMetrics {
                        TagThreatCard(metrics: tag)
                            .padding(.horizontal)
                    }
                    
                    // Threat Timeline (Traditional ML)
                    ThreatTimelineCard(vault: vault)
                        .padding(.horizontal)
                    
                    // ML Insights
                    MLInsightsCard(
                        geoMetrics: geoMetrics,
                        accessMetrics: accessMetrics,
                        tagMetrics: tagMetrics
                    )
                    .padding(.horizontal)
                    
                    // Formal Logic Threat Inferences
                    if let result = threatInferenceResult {
                        FormalLogicThreatCard(result: result)
                            .padding(.horizontal)
                    }
                    
                    // Granular Score Breakdown
                    if let result = threatInferenceResult, showGranularDetails {
                        GranularScoreBreakdownCard(result: result)
                            .padding(.horizontal)
                    }
                    
                    // Recommendations
                    if let result = threatInferenceResult, !result.recommendations.isEmpty {
                        ThreatRecommendationsCard(recommendations: result.recommendations)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            
            if isAnalyzing {
                LoadingView("Analyzing threats...")
            }
        }
        .navigationTitle("Threat Monitor")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await analyzeThreats()
        }
        .refreshable {
            await analyzeThreats()
        }
    }
    
    private func analyzeThreats() async {
        isAnalyzing = true
        
        // Configure services
        mlService.configure(vaultService: vaultService)
        threatService.configure(vaultService: vaultService)
        
        // Configure formal logic service
        let logicEngine = FormalLogicEngine()
        formalLogicService.configure(
            modelContext: modelContext,
            formalLogicEngine: logicEngine,
            threatMonitoringService: threatService,
            mlThreatAnalysisService: mlService,
            vaultService: vaultService,
            documentService: documentService
        )
        
        // Run formal logic threat inference
        threatInferenceResult = await formalLogicService.analyzeVaultForThreats(vault: vault)
        
        // Update vault threat metrics
        if let result = threatInferenceResult {
            try? await formalLogicService.updateVaultThreatMetrics(vault: vault, result: result)
        }
        
        // Run ML analysis (for ML insights card)
        geoMetrics = await mlService.analyzeGeoClassification(for: vault)
        accessMetrics = await mlService.analyzeAccessPatterns(for: vault)
        tagMetrics = mlService.analyzeTagPatterns(for: vault)
        
        // Use formal logic composite score if available, otherwise calculate from ML
        if let result = threatInferenceResult {
            overallRiskScore = result.granularScores.compositeScore / 100.0 // Convert 0-100 to 0-1
        } else {
            // Calculate overall risk from ML metrics
            let geoRisk = geoMetrics?.riskScore ?? 0
            let accessRisk = accessMetrics?.riskScore ?? 0
            let tagRisk = tagMetrics?.riskScore ?? 0
            overallRiskScore = (geoRisk * 0.4 + accessRisk * 0.3 + tagRisk * 0.3)
        }
        
        // Run traditional threat analysis
        _ = await threatService.analyzeThreatLevel(for: vault)
        
        isAnalyzing = false
    }
    
    private func riskLevel(for score: Double) -> String {
        if score >= 0.75 {
            return "Critical"
        } else if score >= 0.5 {
            return "High"
        } else if score >= 0.25 {
            return "Medium"
        } else {
            return "Low"
        }
    }
    
    private func colorForRisk(_ level: String) -> Color {
        let colors = theme.colors(for: colorScheme)
        switch level {
        case "Critical": return colors.error
        case "High": return .orange
        case "Medium": return colors.warning
        default: return colors.success
        }
    }
}

// MARK: - Overall Risk Card

struct OverallRiskCard: View {
    let riskScore: Double
    let level: String
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .font(.title)
                        .foregroundColor(colorForLevel)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Overall Risk Level")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        Text(level)
                            .font(theme.typography.title)
                            .foregroundColor(colorForLevel)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    // Risk Score
                    VStack(spacing: 4) {
                        Text(String(format: "%.0f%%", riskScore * 100))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(colorForLevel)
                        
                        Text("Risk Score")
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                
                // Risk Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colors.surface.opacity(0.5))
                            .frame(height: 8)
                        
                        // Foreground
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForLevel)
                            .frame(width: geometry.size.width * riskScore, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var colorForLevel: Color {
        let colors = theme.colors(for: colorScheme)
        switch level {
        case "Critical": return colors.error
        case "High": return .orange
        case "Medium": return colors.warning
        default: return colors.success
        }
    }
}

// MARK: - Geo Threat Card

struct GeoThreatCard: View {
    let metrics: GeoThreatMetrics
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(colors.info)
                    
                    Text("Geographic Analysis")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    RiskBadge(score: metrics.riskScore)
                }
                
                Divider()
                
                // Metrics Grid
                VStack(spacing: UnifiedTheme.Spacing.sm) {
                    MetricRow(
                        icon: "mappin.circle.fill",
                        label: "Access Locations",
                        value: "\(metrics.accessLocations)",
                        iconColor: colors.primary
                    )
                    
                    MetricRow(
                        icon: "location.fill",
                        label: "Unique Locations",
                        value: "\(metrics.uniqueLocations)",
                        iconColor: colors.secondary
                    )
                    
                    MetricRow(
                        icon: "arrow.up.left.and.arrow.down.right",
                        label: "Location Spread",
                        value: String(format: "%.2f°", metrics.locationSpread),
                        iconColor: colors.warning
                    )
                    
                    if !metrics.suspiciousLocations.isEmpty {
                        MetricRow(
                            icon: "exclamationmark.triangle.fill",
                            label: "Suspicious Locations",
                            value: "\(metrics.suspiciousLocations.count)",
                            iconColor: colors.error
                        )
                    }
                }
                
                // Insights
                if metrics.riskScore > 0.5 {
                    InsightBox(
                        icon: "exclamationmark.circle.fill",
                        message: "High geographic diversity detected. This may indicate account sharing or unauthorized access.",
                        color: colors.warning
                    )
                } else if metrics.uniqueLocations == 1 {
                    InsightBox(
                        icon: "checkmark.circle.fill",
                        message: "All access from single location - normal usage pattern.",
                        color: colors.success
                    )
                }
            }
        }
    }
}

// MARK: - Access Pattern Card

struct AccessPatternCard: View {
    let metrics: AccessPatternMetrics
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(colors.secondary)
                    
                    Text("Access Pattern Analysis")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    RiskBadge(score: metrics.riskScore)
                }
                
                Divider()
                
                // Metrics
                VStack(spacing: UnifiedTheme.Spacing.sm) {
                    MetricRow(
                        icon: "hand.tap.fill",
                        label: "Total Accesses",
                        value: "\(metrics.totalAccesses)",
                        iconColor: colors.primary
                    )
                    
                    MetricRow(
                        icon: "calendar",
                        label: "Frequency",
                        value: String(format: "%.1f/day", metrics.frequency),
                        iconColor: colors.info
                    )
                    
                    if metrics.unusualTimeCount > 0 {
                        MetricRow(
                            icon: "moon.fill",
                            label: "Unusual Time Access",
                            value: "\(metrics.unusualTimeCount)",
                            iconColor: colors.warning
                        )
                    }
                    
                    if metrics.burstsDetected > 0 {
                        MetricRow(
                            icon: "bolt.fill",
                            label: "Burst Events",
                            value: "\(metrics.burstsDetected)",
                            iconColor: colors.error
                        )
                    }
                }
                
                // Access Type Distribution
                if !metrics.accessTypes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Access Type Distribution")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        ForEach(Array(metrics.accessTypes.keys.sorted()), id: \.self) { type in
                            if let count = metrics.accessTypes[type] {
                                HStack {
                                    Text(type.capitalized)
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text("\(count)")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                        }
                    }
                }
                
                // Insights
                if metrics.burstsDetected > 0 {
                    InsightBox(
                        icon: "exclamationmark.triangle.fill",
                        message: "Burst access detected - may indicate automated script or compromise.",
                        color: colors.error
                    )
                } else if metrics.frequency < 0.5 {
                    InsightBox(
                        icon: "checkmark.circle.fill",
                        message: "Low frequency access - normal usage pattern.",
                        color: colors.success
                    )
                }
            }
        }
    }
}

// MARK: - Tag Threat Card

struct TagThreatCard: View {
    let metrics: TagThreatMetrics
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(colors.primary)
                    
                    Text("Document Tag Analysis")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    RiskBadge(score: metrics.riskScore)
                }
                
                Divider()
                
                // Metrics
                VStack(spacing: UnifiedTheme.Spacing.sm) {
                    MetricRow(
                        icon: "number",
                        label: "Total Tags",
                        value: "\(metrics.totalTags)",
                        iconColor: colors.info
                    )
                    
                    MetricRow(
                        icon: "sparkles",
                        label: "Unique Tags",
                        value: "\(metrics.uniqueTags)",
                        iconColor: colors.secondary
                    )
                    
                    if metrics.exfiltrationRisk > 0.5 {
                        MetricRow(
                            icon: "arrow.up.doc.fill",
                            label: "Exfiltration Risk",
                            value: String(format: "%.0f%%", metrics.exfiltrationRisk * 100),
                            iconColor: colors.error
                        )
                    }
                }
                
                // Top Tags
                if !metrics.topTags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top Tags")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        ForEach(Array(metrics.topTags.prefix(5)), id: \.0) { tag, count in
                            HStack {
                                Text(tag)
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textPrimary)
                                
                                Spacer()
                                
                                Text("\(count)")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                    }
                }
                
                // Suspicious Tags
                if !metrics.suspiciousTags.isEmpty {
                    InsightBox(
                        icon: "exclamationmark.shield.fill",
                        message: "Suspicious tags detected: \(metrics.suspiciousTags.joined(separator: ", "))",
                        color: colors.error
                    )
                } else {
                    InsightBox(
                        icon: "checkmark.seal.fill",
                        message: "No suspicious patterns in document tags.",
                        color: colors.success
                    )
                }
            }
        }
    }
}

// MARK: - Threat Timeline Card

struct ThreatTimelineCard: View {
    let vault: Vault
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vaultService: VaultService
    @StateObject private var threatService = ThreatMonitoringService()
    @State private var metrics: [ThreatMetric] = []
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(colors.info)
                    
                    Text("Threat Timeline")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                }
                
                if metrics.isEmpty {
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(colors.textTertiary)
                        
                        Text("No timeline data available")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                        
                        Text("Threat timeline will appear as vault access patterns are recorded")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, UnifiedTheme.Spacing.xl)
                } else if metrics.count == 1 {
                    // Single data point - show as a bar or point
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        HStack {
                            Text("Threat Score")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f", metrics.first?.threatScore ?? 0))
                                .font(theme.typography.title2)
                                .foregroundColor(colors.primary)
                                .fontWeight(.bold)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(colors.surface.opacity(0.5))
                                    .frame(height: 20)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(colors.primary)
                                    .frame(width: geometry.size.width * min((metrics.first?.threatScore ?? 0) / 100.0, 1.0), height: 20)
                            }
                        }
                        .frame(height: 20)
                        
                        Text("Single data point - more data will appear over time")
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textTertiary)
                    }
                    .padding(.vertical)
                } else {
                    Chart {
                        ForEach(metrics) { metric in
                            LineMark(
                                x: .value("Date", metric.date),
                                y: .value("Threat Score", metric.threatScore)
                            )
                            .foregroundStyle(colors.error)
                            .interpolationMethod(.catmullRom)
                            
                            AreaMark(
                                x: .value("Date", metric.date),
                                y: .value("Threat Score", metric.threatScore)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [colors.error.opacity(0.3), colors.error.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .frame(height: 150)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel()
                                .font(.caption2)
                                .foregroundStyle(colors.textSecondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisValueLabel()
                                .font(.caption2)
                                .foregroundStyle(colors.textSecondary)
                        }
                    }
                }
            }
        }
        .task {
            // Load metrics on appear
            metrics = await threatService.generateThreatMetrics(for: vault)
        }
    }
}

// MARK: - ML Insights Card

struct MLInsightsCard: View {
    let geoMetrics: GeoThreatMetrics?
    let accessMetrics: AccessPatternMetrics?
    let tagMetrics: TagThreatMetrics?
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    private var insights: [(icon: String, text: String, confidence: Double)] {
        var result: [(icon: String, text: String, confidence: Double)] = []
        
        // Geo insights
        if let geo = geoMetrics {
            if geo.riskScore > 0.5 {
                result.append((
                    icon: "map",
                    text: "ML detected unusual geographic patterns suggesting potential account sharing",
                    confidence: geo.riskScore
                ))
            } else if geo.uniqueLocations > 1 {
                result.append((
                    icon: "map",
                    text: "Access from \(geo.uniqueLocations) location(s) - normal geographic distribution",
                    confidence: 1.0 - geo.riskScore
                ))
            } else if geo.accessLocations > 0 {
                result.append((
                    icon: "map",
                    text: "All access from single location - secure usage pattern",
                    confidence: 0.95
                ))
            }
        }
        
        // Access pattern insights
        if let access = accessMetrics {
            if access.burstsDetected > 0 {
                result.append((
                    icon: "bolt",
                    text: "Access burst pattern detected - may indicate automated activity",
                    confidence: access.riskScore
                ))
            } else if access.totalAccesses > 0 {
                result.append((
                    icon: "chart.line.uptrend.xyaxis",
                    text: "Access frequency: \(String(format: "%.1f", access.frequency)) per day - normal pattern",
                    confidence: 1.0 - access.riskScore
                ))
            }
        }
        
        // Tag insights
        if let tag = tagMetrics {
            if !tag.suspiciousTags.isEmpty {
                result.append((
                    icon: "tag",
                    text: "Suspicious content patterns identified in document metadata",
                    confidence: tag.riskScore
                ))
            } else if tag.totalTags > 0 {
                result.append((
                    icon: "tag",
                    text: "\(tag.totalTags) tags analyzed across documents - no suspicious patterns detected",
                    confidence: 1.0 - tag.riskScore
                ))
            }
        }
        
        // Default: All clear or summary if no insights
        if result.isEmpty {
            let geoRisk = geoMetrics?.riskScore ?? 0
            let accessRisk = accessMetrics?.riskScore ?? 0
            let tagRisk = tagMetrics?.riskScore ?? 0
            let avgRisk = (geoRisk + accessRisk + tagRisk) / 3.0
            
            if avgRisk < 0.3 {
                result.append((
                    icon: "checkmark.seal.fill",
                    text: "ML analysis shows normal usage patterns across all metrics. No threats detected.",
                    confidence: 0.9
                ))
            } else {
                result.append((
                    icon: "info.circle.fill",
                    text: "ML analysis is monitoring vault activity. Continue using the vault normally.",
                    confidence: 0.8
                ))
            }
        }
        
        return result
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(colors.primary)
                    
                    Text("ML-Powered Insights")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    // Display insights
                    ForEach(Array(insights.enumerated()), id: \.offset) { _, insight in
                        InsightRow(
                            icon: insight.icon,
                            text: insight.text,
                            confidence: insight.confidence
                        )
                    }
                }
                
                // Disclaimer
                Text("⚡ Zero-knowledge ML: Analysis uses only metadata, never accesses encrypted content")
                    .font(theme.typography.caption2)
                    .foregroundColor(colors.textTertiary)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Helper Views

struct RiskBadge: View {
    let score: Double
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let level = score >= 0.75 ? "Critical" : score >= 0.5 ? "High" : score >= 0.25 ? "Medium" : "Low"
        let color: Color = score >= 0.75 ? theme.colors(for: colorScheme).error :
                          score >= 0.5 ? .orange :
                          score >= 0.25 ? theme.colors(for: colorScheme).warning :
                          theme.colors(for: colorScheme).success
        
        Text(level)
            .font(theme.typography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(4)
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let iconColor: Color
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(label)
                .font(theme.typography.body)
                .foregroundColor(theme.colors(for: colorScheme).textPrimary)
            
            Spacer()
            
            Text(value)
                .font(theme.typography.subheadline)
                .foregroundColor(theme.colors(for: colorScheme).textSecondary)
                .fontWeight(.semibold)
        }
    }
}

struct InsightBox: View {
    let icon: String
    let message: String
    let color: Color
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(message)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors(for: colorScheme).textPrimary)
            
            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    let confidence: Double
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.colors(for: colorScheme).primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors(for: colorScheme).textPrimary)
                
                HStack(spacing: 4) {
                    Text("Confidence:")
                        .font(theme.typography.caption2)
                        .foregroundColor(theme.colors(for: colorScheme).textTertiary)
                    
                    Text(String(format: "%.0f%%", confidence * 100))
                        .font(theme.typography.caption2)
                        .foregroundColor(theme.colors(for: colorScheme).primary)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Granular Threat Score Components

struct GranularThreatScoreCard: View {
    let result: ThreatInferenceResult
    @Binding var showDetails: Bool
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let score = result.granularScores.compositeScore
        let level = result.threatLevel
        
        StandardCard {
            VStack(spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Threat Level")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        Text(level.rawValue)
                            .font(theme.typography.largeTitle)
                            .foregroundColor(colorForLevel(level))
                            .fontWeight(.bold)
                        
                        // Score with 2 decimal precision
                        Text(String(format: "Score: %.2f/100", score))
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Circular progress indicator
                    ZStack {
                        Circle()
                            .stroke(colors.textTertiary.opacity(0.3), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: score / 100.0)
                            .stroke(colorForLevel(level), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text(String(format: "%.2f", score))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(colorForLevel(level))
                            
                            Text("Score")
                                .font(theme.typography.caption2)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                }
                
                // Score trend indicator
                if let delta = result.granularScores.scoreDelta {
                    HStack(spacing: 4) {
                        Image(systemName: delta > 0 ? "arrow.up.right" : delta < 0 ? "arrow.down.right" : "minus")
                            .foregroundColor(delta > 0 ? colors.error : delta < 0 ? colors.success : colors.textSecondary)
                            .font(.caption)
                        
                        Text(String(format: "%.2f", abs(delta)))
                            .font(theme.typography.caption)
                            .foregroundColor(delta > 0 ? colors.error : delta < 0 ? colors.success : colors.textSecondary)
                        
                        Text("from last assessment")
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textTertiary)
                    }
                }
                
                // Details toggle
                Button {
                    showDetails.toggle()
                } label: {
                    HStack {
                        Text(showDetails ? "Hide Details" : "Show Details")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.primary)
                        
                        Spacer()
                        
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .foregroundColor(colors.primary)
                            .font(.caption)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func colorForLevel(_ level: GranularThreatLevel) -> Color {
        let colors = theme.colors(for: colorScheme)
        switch level.numericValue {
        case 9...10: return colors.error // Critical/Extreme
        case 7...8: return .orange       // High/High-Critical
        case 5...6: return colors.warning // Medium/Medium-High
        case 3...4: return .yellow       // Low/Low-Medium
        default: return colors.success    // Minimal/Very Low
        }
    }
}

struct GranularScoreBreakdownCard: View {
    let result: ThreatInferenceResult
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                Text("Granular Score Breakdown")
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                Divider()
                
                // Logic Type Scores
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    Text("Logic Type Scores")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .fontWeight(.semibold)
                    
                    LogicScoreRow(
                        label: "Deductive",
                        score: result.logicBreakdown.deductiveScore,
                        icon: "checkmark.seal.fill",
                        colors: colors,
                        theme: theme
                    )
                    
                    LogicScoreRow(
                        label: "Inductive",
                        score: result.logicBreakdown.inductiveScore,
                        icon: "chart.bar.fill",
                        colors: colors,
                        theme: theme
                    )
                    
                    LogicScoreRow(
                        label: "Abductive",
                        score: result.logicBreakdown.abductiveScore,
                        icon: "lightbulb.fill",
                        colors: colors,
                        theme: theme
                    )
                    
                    LogicScoreRow(
                        label: "Statistical",
                        score: result.logicBreakdown.statisticalScore,
                        icon: "chart.line.uptrend.xyaxis",
                        colors: colors,
                        theme: theme
                    )
                    
                    LogicScoreRow(
                        label: "Analogical",
                        score: result.logicBreakdown.analogicalScore,
                        icon: "arrow.triangle.2.circlepath",
                        colors: colors,
                        theme: theme
                    )
                    
                    LogicScoreRow(
                        label: "Temporal",
                        score: result.logicBreakdown.temporalScore,
                        icon: "clock.fill",
                        colors: colors,
                        theme: theme
                    )
                    
                    LogicScoreRow(
                        label: "Modal",
                        score: result.logicBreakdown.modalScore,
                        icon: "eye.fill",
                        colors: colors,
                        theme: theme
                    )
                }
                
                Divider()
                
                // Category Scores
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    Text("Category Scores")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .fontWeight(.semibold)
                    
                    CategoryScoreRow(
                        label: "Access Pattern",
                        score: result.categoryBreakdown.accessPatternScore,
                        colors: colors,
                        theme: theme
                    )
                    
                    CategoryScoreRow(
                        label: "Geographic",
                        score: result.categoryBreakdown.geographicScore,
                        colors: colors,
                        theme: theme
                    )
                    
                    CategoryScoreRow(
                        label: "Document Content",
                        score: result.categoryBreakdown.documentContentScore,
                        colors: colors,
                        theme: theme
                    )
                    
                    CategoryScoreRow(
                        label: "Behavioral",
                        score: result.categoryBreakdown.behavioralScore,
                        colors: colors,
                        theme: theme
                    )
                    
                    CategoryScoreRow(
                        label: "External Threat",
                        score: result.categoryBreakdown.externalThreatScore,
                        colors: colors,
                        theme: theme
                    )
                    
                    CategoryScoreRow(
                        label: "Compliance",
                        score: result.categoryBreakdown.complianceScore,
                        colors: colors,
                        theme: theme
                    )
                    
                    CategoryScoreRow(
                        label: "Data Exfiltration",
                        score: result.categoryBreakdown.dataExfiltrationScore,
                        colors: colors,
                        theme: theme
                    )
                }
            }
        }
    }
}

struct LogicScoreRow: View {
    let label: String
    let score: Double
    let icon: String
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(colors.primary)
                .frame(width: 20)
            
            Text(label)
                .font(theme.typography.body)
                .foregroundColor(colors.textPrimary)
            
            Spacer()
            
            Text(String(format: "%.2f", score))
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textSecondary)
                .fontWeight(.semibold)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colors.surface.opacity(0.5))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForScore(score))
                        .frame(width: geometry.size.width * (score / 100.0), height: 4)
                }
            }
            .frame(width: 60, height: 4)
        }
    }
    
    private func colorForScore(_ score: Double) -> Color {
        if score >= 75 {
            return colors.error
        } else if score >= 50 {
            return .orange
        } else if score >= 25 {
            return colors.warning
        } else {
            return colors.success
        }
    }
}

struct CategoryScoreRow: View {
    let label: String
    let score: Double
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack {
            Text(label)
                .font(theme.typography.body)
                .foregroundColor(colors.textPrimary)
            
            Spacer()
            
            Text(String(format: "%.2f", score))
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textSecondary)
                .fontWeight(.semibold)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colors.surface.opacity(0.5))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForScore(score))
                        .frame(width: geometry.size.width * (score / 100.0), height: 4)
                }
            }
            .frame(width: 80, height: 4)
        }
    }
    
    private func colorForScore(_ score: Double) -> Color {
        if score >= 75 {
            return colors.error
        } else if score >= 50 {
            return .orange
        } else if score >= 25 {
            return colors.warning
        } else {
            return colors.success
        }
    }
}

struct FormalLogicThreatCard: View {
    let result: ThreatInferenceResult
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(colors.primary)
                    
                    Text("Formal Logic Threat Inferences")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(result.threatInferences.count)")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colors.surface)
                        .cornerRadius(8)
                }
                
                Divider()
                
                // Top contributing inferences
                if !result.inferenceContributions.isEmpty {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Top Contributing Threats")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                            .fontWeight(.semibold)
                        
                        ForEach(Array(result.inferenceContributions.prefix(5)), id: \.inferenceID) { contribution in
                            InferenceContributionRow(contribution: contribution, colors: colors, theme: theme)
                        }
                    }
                } else {
                    Text("No threat inferences generated")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, UnifiedTheme.Spacing.md)
                }
            }
        }
    }
}

struct InferenceContributionRow: View {
    let contribution: InferenceContribution
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: iconForLogicType(contribution.logicType))
                    .foregroundColor(colorForImpact(contribution.impact))
                    .frame(width: 20)
                
                Text(contribution.inference.conclusion)
                    .font(theme.typography.body)
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(2)
                
                Spacer()
                
                Text(String(format: "%.1f", contribution.contributionScore))
                    .font(theme.typography.caption)
                    .foregroundColor(colorForImpact(contribution.impact))
                    .fontWeight(.bold)
            }
            
            HStack(spacing: 8) {
                Text(contribution.category.description)
                    .font(theme.typography.caption2)
                    .foregroundColor(colors.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(colors.surface)
                    .cornerRadius(4)
                
                Text(String(format: "%.0f%% confidence", contribution.confidence * 100))
                    .font(theme.typography.caption2)
                    .foregroundColor(colors.textTertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForLogicType(_ type: LogicType) -> String {
        switch type {
        case .deductive: return "checkmark.seal.fill"
        case .inductive: return "chart.bar.fill"
        case .abductive: return "lightbulb.fill"
        case .statistical: return "chart.line.uptrend.xyaxis"
        case .analogical: return "arrow.triangle.2.circlepath"
        case .temporal: return "clock.fill"
        case .modal: return "eye.fill"
        }
    }
    
    private func colorForImpact(_ impact: ThreatImpact) -> Color {
        switch impact {
        case .critical: return colors.error
        case .high: return .orange
        case .medium: return colors.warning
        case .low: return colors.success
        }
    }
}

struct ThreatRecommendationsCard: View {
    let recommendations: [ThreatRecommendation]
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "list.bullet.clipboard.fill")
                        .foregroundColor(colors.primary)
                    
                    Text("Recommended Actions")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                }
                
                Divider()
                
                ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                    RecommendationRow(
                        recommendation: recommendation,
                        index: index + 1,
                        colors: colors,
                        theme: theme
                    )
                }
            }
        }
    }
}

struct RecommendationRow: View {
    let recommendation: ThreatRecommendation
    let index: Int
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
            HStack(alignment: .top, spacing: UnifiedTheme.Spacing.sm) {
                // Priority number
                ZStack {
                    Circle()
                        .fill(colorForUrgency(recommendation.urgency))
                        .frame(width: 24, height: 24)
                    
                    Text("\(index)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.action)
                        .font(theme.typography.body)
                        .foregroundColor(colors.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text(recommendation.rationale)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                    
                    HStack(spacing: 8) {
                        // Urgency badge
                        HStack(spacing: 4) {
                            Image(systemName: urgencyIcon(recommendation.urgency))
                                .font(.caption2)
                            Text(urgencyText(recommendation.urgency))
                                .font(theme.typography.caption2)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(colorForUrgency(recommendation.urgency))
                        .cornerRadius(4)
                        
                        // Expected impact
                        Text(String(format: "Expected impact: -%.1f", recommendation.expectedImpact))
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textTertiary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForUrgency(_ urgency: UrgencyLevel) -> Color {
        switch urgency {
        case .immediate: return colors.error
        case .urgent: return .orange
        case .important: return colors.warning
        case .routine: return colors.success
        }
    }
    
    private func urgencyIcon(_ urgency: UrgencyLevel) -> String {
        switch urgency {
        case .immediate: return "bolt.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        case .important: return "info.circle.fill"
        case .routine: return "clock.fill"
        }
    }
    
    private func urgencyText(_ urgency: UrgencyLevel) -> String {
        switch urgency {
        case .immediate: return "Immediate"
        case .urgent: return "Urgent"
        case .important: return "Important"
        case .routine: return "Routine"
        }
    }
}

// MARK: - Extensions

extension ThreatCategory {
    var description: String {
        switch self {
        case .accessPattern: return "Access Pattern"
        case .geographic: return "Geographic"
        case .documentContent: return "Document Content"
        case .behavioral: return "Behavioral"
        case .externalThreat: return "External Threat"
        case .compliance: return "Compliance"
        case .dataExfiltration: return "Data Exfiltration"
        }
    }
}


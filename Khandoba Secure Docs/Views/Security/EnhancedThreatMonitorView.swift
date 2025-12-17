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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var mlService = MLThreatAnalysisService()
    @EnvironmentObject var vaultService: VaultService
    @EnvironmentObject var supabaseService: SupabaseService
    @StateObject private var threatService = ThreatMonitoringService()
    
    @State private var geoMetrics: GeoThreatMetrics?
    @State private var accessMetrics: AccessPatternMetrics?
    @State private var tagMetrics: TagThreatMetrics?
    @State private var overallRiskScore: Double = 0
    @State private var isAnalyzing = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    // Overall Risk Score
                    OverallRiskCard(
                        riskScore: overallRiskScore,
                        level: riskLevel(for: overallRiskScore)
                    )
                    .padding(.horizontal)
                    
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
                }
                .padding(.vertical)
            }
            
            if isAnalyzing {
                LoadingView("Analyzing threats...")
            }
        }
        .navigationTitle("Threat Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await analyzeThreats()
        }
        .refreshable {
            await analyzeThreats()
        }
    }
    
    private func analyzeThreats() async {
        isAnalyzing = true
        
        // Configure ML service
        mlService.configure(vaultService: vaultService)
        
        // Run ML analysis
        geoMetrics = await mlService.analyzeGeoClassification(for: vault)
        accessMetrics = await mlService.analyzeAccessPatterns(for: vault)
        tagMetrics = await mlService.analyzeTagPatterns(for: vault)
        
        // Calculate overall risk
        let geoRisk = geoMetrics?.riskScore ?? 0
        let accessRisk = accessMetrics?.riskScore ?? 0
        let tagRisk = tagMetrics?.riskScore ?? 0
        
        overallRiskScore = (geoRisk * 0.4 + accessRisk * 0.3 + tagRisk * 0.3)
        
        // Run traditional threat analysis
        _ = await threatService.analyzeThreatLevel(for: vault)
        // Note: generateThreatMetrics is now async - update call site if needed
        
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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vaultService: VaultService
    @EnvironmentObject var supabaseService: SupabaseService
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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
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


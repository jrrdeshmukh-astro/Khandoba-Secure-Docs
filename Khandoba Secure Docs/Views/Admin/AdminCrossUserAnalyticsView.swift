//
//  AdminCrossUserAnalyticsView.swift
//  Khandoba Secure Docs
//
//  Cross-user ML analytics for admin (zero-knowledge)

import SwiftUI
import SwiftData
import Charts

struct AdminCrossUserAnalyticsView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var mlService = MLThreatAnalysisService()
    @State private var crossUserMetrics: CrossUserThreatMetrics?
    @State private var allVaults: [Vault] = []
    @State private var isAnalyzing = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    // Zero-Knowledge Banner
                    StandardCard {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.title2)
                                .foregroundColor(colors.success)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Zero-Knowledge Analytics")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                Text("Analysis uses only metadata. Encrypted content is never accessed.")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if let metrics = crossUserMetrics {
                        // Summary Stats
                        HStack(spacing: UnifiedTheme.Spacing.md) {
                            AdminStatCard(
                                icon: "lock.square.stack.fill",
                                value: "\(metrics.totalVaultsAnalyzed)",
                                label: "Vaults",
                                color: colors.primary
                            )
                            
                            AdminStatCard(
                                icon: "hand.tap.fill",
                                value: "\(metrics.totalAccessEvents)",
                                label: "Access Events",
                                color: colors.secondary
                            )
                        }
                        .padding(.horizontal)
                        
                        // Global Patterns
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                Text("Global Patterns")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                Divider()
                                
                                PatternRow(
                                    icon: "map.fill",
                                    title: "Geographic",
                                    description: metrics.globalGeoPatterns
                                )
                                
                                PatternRow(
                                    icon: "tag.fill",
                                    title: "Document Types",
                                    description: metrics.globalTagPatterns
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Threat Predictions
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(colors.primary)
                                    
                                    Text("ML Predictions")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.0f%% confidence", metrics.confidenceScore * 100))
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                                
                                Divider()
                                
                                ForEach(metrics.threatPredictions, id: \.self) { prediction in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: iconForPrediction(prediction))
                                            .foregroundColor(colorForPrediction(prediction))
                                        
                                        Text(prediction)
                                            .font(theme.typography.body)
                                            .foregroundColor(colors.textPrimary)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // ML Methodology
                        StandardCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Analysis Methodology")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    MethodRow(icon: "location.fill", text: "Geographic clustering & anomaly detection")
                                    MethodRow(icon: "clock.fill", text: "Temporal pattern analysis")
                                    MethodRow(icon: "tag.fill", text: "Document metadata frequency analysis")
                                    MethodRow(icon: "chart.line.uptrend.xyaxis", text: "Access pattern prediction")
                                    MethodRow(icon: "shield.fill", text: "Zero-knowledge threat scoring")
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            
            if isAnalyzing {
                LoadingView("Analyzing cross-user patterns...")
            }
        }
        .navigationTitle("Cross-User Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadAnalytics()
        }
        .refreshable {
            await loadAnalytics()
        }
    }
    
    private func loadAnalytics() async {
        isAnalyzing = true
        
        // Fetch all vaults (metadata only)
        let descriptor = FetchDescriptor<Vault>()
        do {
            allVaults = try modelContext.fetch(descriptor)
            crossUserMetrics = mlService.analyzeAcrossUsers(vaults: allVaults)
        } catch {
            print("Error fetching vaults: \(error)")
        }
        
        isAnalyzing = false
    }
    
    private func iconForPrediction(_ prediction: String) -> String {
        if prediction.contains("Normal") || prediction.contains("No anomalous") {
            return "checkmark.seal.fill"
        } else if prediction.contains("sharing") {
            return "person.2.fill"
        } else if prediction.contains("Read-heavy") {
            return "eye.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    private func colorForPrediction(_ prediction: String) -> Color {
        let colors = theme.colors(for: colorScheme)
        if prediction.contains("Normal") || prediction.contains("No anomalous") || prediction.contains("Read-heavy") {
            return colors.success
        } else if prediction.contains("Potential") {
            return colors.warning
        } else {
            return colors.error
        }
    }
}

struct AdminStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        StandardCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(theme.colors(for: colorScheme).textPrimary)
                
                Text(label)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors(for: colorScheme).textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

struct PatternRow: View {
    let icon: String
    let title: String
    let description: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.colors(for: colorScheme).primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.typography.subheadline)
                    .foregroundColor(theme.colors(for: colorScheme).textPrimary)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors(for: colorScheme).textSecondary)
            }
        }
    }
}

struct MethodRow: View {
    let icon: String
    let text: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.colors(for: colorScheme).info)
                .frame(width: 20)
            
            Text(text)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors(for: colorScheme).textPrimary)
        }
    }
}


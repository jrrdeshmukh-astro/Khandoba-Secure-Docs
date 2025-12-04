//
//  IntelReportView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import Charts

struct IntelReportView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vaultService: VaultService
    
    @StateObject private var intelService = IntelReportService()
    @State private var isLoading = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if isLoading {
                    LoadingView("Generating intel report...")
                } else if let report = intelService.currentReport {
                    ScrollView {
                        VStack(spacing: UnifiedTheme.Spacing.lg) {
                            // Header
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                    HStack {
                                        Image(systemName: "chart.bar.doc.horizontal.fill")
                                            .font(.title)
                                            .foregroundColor(colors.primary)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Intelligence Report")
                                                .font(theme.typography.headline)
                                                .foregroundColor(colors.textPrimary)
                                            
                                            Text("Generated \(report.generatedAt, style: .relative)")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Statistics Comparison
                            HStack(spacing: UnifiedTheme.Spacing.md) {
                                // Source Stats
                                StandardCard {
                                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                                        Image(systemName: "camera.fill")
                                            .font(.title)
                                            .foregroundColor(colors.info)
                                        
                                        Text("\(report.sourceAnalysis.count)")
                                            .font(theme.typography.largeTitle)
                                            .foregroundColor(colors.textPrimary)
                                            .fontWeight(.bold)
                                        
                                        Text("Source Documents")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.textSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                
                                // Sink Stats
                                StandardCard {
                                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                                        Image(systemName: "square.and.arrow.down.fill")
                                            .font(.title)
                                            .foregroundColor(colors.success)
                                        
                                        Text("\(report.sinkAnalysis.count)")
                                            .font(theme.typography.largeTitle)
                                            .foregroundColor(colors.textPrimary)
                                            .fontWeight(.bold)
                                        
                                        Text("Sink Documents")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.textSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Narrative Story
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                    HStack {
                                        Image(systemName: "text.quote")
                                            .foregroundColor(colors.primary)
                                        Text("Intelligence Narrative")
                                            .font(theme.typography.headline)
                                            .foregroundColor(colors.textPrimary)
                                    }
                                    
                                    Text(report.narrative)
                                        .font(theme.typography.body)
                                        .foregroundColor(colors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Top Tags Comparison
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                Text("Tag Analysis")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                    .padding(.horizontal)
                                
                                HStack(alignment: .top, spacing: UnifiedTheme.Spacing.md) {
                                    // Source Tags
                                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                        Text("Source Tags")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.info)
                                        
                                        ForEach(report.sourceAnalysis.topTags.prefix(5), id: \.self) { tag in
                                            Text("• \(tag)")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(colors.surface)
                                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                                    
                                    // Sink Tags
                                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                        Text("Sink Tags")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.success)
                                        
                                        ForEach(report.sinkAnalysis.topTags.prefix(5), id: \.self) { tag in
                                            Text("• \(tag)")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(colors.surface)
                                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                } else {
                    EmptyStateView(
                        icon: "chart.bar.doc.horizontal",
                        title: "No Intel Report",
                        message: "Generate a report to analyze your documents",
                        actionTitle: "Generate Report"
                    ) {
                        // Wrap async work in a Task to satisfy synchronous action closure
                        Task {
                            await generateReport()
                        }
                    }
                }
            }
            .navigationTitle("Intel Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await generateReport()
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(colors.primary)
                    }
                }
            }
        }
        .task {
            await generateReport()
        }
    }
    
    private func generateReport() async {
        isLoading = true
        _ = await intelService.generateIntelReport(for: vaultService.vaults)
        isLoading = false
    }
}

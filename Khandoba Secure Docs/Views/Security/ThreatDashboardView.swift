//
//  ThreatDashboardView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import Charts
import Combine

struct ThreatDashboardView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var threatService = ThreatMonitoringService()
    
    @State private var threatMetrics: [ThreatMetric] = []
    @State private var threats: [ThreatEvent] = []
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    // Threat Level Card
                    StandardCard {
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Threat Level")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                    
                                    Text(threatService.threatLevel.rawValue)
                                        .font(theme.typography.largeTitle)
                                        .foregroundColor(threatService.threatLevel.color)
                                        .fontWeight(.bold)
                                }
                                
                                Spacer()
                                
                                ZStack {
                                    Circle()
                                        .stroke(colors.textTertiary.opacity(0.3), lineWidth: 8)
                                        .frame(width: 80, height: 80)
                                    
                                    Circle()
                                        .trim(from: 0, to: threatService.anomalyScore / 100)
                                        .stroke(threatService.threatLevel.color, lineWidth: 8)
                                        .frame(width: 80, height: 80)
                                        .rotationEffect(.degrees(-90))
                                    
                                    Text("\(Int(threatService.anomalyScore))")
                                        .font(theme.typography.title2)
                                        .foregroundColor(colors.textPrimary)
                                        .fontWeight(.bold)
                                }
                            }
                            
                            Text("Anomaly Score: \(Int(threatService.anomalyScore))/100")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Threat Timeline Chart
                    if !threatMetrics.isEmpty {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Threat Timeline")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                                .padding(.horizontal)
                            
                            StandardCard {
                                Chart(threatMetrics) { metric in
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
                                    .foregroundStyle(colors.error.opacity(0.3))
                                    .interpolationMethod(.catmullRom)
                                }
                                .frame(height: 200)
                                .chartXAxis {
                                    AxisMarks(values: .automatic) { _ in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel(format: .dateTime.month().day())
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks(values: .automatic) { _ in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Threats
                    if !threats.isEmpty {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Recent Threats")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                                .padding(.horizontal)
                            
                            ForEach(threats) { threat in
                                ThreatEventRow(threat: threat)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Threat Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await analyzeThreat()
        }
    }
    
    private func analyzeThreat() async {
        _ = await threatService.analyzeThreatLevel(for: vault)
        threatMetrics = threatService.generateThreatMetrics(for: vault)
        threats = threatService.detectThreats(for: vault)
    }
}

struct ThreatEventRow: View {
    let threat: ThreatEvent
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(threat.severity.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(threat.severity.rawValue)
                            .font(theme.typography.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(threat.severity.color)
                            .cornerRadius(UnifiedTheme.CornerRadius.sm)
                        
                        Text(threat.timestamp, style: .relative)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textTertiary)
                    }
                    
                    Text(threat.description)
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                }
                
                Spacer()
            }
        }
    }
}


//
//  ComplianceFrameworkDetailView.swift
//  Khandoba Secure Docs
//
//  Compliance framework detail view
//

import SwiftUI

struct ComplianceFrameworkDetailView: View {
    let record: ComplianceRecord
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var complianceService = ComplianceEngineService.shared
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ScrollView {
            VStack(spacing: UnifiedTheme.Spacing.lg) {
                // Status Card
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text("Status")
                            .font(theme.typography.headline)
                        Text(record.status)
                            .font(theme.typography.title2)
                            .foregroundColor(statusColor)
                        
                        Text("Risk Score: \(Int(record.riskScore * 100))%")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                    .padding()
                }
                
                // Controls Section
                if let controls = record.controls, !controls.isEmpty {
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Controls")
                                .font(theme.typography.headline)
                            
                            ForEach(controls, id: \.id) { control in
                                ControlRow(control: control)
                            }
                        }
                        .padding()
                    }
                }
                
                // Audit Findings
                if let findings = record.auditFindings, !findings.isEmpty {
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Audit Findings")
                                .font(theme.typography.headline)
                            
                            ForEach(findings, id: \.id) { finding in
                                FindingRow(finding: finding)
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding()
        }
        .navigationTitle(record.framework)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var statusColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch record.statusEnum {
        case .compliant:
            return colors.success
        case .partiallyCompliant:
            return colors.warning
        case .nonCompliant:
            return colors.error
        case .notAssessed:
            return colors.textTertiary
        case .none:
            return colors.textTertiary
        }
    }
}

private struct ControlRow: View {
    let control: ComplianceControl
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(control.controlId)
                    .font(theme.typography.subheadline)
                    .fontWeight(.semibold)
                Text(control.name)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
            }
            
            Spacer()
            
            Text(control.implementationStatus)
                .font(theme.typography.caption)
                .foregroundColor(implementationColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(implementationColor.opacity(0.2))
                .cornerRadius(UnifiedTheme.CornerRadius.sm)
        }
        .padding(.vertical, 4)
    }
    
    private var implementationColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch control.implementationStatus {
        case "Implemented":
            return colors.success
        case "In Progress":
            return colors.warning
        default:
            return colors.error
        }
    }
}

private struct FindingRow: View {
    let finding: AuditFinding
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(finding.title)
                    .font(theme.typography.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(finding.severity)
                    .font(theme.typography.caption)
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(severityColor.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(finding.findingDescription)
                .font(theme.typography.caption)
                .foregroundColor(colors.textSecondary)
        }
        .padding(.vertical, 4)
    }
    
    private var severityColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch finding.severity {
        case "Critical", "High":
            return colors.error
        case "Medium":
            return colors.warning
        default:
            return colors.info
        }
    }
}


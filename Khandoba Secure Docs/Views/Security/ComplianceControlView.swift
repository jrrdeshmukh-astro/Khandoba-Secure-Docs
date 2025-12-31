//
//  ComplianceControlView.swift
//  Khandoba Secure Docs
//
//  Compliance control detail view
//

import SwiftUI

struct ComplianceControlView: View {
    let control: ComplianceControl
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ScrollView {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text(control.controlId)
                            .font(theme.typography.title2)
                            .foregroundColor(colors.textPrimary)
                        
                        Text(control.name)
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        if let description = control.controlDescription {
                            Text(description)
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding()
                }
                
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text("Implementation Status")
                            .font(theme.typography.headline)
                        
                        Text(control.implementationStatus)
                            .font(theme.typography.title2)
                            .foregroundColor(implementationColor)
                        
                        if let lastVerified = control.lastVerified {
                            Text("Last Verified: \(DateFormatter.localizedString(from: lastVerified, dateStyle: .medium, timeStyle: .short))")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding()
                }
                
                if let notes = control.notes, !notes.isEmpty {
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Notes")
                                .font(theme.typography.headline)
                            Text(notes)
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding()
                    }
                }
            }
            .padding()
        }
        .navigationTitle(control.controlId)
        .navigationBarTitleDisplayMode(.inline)
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


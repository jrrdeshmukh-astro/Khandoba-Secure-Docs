//
//  SecurityActionRow.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct SecurityActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack(spacing: UnifiedTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                
                Text(subtitle)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(colors.textTertiary)
                .font(.caption)
        }
        .padding(.vertical, UnifiedTheme.Spacing.xs)
    }
}


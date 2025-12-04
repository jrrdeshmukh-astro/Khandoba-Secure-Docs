//
//  StandardCard.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct StandardCard<Content: View>: View {
    let content: Content
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let shadow = UnifiedTheme.Shadow.sm(for: colorScheme)
        
        content
            .padding(UnifiedTheme.Spacing.md)
            .background(colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Text(value)
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
            }
        }
    }
}


//
//  LoadingView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct LoadingView: View {
    let message: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(colors.primary)
            
            Text(message)
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(colors.textTertiary)
            
            VStack(spacing: UnifiedTheme.Spacing.xs) {
                Text(title)
                    .font(theme.typography.title2)
                    .foregroundColor(colors.textPrimary)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(theme.typography.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(theme.typography.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, UnifiedTheme.Spacing.xl)
                        .padding(.vertical, UnifiedTheme.Spacing.md)
                        .background(colors.primary)
                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                }
                .padding(.top, UnifiedTheme.Spacing.md)
            }
        }
        .padding(UnifiedTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


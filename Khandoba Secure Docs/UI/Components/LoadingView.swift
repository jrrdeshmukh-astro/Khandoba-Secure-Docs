//
//  LoadingView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct LoadingView: View {
    let message: String
    let progress: Double?
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    init(_ message: String = "Loading...", progress: Double? = nil) {
        self.message = message
        self.progress = progress
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            if let progress = progress {
                VStack(spacing: UnifiedTheme.Spacing.md) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: colors.primary))
                        .frame(width: 200)
                    
                    Text("\(Int(progress * 100))%")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(colors.primary)
            }
            
            Text(message)
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}

/// Overlay loading indicator for non-blocking operations
struct LoadingOverlay: View {
    let message: String?
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: UnifiedTheme.Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(colors.primary)
                
                if let message = message {
                    Text(message)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(UnifiedTheme.Spacing.xl)
            .background(colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
            .shadow(radius: 10)
        }
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


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
    let style: LoadingStyle
    let progress: Double?
    let onCancel: (() -> Void)?
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @State private var isVisible = false
    
    enum LoadingStyle {
        case spinner
        case pulsing
        case dots
        case progressRing
    }
    
    init(
        message: String? = nil,
        style: LoadingStyle = .spinner,
        progress: Double? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.message = message
        self.style = style
        self.progress = progress
        self.onCancel = onCancel
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            // Blur background with opacity animation
            colors.background.opacity(0.8)
                .ignoresSafeArea()
                .blur(radius: isVisible ? 10 : 0)
                .opacity(isVisible ? 1.0 : 0.0)
            
            // Loading content
            VStack(spacing: UnifiedTheme.Spacing.md) {
                // Loading indicator based on style
                Group {
                    switch style {
                    case .spinner:
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(colors.primary)
                    case .pulsing:
                        PulsingLoadingView(message: nil, ringCount: 3)
                    case .dots:
                        DotsLoadingView(message: nil, dotCount: 3)
                    case .progressRing:
                        if let progress = progress {
                            ProgressRingView(progress: progress, message: nil)
                        } else {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(colors.primary)
                        }
                    }
                }
                
                if let message = message {
                    Text(message)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
                
                if let onCancel = onCancel {
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                    .padding(.top, UnifiedTheme.Spacing.sm)
                }
            }
            .padding(UnifiedTheme.Spacing.xl)
            .background(colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
            .shadow(radius: 10)
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(LoadingAnimations.spring()) {
                isVisible = true
            }
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


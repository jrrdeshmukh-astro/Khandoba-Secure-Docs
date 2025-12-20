//
//  ClientOnboardingView.swift
//  Khandoba Secure Docs
//
//  Client role onboarding

import SwiftUI

struct ClientOnboardingView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @AppStorage("hasCompletedClientOnboarding") private var hasCompleted = false
    
    @State private var currentPage = 0
    private let totalPages = 4
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? colors.primary : colors.textTertiary)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, UnifiedTheme.Spacing.xl)
                
                // Content
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "lock.shield.fill",
                        title: "Secure Your Documents",
                        description: "Military-grade AES-256 encryption keeps your documents completely private. Zero-knowledge architecture means only you can access your data."
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        icon: "brain.fill",
                        title: "AI-Powered Intelligence",
                        description: "Documents are automatically named and tagged using AI. Intel Reports tell the story of your data with pattern detection and insights."
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        icon: "infinity",
                        title: "Unlimited Everything",
                        description: "All features included with your purchase: unlimited vaults, unlimited storage, and all advanced features."
                    )
                    .tag(2)
                    
                    OnboardingPage(
                        icon: "checkmark.seal.fill",
                        title: "HIPAA Compliant",
                        description: "Built for medical and legal professionals. Includes redaction tools, access logging, and emergency protocols. Your documents are always secure."
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: #if os(iOS) .never #else .automatic #endif))
                
                // Buttons
                VStack(spacing: UnifiedTheme.Spacing.md) {
                    if currentPage < totalPages - 1 {
                        StandardButton(
                            "Continue",
                            icon: nil,
                            style: .primary,
                            isEnabled: true
                        ) {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .foregroundColor(colors.textSecondary)
                    } else {
                        StandardButton(
                            "Get Started",
                            icon: nil,
                            style: .primary,
                            isEnabled: true
                        ) {
                            completeOnboarding()
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func completeOnboarding() {
        hasCompleted = true
        dismiss()
    }
    
    private var colors: UnifiedTheme.Colors {
        theme.colors(for: colorScheme)
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: UnifiedTheme.Spacing.xl) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(colors.primary)
            
            Text(title)
                .font(theme.typography.title)
                .foregroundColor(colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, UnifiedTheme.Spacing.xl)
            
            Spacer()
        }
    }
    
    private var colors: UnifiedTheme.Colors {
        theme.colors(for: colorScheme)
    }
}

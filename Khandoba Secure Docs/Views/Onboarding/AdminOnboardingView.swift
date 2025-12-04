//
//  AdminOnboardingView.swift
//  Khandoba Secure Docs
//
//  Admin role onboarding

import SwiftUI

struct AdminOnboardingView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @AppStorage("hasCompletedAdminOnboarding") private var hasCompleted = false
    
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
                            .fill(currentPage == index ? colors.warning : colors.textTertiary)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, UnifiedTheme.Spacing.xl)
                
                // Content
                TabView(selection: $currentPage) {
                    AdminOnboardingPage(
                        icon: "shield.checkered",
                        title: "Admin Dashboard",
                        description: "Welcome to the admin dashboard. You can manage users, approve requests, and monitor system security while respecting zero-knowledge privacy."
                    )
                    .tag(0)
                    
                    AdminOnboardingPage(
                        icon: "checkmark.shield.fill",
                        title: "Approval Workflows",
                        description: "Review and approve dual-key vault requests, emergency access requests, and vault transfers. Your approval unlocks secure access for users."
                    )
                    .tag(1)
                    
                    AdminOnboardingPage(
                        icon: "eye.slash.fill",
                        title: "Zero-Knowledge Architecture",
                        description: "You can see vault metadata (names, owners, counts) but NEVER document content. This ensures complete privacy for all users."
                    )
                    .tag(2)
                    
                    AdminOnboardingPage(
                        icon: "message.fill",
                        title: "Support & Monitoring",
                        description: "Chat with clients, monitor security threats, and oversee system health. You're the guardian of the platform's security and reliability."
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Buttons
                VStack(spacing: UnifiedTheme.Spacing.md) {
                    if currentPage < totalPages - 1 {
                        StandardButton("Continue", style: .primary) {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .foregroundColor(colors.textSecondary)
                    } else {
                        StandardButton("Start Managing", style: .primary) {
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

struct AdminOnboardingPage: View {
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
                .foregroundColor(colors.warning)
            
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

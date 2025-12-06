//
//  SubscriptionRequiredView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import SwiftUI
import StoreKit
import Combine

struct SubscriptionRequiredView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var abService = ABTestingService.shared
    @StateObject private var subscriptionService = SubscriptionService()
    
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var appeared = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.xl) {
                        // Header
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 70))
                                .foregroundColor(colors.primary)
                            
                            Text("Welcome to Khandoba")
                                .font(theme.typography.largeTitle)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.bold)
                            
                            Text("Professional Security Platform")
                                .font(theme.typography.title2)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding(.top, UnifiedTheme.Spacing.xxl)
                        
                        // Why Premium Section
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            HStack {
                                Image(systemName: "shield.checkered")
                                    .foregroundColor(colors.primary)
                                Text("Why Premium?")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                PremiumFeature(
                                    icon: "lock.shield.fill",
                                    title: "Military-Grade Encryption",
                                    description: "AES-256 encryption for all your documents",
                                    colors: colors
                                )
                                PremiumFeature(
                                    icon: "brain.head.profile",
                                    title: "AI Threat Detection",
                                    description: "ML-powered security monitoring & voice reports",
                                    colors: colors
                                )
                                PremiumFeature(
                                    icon: "location.fill.viewfinder",
                                    title: "Geographic Intelligence",
                                    description: "Location-based access control & anomaly detection",
                                    colors: colors
                                )
                                PremiumFeature(
                                    icon: "key.horizontal.fill",
                                    title: "Dual-Key Vaults",
                                    description: "Auto-approve/deny with ML risk assessment",
                                    colors: colors
                                )
                                PremiumFeature(
                                    icon: "chart.xyaxis.line",
                                    title: "Advanced Analytics",
                                    description: "Source/sink classification & intel reports",
                                    colors: colors
                                )
                                PremiumFeature(
                                    icon: "icloud.fill",
                                    title: "Unlimited Storage",
                                    description: "Store unlimited documents securely",
                                    colors: colors
                                )
                            }
                        }
                        .padding(UnifiedTheme.Spacing.md)
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.xl)
                        .padding(.horizontal, UnifiedTheme.Spacing.xl)
                        
                        // Subscription Plan
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            Text("Subscription")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                            
                            // Monthly plan only
                                monthlyPlanCard(colors: colors)
                                .staggeredAppearance(index: 0, total: 1)
                        }
                        .padding(.horizontal, UnifiedTheme.Spacing.xl)
                        .onAppear {
                            withAnimation(AnimationStyles.spring.delay(0.3)) {
                                appeared = true
                            }
                        }
                        
                        // Subscribe Button
                        Button {
                            subscribeToPlan()
                        } label: {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                    Text("Activate Protection")
                                    Image(systemName: "arrow.right")
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isPurchasing)
                        .padding(.horizontal, UnifiedTheme.Spacing.xl)
                        
                        // Terms
                        VStack(spacing: UnifiedTheme.Spacing.xs) {
                            Text("7-Day Free Trial • Cancel Anytime")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.success)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 4) {
                                Link("Terms of Service", destination: URL(string: "https://khandoba.com/terms")!)
                                Text("•")
                                Link("Privacy Policy", destination: URL(string: "https://khandoba.com/privacy")!)
                            }
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textTertiary)
                        }
                        .padding(.bottom, UnifiedTheme.Spacing.xl)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func subscribeToPlan() {
        isPurchasing = true
        HapticManager.shared.impact(.medium)
        
        Task {
            do {
                // For development/testing: Auto-grant premium access
                // In production, this will use actual StoreKit purchase
                try await purchaseSubscription(selectedPlan)
                
                // Mark user as premium and force UI update
                if let user = authService.currentUser {
                    user.isPremiumSubscriber = true
                    user.subscriptionExpiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                    
                    // Force save to ensure persistence
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
                    
                    await MainActor.run {
                        // Trigger authService refresh to update UI
                        authService.objectWillChange.send()
                    }
                }
                
                // Track A/B test conversion
                abService.trackConversion("subscription_purchased", testID: "pricing_display_v1")
                
                await MainActor.run {
                    isPurchasing = false
                    HapticManager.shared.notification(.success)
                    print(" Subscription activated - user should proceed to main app")
                }
                
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticManager.shared.notification(.error)
                }
            }
        }
    }
    
    // MARK: - Plan Card Helpers
    
    @ViewBuilder
    private func monthlyPlanCard(colors: UnifiedTheme.Colors) -> some View {
        SubscriptionPlanCard(
            plan: .monthly,
            isSelected: selectedPlan == .monthly,
            colors: colors,
            theme: theme
        ) {
            selectedPlan = .monthly
            HapticManager.shared.selection()
        }
    }
    
    
    private func purchaseSubscription(_ plan: SubscriptionPlan) async throws {
        // Simulate purchase delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // For v1.0: Auto-grant access for testing
        // In production with App Store Connect:
        // 1. Fetch products from StoreKit
        // 2. Purchase selected product
        // 3. Verify receipt
        // 4. Update user subscription status
        
        print(" DEV MODE: Subscription auto-granted for: \(plan.rawValue)")
        print("   User will be marked as premium subscriber")
    }
}

// MARK: - Supporting Views

struct PremiumFeature: View {
    let icon: String
    let title: String
    let description: String
    let colors: UnifiedTheme.Colors
    @Environment(\.unifiedTheme) var theme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(colors.primary)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.displayName)
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    Text(plan.description)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(theme.typography.title2)
                        .foregroundColor(colors.textPrimary)
                        .fontWeight(.bold)
                    
                    Text(plan.period)
                        .font(theme.typography.caption2)
                        .foregroundColor(colors.textSecondary)
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(colors.success)
                        .font(.title2)
                }
            }
            .padding(UnifiedTheme.Spacing.md)
            .background(isSelected ? colors.primary.opacity(0.1) : colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: UnifiedTheme.CornerRadius.lg)
                    .stroke(isSelected ? colors.primary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
        }
    }
}

// MARK: - Models

enum SubscriptionPlan: String {
    case monthly = "monthly"
    
    var displayName: String {
        return "Professional Plan"
    }
    
    var description: String {
        return "Full access to security platform"
    }
    
    var price: String {
        return "$5.99"
    }
    
    var period: String {
        return "/month"
    }
}

#Preview {
    SubscriptionRequiredView()
        .environmentObject(AuthenticationService())
}


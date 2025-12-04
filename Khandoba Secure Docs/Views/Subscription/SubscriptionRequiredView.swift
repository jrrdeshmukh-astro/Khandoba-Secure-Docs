//
//  SubscriptionRequiredView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import SwiftUI
import StoreKit

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
                            Image(systemName: "crown.fill")
                                .font(.system(size: 70))
                                .foregroundColor(colors.warning)
                            
                            Text("Welcome to Khandoba")
                                .font(theme.typography.largeTitle)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.bold)
                            
                            Text("Premium Protection Required")
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
                        
                        // Plan Selection
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            Text("Choose Your Plan")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                            
                            // A/B Test: Show yearly first or monthly first
                            if abService.shouldShowYearlyFirst() {
                                // Variant A: Yearly first (with savings badge)
                                yearlyPlanCard(colors: colors)
                                    .staggeredAppearance(index: 0, total: 2)
                                
                                monthlyPlanCard(colors: colors)
                                    .staggeredAppearance(index: 1, total: 2)
                            } else {
                                // Control: Monthly first
                                monthlyPlanCard(colors: colors)
                                    .staggeredAppearance(index: 0, total: 2)
                                
                                yearlyPlanCard(colors: colors)
                                    .staggeredAppearance(index: 1, total: 2)
                            }
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
                                    Image(systemName: "crown.fill")
                                    Text("Start Premium Protection")
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
                // In production, integrate with StoreKit
                try await purchaseSubscription(selectedPlan)
                
                // Mark user as premium
                if let user = authService.currentUser {
                    user.isPremiumSubscriber = true
                    user.subscriptionExpiryDate = selectedPlan == .monthly ?
                        Calendar.current.date(byAdding: .month, value: 1, to: Date()) :
                        Calendar.current.date(byAdding: .year, value: 1, to: Date())
                }
                
                // Track A/B test conversion
                abService.trackConversion("subscription_purchased", testID: "pricing_display_v1")
                
                await MainActor.run {
                    isPurchasing = false
                    HapticManager.shared.notification(.success)
                    // Navigate to main app
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
    
    @ViewBuilder
    private func yearlyPlanCard(colors: UnifiedTheme.Colors) -> some View {
        ZStack(alignment: .topTrailing) {
            SubscriptionPlanCard(
                plan: .yearly,
                isSelected: selectedPlan == .yearly,
                colors: colors,
                theme: theme
            ) {
                selectedPlan = .yearly
                HapticManager.shared.selection()
            }
            
            // Best Value Badge
            Text("SAVE 40%")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colors.success)
                .cornerRadius(4)
                .offset(x: -10, y: -10)
                .glow(color: colors.success, radius: 4)
        }
    }
    
    private func purchaseSubscription(_ plan: SubscriptionPlan) async throws {
        // Simulate purchase delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // In production:
        // 1. Fetch products from StoreKit
        // 2. Purchase selected product
        // 3. Verify receipt
        // 4. Update user subscription status
        
        print("✅ Subscription purchased: \(plan.rawValue)")
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
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly Plan"
        case .yearly: return "Yearly Plan"
        }
    }
    
    var description: String {
        switch self {
        case .monthly: return "Billed monthly"
        case .yearly: return "Billed annually • Best Value"
        }
    }
    
    var price: String {
        switch self {
        case .monthly: return "$9.99"
        case .yearly: return "$5.99"
        }
    }
    
    var period: String {
        switch self {
        case .monthly: return "/month"
        case .yearly: return "/month"
        }
    }
}

#Preview {
    SubscriptionRequiredView()
        .environmentObject(AuthenticationService())
}


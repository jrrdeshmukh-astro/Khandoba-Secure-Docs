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
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var abService = ABTestingService.shared
    @StateObject private var subscriptionService = SubscriptionService()
    
    @State private var selectedPlan: SubscriptionPlan = .monthly
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showRestoreSuccess = false
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
                            Text("Subscription Plan")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                            
                            // Monthly plan only - $5.99/month
                            monthlyPlanCard(colors: colors)
                                .staggeredAppearance(index: 0, total: 1)
                            
                            // Required subscription information display
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                Text("Subscription Details:")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                                    .fontWeight(.semibold)
                                
                                Text("• Title: Khandoba Premium")
                                    .font(theme.typography.caption2)
                                    .foregroundColor(colors.textSecondary)
                                
                                Text("• Length: Monthly (auto-renewable)")
                                    .font(theme.typography.caption2)
                                    .foregroundColor(colors.textSecondary)
                                
                                Text("• Price: $5.99 per month")
                                    .font(theme.typography.caption2)
                                    .foregroundColor(colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(UnifiedTheme.Spacing.sm)
                            .background(colors.surface.opacity(0.5))
                            .cornerRadius(UnifiedTheme.CornerRadius.md)
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
                        .disabled(isPurchasing || isRestoring)
                        .padding(.horizontal, UnifiedTheme.Spacing.xl)
                        
                        // Restore Purchases Button
                        Button {
                            restorePurchases()
                        } label: {
                            if isRestoring {
                                HStack {
                                    ProgressView()
                                        .tint(colors.textSecondary)
                                    Text("Restoring...")
                                }
                            } else {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Restore Purchases")
                                }
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(isPurchasing || isRestoring)
                        .padding(.horizontal, UnifiedTheme.Spacing.xl)
                        
                        // Subscription Information (Required by App Store)
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            // Subscription Details
                            VStack(spacing: UnifiedTheme.Spacing.xs) {
                                Text("Khandoba Premium")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textPrimary)
                                    .fontWeight(.semibold)
                                
                                Text("$5.99 per month")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textPrimary)
                                
                                Text("Auto-renewable subscription")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                            .padding(.vertical, UnifiedTheme.Spacing.sm)
                            
                            // Terms and Privacy Links (Required)
                            VStack(spacing: UnifiedTheme.Spacing.xs) {
                                HStack(spacing: 4) {
                                    Link("Terms of Service", destination: URL(string: "https://khandoba.org/terms")!)
                                    Text("•")
                                    Link("Privacy Policy", destination: URL(string: "https://khandoba.org/privacy")!)
                                }
                                .font(theme.typography.caption2)
                                .foregroundColor(colors.textTertiary)
                                
                                Text("Cancel anytime in App Store Settings")
                                    .font(theme.typography.caption2)
                                    .foregroundColor(colors.textTertiary)
                            }
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
        .alert("Subscription Restored", isPresented: $showRestoreSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your subscription has been restored. You now have full access to all premium features.")
        }
        .onAppear {
            // Configure subscription service with model context
            subscriptionService.configure(modelContext: modelContext)
            
            // Load products from App Store Connect
            Task {
                await subscriptionService.loadProducts()
            }
        }
    }
    
    private func subscribeToPlan() {
        isPurchasing = true
        HapticManager.shared.impact(.medium)
        
        Task {
            do {
                // Load products first
                await subscriptionService.loadProducts()
                
                // Get the monthly subscription product
                guard let product = subscriptionService.products.first else {
                    throw SubscriptionError.productNotFound
                }
                
                // Purchase using StoreKit
                let result = try await subscriptionService.purchase(product)
                
                switch result {
                case .success:
                    // Update user subscription status (handled by SubscriptionService)
                    await subscriptionService.updatePurchasedProducts()
                    
                    // Track A/B test conversion
                    abService.trackConversion("subscription_purchased", testID: "pricing_display_v1")
                    
                    await MainActor.run {
                        isPurchasing = false
                        HapticManager.shared.notification(.success)
                        print("✅ Subscription activated - user should proceed to main app")
                    }
                    
                case .cancelled:
                    await MainActor.run {
                        isPurchasing = false
                        print("ℹ️ Purchase cancelled by user")
                    }
                    
                case .pending:
                    await MainActor.run {
                        isPurchasing = false
                        errorMessage = "Purchase is pending approval. You will be notified when it completes."
                        showError = true
                    }
                    
                case .failed:
                    await MainActor.run {
                        isPurchasing = false
                        errorMessage = "Purchase failed. Please try again."
                        showError = true
                        HapticManager.shared.notification(.error)
                    }
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
    
    private func restorePurchases() {
        isRestoring = true
        HapticManager.shared.impact(.light)
        
        Task {
            do {
                // Restore purchases from App Store
                try await subscriptionService.restorePurchases()
                
                // Check if subscription was restored
                await subscriptionService.updatePurchasedProducts()
                
                // Wait a moment for database update to complete
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Check if user now has active subscription
                if subscriptionService.subscriptionStatus == .active {
                    // Notify that subscription status changed (will trigger view refresh)
                    NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
                    
                    await MainActor.run {
                        isRestoring = false
                        showRestoreSuccess = true
                        HapticManager.shared.notification(.success)
                        print("✅ Subscription restored successfully")
                        print("   Subscription status: \(subscriptionService.subscriptionStatus)")
                        print("   Purchased products: \(subscriptionService.purchasedProductIDs)")
                    }
                } else {
                    await MainActor.run {
                        isRestoring = false
                        errorMessage = "No active subscription found. Please purchase a subscription or contact support if you believe this is an error."
                        showError = true
                        HapticManager.shared.notification(.error)
                        print("ℹ️ No active subscription found to restore")
                    }
                }
            } catch {
                await MainActor.run {
                    isRestoring = false
                    errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
                    showError = true
                    HapticManager.shared.notification(.error)
                    print("❌ Error restoring purchases: \(error.localizedDescription)")
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
    
    
    // Purchase function removed - now handled directly in subscribeToPlan()
}

// MARK: - Supporting Views

struct PremiumFeature: View {
    let icon: String
    let title: String
    let description: String
    let colors: UnifiedTheme.Colors
    @SwiftUI.Environment(\.unifiedTheme) var theme
    
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


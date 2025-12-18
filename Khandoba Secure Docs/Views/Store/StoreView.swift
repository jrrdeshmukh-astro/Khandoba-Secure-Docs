//
//  StoreView.swift
//  Khandoba Secure Docs
//
//  NOTE: This view is not currently used in navigation (app is paid, not subscription-based)
//  Kept for potential future use or reference
//

import SwiftUI
import StoreKit

struct StoreView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var subscriptionService = SubscriptionService()
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showRestoreSuccess = false
    @State private var isRestoring = false
    @State private var restoreSuccessMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Current Status
                        currentStatusSection
                        
                        // Premium Features
                        featuresSection
                        
                        // Subscription Options
                        subscriptionSection
                        
                        // Manage Subscription
                        if subscriptionService.subscriptionStatus == .active {
                            manageSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Purchases Restored", isPresented: $showRestoreSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreSuccessMessage)
        }
        .onAppear {
            // Configure subscription service with model context
            subscriptionService.configure(modelContext: modelContext)
            
            // Load products and check subscription status
            Task {
                await subscriptionService.loadProducts()
                await subscriptionService.updatePurchasedProducts()
            }
        }
    }
    
    private var colors: UnifiedTheme.Colors {
        theme.colors(for: colorScheme)
    }
    
    // MARK: - Current Status Section
    
    private var currentStatusSection: some View {
        StandardCard {
            VStack(spacing: UnifiedTheme.Spacing.md) {
                if subscriptionService.subscriptionStatus == .active {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(colors.success)
                    
                    Text("Premium Active")
                        .font(theme.typography.title2)
                        .foregroundColor(colors.textPrimary)
                    
                    Text("Unlimited vaults and storage")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                } else {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(colors.textSecondary)
                    
                    Text("Free Plan")
                        .font(theme.typography.title2)
                        .foregroundColor(colors.textPrimary)
                    
                    Text("Upgrade to unlock unlimited access")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(UnifiedTheme.Spacing.lg)
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                Text("Premium Features")
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                FeatureRow(icon: "infinity", title: "Unlimited Vaults", description: "Create as many vaults as you need")
                Divider()
                FeatureRow(icon: "icloud.fill", title: "Unlimited Storage", description: "No limits on documents or file sizes")
                Divider()
                FeatureRow(icon: "brain.fill", title: "AI Intelligence", description: "Full access to Intel Reports and NLP tagging")
                Divider()
                FeatureRow(icon: "shield.checkered", title: "Advanced Security", description: "Threat monitoring and access analytics")
                Divider()
                FeatureRow(icon: "person.2.fill", title: "Collaboration", description: "Share vaults and collaborate securely")
                Divider()
                FeatureRow(icon: "arrow.triangle.2.circlepath", title: "All Features", description: "Every premium feature included")
            }
            .padding(UnifiedTheme.Spacing.md)
        }
    }
    
    // MARK: - Subscription Section
    
    @ViewBuilder
    private var subscriptionSection: some View {
            if subscriptionService.isLoading {
                ProgressView()
                    .padding()
            } else if let product = subscriptionService.products.first {
                StandardCard {
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Khandoba Premium")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                Text("Unlimited everything")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(product.displayPrice)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(colors.primary)
                                
                                Text("per month")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                        
                        if subscriptionService.subscriptionStatus != .active {
                            StandardButton(
                                "Subscribe Now",
                                style: .primary,
                                action: {
                                    Task {
                                        do {
                                            _ = try await subscriptionService.purchase(product)
                                        } catch {
                                            errorMessage = error.localizedDescription
                                            showError = true
                                        }
                                    }
                                }
                            )
                            
                            // Required subscription metadata (Guideline 3.1.2)
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                Text("Subscription Information:")
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
                            
                            // Required Terms and Privacy links (Guideline 3.1.2)
                            VStack(spacing: UnifiedTheme.Spacing.xs) {
                                HStack(spacing: 4) {
                                    Link("Terms of Service", destination: URL(string: "https://khandoba.org/terms")!)
                                    Text("•")
                                    Link("Privacy Policy", destination: URL(string: "https://khandoba.org/privacy")!)
                                }
                                .font(theme.typography.caption2)
                                .foregroundColor(colors.primary)
                                
                                Text("Cancel anytime in App Store Settings")
                                    .font(theme.typography.caption2)
                                    .foregroundColor(colors.textSecondary)
                            }
                            .padding(.top, UnifiedTheme.Spacing.xs)
                            
                            Button {
                                Task {
                                    isRestoring = true
                                    do {
                                        try await subscriptionService.restorePurchases()
                                        
                                        // Wait a moment for status to update
                                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                        
                                        // Force refresh subscription status
                                        await subscriptionService.updatePurchasedProducts()
                                        
                                        await MainActor.run {
                                            isRestoring = false
                                            
                                            if subscriptionService.subscriptionStatus == .active {
                                                restoreSuccessMessage = "Your premium subscription has been restored successfully!"
                                            } else {
                                                restoreSuccessMessage = "No active subscriptions found to restore."
                                            }
                                            showRestoreSuccess = true
                                        }
                                    } catch {
                                        await MainActor.run {
                                            isRestoring = false
                                            errorMessage = error.localizedDescription
                                            showError = true
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    if isRestoring {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(colors.secondary)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text("Restore Purchases")
                                }
                            }
                            .font(theme.typography.caption)
                            .foregroundColor(colors.secondary)
                            .disabled(isRestoring)
                        }
                    }
                    .padding(UnifiedTheme.Spacing.md)
                }
            } else {
                // Product not available yet (needs to be created in App Store Connect)
                StandardCard {
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(colors.warning)
                        
                        Text("Subscription Not Available")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text("The Premium subscription will be available after it's created in App Store Connect.")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Premium Features ($5.99/month):")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("• Unlimited vaults\n• Unlimited storage\n• All AI features\n• Family Sharing")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding(.top)
                    }
                    .padding(UnifiedTheme.Spacing.lg)
                }
                .padding(.horizontal)
        }
    }
    
    // MARK: - Manage Section
    
    private var manageSection: some View {
        StandardCard {
            VStack(spacing: UnifiedTheme.Spacing.md) {
                Button {
                    Task {
                        // Open Apple's subscription management
                        #if !APP_EXTENSION
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            do {
                                try await AppStore.showManageSubscriptions(in: windowScene)
                            } catch {
                                print(" Failed to show manage subscriptions: \(error)")
                            }
                        }
                        #endif
                    }
                } label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Manage Subscription")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .foregroundColor(colors.textPrimary)
                }
                
                Text("Cancel anytime from your App Store subscriptions")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
            }
            .padding(UnifiedTheme.Spacing.md)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(colors.primary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.typography.body)
                    .foregroundColor(colors.textPrimary)
                
                Text(description)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
            }
        }
    }
    
    private var colors: UnifiedTheme.Colors {
        theme.colors(for: colorScheme)
    }
}

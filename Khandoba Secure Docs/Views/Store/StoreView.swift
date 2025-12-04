//
//  StoreView.swift
//  Khandoba Secure Docs
//
//  Premium Subscription Store
//

import SwiftUI
import StoreKit

struct StoreView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var subscriptionService = SubscriptionService()
    
    @State private var showError = false
    @State private var errorMessage = ""
    
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
    
    private var subscriptionSection: some View {
        Group {
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
                                            try await subscriptionService.purchase()
                                        } catch {
                                            errorMessage = error.localizedDescription
                                            showError = true
                                        }
                                    }
                                }
                            )
                            
                            Text("$5.99/month • Cancel anytime")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Restore Purchases") {
                                Task {
                                    do {
                                        try await subscriptionService.restore()
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showError = true
                                    }
                                }
                            }
                            .font(theme.typography.caption)
                            .foregroundColor(colors.secondary)
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
    }
    
    // MARK: - Manage Section
    
    private var manageSection: some View {
        StandardCard {
            VStack(spacing: UnifiedTheme.Spacing.md) {
                Button {
                    Task {
                        // Open Apple's subscription management
                        if let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene {
                            do {
                                try await AppStore.showManageSubscriptions(in: windowScene)
                            } catch {
                                print("❌ Failed to show manage subscriptions: \(error)")
                            }
                        }
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

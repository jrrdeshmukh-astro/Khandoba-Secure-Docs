//
//  PaymentManagementView.swift
//  Khandoba Secure Docs
//
//  Payment management admin view
//

import SwiftUI
import StoreKit

struct PaymentManagementView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscriptionService = SubscriptionService()
    
    @State private var revenueData: RevenueData?
    @State private var isLoading = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Revenue Overview
                        RevenueOverviewCard(data: revenueData)
                        
                        // Subscription Stats
                        SubscriptionStatsCard(service: subscriptionService)
                        
                        // Transaction History
                        TransactionHistoryCard()
                    }
                    .padding()
                }
                .navigationTitle("Payment Management")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .onAppear {
            configureService()
            loadRevenueData()
        }
    }
    
    private func configureService() {
        subscriptionService.configure(modelContext: modelContext)
    }
    
    private func loadRevenueData() {
        isLoading = true
        Task {
            // Load revenue data from StoreKit
            // This would integrate with StoreKit 2 transaction history
            revenueData = RevenueData(
                totalRevenue: 0.0,
                monthlyRevenue: 0.0,
                activeSubscriptions: 0,
                totalTransactions: 0
            )
            isLoading = false
        }
    }
}

private struct RevenueData {
    let totalRevenue: Double
    let monthlyRevenue: Double
    let activeSubscriptions: Int
    let totalTransactions: Int
}

private struct RevenueOverviewCard: View {
    let data: RevenueData?
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                Text("Revenue Overview")
                    .font(theme.typography.headline)
                
                if let data = data {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Revenue")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                            Text(formatCurrency(data.totalRevenue))
                                .font(theme.typography.title2)
                                .foregroundColor(colors.textPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Monthly Revenue")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                            Text(formatCurrency(data.monthlyRevenue))
                                .font(theme.typography.title2)
                                .foregroundColor(colors.textPrimary)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .padding()
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

private struct SubscriptionStatsCard: View {
    @ObservedObject var service: SubscriptionService
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                Text("Subscription Status")
                    .font(theme.typography.headline)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Status")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        Text(service.subscriptionStatus == .active ? "Active" : "Inactive")
                            .font(theme.typography.title2)
                            .foregroundColor(colors.textPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Active Products")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        Text("\(service.purchasedProductIDs.count)")
                            .font(theme.typography.title2)
                            .foregroundColor(colors.textPrimary)
                    }
                }
            }
            .padding()
        }
    }
}

private struct TransactionHistoryCard: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                Text("Transaction History")
                    .font(theme.typography.headline)
                
                Text("Transaction history would be displayed here")
                    .font(theme.typography.body)
                    .foregroundColor(colors.textSecondary)
            }
            .padding()
        }
    }
}


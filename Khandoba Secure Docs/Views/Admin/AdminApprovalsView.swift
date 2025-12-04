//
//  AdminApprovalsView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct AdminApprovalsView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<DualKeyRequest> { $0.status == "pending" })
    private var pendingDualKey: [DualKeyRequest]
    
    @Query(filter: #Predicate<EmergencyAccessRequest> { $0.status == "pending" })
    private var pendingEmergency: [EmergencyAccessRequest]
    
    @Query(filter: #Predicate<VaultTransferRequest> { $0.status == "pending" })
    private var pendingTransfers: [VaultTransferRequest]
    
    var totalPending: Int {
        pendingDualKey.count + pendingEmergency.count + pendingTransfers.count
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Summary Card
                        StandardCard {
                            VStack(spacing: UnifiedTheme.Spacing.md) {
                                HStack {
                                    Image(systemName: "bell.badge.fill")
                                        .font(.title)
                                        .foregroundColor(totalPending > 0 ? colors.warning : colors.success)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Pending Approvals")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.textSecondary)
                                        
                                        Text("\(totalPending)")
                                            .font(theme.typography.largeTitle)
                                            .foregroundColor(colors.textPrimary)
                                            .fontWeight(.bold)
                                    }
                                    
                                    Spacer()
                                }
                                
                                HStack(spacing: UnifiedTheme.Spacing.lg) {
                                    ApprovalStat(
                                        icon: "key.fill",
                                        count: pendingDualKey.count,
                                        label: "Dual-Key",
                                        color: colors.info
                                    )
                                    
                                    ApprovalStat(
                                        icon: "exclamationmark.triangle.fill",
                                        count: pendingEmergency.count,
                                        label: "Emergency",
                                        color: colors.error
                                    )
                                    
                                    ApprovalStat(
                                        icon: "arrow.triangle.2.circlepath",
                                        count: pendingTransfers.count,
                                        label: "Transfers",
                                        color: colors.warning
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Quick Access Cards
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            NavigationLink {
                                DualKeyApprovalView()
                            } label: {
                                ApprovalCategoryCard(
                                    icon: "key.fill",
                                    title: "Dual-Key Requests",
                                    count: pendingDualKey.count,
                                    color: colors.info
                                )
                            }
                            
                            NavigationLink {
                                EmergencyApprovalView()
                            } label: {
                                ApprovalCategoryCard(
                                    icon: "exclamationmark.triangle.fill",
                                    title: "Emergency Access",
                                    count: pendingEmergency.count,
                                    color: colors.error
                                )
                            }
                            
                            NavigationLink {
                                TransferApprovalView()
                            } label: {
                                ApprovalCategoryCard(
                                    icon: "arrow.triangle.2.circlepath",
                                    title: "Vault Transfers",
                                    count: pendingTransfers.count,
                                    color: colors.warning
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Approvals")
        }
    }
}

struct ApprovalStat: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text("\(count)")
                .font(theme.typography.headline)
                .foregroundColor(colors.textPrimary)
                .fontWeight(.bold)
            
            Text(label)
                .font(theme.typography.caption2)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ApprovalCategoryCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text("\(count) pending")
                        .font(theme.typography.caption)
                        .foregroundColor(count > 0 ? color : colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(colors.textTertiary)
            }
        }
    }
}


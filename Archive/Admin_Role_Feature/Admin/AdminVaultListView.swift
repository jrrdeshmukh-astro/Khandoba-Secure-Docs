//
//  AdminVaultListView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct AdminVaultListView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Vault.createdAt, order: .reverse) private var allVaults: [Vault]
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if allVaults.isEmpty {
                    EmptyStateView(
                        icon: "lock.shield",
                        title: "No Vaults",
                        message: "No vaults have been created in the system"
                    )
                } else {
                    List {
                        ForEach(allVaults) { vault in
                            NavigationLink {
                                AdminVaultDetailView(vault: vault)
                            } label: {
                                AdminVaultRow(vault: vault)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(colors.background)
                }
            }
            .navigationTitle("All Vaults")
        }
    }
}

struct AdminVaultRow: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack(spacing: UnifiedTheme.Spacing.md) {
            Group {
                if vault.keyType == "dual" {
                    HStack(spacing: -2) {
                        Image(systemName: "key.fill")
                            .font(.caption)
                        Image(systemName: "key.fill")
                            .font(.caption)
                            .rotationEffect(.degrees(15))
                    }
                } else {
                    Image(systemName: "lock.fill")
                }
            }
            .foregroundColor(colors.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(vault.name)
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                
                Text("Owner: \(vault.owner?.fullName ?? "Unknown")")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                
                HStack(spacing: 8) {
                    Text("\(vault.documents?.count ?? 0) docs")
                        .font(theme.typography.caption2)
                        .foregroundColor(colors.textTertiary)
                    
                    Text("•")
                        .foregroundColor(colors.textTertiary)
                    
                    Text(vault.status.capitalized)
                        .font(theme.typography.caption2)
                        .foregroundColor(vault.status == "active" ? colors.success : colors.textTertiary)
                }
            }
            
            Spacer()
        }
    }
}


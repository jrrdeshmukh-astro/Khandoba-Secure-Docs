//
//  VaultListView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct VaultListView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vaultService: VaultService
    
    @State private var showCreateVault = false
    @State private var isLoading = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if isLoading {
                    LoadingView("Loading vaults...")
                } else if vaultService.vaults.isEmpty {
                    EmptyStateView(
                        icon: "lock.shield",
                        title: "No Vaults Yet",
                        message: "Create your first secure vault to store documents",
                        actionTitle: "Create Vault"
                    ) {
                        showCreateVault = true
                    }
                } else {
                    List {
                        ForEach(vaultService.vaults) { vault in
                            NavigationLink {
                                VaultDetailView(vault: vault)
                            } label: {
                                VaultRow(vault: vault)
                            }
                            .listRowBackground(colors.surface)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(colors.background)
                    .tint(colors.primary) // Override iOS default tint
                }
            }
            .navigationTitle("Vaults")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateVault = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showCreateVault) {
                CreateVaultView()
            }
            .refreshable {
                await loadVaults()
            }
        }
        .task {
            await loadVaults()
        }
    }
    
    private func loadVaults() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await vaultService.loadVaults()
        } catch {
            print("Error loading vaults: \(error)")
        }
    }
}

struct VaultRow: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vaultService: VaultService
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let hasActiveSession = vaultService.hasActiveSession(for: vault.id)
        
        HStack(spacing: UnifiedTheme.Spacing.md) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                // Show dual-key icon if applicable
                if vault.keyType == "dual" {
                    HStack(spacing: -2) {
                        Image(systemName: "key.fill")
                            .font(.caption)
                        Image(systemName: "key.fill")
                            .font(.caption)
                            .rotationEffect(.degrees(15))
                    }
                    .foregroundColor(statusColor)
                } else {
                    Image(systemName: hasActiveSession ? "lock.open.fill" : "lock.fill")
                        .foregroundColor(statusColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(vault.name)
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    // Dual-Key Badge
                    if vault.keyType == "dual" {
                        HStack(spacing: 2) {
                            HStack(spacing: -2) {
                                Image(systemName: "key.fill")
                                    .font(.caption2)
                                Image(systemName: "key.fill")
                                    .font(.caption2)
                                    .rotationEffect(.degrees(15))
                            }
                            Text("DUAL-KEY")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(colors.textPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(colors.warning)
                        .cornerRadius(4)
                    }
                }
                
                if let description = vault.vaultDescription, !description.isEmpty {
                    Text(description)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: UnifiedTheme.Spacing.xs) {
                    Image(systemName: "doc.fill")
                        .font(.caption2)
                        .foregroundColor(colors.textTertiary)
                    
                    Text("\(vault.documents?.count ?? 0) documents")
                        .font(theme.typography.caption2)
                        .foregroundColor(colors.textTertiary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, UnifiedTheme.Spacing.xs)
    }
    
    private var statusColor: Color {
        let colors = theme.colors(for: colorScheme)
        if vaultService.hasActiveSession(for: vault.id) {
            return colors.success
        }
        return colors.error
    }
}


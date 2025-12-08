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
    @Environment(\.modelContext) private var modelContext
    
    @State private var showCreateVault = false
    @State private var isLoading = false
    @State private var selectedVaultID: UUID?
    @State private var navigateToVaultID: UUID?
    
    // Filter out system vaults (Intel Reports, etc.)
    private var userVaults: [Vault] {
        vaultService.vaults.filter { vault in
            // Hide "Intel Reports" vault and any system vaults
            vault.name != "Intel Reports" && !vault.isSystemVault
        }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if isLoading {
                    LoadingView("Loading vaults...")
                } else if userVaults.isEmpty {
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
                        ForEach(userVaults) { vault in
                            NavigationLink(
                                destination: VaultDetailView(vault: vault),
                                tag: vault.id,
                                selection: $selectedVaultID
                            ) {
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
        .onReceive(NotificationCenter.default.publisher(for: .navigateToVault)) { notification in
            if let vaultID = notification.userInfo?["vaultID"] as? UUID {
                navigateToVault(vaultID: vaultID)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitShareInvitationReceived)) { _ in
            // Refresh vaults when CloudKit share is received
            Task {
                await loadVaults()
            }
        }
        .onChange(of: navigateToVaultID) { oldValue, newValue in
            if let vaultID = newValue {
                selectedVaultID = vaultID
                navigateToVaultID = nil
            }
        }
    }
    
    private func navigateToVault(vaultID: UUID) {
        // Reload vaults first to ensure the vault is in the list
        Task {
            await loadVaults()
            // Wait a moment for vaults to load
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                // Check if vault exists in the list
                if userVaults.contains(where: { $0.id == vaultID }) {
                    selectedVaultID = vaultID
                } else {
                    // If vault not found, try again after a longer delay
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 more seconds
                        await MainActor.run {
                            if userVaults.contains(where: { $0.id == vaultID }) {
                                selectedVaultID = vaultID
                            }
                        }
                    }
                }
            }
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
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let hasActiveSession = vaultService.hasActiveSession(for: vault.id)
        let isSharedVault = isVaultShared
        
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
                    
                    // Shared Vault Badge
                    if isSharedVault {
                        HStack(spacing: 2) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("SHARED")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(colors.info)
                        .cornerRadius(4)
                    }
                    
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
    
    /// Check if this vault is shared (not owned by current user)
    private var isVaultShared: Bool {
        guard let currentUser = authService.currentUser,
              let vaultOwner = vault.owner else {
            return false
        }
        // Vault is shared if owner is different from current user
        return vaultOwner.id != currentUser.id
    }
}


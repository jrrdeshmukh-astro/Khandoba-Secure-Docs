//
//  VaultSelectionMessageView.swift
//  Khandoba Secure Docs
//
//  Apple Pay-style vault selection interface for iMessage extension
//

import SwiftUI
import Messages
import SwiftData
import Foundation

struct VaultSelectionMessageView: View {
    let conversation: MSConversation
    let onTransfer: (Vault) -> Void
    let onNominate: (Vault) -> Void
    let onCancel: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vaults: [Vault] = []
    @State private var selectedIndex: Int = 0
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var modelContext: ModelContext?
    @State private var isAuthenticated = false
    
    var selectedVault: Vault? {
        guard !vaults.isEmpty, selectedIndex >= 0, selectedIndex < vaults.count else {
            return nil
        }
        return vaults[selectedIndex]
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background.ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: UnifiedTheme.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading vaults...")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                }
            } else if vaults.isEmpty {
                VStack(spacing: UnifiedTheme.Spacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundColor(colors.textTertiary)
                    Text("No Vaults Available")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    Text("Create a vault in the main app first")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
            } else {
                VStack(spacing: UnifiedTheme.Spacing.xl) {
                    // Vault Selection Display (Apple Pay style)
                    HStack(spacing: UnifiedTheme.Spacing.xl) {
                        // Left Arrow
                        Button {
                            selectPreviousVault()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(colors.primary)
                                .frame(width: 50, height: 50)
                                .background(colors.surface)
                                .clipShape(Circle())
                        }
                        .disabled(selectedIndex == 0)
                        .opacity(selectedIndex == 0 ? 0.3 : 1.0)
                        
                        // Vault Display (Center)
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            if let vault = selectedVault {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(colors.primary)
                                
                                Text(vault.name)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(colors.textPrimary)
                                
                                Text("Vault \(selectedIndex + 1) of \(vaults.count)")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                                
                                if let owner = vault.owner {
                                    Text("Owner: \(owner.fullName)")
                                        .font(theme.typography.caption2)
                                        .foregroundColor(colors.textTertiary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right Arrow
                        Button {
                            selectNextVault()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(colors.primary)
                                .frame(width: 50, height: 50)
                                .background(colors.surface)
                                .clipShape(Circle())
                        }
                        .disabled(selectedIndex >= vaults.count - 1)
                        .opacity(selectedIndex >= vaults.count - 1 ? 0.3 : 1.0)
                    }
                    .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    .padding(.vertical, UnifiedTheme.Spacing.lg)
                    
                    // Action Buttons
                    HStack(spacing: UnifiedTheme.Spacing.md) {
                        // Transfer Button
                        Button {
                            if let vault = selectedVault {
                                onTransfer(vault)
                            }
                        } label: {
                            Text("Transfer")
                                .font(theme.typography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.warning)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        .disabled(selectedVault == nil)
                        
                        // Nominate Button
                        Button {
                            if let vault = selectedVault {
                                onNominate(vault)
                            }
                        } label: {
                            Text("Nominate")
                                .font(theme.typography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.primary)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        .disabled(selectedVault == nil)
                    }
                    .padding(.horizontal, UnifiedTheme.Spacing.lg)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await loadVaults()
        }
    }
    
    private func selectPreviousVault() {
        guard selectedIndex > 0 else { return }
        withAnimation {
            selectedIndex -= 1
        }
    }
    
    private func selectNextVault() {
        guard selectedIndex < vaults.count - 1 else { return }
        withAnimation {
            selectedIndex += 1
        }
    }
    
    private func loadVaults() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Use shared container with timeout
        do {
            let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
            let context = container.mainContext
            
            // Check authentication - verify user exists
            let users = try context.fetch(FetchDescriptor<User>())
            if users.isEmpty {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Please sign in to the main app first"
                    showError = true
                }
                return
            }
            
            // Load vaults
            let vaultDescriptor = FetchDescriptor<Vault>(
                sortBy: [SortDescriptor<Vault>(\.createdAt, order: .reverse)]
            )
            let allVaults = try context.fetch(vaultDescriptor)
            let availableVaults = allVaults.filter { !$0.isSystemVault }
            
            // Pending nomination selection (if any)
            var initialSelectedIndex = 0
            if let sharedDefaults = UserDefaults(suiteName: MessageAppConfig.appGroupIdentifier),
               let pendingVaultIDString = sharedDefaults.string(forKey: "pendingNominationVaultID"),
               let pendingVaultID = UUID(uuidString: pendingVaultIDString),
               let vaultIndex = availableVaults.firstIndex(where: { $0.id == pendingVaultID }) {
                initialSelectedIndex = vaultIndex
                sharedDefaults.removeObject(forKey: "pendingNominationVaultID")
                sharedDefaults.synchronize()
            }
            
            await MainActor.run {
                vaults = availableVaults
                selectedIndex = initialSelectedIndex
                isLoading = false
                isAuthenticated = true
                modelContext = context
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to load vaults: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}


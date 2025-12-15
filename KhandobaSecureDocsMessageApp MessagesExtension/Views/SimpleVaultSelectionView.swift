//
//  SimpleVaultSelectionView.swift
//  Khandoba Secure Docs
//
//  Simplified vault selection for iMessage extension
//

import SwiftUI
import SwiftData

struct SimpleVaultSelectionView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    let onVaultSelected: (Vault) -> Void
    let onCancel: () -> Void
    
    @State private var vaults: [Vault] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    onCancel()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colors.primary)
                }
                
                Text("Select Vault")
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
            }
            .padding()
            .background(colors.surface)
            
            Divider()
            
            // Content
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading vaults...")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(colors.warning)
                    Text(error)
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vaults.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 40))
                        .foregroundColor(colors.textSecondary)
                    Text("No vaults available")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    Text("Create a vault in the main app first")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(vaults) { vault in
                            Button(action: {
                                onVaultSelected(vault)
                            }) {
                                HStack {
                                    Image(systemName: vault.keyType == "dual" ? "key.fill" : "key")
                                        .font(.system(size: 20))
                                        .foregroundColor(colors.primary)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(vault.name)
                                            .font(theme.typography.headline)
                                            .foregroundColor(colors.textPrimary)
                                        
                                        // Show vault type indicator if needed
                                        if vault.keyType == "dual" {
                                            Text("Dual-Key")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(colors.textSecondary)
                                }
                                .padding()
                                .background(colors.surface)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .task {
            await loadVaults()
        }
    }
    
    private func loadVaults() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
            let context = container.mainContext
            
            // Fetch vaults (excluding system vaults)
            let descriptor = FetchDescriptor<Vault>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            let allVaults = try context.fetch(descriptor)
            let userVaults = allVaults.filter { !$0.isSystemVault }
            
            await MainActor.run {
                self.vaults = userVaults
                self.isLoading = false
                print("✅ Loaded \(userVaults.count) vault(s)")
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load vaults: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Failed to load vaults: \(error.localizedDescription)")
            }
        }
    }
}

//
//  CloudKitShareSuccessView.swift
//  Khandoba Secure Docs
//
//  Success view shown when a CloudKit share is accepted
//  The vault is already synced via SwiftData, so we just show success and navigate
//

import SwiftUI
import SwiftData

struct CloudKitShareSuccessView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    let rootRecordID: String?
    let vaultID: UUID?
    let onNavigateToVault: ((UUID) -> Void)?
    
    @State private var vaultName: String = "the vault"
    @State private var vault: Vault?
    @State private var isLoading = true
    @State private var showVault = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Syncing vault...")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: UnifiedTheme.Spacing.xl) {
                            // Success Icon
                            VStack(spacing: UnifiedTheme.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(colors.success)
                                
                                Text("Vault Shared Successfully")
                                    .font(theme.typography.title)
                                    .foregroundColor(colors.textPrimary)
                                
                                Text("You now have access to \(vaultName)")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, UnifiedTheme.Spacing.xl)
                            
                            // Info Card
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(colors.info)
                                        Text("How It Works")
                                            .font(theme.typography.subheadline)
                                            .foregroundColor(colors.textPrimary)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text("The vault has been added to your vault list. When the vault owner unlocks it, you'll automatically have access to view and manage documents. The vault is shared in real-time - no documents are copied.")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Action Buttons
                            VStack(spacing: UnifiedTheme.Spacing.md) {
                                // Open Vault Button (if vault found)
                                if let vault = vault {
                                    Button {
                                        onNavigateToVault?(vault.id)
                                        dismiss()
                                    } label: {
                                        HStack {
                                            Image(systemName: "lock.open.fill")
                                            Text("Open Vault")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(colors.primary)
                                        .foregroundColor(.white)
                                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                    }
                                }
                                
                                // Done Button
                                Button {
                                    dismiss()
                                } label: {
                                    Text(vault != nil ? "Done" : "View Vaults")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(vault != nil ? colors.surface : colors.primary)
                                        .foregroundColor(vault != nil ? colors.textPrimary : .white)
                                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, UnifiedTheme.Spacing.xl)
                        }
                    }
                }
            }
            .navigationTitle("Share Accepted")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .task {
            await loadVaultInfo()
        }
    }
    
    private func loadVaultInfo() async {
        // Try to find the vault by vaultID (preferred) or root record ID
        if let vaultID = vaultID {
            // Find vault by ID
            let descriptor = FetchDescriptor<Vault>(
                predicate: #Predicate { $0.id == vaultID }
            )
            
            do {
                if let foundVault = try modelContext.fetch(descriptor).first {
                    await MainActor.run {
                        vault = foundVault
                        vaultName = foundVault.name
                        isLoading = false
                    }
                    return
                }
            } catch {
                print("   ⚠️ Error finding vault by ID: \(error.localizedDescription)")
            }
        }
        
        // Fallback: Try to find recently shared vault
        guard let currentUser = authService.currentUser else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        // Wait a moment for SwiftData to sync
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Find vaults that are not owned by current user (shared vaults)
        // and were created/synced recently (within last 5 minutes)
        let descriptor = FetchDescriptor<Vault>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let vaults = try modelContext.fetch(descriptor)
            let recentTime = Date().addingTimeInterval(-300) // 5 minutes ago
            
            if let sharedVault = vaults.first(where: { vault in
                guard let owner = vault.owner else { return false }
                return owner.id != currentUser.id && vault.createdAt >= recentTime
            }) {
                await MainActor.run {
                    vault = sharedVault
                    vaultName = sharedVault.name
                    isLoading = false
                }
                return
            }
        } catch {
            print("   ⚠️ Error finding shared vault: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}


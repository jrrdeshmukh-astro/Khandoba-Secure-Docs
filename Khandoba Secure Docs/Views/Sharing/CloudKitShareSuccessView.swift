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
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let rootRecordID: String?
    @State private var vaultName: String = "the vault"
    @State private var isLoading = true
    
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
                            
                            // Done Button
                            Button {
                                dismiss()
                            } label: {
                                Text("Done")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(colors.primary)
                                    .foregroundColor(.white)
                                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, UnifiedTheme.Spacing.xl)
                        }
                    }
                }
            }
            .navigationTitle("Share Accepted")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await loadVaultInfo()
        }
    }
    
    private func loadVaultInfo() async {
        // Try to find the vault by root record ID
        // SwiftData should have synced it by now
        guard let rootRecordID = rootRecordID else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        // Wait a moment for SwiftData to sync
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Try to find the vault
        // Note: We can't directly query by CloudKit record ID in SwiftData
        // But the vault should appear in the vault list automatically
        await MainActor.run {
            isLoading = false
        }
    }
}


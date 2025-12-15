//
//  NomineeInvitationFlowView.swift
//  Khandoba Secure Docs
//
//  Apple Cash-style nominee invitation flow
//

import SwiftUI
import SwiftData
@preconcurrency import Messages

struct NomineeInvitationFlowView: View {
    let conversation: MSConversation
    let onCancel: () -> Void
    let onSend: (Vault, String) -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vaults: [Vault] = []
    @State private var selectedVault: Vault?
    @State private var isLoading = true
    @State private var showVaultSelector = false
    @State private var recipientName: String = ""
    @State private var showKeypad = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // Header (Apple Cash style)
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colors.textPrimary)
                        .frame(width: 32, height: 32)
                }
                
                Spacer()
                
                Text("Khandoba Secure Docs")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
                
                // Placeholder for balance
                Button(action: {
                    showVaultSelector.toggle()
                }) {
                    Text("Change Vault")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(colors.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(colors.surface)
            
            Divider()
            
            // Main Content
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading vaults...")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
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
                    VStack(spacing: 24) {
                        // Recipient Info (Apple Cash style)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Send to")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(colors.textSecondary)
                            
                            if !conversation.remoteParticipantIdentifiers.isEmpty {
                                Text("Recipient")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(colors.textPrimary)
                            } else {
                                TextField("Recipient name", text: $recipientName)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(colors.textPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Large Vault Display (like "$1" in Apple Cash)
                        if let vault = selectedVault {
                            VStack(spacing: 12) {
                                Text(vault.name)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(colors.textPrimary)
                                
                                Text(vault.keyType == "dual" ? "Dual-Key Vault" : "Single-Key Vault")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(colors.textSecondary)
                                
                                Button(action: {
                                    showVaultSelector.toggle()
                                }) {
                                    Text("Change Vault")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(colors.primary)
                                }
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                        
                        // Vault Rolodex (if selector is shown)
                        if showVaultSelector {
                            VaultRolodexView(
                                vaults: vaults,
                                selectedVault: $selectedVault
                            ) { vault in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showVaultSelector = false
                                }
                            }
                            .padding(.vertical, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Vault Details Card (like payment method card)
                        if let vault = selectedVault {
                            VaultCardView(
                                vault: vault,
                                isSelected: true
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showVaultSelector.toggle()
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        } else {
                            // Loading placeholder
                            VStack(spacing: 16) {
                                ProgressView()
                                Text("Selecting vault...")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textSecondary)
                            }
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        }
                    }
                }
                
                // Action Buttons (Apple Cash style - Request/Send)
                VStack(spacing: 12) {
                    Button(action: {
                        if let vault = selectedVault {
                            let name = recipientName.isEmpty ? "Recipient" : recipientName
                            // Send immediately (Apple Cash style - no confirmation screen)
                            onSend(vault, name)
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24))
                            Text("Send Invitation")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(colors.primary)
                        .cornerRadius(14)
                    }
                    .disabled(selectedVault == nil)
                    .opacity(selectedVault == nil ? 0.6 : 1.0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(colors.surface)
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
        defer { isLoading = false }
        
        do {
            let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
            let context = container.mainContext
            
            let descriptor = FetchDescriptor<Vault>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            let allVaults = try context.fetch(descriptor)
            let userVaults = allVaults.filter { !$0.isSystemVault }
            
            await MainActor.run {
                self.vaults = userVaults
                self.selectedVault = userVaults.first
                print("✅ Loaded \(userVaults.count) vault(s), selected: \(self.selectedVault?.name ?? "none")")
            }
        } catch {
            print("❌ Failed to load vaults: \(error.localizedDescription)")
        }
    }
}

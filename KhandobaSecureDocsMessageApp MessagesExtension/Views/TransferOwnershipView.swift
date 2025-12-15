//
//  TransferOwnershipView.swift
//  Khandoba Secure Docs
//
//  Apple Cash-style transfer ownership flow
//

import SwiftUI
import SwiftData
@preconcurrency import Messages

struct TransferOwnershipView: View {
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
    @State private var showFaceID = false
    @State private var isAuthenticating = false
    
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Recipient Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Transfer to")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(colors.textSecondary)
                            
                            Text("Recipient")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(colors.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Large Vault Display (Apple Cash style - exact match)
                        if let vault = selectedVault {
                            VStack(spacing: 16) {
                                Text(vault.name)
                                    .font(.system(size: 56, weight: .bold, design: .rounded))
                                    .foregroundColor(colors.textPrimary)
                                    .tracking(-1)
                                
                                Text(vault.keyType == "dual" ? "Dual-Key Vault" : "Single-Key Vault")
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .foregroundColor(colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                        
                        // Vault Rolodex
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
                        
                        // Vault Card
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
                        }
                    }
                }
                
                // Action Button (Apple Cash style - exact match)
                VStack(spacing: 0) {
                    Button(action: {
                        guard let vault = selectedVault else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showFaceID = true
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 22, weight: .semibold))
                            Text("Transfer Ownership")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colors.primary,
                                    colors.primary.opacity(0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(selectedVault == nil || isAuthenticating)
                    .opacity(selectedVault == nil || isAuthenticating ? 0.6 : 1.0)
                    .scaleEffect(selectedVault == nil || isAuthenticating ? 0.98 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedVault)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(colors.surface)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .overlay {
            if showFaceID {
                FaceIDOverlayView(
                    biometricType: BiometricAuthService.shared.biometricType()
                ) {
                    showFaceID = false
                }
                .transition(.opacity)
                .onAppear {
                    authenticateAndSend()
                }
            }
        }
        .task {
            await loadVaults()
        }
    }
    
    private func authenticateAndSend() {
        guard let vault = selectedVault else {
            showFaceID = false
            return
        }
        
        Task {
            isAuthenticating = true
            defer { isAuthenticating = false }
            
            do {
                let success = try await BiometricAuthService.shared.authenticate(
                    reason: "Authenticate to transfer vault ownership"
                )
                
                if success {
                    await MainActor.run {
                        let name = recipientName.isEmpty ? "Recipient" : recipientName
                        onSend(vault, name)
                        showFaceID = false
                    }
                } else {
                    await MainActor.run {
                        showFaceID = false
                    }
                }
            } catch {
                await MainActor.run {
                    showFaceID = false
                }
            }
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
            }
        } catch {
            print("❌ Failed to load vaults: \(error.localizedDescription)")
        }
    }
}

//
//  AcceptTransferView.swift
//  Khandoba Secure Docs
//
//  Accept vault transfer ownership view with deep link support
//

import SwiftUI
import SwiftData

struct AcceptTransferView: View {
    let transferToken: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var transferRequest: VaultTransferRequest?
    @State private var showSuccess = false
    @State private var isAccepting = false
    
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
                        Text("Loading transfer request...")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                    }
                } else if let request = transferRequest {
                    if showSuccess {
                        successView(colors: colors)
                    } else {
                        transferDetailsView(request: request, colors: colors)
                    }
                } else {
                    errorView(colors: colors)
                }
            }
            .navigationTitle("Transfer Ownership")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .task {
            await loadTransferRequest()
        }
    }
    
    // MARK: - Transfer Details View
    
    private func transferDetailsView(request: VaultTransferRequest, colors: UnifiedTheme.Colors) -> some View {
        ScrollView {
            VStack(spacing: UnifiedTheme.Spacing.xl) {
                // Header
                VStack(spacing: UnifiedTheme.Spacing.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(colors.warning)
                    
                    Text("Vault Ownership Transfer")
                        .font(theme.typography.title)
                        .foregroundColor(colors.textPrimary)
                    
                    Text("You've been offered ownership of a vault")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, UnifiedTheme.Spacing.xl)
                
                // Warning Card
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(colors.warning)
                            Text("Important")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Accepting this transfer will make you the new owner of this vault. The previous owner will lose all access. This action cannot be undone.")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                .padding(.horizontal)
                
                // Transfer Details
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        if let vault = request.vault {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                Text("Vault Name")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                                
                                Text(vault.name)
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                if let description = vault.vaultDescription {
                                    Text(description)
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                        .padding(.top, 4)
                                }
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                Text("Transferred By")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                                
                                Text("Vault Owner")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textPrimary)
                            }
                            
                            if let reason = request.reason, !reason.isEmpty {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                    Text("Reason")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                    
                                    Text(reason)
                                        .font(theme.typography.body)
                                        .foregroundColor(colors.textPrimary)
                                }
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                Text("Requested On")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                                
                                Text(request.requestedAt, style: .date)
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textPrimary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Accept Button
                Button {
                    acceptTransfer(request: request)
                } label: {
                    HStack {
                        if isAccepting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Accept Transfer")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.warning)
                    .foregroundColor(.white)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                }
                .disabled(isAccepting)
                .padding(.horizontal)
                
                // Decline Button
                Button {
                    dismiss()
                } label: {
                    Text("Decline")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.surface)
                        .foregroundColor(colors.textPrimary)
                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Success View
    
    private func successView(colors: UnifiedTheme.Colors) -> some View {
        VStack(spacing: UnifiedTheme.Spacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(colors.success)
            
            Text("Transfer Accepted!")
                .font(theme.typography.title)
                .foregroundColor(colors.textPrimary)
            
            Text("You are now the owner of this vault")
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            
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
        }
        .padding()
    }
    
    // MARK: - Error View
    
    private func errorView(colors: UnifiedTheme.Colors) -> some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.error)
            
            Text("Transfer Not Found")
                .font(theme.typography.title)
                .foregroundColor(colors.textPrimary)
            
            Text("This transfer request may have expired or been cancelled.")
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func loadTransferRequest() async {
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<VaultTransferRequest>(
                predicate: #Predicate { $0.transferToken == transferToken }
            )
            
            let requests = try modelContext.fetch(descriptor)
            
            await MainActor.run {
                transferRequest = requests.first
                isLoading = false
                
                if transferRequest == nil {
                    errorMessage = "Transfer request not found. It may have expired or been cancelled."
                    showError = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load transfer request: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }
    
    private func acceptTransfer(request: VaultTransferRequest) {
        guard let vault = request.vault,
              let currentUser = authService.currentUser else {
            errorMessage = "Unable to complete transfer. Please try again."
            showError = true
            return
        }
        
        isAccepting = true
        
        Task {
            do {
                // Update vault owner
                vault.owner = currentUser
                
                // Add vault to user's owned vaults if not already there
                if currentUser.ownedVaults == nil {
                    currentUser.ownedVaults = []
                }
                if !(currentUser.ownedVaults?.contains(where: { $0.id == vault.id }) ?? false) {
                    currentUser.ownedVaults?.append(vault)
                }
                
                // Update transfer request status
                request.status = "completed"
                request.approvedAt = Date()
                request.newOwnerID = currentUser.id
                
                // Remove vault from previous owner's owned vaults
                if let previousOwner = try? await findPreviousOwner(vault: vault) {
                    previousOwner.ownedVaults?.removeAll { $0.id == vault.id }
                }
                
                try modelContext.save()
                
                await MainActor.run {
                    showSuccess = true
                    isAccepting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to accept transfer: \(error.localizedDescription)"
                    showError = true
                    isAccepting = false
                }
            }
        }
    }
    
    private func findPreviousOwner(vault: Vault) async throws -> User? {
        // Find the user who requested the transfer
        guard let requestedByUserID = transferRequest?.requestedByUserID else {
            return nil
        }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == requestedByUserID }
        )
        
        return try modelContext.fetch(descriptor).first
    }
}


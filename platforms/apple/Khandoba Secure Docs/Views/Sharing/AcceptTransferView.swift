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
    @EnvironmentObject var supabaseService: SupabaseService
    
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
        print("🔄 Loading transfer request with token: \(transferToken)")
        isLoading = true
        
        do {
            // Supabase mode - exclusive use when enabled
            if AppConfig.useSupabase {
                guard let supabaseService = supabaseService else {
                    throw TransferError.serviceNotConfigured
                }
                
                // Fetch transfer request from Supabase
                let filters: [String: Any] = ["transfer_token": transferToken]
                let supabaseRequests: [SupabaseVaultTransferRequest] = try await supabaseService.fetchAll(
                    "vault_transfer_requests",
                    filters: filters
                )
                
                print("   Found \(supabaseRequests.count) transfer request(s) in Supabase")
                
                guard let supabaseRequest = supabaseRequests.first else {
                    await MainActor.run {
                        print("   ❌ Transfer request not found in Supabase")
                        errorMessage = "Transfer request not found. It may have expired or been cancelled."
                        showError = true
                        isLoading = false
                    }
                    return
                }
                
                // Fetch vault and user data
                let vaultID = supabaseRequest.vaultID
                let vaultFilters: [String: Any] = ["id": vaultID.uuidString]
                let supabaseVaults: [SupabaseVault] = try await supabaseService.fetchAll(
                    "vaults",
                    filters: vaultFilters
                )
                
                guard let supabaseVault = supabaseVaults.first else {
                    await MainActor.run {
                        print("   ❌ Vault not found for transfer request")
                        errorMessage = "Vault associated with transfer request not found."
                        showError = true
                        isLoading = false
                    }
                    return
                }
                
                // Convert to SwiftData model for UI compatibility
                // Note: This is a temporary conversion - in full Supabase mode, we'd use Supabase models directly
                let request = VaultTransferRequest(
                    reason: supabaseRequest.reason,
                    newOwnerName: supabaseRequest.newOwnerName,
                    newOwnerPhone: supabaseRequest.newOwnerPhone,
                    newOwnerEmail: supabaseRequest.newOwnerEmail
                )
                request.id = supabaseRequest.id
                request.transferToken = supabaseRequest.transferToken
                request.status = supabaseRequest.status
                request.requestedAt = supabaseRequest.requestedAt
                request.approvedAt = supabaseRequest.approvedAt
                request.newOwnerID = supabaseRequest.newOwnerID
                request.requestedByUserID = supabaseRequest.requestedByUserID
                request.approverID = supabaseRequest.approverID
                
                // Create a temporary Vault object for display
                let vault = Vault(
                    name: supabaseVault.name,
                    vaultDescription: supabaseVault.vaultDescription,
                    isDualKey: supabaseVault.isDualKey,
                    ownerID: supabaseVault.ownerID
                )
                vault.id = supabaseVault.id
                request.vault = vault
                
                await MainActor.run {
                    transferRequest = request
                    isLoading = false
                    print("   ✅ Transfer request loaded: \(vault.name)")
                }
                return
            }
            
            // SwiftData/CloudKit mode
            let descriptor = FetchDescriptor<VaultTransferRequest>(
                predicate: #Predicate { $0.transferToken == transferToken }
            )
            
            let requests = try modelContext.fetch(descriptor)
            print("   Found \(requests.count) transfer request(s)")
            
            await MainActor.run {
                transferRequest = requests.first
                isLoading = false
                
                if transferRequest == nil {
                    print("   ❌ Transfer request not found")
                    errorMessage = "Transfer request not found. It may have expired or been cancelled."
                    showError = true
                } else {
                    print("   ✅ Transfer request loaded: \(transferRequest?.vault?.name ?? "Unknown vault")")
                }
            }
        } catch {
            print("   ❌ Error loading transfer request: \(error.localizedDescription)")
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
        
        // Validation: Check if user is already the owner
        if vault.owner?.id == currentUser.id {
            errorMessage = "You are already the owner of this vault."
            showError = true
            return
        }
        
        // Validation: Check transfer request status
        if request.status == "completed" {
            errorMessage = "This transfer has already been completed."
            showError = true
            return
        }
        
        // Validation: Check if transfer request is still valid (not expired)
        // Transfer requests expire after 30 days
        // requestedAt is non-optional, so we can use it directly
        if Date().timeIntervalSince(request.requestedAt) > 30 * 24 * 60 * 60 {
            errorMessage = "This transfer request has expired. Please ask the owner to create a new transfer request."
            showError = true
            return
        }
        
        isAccepting = true
        
        Task {
            do {
                // Supabase mode - exclusive use when enabled
                if AppConfig.useSupabase {
                    guard let supabaseService = supabaseService else {
                        throw TransferError.serviceNotConfigured
                    }
                    
                    print("🔄 Accepting transfer in Supabase mode...")
                    
                    // Update vault owner in Supabase
                    let vaultUpdate: [String: Any] = [
                        "owner_id": currentUser.id.uuidString,
                        "updated_at": ISO8601DateFormatter().string(from: Date())
                    ]
                    let _: SupabaseVault = try await supabaseService.update(
                        "vaults",
                        id: vault.id.uuidString,
                        values: vaultUpdate
                    )
                    
                    // Update transfer request status in Supabase
                    let requestUpdate: [String: Any] = [
                        "status": "completed",
                        "new_owner_id": currentUser.id.uuidString,
                        "approved_at": ISO8601DateFormatter().string(from: Date()),
                        "updated_at": ISO8601DateFormatter().string(from: Date())
                    ]
                    let _: SupabaseVaultTransferRequest = try await supabaseService.update(
                        "vault_transfer_requests",
                        id: request.id.uuidString,
                        values: requestUpdate
                    )
                    
                    // Update nominees to inactive (new owner will need to re-invite)
                    let nomineeFilters: [String: Any] = ["vault_id": vault.id.uuidString]
                    let nominees: [SupabaseNominee] = try await supabaseService.fetchAll(
                        "nominees",
                        filters: nomineeFilters
                    )
                    
                    for nominee in nominees {
                        let nomineeUpdate: [String: Any] = [
                            "status": "inactive",
                            "updated_at": ISO8601DateFormatter().string(from: Date())
                        ]
                        let _: SupabaseNominee = try await supabaseService.update(
                            "nominees",
                            id: nominee.id.uuidString,
                            values: nomineeUpdate
                        )
                    }
                    
                    await MainActor.run {
                        showSuccess = true
                        isAccepting = false
                        print("✅ Transfer ownership completed successfully in Supabase")
                    }
                    return
                }
                
                // SwiftData/CloudKit mode
                // Transfer CloudKit share ownership first (if share exists)
                let cloudKitSharing = CloudKitSharingService()
                cloudKitSharing.configure(modelContext: modelContext)
                
                do {
                    // Check if CloudKit share exists (we don't need the share object itself)
                    if try await cloudKitSharing.getOrCreateShare(for: vault) != nil {
                        print("🔄 Transferring CloudKit share ownership...")
                        // Note: CloudKit share ownership transfer requires updating the share's owner
                        // This is handled by CloudKit when the new owner accepts the share
                        // For now, we update local ownership and CloudKit will sync
                        print("   ℹ️ CloudKit share ownership will be updated when share is accepted")
                    }
                } catch {
                    print("⚠️ CloudKit share not available for transfer: \(error.localizedDescription)")
                    // Continue with local transfer even if CloudKit fails
                }
                
                // Find and update previous owner
                let previousOwner = try await findPreviousOwner(vault: vault)
                
                // Update vault owner
                vault.owner = currentUser
                
                // Add vault to user's owned vaults if not already there
                if currentUser.ownedVaults == nil {
                    currentUser.ownedVaults = []
                }
                if !(currentUser.ownedVaults?.contains(where: { $0.id == vault.id }) ?? false) {
                    currentUser.ownedVaults?.append(vault)
                }
                
                // Remove vault from previous owner's owned vaults
                if let previousOwner = previousOwner {
                    previousOwner.ownedVaults?.removeAll { $0.id == vault.id }
                    
                    // Revoke all nominees from previous owner's perspective
                    // New owner will need to re-invite if needed
                    if let nominees = vault.nomineeList {
                        for nominee in nominees {
                            // Mark nominees as needing re-invitation
                            // Don't delete them - new owner may want to keep them
                            nominee.status = .inactive
                        }
                    }
                }
                
                // Update transfer request status
                request.status = "completed"
                request.approvedAt = Date()
                request.newOwnerID = currentUser.id
                
                try modelContext.save()
                
                // Force CloudKit sync
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                try modelContext.save()
                
                await MainActor.run {
                    showSuccess = true
                    isAccepting = false
                    print("✅ Transfer ownership completed successfully")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to accept transfer: \(error.localizedDescription)"
                    showError = true
                    isAccepting = false
                    print("❌ Transfer ownership failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func findPreviousOwner(vault: Vault) async throws -> User? {
        // Find the user who requested the transfer
        guard let requestedByUserID = transferRequest?.requestedByUserID else {
            // Fallback: Use current vault owner
            return vault.owner
        }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == requestedByUserID }
        )
        
        if let previousOwner = try modelContext.fetch(descriptor).first {
            return previousOwner
        }
        
        // Fallback: Use current vault owner if transfer requester not found
        return vault.owner
    }
}

// MARK: - Transfer Error
// Note: TransferError is defined in TransferOwnershipView.swift to avoid duplication


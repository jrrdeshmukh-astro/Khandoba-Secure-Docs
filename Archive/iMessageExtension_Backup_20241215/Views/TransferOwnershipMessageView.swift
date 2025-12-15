//
//  TransferOwnershipMessageView.swift
//  Khandoba Secure Docs
//
//  Transfer ownership view for iMessage app
//

import SwiftUI
import Messages
import SwiftData

struct TransferOwnershipMessageView: View {
    let conversation: MSConversation
    let preselectedVault: Vault?
    let onSendTransfer: (String, String, String) -> Void
    let onCancel: () -> Void
    
    init(conversation: MSConversation, preselectedVault: Vault? = nil, onSendTransfer: @escaping (String, String, String) -> Void, onCancel: @escaping () -> Void) {
        self.conversation = conversation
        self.preselectedVault = preselectedVault
        self.onSendTransfer = onSendTransfer
        self.onCancel = onCancel
    }
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vaultName: String = ""
    @State private var recipientName: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var vaults: [Vault] = []
    @State private var selectedVault: Vault?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var modelContext: ModelContext?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
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
                                
                                Text("Transferring ownership is permanent. The new owner will have complete control over this vault and all its documents. You will lose all access.")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                        
                        // Vault Selection
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                            Text("Select Vault")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                            
                            if vaults.isEmpty {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Loading vaults...")
                                        .font(theme.typography.body)
                                        .foregroundColor(colors.textSecondary)
                                }
                                .padding(UnifiedTheme.Spacing.md)
                                .frame(maxWidth: .infinity)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            } else {
                                Picker("Vault", selection: $selectedVault) {
                                    ForEach(vaults) { vault in
                                        Text(vault.name).tag(vault as Vault?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(UnifiedTheme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                .onChange(of: selectedVault) { _, newValue in
                                    if let vault = newValue {
                                        vaultName = vault.name
                                    }
                                }
                            }
                        }
                        
                        // Recipient Details
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                            Text("New Owner Name")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                            
                            TextField("Recipient name", text: $recipientName)
                                .font(theme.typography.body)
                                .padding(UnifiedTheme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                            Text("Phone Number (Optional)")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                            
                            TextField("+1 (555) 123-4567", text: $phoneNumber)
                                .font(theme.typography.body)
                                .keyboardType(.phonePad)
                                .padding(UnifiedTheme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                            Text("Email (Optional)")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                            
                            TextField("email@example.com", text: $email)
                                .font(theme.typography.body)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .padding(UnifiedTheme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        
                        if selectedVault != nil {
                            StandardCard {
                                HStack {
                                    Image(systemName: "lock.shield.fill")
                                        .foregroundColor(colors.warning)
                                    Text("Vault: \(vaultName)")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                        }
                        
                        Button {
                            sendTransferRequest()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Transfer Request")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(vaultName.isEmpty || recipientName.isEmpty || isLoading)
                    }
                    .padding(UnifiedTheme.Spacing.lg)
                }
            }
            .navigationTitle("Transfer Ownership")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadVaults()
            }
        }
    }
    
    private func loadVaults() {
        Task {
            do {
                // Use shared container
                let container = try await SharedModelContainer.containerWithTimeout(seconds: 8)
                let context = container.mainContext
                
                print("📦 iMessage Extension (Transfer): ModelContainer created with App Group: \(MessageAppConfig.appGroupIdentifier)")
                
                // Give CloudKit a moment to sync if needed
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                let descriptor = FetchDescriptor<Vault>(
                    sortBy: [SortDescriptor<Vault>(\.createdAt, order: .reverse)]
                )
                
                let fetchedVaults = try context.fetch(descriptor)
                
                print("📦 iMessage Extension (Transfer): Fetched \(fetchedVaults.count) vault(s) from shared container")
                
                await MainActor.run {
                    vaults = fetchedVaults.filter { !$0.isSystemVault }
                    
                    // Use preselected vault if provided, otherwise use first vault
                    if let preselected = preselectedVault,
                       let matchingVault = vaults.first(where: { $0.id == preselected.id }) {
                        selectedVault = matchingVault
                        vaultName = matchingVault.name
                    } else if let firstVault = vaults.first {
                        selectedVault = firstVault
                        vaultName = firstVault.name
                    }
                    modelContext = context
                }
            } catch {
                print("❌ Failed to load vaults: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "Failed to load vaults. Please ensure you have created a vault in the main app first, then try again."
                    showError = true
                }
            }
        }
    }
    
    private func sendTransferRequest() {
        guard !vaultName.isEmpty, !recipientName.isEmpty else {
            errorMessage = "Please select a vault and enter recipient name"
            showError = true
            return
        }
        
        guard let vault = selectedVault else {
            errorMessage = "Please select a vault"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Create transfer request
                let transferToken = UUID().uuidString
                
                if let context = modelContext {
                    let userDescriptor = FetchDescriptor<User>()
                    let users = try context.fetch(userDescriptor)
                    guard let currentUser = users.first else {
                        throw NSError(domain: "MessageApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user found"])
                    }
                    
                    let transferRequest = VaultTransferRequest(
                        newOwnerName: recipientName,
                        newOwnerPhone: phoneNumber.isEmpty ? nil : phoneNumber,
                        newOwnerEmail: email.isEmpty ? nil : email,
                        transferToken: transferToken
                    )
                    transferRequest.vault = vault
                    transferRequest.requestedByUserID = currentUser.id
                    
                    if vault.transferRequests == nil {
                        vault.transferRequests = []
                    }
                    vault.transferRequests?.append(transferRequest)
                    
                    context.insert(transferRequest)
                    try context.save()
                }
                
                await MainActor.run {
                    onSendTransfer(transferToken, vaultName, recipientName)
                    isLoading = false
                }
            } catch {
                print("❌ Failed to create transfer request: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "Failed to create transfer request: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}


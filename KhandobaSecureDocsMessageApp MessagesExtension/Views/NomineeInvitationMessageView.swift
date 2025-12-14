//
//  NomineeInvitationMessageView.swift
//  Khandoba Secure Docs
//
//  Nominee invitation view for iMessage app
//

import SwiftUI
import Messages
import SwiftData

struct NomineeInvitationMessageView: View {
    let conversation: MSConversation
    let onSendInvitation: (String, String, String) -> Void
    let onCancel: () -> Void
    
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
                                .onChange(of: selectedVault) { newValue in
                                    if let vault = newValue {
                                        vaultName = vault.name
                                    }
                                }
                            }
                        }
                        
                        // Recipient Details
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                            Text("Recipient Name")
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
                                        .foregroundColor(colors.info)
                                    Text("Vault: \(vaultName)")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                        }
                        
                        Button {
                            sendInvitation()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Invitation")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(vaultName.isEmpty || recipientName.isEmpty || isLoading)
                    }
                    .padding(UnifiedTheme.Spacing.lg)
                }
            }
            .navigationTitle("Invite Nominee")
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
                let schema = Schema([Vault.self, User.self, Nominee.self])
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
                
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                let context = container.mainContext
                
                let descriptor = FetchDescriptor<Vault>(
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                
                let fetchedVaults = try context.fetch(descriptor)
                
                await MainActor.run {
                    vaults = fetchedVaults.filter { !$0.isSystemVault }
                    
                    // Check if there's a pending vault ID from main app
                    let appGroupID = "group.com.khandoba.securedocs"
                    if let sharedDefaults = UserDefaults(suiteName: appGroupID),
                       let vaultIDString = sharedDefaults.string(forKey: "pending_nominee_vault_id"),
                       let vaultID = UUID(uuidString: vaultIDString) {
                        // Find the vault with matching ID
                        if let pendingVault = vaults.first(where: { $0.id == vaultID }) {
                            selectedVault = pendingVault
                            vaultName = pendingVault.name
                            print("✅ Pre-selected vault from main app: \(pendingVault.name)")
                            
                            // Clear the stored vault ID after using it
                            sharedDefaults.removeObject(forKey: "pending_nominee_vault_id")
                            sharedDefaults.removeObject(forKey: "pending_nominee_vault_name")
                            sharedDefaults.synchronize()
                        } else {
                            // Vault not found, use first vault as fallback
                            if let firstVault = vaults.first {
                                selectedVault = firstVault
                                vaultName = firstVault.name
                            }
                        }
                    } else {
                        // No pending vault, use first vault
                        if let firstVault = vaults.first {
                            selectedVault = firstVault
                            vaultName = firstVault.name
                        }
                    }
                    
                    modelContext = context
                }
            } catch {
                print("❌ Failed to load vaults: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "Failed to load vaults: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func sendInvitation() {
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
                // Create nominee
                let inviteToken = UUID().uuidString
                
                if let context = modelContext {
                    let userDescriptor = FetchDescriptor<User>()
                    let users = try context.fetch(userDescriptor)
                    guard let currentUser = users.first else {
                        throw NSError(domain: "MessageApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user found"])
                    }
                    
                    let nominee = Nominee(
                        name: recipientName,
                        phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                        email: email.isEmpty ? nil : email
                    )
                    nominee.vault = vault
                    nominee.invitedByUserID = currentUser.id
                    nominee.inviteToken = inviteToken
                    
                    if vault.nomineeList == nil {
                        vault.nomineeList = []
                    }
                    vault.nomineeList?.append(nominee)
                    
                    context.insert(nominee)
                    try context.save()
                }
                
                await MainActor.run {
                    onSendInvitation(inviteToken, vaultName, recipientName)
                    isLoading = false
                }
            } catch {
                print("❌ Failed to create invitation: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "Failed to create invitation: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

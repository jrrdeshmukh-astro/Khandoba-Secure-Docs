//
//  NomineeInvitationMessageView.swift
//  Khandoba Secure Docs
//
//  Nominee invitation view for iMessage app
//

import SwiftUI
import Messages
import SwiftData
import Foundation

struct NomineeInvitationMessageView: View {
    let conversation: MSConversation
    let onSendInvitation: (String, String, String) -> Void
    let onCancel: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vaultName: String = ""
    @State private var recipientName: String = ""
    @State private var isLoading = false
    @State private var isLoadingVaults = true
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
                            
                            if isLoadingVaults {
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
                            } else if vaults.isEmpty {
                                StandardCard {
                                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                                        Image(systemName: "lock.shield.fill")
                                            .font(.title2)
                                            .foregroundColor(colors.textTertiary)
                                        Text("No Vaults Available")
                                            .font(theme.typography.subheadline)
                                            .foregroundColor(colors.textPrimary)
                                        Text("Create a vault in the main app first")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, UnifiedTheme.Spacing.md)
                                }
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
        isLoadingVaults = true
        
        Task {
            // Add timeout to prevent infinite loading
            do {
                // Try to load with timeout
                try await withTimeout(seconds: 10) {
                    // Use the same schema as main app for compatibility
                    let schema = Schema([
                        User.self,
                        UserRole.self,
                        Vault.self,
                        VaultSession.self,
                        VaultAccessLog.self,
                        DualKeyRequest.self,
                        Document.self,
                        DocumentVersion.self,
                        ChatMessage.self,
                        Nominee.self,
                        VaultTransferRequest.self,
                        VaultAccessRequest.self,
                        EmergencyAccessRequest.self
                    ])
                    
                    // Use App Group for shared storage with main app
                    // This is CRITICAL - without this, the extension can't access the main app's data
                    let appGroupIdentifier = "group.com.khandoba.securedocs"
                    
                    // Ensure Application Support directory exists in App Group
                    // This prevents CoreData errors about missing directories
                    if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
                        let appSupportURL = appGroupURL.appendingPathComponent("Library/Application Support", isDirectory: true)
                        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
                        print("📦 iMessage Extension: Ensured Application Support directory exists")
                    }
                    
                    let modelConfiguration = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: false,
                        groupContainer: .identifier(appGroupIdentifier),
                        cloudKitDatabase: .automatic
                    )
                    
                    let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                    let context = container.mainContext
                    
                    print("📦 iMessage Extension: ModelContainer created with App Group: \(appGroupIdentifier)")
                    
                    // Give CloudKit a moment to sync if needed
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    
                    let descriptor = FetchDescriptor<Vault>(
                        sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                    )
                    
                    let fetchedVaults = try context.fetch(descriptor)
                    
                    print("📦 iMessage Extension: Fetched \(fetchedVaults.count) vault(s) from shared container")
                    for vault in fetchedVaults {
                        print("   - \(vault.name) (ID: \(vault.id), System: \(vault.isSystemVault))")
                    }
                    
                    await MainActor.run {
                        vaults = fetchedVaults.filter { !$0.isSystemVault }
                        isLoadingVaults = false
                        print("📦 iMessage Extension: Filtered to \(vaults.count) non-system vault(s)")
                        
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
                }
            } catch {
                print("❌ Failed to load vaults: \(error.localizedDescription)")
                print("❌ Error details: \(error)")
                
                // Check if it's a timeout error
                if error is TimeoutError {
                    await MainActor.run {
                        isLoadingVaults = false
                        errorMessage = "Loading vaults timed out. Please check your connection and try again."
                        showError = true
                    }
                } else {
                    await MainActor.run {
                        isLoadingVaults = false
                        errorMessage = "Failed to load vaults. Please ensure you have created a vault in the main app first, then try again."
                        showError = true
                    }
                }
            }
        }
    }
    
    // Helper function for timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            group.cancelAll()
            return result
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
                        phoneNumber: nil,
                        email: nil
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

// MARK: - Timeout Error
private struct TimeoutError: Error {
    var localizedDescription: String {
        "Operation timed out"
    }
}

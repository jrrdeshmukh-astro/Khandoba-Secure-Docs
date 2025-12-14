//
//  VaultSelectionMessageView.swift
//  Khandoba Secure Docs
//
//  Apple Pay-style vault selection interface for iMessage extension
//

import SwiftUI
import Messages
import SwiftData
import Foundation

struct VaultSelectionMessageView: View {
    let conversation: MSConversation
    let onTransfer: (Vault) -> Void
    let onNominate: (Vault) -> Void
    let onCancel: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vaults: [Vault] = []
    @State private var selectedIndex: Int = 0
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var modelContext: ModelContext?
    @State private var isAuthenticated = false
    
    var selectedVault: Vault? {
        guard !vaults.isEmpty, selectedIndex >= 0, selectedIndex < vaults.count else {
            return nil
        }
        return vaults[selectedIndex]
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background.ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: UnifiedTheme.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading vaults...")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                }
            } else if vaults.isEmpty {
                VStack(spacing: UnifiedTheme.Spacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 50))
                        .foregroundColor(colors.textTertiary)
                    Text("No Vaults Available")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    Text("Create a vault in the main app first")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
            } else {
                VStack(spacing: UnifiedTheme.Spacing.xl) {
                    // Vault Selection Display (Apple Pay style)
                    HStack(spacing: UnifiedTheme.Spacing.xl) {
                        // Left Arrow
                        Button {
                            selectPreviousVault()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(colors.primary)
                                .frame(width: 50, height: 50)
                                .background(colors.surface)
                                .clipShape(Circle())
                        }
                        .disabled(selectedIndex == 0)
                        .opacity(selectedIndex == 0 ? 0.3 : 1.0)
                        
                        // Vault Display (Center)
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            if let vault = selectedVault {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(colors.primary)
                                
                                Text(vault.name)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(colors.textPrimary)
                                
                                Text("Vault \(selectedIndex + 1) of \(vaults.count)")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                                
                                if let owner = vault.owner {
                                    Text("Owner: \(owner.fullName)")
                                        .font(theme.typography.caption2)
                                        .foregroundColor(colors.textTertiary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right Arrow
                        Button {
                            selectNextVault()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(colors.primary)
                                .frame(width: 50, height: 50)
                                .background(colors.surface)
                                .clipShape(Circle())
                        }
                        .disabled(selectedIndex >= vaults.count - 1)
                        .opacity(selectedIndex >= vaults.count - 1 ? 0.3 : 1.0)
                    }
                    .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    .padding(.vertical, UnifiedTheme.Spacing.lg)
                    
                    // Action Buttons
                    HStack(spacing: UnifiedTheme.Spacing.md) {
                        // Transfer Button
                        Button {
                            if let vault = selectedVault {
                                onTransfer(vault)
                            }
                        } label: {
                            Text("Transfer")
                                .font(theme.typography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.warning)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        .disabled(selectedVault == nil)
                        
                        // Nominate Button
                        Button {
                            if let vault = selectedVault {
                                onNominate(vault)
                            }
                        } label: {
                            Text("Nominate")
                                .font(theme.typography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.primary)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        .disabled(selectedVault == nil)
                    }
                    .padding(.horizontal, UnifiedTheme.Spacing.lg)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await loadVaults()
        }
    }
    
    private func selectPreviousVault() {
        guard selectedIndex > 0 else { return }
        withAnimation {
            selectedIndex -= 1
        }
    }
    
    private func selectNextVault() {
        guard selectedIndex < vaults.count - 1 else { return }
        withAnimation {
            selectedIndex += 1
        }
    }
    
    private func loadVaults() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Add timeout to prevent infinite hanging
        do {
            try await withTimeout(seconds: 8) {
                try await performVaultLoad()
            }
        } catch is TimeoutError {
            print("⏱️ Vault loading timed out")
            await MainActor.run {
                isLoading = false
                errorMessage = "Loading vaults timed out. Please try again."
                showError = true
            }
        } catch {
            print("❌ Failed to load vaults: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to load vaults: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func performVaultLoad() async throws {
        // Use the same schema as main app
        let schema = Schema([
            User.self,
            Vault.self,
            Nominee.self
        ])
        
        let appGroupIdentifier = "group.com.khandoba.securedocs"
        
        // Verify App Group is accessible (check entitlements)
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            let error = NSError(
                domain: "VaultSelectionError",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "App Group not accessible. Please ensure the iMessage extension has the App Group capability enabled in Xcode (Signing & Capabilities)."
                ]
            )
            throw error
        }
        
        // Ensure Application Support directory exists
        let appSupportURL = appGroupURL.appendingPathComponent("Library/Application Support", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
        
        print("📦 App Group URL verified: \(appGroupURL.path)")
        
        // Create ModelContainer (this can be slow with CloudKit)
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier),
            cloudKitDatabase: .automatic
        )
        
        // Run container creation in background to avoid blocking
        let container = try await Task.detached(priority: .userInitiated) {
            try ModelContainer(for: schema, configurations: [modelConfiguration])
        }.value
        
        let context = container.mainContext
        
        // Check authentication - verify user exists
        let userDescriptor = FetchDescriptor<User>()
        let users = try context.fetch(userDescriptor)
        
        if users.isEmpty {
            await MainActor.run {
                isLoading = false
                errorMessage = "Please sign in to the main app first"
                showError = true
            }
            return
        }
        
        // Load vaults
        let vaultDescriptor = FetchDescriptor<Vault>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allVaults = try context.fetch(vaultDescriptor)
        let availableVaults = allVaults.filter { !$0.isSystemVault }
        
        print("📦 VaultSelectionMessageView: Loaded \(availableVaults.count) vault(s)")
        
        await MainActor.run {
            vaults = availableVaults
            selectedIndex = 0
            isLoading = false
            isAuthenticated = true
            modelContext = context
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
}

// MARK: - Timeout Error
private struct TimeoutError: Error {
    var localizedDescription: String {
        "Operation timed out"
    }
}

//
//  CreateVaultView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct CreateVaultView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var vaultService: VaultService
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    
    @State private var name = ""
    @State private var description = ""
    @State private var keyType: KeyType = .single
    @State private var vaultType: VaultType = .both
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum KeyType: String, CaseIterable {
        case single = "single"
        case dual = "dual"
        
        var displayName: String {
            switch self {
            case .single: return "Single Key"
            case .dual: return "Dual Key"
            }
        }
        
        var description: String {
            switch self {
            case .single: return "You have full access"
            case .dual: return "Requires admin approval"
            }
        }
    }
    
    enum VaultType: String, CaseIterable {
        case source = "source"
        case sink = "sink"
        case both = "both"
        
        var displayName: String {
            switch self {
            case .source: return "Source Vault"
            case .sink: return "Sink Vault"
            case .both: return "Mixed Vault"
            }
        }
        
        var description: String {
            switch self {
            case .source: return "For live recordings (camera, voice)"
            case .sink: return "For uploads from external apps"
            case .both: return "For both live recordings and uploads"
            }
        }
        
        var icon: String {
            switch self {
            case .source: return "camera.fill"
            case .sink: return "arrow.down.circle.fill"
            case .both: return "arrow.up.arrow.down.circle.fill"
            }
        }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Name
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                            Text("Vault Name")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                            
                            TextField("Enter vault name", text: $name)
                                .font(theme.typography.body)
                                .padding(UnifiedTheme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                            Text("Description (Optional)")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                            
                            TextField("Enter description", text: $description)
                                .font(theme.typography.body)
                                .padding(UnifiedTheme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        
                        // Key Type
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Key Type")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                            
                            ForEach(KeyType.allCases, id: \.self) { type in
                                KeyTypeRow(
                                    type: type,
                                    isSelected: keyType == type
                                ) {
                                    keyType = type
                                }
                            }
                        }
                        
                        // Vault Type Selection
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Vault Type")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                            
                            ForEach(VaultType.allCases, id: \.self) { type in
                                VaultTypeRow(
                                    type: type,
                                    isSelected: vaultType == type
                                ) {
                                    vaultType = type
                                }
                            }
                        }
                        
                        // Create Button
                        Button {
                            createVault()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Vault")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(name.isEmpty || isLoading)
                    }
                    .padding(UnifiedTheme.Spacing.lg)
                }
            }
            .navigationTitle("New Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .overlay {
                if isLoading {
                    LoadingOverlay(message: "Creating vault...")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createVault() {
        isLoading = true
        Task {
            do {
                // Ensure vault service is configured with current user
                await ensureVaultServiceConfigured()
                
                // Create vault
                _ = try await vaultService.createVault(
                    name: name,
                    description: description.isEmpty ? nil : description,
                    keyType: keyType.rawValue,
                    vaultType: vaultType.rawValue
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = ErrorHandler.userFriendlyMessage(for: error)
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func ensureVaultServiceConfigured() async {
        // Check if vault service has a user ID configured
        // If not, configure it with the current user
        guard let userID = authService.currentUser?.id else {
            await MainActor.run {
                errorMessage = "Please sign in to create a vault."
                showError = true
                isLoading = false
            }
            return
        }
        
        // Check if service is already configured
        // We can't directly check, so we'll try to configure it anyway
        // The configure method is idempotent
        if AppConfig.useSupabase {
            await MainActor.run {
                vaultService.configure(supabaseService: supabaseService, userID: userID)
            }
        } else {
            await MainActor.run {
                vaultService.configure(modelContext: modelContext, userID: userID)
            }
        }
    }
}

struct VaultTypeRow: View {
    let type: CreateVaultView.VaultType
    let isSelected: Bool
    let action: () -> Void
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(colors.primary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(theme.typography.body)
                        .foregroundColor(colors.textPrimary)
                    
                    Text(type.description)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? colors.primary : colors.textTertiary)
            }
            .padding(UnifiedTheme.Spacing.md)
            .background(isSelected ? colors.primary.opacity(0.1) : colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
        }
    }
    
    private var colors: UnifiedTheme.Colors {
        theme.colors(for: colorScheme)
    }
}

struct KeyTypeRow: View {
    let type: CreateVaultView.KeyType
    let isSelected: Bool
    let action: () -> Void
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: action) {
            StandardCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.displayName)
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text(type.description)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(colors.primary)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(colors.textTertiary)
                    }
                }
            }
        }
    }
}


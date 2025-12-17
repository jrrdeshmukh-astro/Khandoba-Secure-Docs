//
//  VaultRequestView.swift
//  Khandoba Secure Docs
//
//  Zelle-like interface for requesting and sending vault access
//

import SwiftUI
import SwiftData

struct VaultRequestView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    
    @StateObject private var requestService = VaultRequestService()
    @StateObject private var nomineeService = NomineeService()
    
    @State private var selectedTab: RequestTab = .request
    @State private var selectedVault: Vault?
    @State private var recipientEmail: String = ""
    @State private var recipientPhone: String = ""
    @State private var recipientName: String = ""
    @State private var message: String = ""
    @State private var showVaultPicker = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum RequestTab {
        case request
        case send
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Selector (Zelle-style)
                    HStack(spacing: 0) {
                        tabButton("Request Access", tab: .request, colors: colors)
                        tabButton("Send Access", tab: .send, colors: colors)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: UnifiedTheme.Spacing.lg) {
                            if selectedTab == .request {
                                requestAccessView(colors: colors)
                            } else {
                                sendAccessView(colors: colors)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Vault Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.textSecondary)
                }
            }
            .sheet(isPresented: $showVaultPicker) {
                VaultPickerView(selectedVault: $selectedVault)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(selectedTab == .request 
                     ? "Vault access request sent successfully"
                     : "Vault access sent successfully")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .task {
            await configureServices()
            try? await requestService.loadRequests()
        }
    }
    
    // MARK: - Tab Button
    
    private func tabButton(_ title: String, tab: RequestTab, colors: UnifiedTheme.Colors) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: UnifiedTheme.Spacing.xs) {
                Text(title)
                    .font(theme.typography.headline)
                    .foregroundColor(selectedTab == tab ? colors.primary : colors.textSecondary)
                
                Rectangle()
                    .fill(selectedTab == tab ? colors.primary : Color.clear)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Request Access View (Like "Request Money")
    
    private func requestAccessView(colors: UnifiedTheme.Colors) -> some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            // Instructions
            Text("Request access to a vault from its owner")
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            // Vault Selection
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    Text("Select Vault")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                    
                    Button {
                        showVaultPicker = true
                    } label: {
                        HStack {
                            Text(selectedVault?.name ?? "Choose a vault")
                                .font(theme.typography.body)
                                .foregroundColor(selectedVault != nil ? colors.textPrimary : colors.textSecondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(colors.textTertiary)
                        }
                    }
                }
            }
            
            // Owner Contact Info
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                    Text("Owner Contact")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                    
                    TextField("Email or Phone", text: $recipientEmail)
                        .textFieldStyle(.plain)
                        .font(theme.typography.body)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                    
                    Text("Enter the vault owner's email or phone number")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textTertiary)
                }
            }
            
            // Optional Message
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    Text("Message (Optional)")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                    
                    TextField("Add a message...", text: $message, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(theme.typography.body)
                        .lineLimit(3...6)
                        .padding()
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                }
            }
            
            // Request Button
            Button {
                Task {
                    await requestAccess()
                }
            } label: {
                HStack {
                    if requestService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Request Access")
                    }
                }
                .font(theme.typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(colors.primary)
                .cornerRadius(UnifiedTheme.CornerRadius.lg)
            }
            .disabled(requestService.isLoading || selectedVault == nil || recipientEmail.isEmpty)
            .opacity((selectedVault != nil && !recipientEmail.isEmpty) ? 1.0 : 0.6)
        }
    }
    
    // MARK: - Send Access View (Like "Send Money")
    
    private func sendAccessView(colors: UnifiedTheme.Colors) -> some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            // Instructions
            Text("Send vault access to someone")
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            // Vault Selection
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    Text("Your Vault")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                    
                    Button {
                        showVaultPicker = true
                    } label: {
                        HStack {
                            Text(selectedVault?.name ?? "Choose your vault")
                                .font(theme.typography.body)
                                .foregroundColor(selectedVault != nil ? colors.textPrimary : colors.textSecondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(colors.textTertiary)
                        }
                    }
                }
            }
            
            // Recipient Info
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                    Text("Recipient")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                    
                    TextField("Name", text: $recipientName)
                        .textFieldStyle(.plain)
                        .font(theme.typography.body)
                        .padding()
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                    
                    TextField("Email or Phone", text: $recipientEmail)
                        .textFieldStyle(.plain)
                        .font(theme.typography.body)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                }
            }
            
            // Optional Message
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    Text("Message (Optional)")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                    
                    TextField("Add a message...", text: $message, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(theme.typography.body)
                        .lineLimit(3...6)
                        .padding()
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                }
            }
            
            // Send Button
            Button {
                Task {
                    await sendAccess()
                }
            } label: {
                HStack {
                    if requestService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Send Access")
                    }
                }
                .font(theme.typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(colors.primary)
                .cornerRadius(UnifiedTheme.CornerRadius.lg)
            }
            .disabled(requestService.isLoading || selectedVault == nil || recipientEmail.isEmpty)
            .opacity((selectedVault != nil && !recipientEmail.isEmpty) ? 1.0 : 0.6)
        }
    }
    
    // MARK: - Actions
    
    private func configureServices() async {
        var cloudKitSharing: CloudKitSharingService? = nil
        
        if AppConfig.useSupabase {
            nomineeService.configure(
                supabaseService: supabaseService,
                currentUserID: authService.currentUser?.id
            )
        } else {
            cloudKitSharing = CloudKitSharingService()
            cloudKitSharing?.configure(modelContext: modelContext)

            nomineeService.configure(
                modelContext: modelContext,
                currentUserID: authService.currentUser?.id
            )
        }
        
        requestService.configure(
            modelContext: modelContext,
            currentUserID: authService.currentUser?.id,
            cloudKitSharing: cloudKitSharing,
            nomineeService: nomineeService
        )
    }
    
    private func requestAccess() async {
        guard let vault = selectedVault else { return }
        
        do {
            // Parse email/phone
            let email = recipientEmail.contains("@") ? recipientEmail : nil
            let phone = recipientEmail.contains("@") ? nil : recipientEmail
            
            _ = try await requestService.requestVaultAccess(
                vault: vault,
                from: email,
                from: phone,
                message: message.isEmpty ? nil : message
            )
            
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func sendAccess() async {
        guard let vault = selectedVault else { return }
        
        do {
            // Parse email/phone
            let email = recipientEmail.contains("@") ? recipientEmail : nil
            let phone = recipientEmail.contains("@") ? nil : recipientEmail
            
            _ = try await requestService.sendVaultAccess(
                vault: vault,
                to: email,
                to: phone,
                to: recipientName.isEmpty ? nil : recipientName,
                message: message.isEmpty ? nil : message
            )
            
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Vault Picker View

struct VaultPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @Binding var selectedVault: Vault?
    
    @Query(sort: \Vault.createdAt, order: .reverse) private var allVaults: [Vault]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allVaults.filter { $0.owner?.id == authService.currentUser?.id }) { vault in
                    Button {
                        selectedVault = vault
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(vault.name)
                                    .font(.headline)
                                if let description = vault.vaultDescription {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedVault?.id == vault.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

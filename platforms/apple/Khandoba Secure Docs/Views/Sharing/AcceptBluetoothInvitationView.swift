//
//  AcceptBluetoothInvitationView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//

import SwiftUI
import SwiftData

struct AcceptBluetoothInvitationView: View {
    let invitation: BluetoothSessionInvitation
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    @EnvironmentObject var vaultService: VaultService
    
    @StateObject private var nomineeService = NomineeService()
    @StateObject private var sharedVaultSessionService = SharedVaultSessionService()
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var inviterName: String = "Unknown User"
    @State private var vaultName: String = "Unknown Vault"
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.xl) {
                        // Header
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(colors.primary)
                            
                            Text("Bluetooth Session Invitation")
                                .font(theme.typography.title)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("You've been invited to access a vault session")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, UnifiedTheme.Spacing.xl)
                        
                        // Invitation Details
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                BluetoothDetailRow(
                                    icon: "person.fill",
                                    label: "Inviter",
                                    value: inviterName,
                                    colors: colors
                                )
                                
                                Divider()
                                
                                BluetoothDetailRow(
                                    icon: "lock.shield.fill",
                                    label: "Vault",
                                    value: vaultName,
                                    colors: colors
                                )
                                
                                Divider()
                                
                                BluetoothDetailRow(
                                    icon: "clock.fill",
                                    label: "Session Duration",
                                    value: formatDuration(invitation.sessionDuration),
                                    colors: colors
                                )
                                
                                if let selectedDocumentIDs = invitation.selectedDocumentIDs, !selectedDocumentIDs.isEmpty {
                                    Divider()
                                    
                                    BluetoothDetailRow(
                                        icon: "doc.fill",
                                        label: "Documents",
                                        value: "\(selectedDocumentIDs.count) selected",
                                        colors: colors
                                    )
                                }
                            }
                        }
                        
                        // Actions
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            Button {
                                Task {
                                    await acceptInvitation()
                                }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Accept Invitation")
                                    }
                                }
                                .font(theme.typography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.primary)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            }
                            .disabled(isLoading)
                            
                            Button {
                                dismiss()
                            } label: {
                                Text("Decline")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.error)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(colors.surface)
                                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            }
                            .disabled(isLoading)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Session Invitation")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.textSecondary)
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.textSecondary)
                }
                #endif
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadInvitationDetails()
            }
        }
    }
    
    private func loadInvitationDetails() async {
        // Load vault name
        do {
            if AppConfig.useSupabase {
                let supabaseVault: SupabaseVault = try await supabaseService.fetch(
                    "vaults",
                    id: invitation.vaultID
                )
                await MainActor.run {
                    vaultName = supabaseVault.name
                }
                
                // Load inviter name
                let supabaseUser: SupabaseUser = try await supabaseService.fetch(
                    "users",
                    id: invitation.inviterUserID
                )
                await MainActor.run {
                    inviterName = supabaseUser.fullName
                }
            } else {
                // SwiftData/CloudKit mode
                let vaultDescriptor = FetchDescriptor<Vault>(
                    predicate: #Predicate { $0.id == invitation.vaultID }
                )
                if let vault = try? modelContext.fetch(vaultDescriptor).first {
                    await MainActor.run {
                        vaultName = vault.name
                    }
                }
                
                let userDescriptor = FetchDescriptor<User>(
                    predicate: #Predicate { $0.id == invitation.inviterUserID }
                )
                if let user = try? modelContext.fetch(userDescriptor).first {
                    await MainActor.run {
                        inviterName = user.fullName
                    }
                }
            }
        } catch {
            print("⚠️ Failed to load invitation details: \(error.localizedDescription)")
        }
    }
    
    private func acceptInvitation() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Configure services
            if AppConfig.useSupabase {
                nomineeService.configure(
                    supabaseService: supabaseService,
                    currentUserID: authService.currentUser?.id
                )
                // SharedVaultSessionService doesn't support Supabase mode yet
                // Will use SwiftData mode for now
            } else {
                nomineeService.configure(
                    modelContext: modelContext,
                    currentUserID: authService.currentUser?.id
                )
                sharedVaultSessionService.configure(
                    modelContext: modelContext,
                    userID: authService.currentUser?.id ?? UUID()
                )
            }
            
            // Find vault from vaultService
            guard let vault = vaultService.vaults.first(where: { $0.id == invitation.vaultID }) else {
                throw NomineeError.vaultNotFound
            }
            
            guard let currentUser = authService.currentUser else {
                throw NomineeError.userNotAuthenticated
            }
            
            // Calculate session expiration date
            let sessionExpiresAt = Date().addingTimeInterval(invitation.sessionDuration)
            
            // Create session-based nominee
            let _ = try await nomineeService.inviteNominee(
                name: currentUser.fullName,
                phoneNumber: nil,
                email: nil,
                to: vault,
                invitedByUserID: currentUser.id,
                selectedDocumentIDs: invitation.selectedDocumentIDs,
                sessionExpiresAt: sessionExpiresAt,
                isSubsetAccess: invitation.selectedDocumentIDs != nil && !invitation.selectedDocumentIDs!.isEmpty
            )
            
            print("✅ Bluetooth session invitation accepted")
            print("   Vault: \(vaultName)")
            print("   Session duration: \(formatDuration(invitation.sessionDuration))")
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Supporting Views

private struct BluetoothDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let colors: UnifiedTheme.Colors
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(colors.textPrimary)
            }
            
            Spacer()
        }
    }
}

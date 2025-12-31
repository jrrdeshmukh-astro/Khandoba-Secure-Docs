//
//  AcceptNomineeInvitationView.swift
//  Khandoba Secure Docs
//
//  Accept nominee invitation view with deep link support
//

import SwiftUI
import SwiftData

struct AcceptNomineeInvitationView: View {
    let inviteToken: String
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var nomineeService = NomineeService()
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var nominee: Nominee?
    @State private var showSuccess = false
    @State private var acceptedVault: Vault?
    
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
                        Text("Loading invitation...")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                    }
                } else if let nominee = nominee {
                    ScrollView {
                        VStack(spacing: UnifiedTheme.Spacing.xl) {
                            // Header
                            VStack(spacing: UnifiedTheme.Spacing.sm) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 60))
                                    .foregroundColor(colors.primary)
                                
                                Text("Vault Invitation")
                                    .font(theme.typography.title)
                                    .foregroundColor(colors.textPrimary)
                                
                                Text("You've been invited to access a vault")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, UnifiedTheme.Spacing.xl)
                            
                            // Invitation Details
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                    if let vault = nominee.vault {
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
                                            Text("Invited By")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                            
                                            Text("Vault Owner")
                                                .font(theme.typography.body)
                                                .foregroundColor(colors.textPrimary)
                                        }
                                        
                                        Divider()
                                        
                                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                            Text("Invited On")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                            
                                            Text(nominee.invitedAt.formatted(date: .long, time: .shortened))
                                                .font(theme.typography.body)
                                                .foregroundColor(colors.textPrimary)
                                        }
                                        
                                        Divider()
                                        
                                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                            Text("Access Level")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                            
                                            Text("Concurrent Access")
                                                .font(theme.typography.body)
                                                .foregroundColor(colors.textPrimary)
                                            
                                            Text("You'll have access when the vault owner unlocks it")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                                .padding(.top, 4)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Info Card
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(colors.info)
                                        Text("How It Works")
                                            .font(theme.typography.subheadline)
                                            .foregroundColor(colors.textPrimary)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text("When the vault owner unlocks the vault, you'll automatically have access to view and manage documents. The vault will be shared in real-time - no documents are copied.")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Accept Button
                            Button {
                                acceptInvitation()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Accept Invitation")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            }
                            .disabled(isLoading)
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
                            .disabled(isLoading)
                            .padding(.horizontal)
                            .padding(.bottom, UnifiedTheme.Spacing.xl)
                        }
                    }
                } else {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(colors.warning)
                        
                        Text("Invitation Not Found")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text("This invitation may have expired or is invalid.")
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
            }
            .navigationTitle("Accept Invitation")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                if let vault = acceptedVault {
                    Button("Open Vault") {
                        // Navigate to vault - this will be handled by the parent view
                        dismiss()
                        // Post notification to navigate to vault
                        NotificationCenter.default.post(
                            name: .navigateToVault,
                            object: nil,
                            userInfo: ["vaultID": vault.id]
                        )
                    }
                    Button("Done") {
                        dismiss()
                    }
                } else {
                Button("OK") {
                    dismiss()
                    }
                }
            } message: {
                if let vault = acceptedVault {
                    Text("Invitation accepted! You now have access to '\(vault.name)'. Tap 'Open Vault' to view it now.")
                } else {
                Text("Invitation accepted! You'll have access when the vault owner unlocks it.")
                }
            }
            .onAppear {
                if AppConfig.useSupabase {
                    nomineeService.configure(supabaseService: supabaseService)
                } else {
                nomineeService.configure(modelContext: modelContext)
                }
                loadInvitation()
            }
        }
    }
    
    private func loadInvitation() {
        print("📧 Loading nominee invitation with token: \(inviteToken)")
        isLoading = true
        Task {
            do {
                // Load the invitation without accepting it yet
                if let loadedNominee = try await nomineeService.loadInvite(token: inviteToken) {
                    print("   ✅ Nominee invitation loaded: \(loadedNominee.vault?.name ?? "Unknown vault")")
                    await MainActor.run {
                        nominee = loadedNominee
                        isLoading = false
                    }
                } else {
                    print("   ❌ Nominee invitation not found")
                    await MainActor.run {
                        errorMessage = "Invitation not found. It may have expired or been cancelled."
                        showError = true
                        isLoading = false
                    }
                }
            } catch {
                print("   ❌ Error loading nominee invitation: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func acceptInvitation() {
        guard nominee != nil else { return }
        
        isLoading = true
        Task {
            do {
                // Use service method to accept invitation
                let acceptedNominee = try await nomineeService.acceptInvite(token: inviteToken)
                
                // Reload the nominee to get updated vault relationship
                if let updatedNominee = try await nomineeService.loadInvite(token: inviteToken) {
                    await MainActor.run {
                        acceptedVault = updatedNominee.vault
                        showSuccess = true
                        isLoading = false
                    }
                } else {
                await MainActor.run {
                        acceptedVault = acceptedNominee?.vault
                    showSuccess = true
                    isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var nomineeService = NomineeService()
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var nominee: Nominee?
    @State private var showSuccess = false
    
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
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Invitation accepted! You'll have access when the vault owner unlocks it.")
            }
            .onAppear {
                nomineeService.configure(modelContext: modelContext)
                loadInvitation()
            }
        }
    }
    
    private func loadInvitation() {
        isLoading = true
        Task {
            do {
                let loadedNominee = try await nomineeService.acceptInvite(token: inviteToken)
                await MainActor.run {
                    nominee = loadedNominee
                    isLoading = false
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
    
    private func acceptInvitation() {
        guard let nominee = nominee else { return }
        
        isLoading = true
        Task {
            do {
                // Update nominee status to accepted
                nominee.status = "accepted"
                nominee.acceptedAt = Date()
                
                try modelContext.save()
                
                await MainActor.run {
                    showSuccess = true
                    isLoading = false
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

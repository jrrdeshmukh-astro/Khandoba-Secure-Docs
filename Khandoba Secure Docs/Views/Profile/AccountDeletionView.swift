//
//  AccountDeletionView.swift
//  Khandoba Secure Docs
//
//  Account deletion view - App Store Guideline 5.1.1(v) compliance
//

import SwiftUI
import SwiftData

struct AccountDeletionView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @SwiftUI.Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var deletionService = AccountDeletionService()
    @State private var showConfirmation = false
    @State private var showFinalWarning = false
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xl) {
                        // Warning Header
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(colors.warning)
                            
                            Text("Delete Account")
                                .font(theme.typography.largeTitle)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.bold)
                            
                            Text("This action cannot be undone")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, UnifiedTheme.Spacing.xl)
                        
                        // What Will Be Deleted
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("What will be deleted:")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                DeletionItem(
                                    icon: "lock.shield.fill",
                                    text: "All your vaults and documents",
                                    colors: colors
                                )
                                DeletionItem(
                                    icon: "person.circle.fill",
                                    text: "Your profile and account information",
                                    colors: colors
                                )
                                DeletionItem(
                                    icon: "chart.bar.fill",
                                    text: "All access logs and analytics",
                                    colors: colors
                                )
                                DeletionItem(
                                    icon: "message.fill",
                                    text: "All chat messages and conversations",
                                    colors: colors
                                )
                                DeletionItem(
                                    icon: "key.fill",
                                    text: "All encryption keys (data cannot be recovered)",
                                    colors: colors
                                )
                                DeletionItem(
                                    icon: "person.2.fill",
                                    text: "Access to all shared vaults (nominee access terminated)",
                                    colors: colors
                                )
                            }
                        }
                        .padding(UnifiedTheme.Spacing.md)
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        .padding(.horizontal)
                        
                        // Important Notes
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Important:")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("• Your subscription will be cancelled through the App Store")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                            
                            Text("• You can cancel your subscription in Settings → Subscriptions before deleting your account")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                            
                            Text("• All data is permanently deleted and cannot be recovered")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .fontWeight(.semibold)
                            
                            Divider()
                                .padding(.vertical, UnifiedTheme.Spacing.xs)
                            
                            Text("• Access logs and location data from shared vaults will remain with the vault owner for security and audit purposes")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .italic()
                            
                            Text("• If you were a nominee (had access to someone else's vault), your access will be terminated but historical access records will be preserved")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .italic()
                        }
                        .padding(UnifiedTheme.Spacing.md)
                        .background(colors.warning.opacity(0.1))
                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        .padding(.horizontal)
                        
                        // Delete Button
                        Button {
                            showFinalWarning = true
                        } label: {
                            HStack {
                                if isDeleting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "trash.fill")
                                    Text("Delete My Account")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.error)
                            .foregroundColor(.white)
                            .font(theme.typography.headline)
                            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        .disabled(isDeleting)
                        .padding(.horizontal)
                        .padding(.bottom, UnifiedTheme.Spacing.xl)
                    }
                }
            }
            .navigationTitle("Delete Account")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                #endif
            }
        }
        .alert("Delete Account", isPresented: $showFinalWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Forever", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you absolutely sure? This will permanently delete your account and all data. This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // iOS-ONLY: Using SwiftData/CloudKit exclusively
            deletionService.configure(modelContext: modelContext)
        }
    }
    
    private func deleteAccount() {
        guard let user = authService.currentUser else {
            errorMessage = "User account not found."
            showError = true
            return
        }
        
        isDeleting = true
        
        Task {
            do {
                try await deletionService.deleteAccount(user: user)
                
                // Sign out after successful deletion
                await MainActor.run {
                    Task {
                        try? await authService.signOut()
                    }
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct DeletionItem: View {
    let icon: String
    let text: String
    let colors: UnifiedTheme.Colors
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(colors.error)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(colors.textPrimary)
        }
    }
}

#Preview {
    AccountDeletionView()
        .environmentObject(AuthenticationService())
        .modelContainer(for: User.self, inMemory: true)
}

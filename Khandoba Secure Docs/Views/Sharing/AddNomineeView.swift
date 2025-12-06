//
//  AddNomineeView.swift
//  Khandoba Secure Docs
//
//  View for creating nominees and generating invite links
//

import SwiftUI
import SwiftData
import UIKit

struct AddNomineeView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var nomineeService = NomineeService()
    
    // Form fields
    @State private var nomineeName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    
    // State
    @State private var isCreating = false
    @State private var createdNominee: Nominee?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCopiedAlert = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        if let nominee = createdNominee {
                            // Success state - show invite link
                            inviteLinkView(nominee: nominee, colors: colors)
                        } else {
                            // Form state - enter nominee details
                            nomineeFormView(colors: colors)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Invite Nominee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Copied!", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Invitation link copied to clipboard")
            }
            .onAppear {
                nomineeService.configure(modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Nominee Form
    
    private func nomineeFormView(colors: UnifiedTheme.Colors) -> some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            // Header
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 50))
                    .foregroundColor(colors.primary)
                
                Text("Add Nominee")
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                
                Text("Enter the nominee's details to generate an invitation link")
                    .font(theme.typography.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            // Vault Info
            StandardCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(colors.primary)
                        Text("Vault")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Text(vault.name)
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Form Fields
            VStack(spacing: UnifiedTheme.Spacing.md) {
                // Name Field
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Full Name *")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        TextField("Enter nominee's name", text: $nomineeName)
                            .font(theme.typography.body)
                            .textInputAutocapitalization(.words)
                            .padding(UnifiedTheme.Spacing.md)
                            .background(colors.surface)
                            .cornerRadius(UnifiedTheme.CornerRadius.md)
                    }
                }
                
                // Phone Field
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Phone Number")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        TextField("(555) 123-4567", text: $phoneNumber)
                            .font(theme.typography.body)
                            .keyboardType(.phonePad)
                            .padding(UnifiedTheme.Spacing.md)
                            .background(colors.surface)
                            .cornerRadius(UnifiedTheme.CornerRadius.md)
                    }
                }
                
                // Email Field
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Email Address")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        TextField("nominee@example.com", text: $email)
                            .font(theme.typography.body)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(UnifiedTheme.Spacing.md)
                            .background(colors.surface)
                            .cornerRadius(UnifiedTheme.CornerRadius.md)
                    }
                }
            }
            
            // Info Card
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(colors.info)
                        Text("What happens next?")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                    }
                    
                    Text("After creating the nominee, you'll receive an invitation link. Share this link via Messages, email, or any other method. The nominee can tap the link to accept the invitation.")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            // Create Button
            Button {
                createNominee()
            } label: {
                HStack {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "person.badge.plus.fill")
                        Text("Create Nominee & Generate Link")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canCreate ? colors.primary : colors.surface)
                .foregroundColor(canCreate ? .white : colors.textTertiary)
                .cornerRadius(UnifiedTheme.CornerRadius.lg)
            }
            .disabled(!canCreate || isCreating)
        }
    }
    
    // MARK: - Invite Link View
    
    private func inviteLinkView(nominee: Nominee, colors: UnifiedTheme.Colors) -> some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            // Success Header
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(colors.success)
                
                Text("Nominee Created!")
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                
                Text("Share the invitation link below")
                    .font(theme.typography.body)
                    .foregroundColor(colors.textSecondary)
            }
            .padding(.top)
            
            // Nominee Info
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(colors.primary)
                        Text("Nominee Details")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                    }
                    
                    Text(nominee.name)
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    if let phone = nominee.phoneNumber, !phone.isEmpty {
                        Text(phone)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    if let email = nominee.email, !email.isEmpty {
                        Text(email)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Invite Link Card
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(colors.primary)
                        Text("Invitation Link")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                    }
                    
                    // Deep Link
                    let deepLink = "khandoba://invite?token=\(nominee.inviteToken)"
                    
                    Text(deepLink)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(colors.textPrimary)
                        .padding(UnifiedTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                        .textSelection(.enabled)
                    
                    // Token (for manual entry)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Or use this token:")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        Text(nominee.inviteToken)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(colors.textPrimary)
                            .padding(UnifiedTheme.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(colors.surface)
                            .cornerRadius(UnifiedTheme.CornerRadius.sm)
                            .textSelection(.enabled)
                    }
                }
            }
            
            // Action Buttons
            VStack(spacing: UnifiedTheme.Spacing.md) {
                // Copy Link Button
                Button {
                    copyInviteLink(nominee: nominee)
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy Invitation Link")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.secondary)
                    .foregroundColor(.white)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                }
                
                // Open Messages Button
                Button {
                    openMessagesWithLink(nominee: nominee)
                } label: {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Open Messages")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                }
                
                // Share Link (iOS Native ShareLink)
                ShareLink(
                    item: URL(string: "khandoba://invite?token=\(nominee.inviteToken)") ?? URL(string: "https://khandoba.app/invite?token=\(nominee.inviteToken)")!,
                    message: Text(generateInvitationMessage(nominee: nominee, deepLink: "khandoba://invite?token=\(nominee.inviteToken)"))
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Share via...")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                }
            }
            
            // Done Button
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.surface)
                    .foregroundColor(colors.textPrimary)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canCreate: Bool {
        !nomineeName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Actions
    
    private func createNominee() {
        guard canCreate else { return }
        guard let currentUser = authService.currentUser else {
            errorMessage = "You must be logged in to create nominees"
            showError = true
            return
        }
        
        isCreating = true
        
        Task {
            do {
                let nominee = try await nomineeService.inviteNominee(
                    name: nomineeName.trimmingCharacters(in: .whitespaces),
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespaces),
                    email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
                    to: vault,
                    invitedByUserID: currentUser.id
                )
                
                await MainActor.run {
                    createdNominee = nominee
                    isCreating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isCreating = false
                }
            }
        }
    }
    
    private func copyInviteLink(nominee: Nominee) {
        let deepLink = "khandoba://invite?token=\(nominee.inviteToken)"
        let message = generateInvitationMessage(nominee: nominee, deepLink: deepLink)
        
        UIPasteboard.general.string = message
        showCopiedAlert = true
    }
    
    private func openMessagesWithLink(nominee: Nominee) {
        #if !APP_EXTENSION
        let deepLink = "khandoba://invite?token=\(nominee.inviteToken)"
        let message = generateInvitationMessage(nominee: nominee, deepLink: deepLink)
        
        // Copy to clipboard first
        UIPasteboard.general.string = message
        
        // Open Messages app
        if let messagesURL = URL(string: "sms:") {
            UIApplication.shared.open(messagesURL) { success in
                if success {
                    // Show alert that link is copied
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showCopiedAlert = true
                    }
                }
            }
        }
        #endif
    }
    
    private func generateInvitationMessage(nominee: Nominee, deepLink: String) -> String {
        let vaultName = vault.name
        let message = """
        You've been invited to access a vault in Khandoba Secure Docs!
        
        Vault: \(vaultName)
        Invited by: \(authService.currentUser?.fullName ?? "Vault Owner")
        
        Tap to accept: \(deepLink)
        
        Or download Khandoba Secure Docs from the App Store and use this token:
        \(nominee.inviteToken)
        """
        return message
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}


//
//  UnifiedAddNomineeView.swift
//  Khandoba Secure Docs
//
//  Unified view for adding nominees with CloudKit sharing support
//

import SwiftUI
import SwiftData
import CloudKit
import Contacts

struct UnifiedAddNomineeView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var nomineeService = NomineeService()
    @StateObject private var cloudKitSharing = CloudKitSharingService()
    
    // Form fields
    @State private var nomineeName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var accessLevel: NomineeAccessLevel = .view
    
    // State
    @State private var isCreating = false
    @State private var createdNominee: Nominee?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCloudKitSharing = false
    @State private var cloudKitShare: CKShare?
    @State private var showContactPicker = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        if let nominee = createdNominee {
                            // Success state - show sharing options
                            inviteSuccessView(nominee: nominee, colors: colors)
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
            .sheet(isPresented: $showCloudKitSharing) {
                if let share = cloudKitShare {
                    CloudKitSharingView(
                        vault: vault,
                        share: share,
                        container: CKContainer(identifier: AppConfig.cloudKitContainer),
                        isPresented: $showCloudKitSharing
                    )
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView(
                    vault: vault,
                    onContactsSelected: { contacts in
                        if let contact = contacts.first {
                            nomineeName = "\(contact.givenName) \(contact.familyName)"
                            phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
                            email = contact.emailAddresses.first?.value as String? ?? ""
                        }
                        showContactPicker = false
                    },
                    onDismiss: {
                        showContactPicker = false
                    }
                )
            }
            .onAppear {
                nomineeService.configure(modelContext: modelContext)
                cloudKitSharing.configure(modelContext: modelContext)
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
                
                Text("Enter the nominee's details to generate an invitation")
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
            
            // Select from Contacts Button
            Button {
                showContactPicker = true
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("Select from Contacts")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(colors.secondary)
                .foregroundColor(.white)
                .cornerRadius(UnifiedTheme.CornerRadius.lg)
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
            
            // Access Level Selection
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                    Text("Access Level")
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    ForEach(NomineeAccessLevel.allCases, id: \.self) { level in
                        AccessLevelRow(
                            level: level,
                            isSelected: accessLevel == level,
                            action: {
                                accessLevel = level
                            }
                        )
                    }
                }
            }
            
            // Info Card
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(colors.info)
                        Text("How it works")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Nominees get real-time concurrent access when you unlock the vault. When you open the vault, they can access it too. No documents are copied - they see the same vault synchronized in real-time.")
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
                        Text("Create Nominee & Share")
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
    
    // MARK: - Invite Success View
    
    private func inviteSuccessView(nominee: Nominee, colors: UnifiedTheme.Colors) -> some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            // Success Header
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(colors.success)
                
                Text("Nominee Created!")
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                
                Text("Share the invitation using CloudKit")
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
            
            // Action Buttons
            VStack(spacing: UnifiedTheme.Spacing.md) {
                // CloudKit Share Button (Primary - Recommended)
                Button {
                    Task {
                        await presentCloudKitSharing()
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Share via CloudKit")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                }
                
                // Copy Link Button (Fallback)
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
        // Show toast or alert
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
    
    // MARK: - CloudKit Sharing
    
    private func presentCloudKitSharing() async {
        print("📤 Presenting CloudKit sharing for vault: \(vault.name)")
        
        do {
            if let share = try await cloudKitSharing.getOrCreateShare(for: vault) {
                await MainActor.run {
                    cloudKitShare = share
                    showCloudKitSharing = true
                }
                print("   ✅ CloudKit sharing controller will be presented")
            } else {
                print("   ⚠️ Could not create CloudKit share")
                await MainActor.run {
                    errorMessage = "CloudKit sharing is currently unavailable. Please use the 'Copy Invitation Link' button instead."
                    showError = true
                }
            }
        } catch {
            print("   ❌ Failed to prepare CloudKit share: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "CloudKit sharing is currently unavailable. Please use the 'Copy Invitation Link' button instead."
                showError = true
            }
        }
    }
}


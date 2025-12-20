//
//  TransferOwnershipView.swift
//  Khandoba Secure Docs
//
//  Modern transfer ownership view with iOS native sharing
//

import SwiftUI
import SwiftData
import Contacts
import CloudKit

#if os(iOS)
import UIKit
#endif

struct TransferOwnershipView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    @StateObject private var nomineeService = NomineeService()
    
    // Form fields
    @State private var newOwnerName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var reason = ""
    @State private var nominees: [Nominee] = []
    
    // State
    @State private var isCreating = false
    @State private var createdRequest: VaultTransferRequest?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCopiedAlert = false
    @State private var showContactPicker = false
    @State private var selectedContact: CNContact?
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showCloudKitSharing = false
    @State private var cloudKitShare: CKShare?
    
    @StateObject private var cloudKitSharing = CloudKitSharingService()
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        if let request = createdRequest {
                            // Success state - show transfer link
                            transferLinkView(request: request, colors: colors)
                        } else {
                            // Form state - enter new owner details
                            transferFormView(colors: colors)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Transfer Ownership")
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
                Text("Transfer link copied to clipboard")
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: shareItems)
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
                            selectedContact = contact
                            newOwnerName = "\(contact.givenName) \(contact.familyName)"
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
        }
    }
    
    // MARK: - Transfer Form
    
    private func transferFormView(colors: UnifiedTheme.Colors) -> some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            // Warning Header
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(colors.warning)
                
                Text("Transfer Ownership")
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                
                Text("You will lose all access to this vault")
                    .font(theme.typography.body)
                    .foregroundColor(colors.warning)
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            // Warning Card
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(colors.warning)
                        Text("Important")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Transferring ownership is permanent and cannot be undone. The new owner will have complete control over this vault and all its documents. You will no longer be able to access this vault.")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
            }
            
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
                        Text("New Owner Name *")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        TextField("Enter new owner's name", text: $newOwnerName)
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
                        
                        TextField("newowner@example.com", text: $email)
                            .font(theme.typography.body)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(UnifiedTheme.Spacing.md)
                            .background(colors.surface)
                            .cornerRadius(UnifiedTheme.CornerRadius.md)
                    }
                }
                
                // Reason Field
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Reason (Optional)")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        TextField("Why are you transferring this vault?", text: $reason, axis: .vertical)
                            .font(theme.typography.body)
                            .lineLimit(3...6)
                            .padding(UnifiedTheme.Spacing.md)
                            .background(colors.surface)
                            .cornerRadius(UnifiedTheme.CornerRadius.md)
                    }
                }
            }
            
            // Create Transfer Request Button
            Button {
                createTransferRequest()
            } label: {
                HStack {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Create Transfer Request")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canCreate ? colors.warning : colors.surface)
                .foregroundColor(canCreate ? .white : colors.textTertiary)
                .cornerRadius(UnifiedTheme.CornerRadius.lg)
            }
            .disabled(!canCreate || isCreating)
        }
    }
    
    // MARK: - Transfer Link View
    
    private func transferLinkView(request: VaultTransferRequest, colors: UnifiedTheme.Colors) -> some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            // Success Header
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(colors.success)
                
                Text("Transfer Request Created!")
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                
                Text("Share the transfer link with the new owner")
                    .font(theme.typography.body)
                    .foregroundColor(colors.textSecondary)
            }
            .padding(.top)
            
            // New Owner Info
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(colors.primary)
                        Text("New Owner Details")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                    }
                    
                    if let name = request.newOwnerName, !name.isEmpty {
                        Text(name)
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                    }
                    
                    if let phone = request.newOwnerPhone, !phone.isEmpty {
                        Text(phone)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    if let email = request.newOwnerEmail, !email.isEmpty {
                        Text(email)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Transfer Link Card
            StandardCard {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(colors.primary)
                        Text("Transfer Link")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                    }
                    
                    // Deep Link
                    let deepLink = "khandoba://transfer?token=\(request.transferToken)"
                    
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
                        
                        Text(request.transferToken)
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
                    copyTransferLink(request: request)
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy Transfer Link")
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
        !newOwnerName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Actions
    
    private func createTransferRequest() {
        guard canCreate else { return }
        guard let currentUser = authService.currentUser else {
            errorMessage = "You must be logged in to transfer ownership"
            showError = true
            return
        }
        
        // Validate that the person is already a nominee
        let isNominee = nominees.contains { nominee in
            // Check by email or phone number
            if !email.isEmpty, let nomineeEmail = nominee.email, nomineeEmail.lowercased() == email.lowercased().trimmingCharacters(in: .whitespaces) {
                return nominee.status == .accepted
            }
            if !phoneNumber.isEmpty, let nomineePhone = nominee.phoneNumber, nomineePhone == phoneNumber.trimmingCharacters(in: .whitespaces) {
                return nominee.status == .accepted
            }
            return false
        }
        
        guard isNominee else {
            errorMessage = "You can only transfer ownership to users who are already nominated and have accepted their invitation for this vault. Please nominate the user first."
            showError = true
            return
        }
        
        isCreating = true
        
        Task {
            do {
                // Supabase mode - exclusive use when enabled
                if AppConfig.useSupabase {
                    guard let supabaseService = supabaseService else {
                        throw TransferError.serviceNotConfigured
                    }
                    
                    // Create transfer request in Supabase
                    let supabaseRequest = SupabaseVaultTransferRequest(
                        vaultID: vault.id,
                        requestedByUserID: currentUser.id,
                        newOwnerName: newOwnerName.trimmingCharacters(in: .whitespaces),
                        newOwnerPhone: phoneNumber.isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespaces),
                        newOwnerEmail: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces),
                        reason: reason.isEmpty ? nil : reason.trimmingCharacters(in: .whitespaces)
                    )
                    
                    let created: SupabaseVaultTransferRequest = try await supabaseService.insert(
                        "vault_transfer_requests",
                        values: supabaseRequest
                    )
                    
                    // Convert to SwiftData model for UI compatibility
                    let request = VaultTransferRequest(
                        reason: created.reason,
                        newOwnerName: created.newOwnerName,
                        newOwnerPhone: created.newOwnerPhone,
                        newOwnerEmail: created.newOwnerEmail
                    )
                    request.id = created.id
                    request.transferToken = created.transferToken
                    request.status = created.status
                    request.requestedAt = created.requestedAt
                    request.requestedByUserID = created.requestedByUserID
                    request.vault = vault
                    
                    await MainActor.run {
                        createdRequest = request
                        isCreating = false
                        print("✅ Transfer request created in Supabase")
                    }
                    return
                }
                
                // SwiftData/CloudKit mode
                let request = VaultTransferRequest(
                    reason: reason.isEmpty ? nil : reason.trimmingCharacters(in: .whitespaces),
                    newOwnerName: newOwnerName.trimmingCharacters(in: .whitespaces),
                    newOwnerPhone: phoneNumber.isEmpty ? nil : phoneNumber.trimmingCharacters(in: .whitespaces),
                    newOwnerEmail: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces)
                )
                
                request.vault = vault
                request.requestedByUserID = currentUser.id
                
                modelContext.insert(request)
                try modelContext.save()
                
                await MainActor.run {
                    createdRequest = request
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
    
    private func copyTransferLink(request: VaultTransferRequest) {
        let message = generateTransferMessage(request: request)
        UIPasteboard.general.string = message
        showCopiedAlert = true
    }
    
    private func openMessagesWithLink(request: VaultTransferRequest) {
        #if !APP_EXTENSION
        let message = generateTransferMessage(request: request)
        
        #if os(iOS)
        // Copy to clipboard first
        UIPasteboard.general.string = message
        
        // Open Messages app
        if let messagesURL = URL(string: "sms:") {
            UIApplication.shared.open(messagesURL) { success in
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showCopiedAlert = true
                    }
                }
            }
        }
        #endif
        #endif
    }
    
    private func shareTransferLink(request: VaultTransferRequest) {
        let message = generateTransferMessage(request: request)
        shareItems = [message]
        showShareSheet = true
    }
    
    private func generateTransferURL(request: VaultTransferRequest) -> URL {
        // Create a URL for ShareLink
        let deepLink = "khandoba://transfer?token=\(request.transferToken)"
        return URL(string: deepLink) ?? URL(string: "https://khandoba.app/transfer?token=\(request.transferToken)")!
    }
    
    private func generateTransferMessage(request: VaultTransferRequest) -> String {
        let vaultName = vault.name
        let deepLink = "khandoba://transfer?token=\(request.transferToken)"
        let ownerName = authService.currentUser?.fullName ?? "Vault Owner"
        
        var message = """
        You've been offered ownership of a vault in Khandoba Secure Docs!
        
        Vault: \(vaultName)
        Transferred by: \(ownerName)
        """
        
        if let reason = request.reason, !reason.isEmpty {
            message += "\nReason: \(reason)"
        }
        
        message += """
        
        Tap to accept: \(deepLink)
        
        Or download Khandoba Secure Docs from the App Store and use this token:
        \(request.transferToken)
        """
        
        return message
    }
    
    // MARK: - CloudKit Sharing
    
    private func presentCloudKitSharing() async {
        print("📤 Presenting CloudKit sharing for transfer: \(vault.name)")
        
        do {
            if let share = try await cloudKitSharing.getOrCreateShare(for: vault) {
                await MainActor.run {
                    cloudKitShare = share
                    showCloudKitSharing = true
                }
                print("   ✅ CloudKit sharing controller will be presented")
            } else {
                print("   ⚠️ Could not create CloudKit share - using fallback")
                await MainActor.run {
                    copyTransferLink(request: createdRequest!)
                    showCopiedAlert = true
                }
            }
        } catch {
            print("   ❌ Failed to prepare CloudKit share: \(error.localizedDescription)")
            await MainActor.run {
                copyTransferLink(request: createdRequest!)
                showCopiedAlert = true
            }
        }
    }
}

// MARK: - Share Sheet (for iOS 15 fallback)

#if os(iOS)
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
#endif

// MARK: - Transfer Error

enum TransferError: LocalizedError {
    case serviceNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .serviceNotConfigured:
            return "Service not configured. Please ensure Supabase is properly initialized."
        }
    }
}


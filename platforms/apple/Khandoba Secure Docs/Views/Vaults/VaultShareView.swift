//
//  VaultShareView.swift
//  Khandoba Secure Docs
//
//  Device-to-device vault sharing with CloudKit (GameCenter-like experience)
//

import SwiftUI
import SwiftData
import CloudKit
import Contacts

struct VaultShareView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject var vaultService: VaultService
    @EnvironmentObject var nomineeService: NomineeService
    @EnvironmentObject var cloudKitSharing: CloudKitSharingService
    @EnvironmentObject var authService: AuthenticationService
    
    let vault: Vault
    
    @State private var selectedContacts: [CNContact] = []
    @State private var showContactPicker = false
    @State private var showCloudKitShare = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var sharePermission: SharePermission = .readWrite
    @State private var invitationSent = false
    
    enum SharePermission: String, CaseIterable {
        case readWrite = "read_write"
        case readOnly = "read_only"
        
        var displayName: String {
            switch self {
            case .readWrite: return "Read & Write"
            case .readOnly: return "Read Only"
            }
        }
        
        var description: String {
            switch self {
            case .readWrite: return "Can view and edit documents"
            case .readOnly: return "Can only view documents"
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
                    VStack(spacing: UnifiedTheme.Spacing.xl) {
                        // Header
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 60))
                                .foregroundColor(colors.primary)
                            
                            Text("Share Vault")
                                .font(theme.typography.title)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("Invite others to access this vault")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, UnifiedTheme.Spacing.lg)
                        }
                        .padding(.top, UnifiedTheme.Spacing.xl)
                        
                        // Vault Info Card
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                Text("Vault Details")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textSecondary)
                                
                                Text(vault.name)
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                if let description = vault.vaultDescription, !description.isEmpty {
                                    Text(description)
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                                
                                HStack {
                                    Label("\(vault.documents?.count ?? 0) documents", systemImage: "doc.fill")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                    
                                    Spacer()
                                    
                                    if vault.keyType == "dual" {
                                        Label("Dual-key", systemImage: "key.fill")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, UnifiedTheme.Spacing.lg)
                        
                        // Permissions Selection
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Permissions")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                                .padding(.horizontal, UnifiedTheme.Spacing.lg)
                            
                            ForEach(SharePermission.allCases, id: \.self) { permission in
                                Button {
                                    sharePermission = permission
                                } label: {
                                    PermissionRow(
                                        permission: permission,
                                        isSelected: sharePermission == permission,
                                        colors: colors
                                    )
                                }
                            }
                        }
                        
                        // Invitation Methods
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Choose Invitation Method")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                                .padding(.horizontal, UnifiedTheme.Spacing.lg)
                            
                            // CloudKit Share (Recommended - GameCenter-like)
                            Button {
                                sendCloudKitInvitation()
                            } label: {
                                InvitationMethodRow(
                                    icon: "person.crop.circle.badge.plus",
                                    title: "iCloud Share",
                                    description: "Send via iCloud (recommended)",
                                    colors: colors
                                )
                            }
                            .disabled(isLoading || invitationSent)
                            
                            // Contact Picker (Alternative)
                            Button {
                                showContactPicker = true
                            } label: {
                                InvitationMethodRow(
                                    icon: "person.crop.circle",
                                    title: "Choose Contact",
                                    description: "Select from your contacts",
                                    colors: colors
                                )
                            }
                            .disabled(isLoading || invitationSent)
                        }
                        
                        if invitationSent {
                            VStack(spacing: UnifiedTheme.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(colors.success)
                                
                                Text("Invitation Sent!")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                Text("The recipient will receive the invitation and can accept it to access the vault")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, UnifiedTheme.Spacing.lg)
                            }
                            .padding(.top, UnifiedTheme.Spacing.xl)
                        }
                        
                        // Continue Button
                        if invitationSent {
                            Button {
                                dismiss()
                            } label: {
                                Text("Done")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, UnifiedTheme.Spacing.lg)
                            .padding(.top, UnifiedTheme.Spacing.lg)
                        }
                    }
                    .padding(.bottom, UnifiedTheme.Spacing.xl)
                }
            }
            .navigationTitle("Share Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !invitationSent {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(colors.textSecondary)
                    }
                }
            }
            .overlay {
                if isLoading {
                    LoadingOverlay(message: "Sending invitation...")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showCloudKitShare) {
                CloudKitShareView(vault: vault, permission: sharePermission) {
                    invitationSent = true
                    showCloudKitShare = false
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerViewWrapper(selectedContacts: $selectedContacts) { contacts in
                    handleContactSelection(contacts)
                }
            }
        }
    }
    
    private func sendCloudKitInvitation() {
        isLoading = true
        Task {
            do {
                // Create nominee for shared access
                guard let currentUser = authService.currentUser else {
                    throw NSError(domain: "VaultShare", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }
                
                // Show CloudKit share sheet
                await MainActor.run {
                    isLoading = false
                    showCloudKitShare = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create invitation: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func handleContactSelection(_ contacts: [CNContact]) {
        // Handle contact-based invitation
        // This would use MessageUI or other native sharing
        Task {
            do {
                for contact in contacts {
                    // Create nominee
                    let nominee = Nominee(
                        name: "\(contact.givenName) \(contact.familyName)",
                        email: contact.emailAddresses.first?.value as String?,
                        phoneNumber: contact.phoneNumbers.first?.value.stringValue,
                        status: .pending
                    )
                    nominee.vault = vault
                    nominee.invitedByUserID = authService.currentUser?.id
                    
                    modelContext.insert(nominee)
                }
                
                try modelContext.save()
                
                // Show CloudKit share for first contact
                if let firstContact = contacts.first {
                    await MainActor.run {
                        showCloudKitShare = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create nominees: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

struct PermissionRow: View {
    let permission: VaultShareView.SharePermission
    let isSelected: Bool
    let colors: UnifiedTheme.Colors
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    
    var body: some View {
        StandardCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(permission.displayName)
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    Text(permission.description)
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
            .padding(UnifiedTheme.Spacing.md)
        }
        .padding(.horizontal, UnifiedTheme.Spacing.lg)
    }
}

// Enhanced CloudKit Share View with permission support
struct CloudKitShareView: UIViewControllerRepresentable {
    let vault: Vault
    let permission: VaultShareView.SharePermission
    let onComplete: () -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        
        // Get CloudKit container
        let container = CKContainer(identifier: AppConfig.cloudKitContainer)
        
        // Create CloudKit sharing controller
        let shareController = UICloudSharingController { controller, completionHandler in
            Task {
                // Use SwiftData's PersistentIdentifier for CloudKit record lookup
                let persistentID = vault.persistentModelID
                completionHandler(nil, container, nil)
            }
        }
        
        shareController.delegate = context.coordinator
        shareController.availablePermissions = permission == .readWrite ? [.allowReadWrite] : [.allowReadOnly]
        
        DispatchQueue.main.async {
            controller.present(shareController, animated: true)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }
    
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let onComplete: () -> Void
        
        init(onComplete: @escaping () -> Void) {
            self.onComplete = onComplete
        }
        
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("❌ CloudKit share failed: \(error.localizedDescription)")
        }
        
        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            return nil
        }
        
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return vault.name
        }
        
        func itemType(for csc: UICloudSharingController) -> String? {
            return "Vault"
        }
        
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("✅ CloudKit share saved successfully")
            DispatchQueue.main.async {
                onComplete()
            }
        }
        
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("ℹ️ CloudKit sharing stopped")
            DispatchQueue.main.async {
                onComplete()
            }
        }
    }
}



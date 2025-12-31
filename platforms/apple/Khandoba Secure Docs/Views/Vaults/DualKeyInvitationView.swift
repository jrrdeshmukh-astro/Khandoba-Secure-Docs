//
//  DualKeyInvitationView.swift
//  Khandoba Secure Docs
//
//  Device-to-device invitation for second signee (GameCenter-like experience)
//

import SwiftUI
import SwiftData
import CloudKit
import Contacts

struct DualKeyInvitationView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject var nomineeService: NomineeService
    @EnvironmentObject var cloudKitSharing: CloudKitSharingService
    
    let vault: Vault
    let onComplete: () -> Void
    
    @State private var selectedContact: CNContact?
    @State private var showContactPicker = false
    @State private var showCloudKitShare = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var invitationSent = false
    
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
                            
                            Text("Invite Second Signee")
                                .font(theme.typography.title)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("Dual-key vaults require approval from both you and a second signee")
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
                            }
                        }
                        .padding(.horizontal, UnifiedTheme.Spacing.lg)
                        
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
                                
                                Text("The second signee will receive the invitation and can accept it to become a co-signer")
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
                                onComplete()
                            } label: {
                                Text("Continue")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, UnifiedTheme.Spacing.lg)
                            .padding(.top, UnifiedTheme.Spacing.lg)
                        }
                    }
                    .padding(.bottom, UnifiedTheme.Spacing.xl)
                }
            }
            .navigationTitle("Invite Signee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !invitationSent {
                        Button("Skip") {
                            onComplete()
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
                CloudKitShareView(vault: vault) {
                    invitationSent = true
                    showCloudKitShare = false
                }
            }
        }
    }
    
    private func sendCloudKitInvitation() {
        isLoading = true
        Task {
            do {
                // Create nominee for second signee (co-signer for dual-key vault)
                let nominee = Nominee(
                    name: "Second Signee",
                    email: nil,
                    phoneNumber: nil,
                    status: .pending
                )
                nominee.vault = vault
                
                modelContext.insert(nominee)
                try modelContext.save()
                
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
}

struct InvitationMethodRow: View {
    let icon: String
    let title: String
    let description: String
    let colors: UnifiedTheme.Colors
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    
    var body: some View {
        StandardCard {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(colors.primary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    Text(description)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(colors.textTertiary)
            }
            .padding(UnifiedTheme.Spacing.md)
        }
        .padding(.horizontal, UnifiedTheme.Spacing.lg)
    }
}

// CloudKit Share View using UICloudSharingController
struct CloudKitShareView: UIViewControllerRepresentable {
    let vault: Vault
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
        shareController.availablePermissions = [.allowReadWrite]
        
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
    }
}


//
//  NomineeInvitationView.swift
//  Khandoba Secure Docs
//
//  Apple Pay-style nominee invitation flow
//

import SwiftUI
import SwiftData
import Contacts
import ContactsUI
import CloudKit

struct NomineeInvitationView: View {
    let vault: Vault?
    
    @SwiftUI.Environment(\.dismiss) private var dismiss
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var vaultService: VaultService
    @EnvironmentObject var supabaseService: SupabaseService
    
    @StateObject private var nomineeService = NomineeService()
    @StateObject private var cloudKitSharing = CloudKitSharingService()
    private let biometricAuth = BiometricAuthService.shared
    
    @State private var selectedContact: CNContact?
    @State private var selectedVault: Vault?
    @State private var showContactPicker = false
    @State private var showFaceID = false
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showCloudKitSharing = false
    @State private var cloudKitShare: CKShare?
    @State private var createdNominee: Nominee?
    
    // Filter out system vaults
    private var userVaults: [Vault] {
        vaultService.vaults.filter { vault in
            vault.name != "Intel Reports" && !vault.isSystemVault
        }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.xl) {
                    // Header
                    HStack {
                        Text("Invite to Vault")
                            .font(theme.typography.title)
                            .foregroundColor(colors.textPrimary)
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(colors.textTertiary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Contact Selection (Apple Pay style)
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Send to")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                            .padding(.horizontal)
                        
                        ContactSelectionCard(contact: selectedContact) {
                            showContactPicker = true
                        }
                        .padding(.horizontal)
                    }
                    
                    // Vault Selection
                    if let selectedVault = selectedVault {
                        // Large Vault Name Display (Apple Pay style - like "$1")
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            Text(selectedVault.name)
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(colors.textPrimary)
                            
                            Text(selectedVault.keyType == "dual" ? "Dual-Key Vault" : "Single-Key Vault")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding(.vertical, UnifiedTheme.Spacing.lg)
                        
                        // Vault Rolodex
                        VaultRolodexView(
                            vaults: userVaults,
                            selectedVault: Binding(
                                get: { selectedVault },
                                set: { newValue in
                                    self.selectedVault = newValue
                                }
                            ),
                            onVaultSelected: { vault in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    self.selectedVault = vault
                                }
                            }
                        )
                        .frame(height: 280)
                        .padding(.horizontal)
                    } else if !userVaults.isEmpty {
                        // Initial vault selection
                        VaultRolodexView(
                            vaults: userVaults,
                            selectedVault: Binding(
                                get: { selectedVault },
                                set: { newValue in
                                    self.selectedVault = newValue
                                }
                            ),
                            onVaultSelected: { vault in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    self.selectedVault = vault
                                }
                            }
                        )
                        .frame(height: 280)
                        .padding(.horizontal)
                    }
                    
                    // Send Invitation Button
                    Button {
                        Task {
                            await authenticateAndSend()
                        }
                    } label: {
                        HStack {
                            if isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send Invitation")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colors.primary,
                                    colors.primary.opacity(0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: colors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal)
                    .padding(.top, UnifiedTheme.Spacing.lg)
                    .disabled(isSending || selectedContact == nil || selectedVault == nil)
                    .opacity((selectedContact == nil || selectedVault == nil) ? 0.5 : 1.0)
                }
                .padding(.vertical)
            }
            
            // Face ID Overlay
            if showFaceID {
                FaceIDOverlayView(
                    biometricType: biometricAuth.biometricType(),
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showFaceID = false
                        }
                    }
                )
            }
            
            // Success Overlay
            if showSuccess {
                SuccessOverlayView {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showContactPicker) {
            ContactGridSelectionView(
                onContactSelected: { contact, isExistingUser in
                    selectedContact = contact
                    showContactPicker = false
                    // isExistingUser can be used for different invitation flows if needed
                    print("📱 Selected contact: \(contact.givenName) \(contact.familyName), isExistingUser: \(isExistingUser)")
                },
                onDismiss: {
                    showContactPicker = false
                }
            )
        }
        .sheet(isPresented: $showCloudKitSharing) {
            if let share = cloudKitShare, let vault = selectedVault {
                CloudKitSharingView(
                    vault: vault,
                    share: share,
                    container: CKContainer(identifier: AppConfig.cloudKitContainer),
                    isPresented: $showCloudKitSharing
                )
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .task {
            // Configure services
            if AppConfig.useSupabase {
                if let userID = authService.currentUser?.id {
                    nomineeService.configure(supabaseService: supabaseService, currentUserID: userID)
                } else {
                    nomineeService.configure(supabaseService: supabaseService)
                }
            } else {
            if let userID = authService.currentUser?.id {
                nomineeService.configure(modelContext: modelContext, currentUserID: userID)
            } else {
                nomineeService.configure(modelContext: modelContext)
            }
            cloudKitSharing.configure(modelContext: modelContext)
            }
            
            // Set initial vault if provided
            if let vault = vault {
                selectedVault = vault
            } else if let firstVault = userVaults.first {
                selectedVault = firstVault
            }
        }
    }
    
    private func authenticateAndSend() async {
        guard let contact = selectedContact,
              let vault = selectedVault,
              let userID = authService.currentUser?.id else {
            await MainActor.run {
                errorMessage = "Please select a contact and vault"
                showError = true
            }
            return
        }
        
        // Validate contact has phone or email
        let hasPhone = !contact.phoneNumbers.isEmpty
        let hasEmail = !contact.emailAddresses.isEmpty
        
        guard hasPhone || hasEmail else {
            await MainActor.run {
                errorMessage = "Contact must have a phone number or email address"
                showError = true
            }
            return
        }
        
        // Show Face ID overlay
        await MainActor.run {
            showFaceID = true
        }
        
        // Authenticate
        do {
            let success = try await biometricAuth.authenticate(reason: "Authenticate to send invitation")
            
            await MainActor.run {
                showFaceID = false
            }
            
            guard success else {
                return // User cancelled
            }
            
            // Create nominee
            await MainActor.run {
                isSending = true
            }
            
            let contactName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            let phoneNumber = contact.phoneNumbers.first?.value.stringValue
            let email = contact.emailAddresses.first?.value as String?
            
            let nominee = try await nomineeService.inviteNominee(
                name: contactName.isEmpty ? "Nominee" : contactName,
                phoneNumber: phoneNumber,
                email: email,
                to: vault,
                invitedByUserID: userID
            )
            
            // Get or create CloudKit share
            if let share = try await cloudKitSharing.getOrCreateShare(for: vault) {
                await MainActor.run {
                    createdNominee = nominee
                    cloudKitShare = share
                    isSending = false
                    showCloudKitSharing = true
                }
            } else {
                // Share not available yet, but nominee created
                await MainActor.run {
                    isSending = false
                    showSuccess = true
                }
            }
            
        } catch let error as BiometricAuthError {
            await MainActor.run {
                showFaceID = false
                isSending = false
                errorMessage = error.errorDescription
                showError = true
            }
        } catch {
            await MainActor.run {
                showFaceID = false
                isSending = false
                errorMessage = "Failed to create invitation: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

// MARK: - Success Overlay

struct SuccessOverlayView: View {
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var checkmarkScale: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(checkmarkScale)
                }
                .scaleEffect(scale)
                
                Text("Invitation Sent!")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.black.opacity(0.8))
                    .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 15)
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                scale = 1.0
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    checkmarkScale = 1.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    onDismiss()
                }
            }
        }
    }
}


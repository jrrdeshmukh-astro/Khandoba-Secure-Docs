//
//  SimplifiedContactSelectionView.swift
//  Khandoba Secure Docs
//
//  Simplified contact selection view - directly shows contact picker without vault card
//

import SwiftUI
import Contacts
import SwiftData
import CloudKit

struct SimplifiedContactSelectionView: View {
    let vault: Vault
    let preselectedContacts: [CNContact]
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var vaultService: VaultService
    
    @StateObject private var nomineeService = NomineeService()
    @StateObject private var cloudKitSharing = CloudKitSharingService()
    private let biometricAuth = BiometricAuthService.shared
    
    @State private var showContactPicker = false
    @State private var selectedContacts: [CNContact] = []
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var showFaceID = false
    @State private var showCloudKitSharing = false
    
    init(vault: Vault, preselectedContacts: [CNContact] = []) {
        self.vault = vault
        self.preselectedContacts = preselectedContacts
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    // Header (minimal - just for context)
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(colors.primary)
                        
                        Text("Select Contacts")
                            .font(theme.typography.title)
                            .foregroundColor(colors.textPrimary)
                        
                        Text("Choose who to invite to \(vault.name)")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, UnifiedTheme.Spacing.xl)
                    
                    // Selected Contacts
                    if !selectedContacts.isEmpty {
                        ScrollView {
                            VStack(spacing: UnifiedTheme.Spacing.sm) {
                                ForEach(Array(selectedContacts.enumerated()), id: \.offset) { index, contact in
                                    StandardCard {
                                        HStack {
                                            Image(systemName: "person.circle.fill")
                                                .foregroundColor(colors.primary)
                                                .font(.system(size: 30))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("\(contact.givenName) \(contact.familyName)")
                                                    .font(theme.typography.body)
                                                    .foregroundColor(colors.textPrimary)
                                                
                                                if let phone = contact.phoneNumbers.first?.value.stringValue {
                                                    Text(phone)
                                                        .font(theme.typography.caption)
                                                        .foregroundColor(colors.textSecondary)
                                                }
                                                
                                                if let email = contact.emailAddresses.first?.value as String? {
                                                    Text(email)
                                                        .font(theme.typography.caption)
                                                        .foregroundColor(colors.textSecondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Button {
                                                selectedContacts.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(colors.textTertiary)
                                            }
                                        }
                                        .padding()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Send Invitation Button
                        Button {
                            Task {
                                await sendInvitations()
                            }
                        } label: {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "person.badge.plus")
                                    Text("Send Invitation")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        .disabled(isProcessing || selectedContacts.isEmpty)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Select Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
                #endif
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView(
                    vault: vault,
                    onContactsSelected: { contacts in
                        for contact in contacts {
                            if !selectedContacts.contains(where: { $0.identifier == contact.identifier }) {
                                selectedContacts.append(contact)
                            }
                        }
                        showContactPicker = false
                    },
                    onDismiss: {
                        showContactPicker = false
                    }
                )
            }
            .onAppear {
                // If contacts are preselected, use them; otherwise open contact picker
                if !preselectedContacts.isEmpty {
                    selectedContacts = preselectedContacts
                } else {
                    // Automatically open contact picker when view appears (only if no preselected contacts)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showContactPicker = true
                    }
                }
                
                // Configure services
                cloudKitSharing.configure(modelContext: modelContext)
                
                // iOS-ONLY: Using SwiftData/CloudKit exclusively
                nomineeService.configure(modelContext: modelContext, vaultService: vaultService)
            }
            .sheet(isPresented: $showCloudKitSharing) {
                CloudKitSharingView(
                    vault: vault,
                    container: CKContainer(identifier: AppConfig.cloudKitContainer),
                    isPresented: $showCloudKitSharing
                )
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if showFaceID {
                    FaceIDOverlayView(
                        biometricType: biometricAuth.biometricType(),
                        onCancel: {
                            showFaceID = false
                        }
                    )
                }
                
                if showSuccess {
                    SuccessOverlayView {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendInvitations() async {
        guard !selectedContacts.isEmpty,
              let userID = authService.currentUser?.id else {
            await MainActor.run {
                errorMessage = "Please select at least one contact"
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
            let success = try await biometricAuth.authenticate(reason: "Authenticate to send invitations")
            
            await MainActor.run {
                showFaceID = false
            }
            
            guard success else {
                return // User cancelled
            }
            
            // Process invitations
            await MainActor.run {
                isProcessing = true
            }
            
            var successCount = 0
            var failedContacts: [String] = []
            
            for contact in selectedContacts {
                let contactName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                let phoneNumber = contact.phoneNumbers.first?.value.stringValue
                let email = contact.emailAddresses.first?.value as String?
                
                // Validate contact has phone or email
                guard !contact.phoneNumbers.isEmpty || !contact.emailAddresses.isEmpty else {
                    failedContacts.append(contactName.isEmpty ? "Unknown" : contactName)
                    continue
                }
                
                do {
                    _ = try await nomineeService.inviteNominee(
                        name: contactName.isEmpty ? "Nominee" : contactName,
                        phoneNumber: phoneNumber,
                        email: email,
                        to: vault,
                        invitedByUserID: userID
                    )
                    successCount += 1
                } catch {
                    failedContacts.append(contactName.isEmpty ? "Unknown" : contactName)
                }
            }
            
            // Get or create CloudKit share for sharing
            if successCount > 0 {
                if let _ = try? await cloudKitSharing.getOrCreateShare(for: vault) {
                    await MainActor.run {
                        isProcessing = false
                        showCloudKitSharing = true
                    }
                } else {
                    await MainActor.run {
                        isProcessing = false
                        showSuccess = true
                    }
                }
            } else {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Failed to send invitations. Please try again."
                    showError = true
                }
            }
            
        } catch {
            await MainActor.run {
                showFaceID = false
                isProcessing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}


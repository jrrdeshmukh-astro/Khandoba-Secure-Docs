//
//  UnifiedShareView.swift
//  Khandoba Secure Docs
//
//  Unified sharing: iMessage + Nominee creation + Transfer ownership

import SwiftUI
import SwiftData
import Contacts
import MessageUI
import Combine

enum ShareMode {
    case nominee
    case transfer
}

struct UnifiedShareView: View {
    let vault: Vault
    let mode: ShareMode
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var nomineeService = NomineeService()
    @State private var selectedContacts: [CNContact] = []
    @State private var showContactPicker = false
    @State private var showMessageComposer = false
    @State private var accessLevel: NomineeAccessLevel = .view
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var createdNominees: [Nominee] = []
    
    // Computed properties to avoid type-checking timeout
    private var selectedPhoneNumbers: [String] {
        selectedContacts.flatMap { contact in
            contact.phoneNumbers.compactMap { $0.value.stringValue }
        }
    }
    
    private var invitationMessage: String {
        if mode == .nominee {
            if !createdNominees.isEmpty {
                // Generate message with all tokens
                let tokens = createdNominees.compactMap { $0.inviteToken }
                let deepLinks = tokens.map { "khandoba://invite?token=\($0)" }.joined(separator: "\n")
                return "You've been invited as a nominee for vault '\(vault.name)' in Khandoba Secure Docs. You'll have concurrent access when the owner unlocks it.\n\nTap to accept:\n\(deepLinks)\n\nOr download the app from the App Store!"
            } else {
                return "You've been invited as a nominee for vault '\(vault.name)' in Khandoba Secure Docs. You'll have concurrent access when the owner unlocks it. Download the app from the App Store!"
            }
        } else {
            return "You've been offered ownership of vault '\(vault.name)' in Khandoba Secure Docs. Accept to become the new owner. Download the app!"
        }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Header
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            Image(systemName: mode == .nominee ? "person.2.fill" : "arrow.triangle.2.circlepath")
                                .font(.largeTitle)
                                .foregroundColor(mode == .nominee ? colors.info : colors.warning)
                            
                            Text(mode == .nominee ? "Invite Nominees" : "Transfer Ownership")
                                .font(theme.typography.title)
                                .foregroundColor(colors.textPrimary)
                            
                            Text(mode == .nominee ?
                                 "Grant concurrent access when vault is unlocked" :
                                 "Transfer complete ownership to another user")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        
                        // Vault Info
                        StandardCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(vault.name)
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                if let description = vault.vaultDescription {
                                    Text(description)
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal)
                        
                        // How it works
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(colors.info)
                                    Text("How it works")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textPrimary)
                                        .fontWeight(.semibold)
                                }
                                
                                Text(mode == .nominee ?
                                     "Nominees get real-time concurrent access when you unlock the vault. When you open the vault, they can access it too. No documents are copied - they see the same vault synchronized in real-time." :
                                     "Transfer complete vault ownership to another user. They become the new owner with full control. You will lose all access to this vault and its documents.")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Access Level Selection (only for nominee mode)
                        if mode == .nominee {
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
                            .padding(.horizontal)
                        }
                        
                        // Select Contacts Button
                        Button {
                            showContactPicker = true
                        } label: {
                            HStack {
                                Image(systemName: mode == .nominee ? "person.crop.circle.badge.plus" : "person.crop.circle")
                                Text(mode == .nominee ? "Select Contacts to Invite" : "Select Contact to Transfer To")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        .disabled(isProcessing)
                        .padding(.horizontal)
                        
                        // Selected Contacts
                        if !selectedContacts.isEmpty {
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                    Text("Selected Contacts")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    ForEach(Array(selectedContacts.enumerated()), id: \.offset) { index, contact in
                                        HStack {
                                            Image(systemName: "person.circle.fill")
                                                .foregroundColor(colors.primary)
                                            
                                            Text("\(contact.givenName) \(contact.familyName)")
                                                .font(theme.typography.body)
                                                .foregroundColor(colors.textPrimary)
                                            
                                            Spacer()
                                            
                                            Button {
                                                selectedContacts.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(colors.textTertiary)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Transfer validation
                            if mode == .transfer && selectedContacts.count > 1 {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(colors.warning)
                                    Text("Can only transfer to one person")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.warning)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Send Button
                            Button {
                                if mode == .nominee {
                                    sendInvitationsAndAddNominees()
                                } else {
                                    transferOwnership()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text(mode == .nominee ? "Send Invitations & Add Nominees" : "Transfer Ownership")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(mode == .nominee ? colors.primary : colors.warning)
                                .foregroundColor(.white)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            }
                            .disabled(isProcessing || (mode == .transfer && selectedContacts.count != 1))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle(mode == .nominee ? "Invite Nominees" : "Transfer Ownership")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView(
                    vault: vault,
                    onContactsSelected: { contacts in
                        selectedContacts = contacts
                        showContactPicker = false
                    },
                    onDismiss: {
                        showContactPicker = false
                    }
                )
            }
            .onAppear {
                // Configure nominee service
                nomineeService.configure(modelContext: modelContext)
            }
            .sheet(isPresented: $showMessageComposer) {
                if !selectedContacts.isEmpty && !selectedPhoneNumbers.isEmpty {
                    MessageComposeView(
                        recipients: selectedPhoneNumbers,
                        message: invitationMessage,
                        onDismiss: {
                            showMessageComposer = false
                            selectedContacts = []
                            createdNominees = []
                            dismiss()
                        }
                    )
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func transferOwnership() {
        guard selectedContacts.count == 1 else {
            errorMessage = "Please select exactly one contact to transfer to"
            showError = true
            return
        }
        
        isProcessing = true
        Task {
            do {
                guard let currentUser = authService.currentUser else {
                    throw AppError.authenticationFailed("User not authenticated")
                }
                
                let contact = selectedContacts[0]
                let fullName = "\(contact.givenName) \(contact.familyName)"
                
                // Create transfer request (nominee with special transfer flag)
                let transferNominee = Nominee(
                    name: fullName,
                    phoneNumber: contact.phoneNumbers.first?.value.stringValue,
                    email: contact.emailAddresses.first?.value as String?,
                    status: "transfer_pending"
                )
                transferNominee.vault = vault
                transferNominee.invitedByUserID = currentUser.id
                
                modelContext.insert(transferNominee)
                try modelContext.save()
                
                // Show iMessage composer
                showMessageComposer = true
                
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isProcessing = false
        }
    }
    
    private func sendInvitationsAndAddNominees() {
        isProcessing = true
        
        Task {
            do {
                guard let currentUser = authService.currentUser else {
                    throw AppError.authenticationFailed("User not authenticated")
                }
                
                // 1. Create nominees for each contact using NomineeService
                var created: [Nominee] = []
                for contact in selectedContacts {
                    let fullName = "\(contact.givenName) \(contact.familyName)"
                    let phoneNumber = contact.phoneNumbers.first?.value.stringValue
                    let email = contact.emailAddresses.first?.value as String?
                    
                    let nominee = try await nomineeService.inviteNominee(
                        name: fullName,
                        phoneNumber: phoneNumber,
                        email: email,
                        to: vault,
                        invitedByUserID: currentUser.id
                    )
                    created.append(nominee)
                }
                
                // Store created nominees for message generation
                await MainActor.run {
                    createdNominees = created
                }
                
                // Small delay to ensure CloudKit sync starts
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // 2. Send iMessage invitations
                await MainActor.run {
                showMessageComposer = true
                isProcessing = false
                }
            } catch {
                await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isProcessing = false
                }
            }
        }
    }
}

enum NomineeAccessLevel: String, CaseIterable {
    case view = "view"
    case edit = "edit"
    case full = "full"
    
    var displayName: String {
        switch self {
        case .view: return "View Only"
        case .edit: return "View & Edit"
        case .full: return "Full Access"
        }
    }
    
    var description: String {
        switch self {
        case .view: return "Can view documents when vault is unlocked"
        case .edit: return "Can view and edit documents concurrently"
        case .full: return "Full concurrent access including deletion"
        }
    }
    
    var icon: String {
        switch self {
        case .view: return "eye.fill"
        case .edit: return "pencil.circle.fill"
        case .full: return "key.fill"
        }
    }
}

struct AccessLevelRow: View {
    let level: NomineeAccessLevel
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: action) {
            HStack {
                Image(systemName: level.icon)
                    .foregroundColor(colors.primary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(theme.typography.body)
                        .foregroundColor(colors.textPrimary)
                    
                    Text(level.description)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(colors.primary)
                }
            }
            .padding()
            .background(isSelected ? colors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(UnifiedTheme.CornerRadius.md)
        }
    }
}

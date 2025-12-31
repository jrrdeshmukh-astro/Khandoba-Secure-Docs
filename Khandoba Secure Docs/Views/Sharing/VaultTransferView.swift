//
//  VaultTransferView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct VaultTransferView: View {
    let vault: Vault
    let preselectedNominee: Nominee?
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var nomineeService = NomineeService()
    
    @State private var selectedUserID: UUID?
    @State private var reason = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var availableUsers: [User] = []
    @State private var nominees: [Nominee] = []
    
    init(vault: Vault, preselectedNominee: Nominee? = nil) {
        self.vault = vault
        self.preselectedNominee = preselectedNominee
    }
    
    private var colors: UnifiedTheme.Colors {
        theme.colors(for: colorScheme)
    }
    
    var body: some View {
        NavigationStack {
            contentView
        }
        .navigationTitle("Transfer Ownership")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            // iOS-ONLY: Using SwiftData/CloudKit exclusively
            nomineeService.configure(
                modelContext: modelContext,
                currentUserID: authService.currentUser?.id
            )
            await loadNominees()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    warningSection
                    ownerSelectionSection
                    reasonSection
                    submitButtonSection
                }
                .padding(.vertical)
            }
        }
    }
    
    @ViewBuilder
    private var warningSection: some View {
        StandardCard {
            HStack(spacing: UnifiedTheme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(colors.warning)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ownership Transfer")
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                        .fontWeight(.semibold)
                    
                    Text("This action requires admin approval and cannot be undone")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var ownerSelectionSection: some View {
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
            Text("Select New Owner")
                .font(theme.typography.headline)
                .foregroundColor(colors.textPrimary)
                .padding(.horizontal)
            
            if availableUsers.isEmpty {
                emptyUsersView
            }
            
            ForEach(availableUsers) { user in
                userSelectionRow(user: user)
            }
        }
    }
    
    @ViewBuilder
    private var emptyUsersView: some View {
        StandardCard {
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 40))
                    .foregroundColor(colors.textSecondary)
                
                Text("No Nominated Users")
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                Text("You can only transfer ownership to users who are already nominated for this vault. Please nominate users first.")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func userSelectionRow(user: User) -> some View {
        Button {
            selectedUserID = user.id
        } label: {
            StandardCard {
                HStack {
                    userAvatarView(user: user)
                    Text(user.fullName)
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                    Spacer()
                    if selectedUserID == user.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(colors.primary)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func userAvatarView(user: User) -> some View {
        if let imageData = user.profilePictureData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(colors.primary.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(String(user.fullName.prefix(1)))
                    .foregroundColor(colors.primary)
            }
        }
    }
    
    @ViewBuilder
    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
            Text("Reason (Optional)")
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textSecondary)
                .padding(.horizontal)
            
            TextField("Why are you transferring this vault?", text: $reason, axis: .vertical)
                .font(theme.typography.body)
                .lineLimit(3...6)
                .padding(UnifiedTheme.Spacing.md)
                .background(colors.surface)
                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var submitButtonSection: some View {
        Button {
            submitTransferRequest()
        } label: {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Request Transfer")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(selectedUserID == nil || isLoading)
        .padding(.horizontal)
    }
    
    private func loadNominees() async {
        do {
            // iOS-ONLY: Using SwiftData/CloudKit exclusively
            // Load nominees for this vault
            try await nomineeService.loadNominees(for: vault, includeInactive: false)
            nominees = nomineeService.nominees
            // If preselectedNominee is provided, pre-select it
            if let preselected = preselectedNominee,
               preselected.status == .accepted || preselected.status == .active {
                // Find the user matching this nominee
                // Note: lowercased() is not supported in predicates, so we normalize before
                if let nomineeEmail = preselected.email, !nomineeEmail.isEmpty {
                    let normalizedEmail = nomineeEmail.lowercased()
                    let userDescriptor = FetchDescriptor<User>(
                        predicate: #Predicate { user in
                            user.email == normalizedEmail
                        }
                    )
                    if let matchingUser = try? modelContext.fetch(userDescriptor).first {
                        await MainActor.run {
                            selectedUserID = matchingUser.id
                        }
                    }
                }
            }

            // Get users who are nominees (only accepted nominees can receive ownership)
            // Match nominees to users by email (User model doesn't have phoneNumber)
            let acceptedNomineeIDs = nominees
                .filter { $0.status == .accepted || $0.status == .active }
                .compactMap { nominee -> UUID? in
                    // Try to find user by email
                    if let email = nominee.email, !email.isEmpty {
                        let userDescriptor = FetchDescriptor<User>(
                            predicate: #Predicate { user in
                                user.email == email
                            }
                        )
                        if let user = try? modelContext.fetch(userDescriptor).first {
                            return user.id
                        }
                    }
                    return nil
                }
            
            // Fetch users who are nominees
            if !acceptedNomineeIDs.isEmpty {
                let userDescriptor = FetchDescriptor<User>(
                    predicate: #Predicate { user in
                        acceptedNomineeIDs.contains(user.id)
                    }
                )
                if let users = try? modelContext.fetch(userDescriptor) {
                    availableUsers = users.filter { $0.id != authService.currentUser?.id }
                }
            } else {
                availableUsers = []
            }
        } catch {
            errorMessage = "Failed to load nominees: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func submitTransferRequest() {
        guard let newOwnerID = selectedUserID,
              let requestedByUserID = authService.currentUser?.id else { return }
        
        // Validate that the selected user is a nominee
        // Match by email (User model doesn't have phoneNumber)
        guard let matchingNominee = nominees.first(where: { nominee in
            // Check if nominee matches the selected user by email
            if let user = availableUsers.first(where: { $0.id == newOwnerID }) {
                if let nomineeEmail = nominee.email, !nomineeEmail.isEmpty,
                   let userEmail = user.email, !userEmail.isEmpty,
                   nomineeEmail.lowercased() == userEmail.lowercased() {
                    return true
                }
            }
            return false
        }) else {
            errorMessage = "You can only transfer ownership to users who are already nominated for this vault."
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // iOS-ONLY: Using SwiftData/CloudKit exclusively
                // Create transfer request locally
                let request = VaultTransferRequest(
                    reason: reason.isEmpty ? nil : reason,
                    newOwnerID: newOwnerID
                )
                request.vault = vault
                request.requestedByUserID = requestedByUserID
                
                // Link transfer request to nominee for notification
                // Store nominee ID in transfer request metadata (using newOwnerEmail as identifier)
                if let nomineeEmail = matchingNominee.email {
                    request.newOwnerEmail = nomineeEmail
                    request.newOwnerName = matchingNominee.name
                }
                
                modelContext.insert(request)
                try modelContext.save()
                
                // Notify the nominee about the transfer request
                // The nominee will see this when they accept their invitation
                // or when they view their nominee status
                print("📤 Transfer request created for nominee: \(matchingNominee.name)")
                print("   Nominee will be notified when they accept their invitation")
                
                await MainActor.run {
                    dismiss()
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


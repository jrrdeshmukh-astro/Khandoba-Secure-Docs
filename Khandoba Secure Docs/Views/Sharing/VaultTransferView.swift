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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var selectedUserID: UUID?
    @State private var reason = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var availableUsers: [User] = []
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Warning
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
                        
                        // Select New Owner
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Select New Owner")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                                .padding(.horizontal)
                            
                            ForEach(availableUsers) { user in
                                Button {
                                    selectedUserID = user.id
                                } label: {
                                    StandardCard {
                                        HStack {
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
                        }
                        
                        // Reason
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
                        
                        // Submit Button
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
                    .padding(.vertical)
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
        }
        .task {
            await loadUsers()
        }
    }
    
    private func loadUsers() async {
        // Load all users except current user
        let descriptor = FetchDescriptor<User>()
        if let users = try? modelContext.fetch(descriptor) {
            availableUsers = users.filter { $0.id != authService.currentUser?.id }
        }
    }
    
    private func submitTransferRequest() {
        guard let newOwnerID = selectedUserID,
              let requestedByUserID = authService.currentUser?.id else { return }
        
        isLoading = true
        
        let request = VaultTransferRequest(
            reason: reason.isEmpty ? nil : reason,
            newOwnerID: newOwnerID
        )
        request.vault = vault
        request.requestedByUserID = requestedByUserID
        
        modelContext.insert(request)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}


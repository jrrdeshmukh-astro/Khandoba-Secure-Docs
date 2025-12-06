//
//  NomineeManagementView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct NomineeManagementView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var chatService: ChatService
    
    @StateObject private var nomineeService = NomineeService()
    @State private var showAddNominee = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    if nomineeService.nominees.isEmpty {
                        EmptyStateView(
                            icon: "person.badge.plus",
                            title: "No Nominees",
                            message: "Invite people to access this vault",
                            actionTitle: "Invite Nominee"
                        ) {
                            showAddNominee = true
                        }
                    } else {
                        LazyVStack(spacing: UnifiedTheme.Spacing.sm) {
                            ForEach(nomineeService.nominees) { nominee in
                                NomineeRow(nominee: nominee, vault: vault) {
                                    await removeNominee(nominee)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Nominees")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddNominee = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(colors.primary)
                }
            }
        }
        .sheet(isPresented: $showAddNominee) {
            AddNomineeView(vault: vault)
        }
        .task {
            nomineeService.configure(modelContext: modelContext)
            
            // Configure chat service
            if let userID = authService.currentUser?.id {
                chatService.configure(modelContext: modelContext, userID: userID)
            }
            
            do {
                try await nomineeService.loadNominees(for: vault)
            } catch {
                print(" Failed to load nominees: \(error.localizedDescription)")
            }
        }
        .onChange(of: showAddNominee) { oldValue, newValue in
            // Reload nominees when the add sheet is dismissed
            if oldValue == true && newValue == false {
                Task {
                    try? await nomineeService.loadNominees(for: vault)
                }
            }
        }
        .refreshable {
            // Pull to refresh
            try? await nomineeService.loadNominees(for: vault)
        }
    }
    
    private func removeNominee(_ nominee: Nominee) async {
        try? await nomineeService.removeNominee(nominee)
    }
}

struct NomineeRow: View {
    let nominee: Nominee
    let vault: Vault
    let onRemove: () async -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var chatService: ChatService
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.fill")
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(nominee.name)
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                    
                    Text(nominee.status.capitalized)
                        .font(theme.typography.caption)
                        .foregroundColor(statusColor)
                    
                    if nominee.status == "pending" {
                        Text("Invited \(nominee.invitedAt, style: .relative)")
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Chat button (only for accepted/active nominees)
                if nominee.status == "accepted" || nominee.status == "active" {
                    NavigationLink {
                        SecureNomineeChatView(vault: vault, nominee: nominee)
                    } label: {
                        Image(systemName: "message.fill")
                            .foregroundColor(colors.primary)
                    }
                }
                
                Button {
                    Task {
                        await onRemove()
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(colors.error)
                }
            }
        }
    }
    
    private var statusColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch nominee.status {
        case "pending": return colors.warning
        case "accepted", "active": return colors.success
        default: return colors.textTertiary
        }
    }
}

struct AddNomineeView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var nomineeService = NomineeService()
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                            Text("Name")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                            
                            TextField("Nominee name", text: $name)
                                .font(theme.typography.body)
                                .padding(UnifiedTheme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                            Text("Phone Number (Optional)")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                            
                            TextField("+1 (555) 123-4567", text: $phoneNumber)
                                .font(theme.typography.body)
                                .keyboardType(.phonePad)
                                .padding(UnifiedTheme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                            Text("Email (Optional)")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                            
                            TextField("email@example.com", text: $email)
                                .font(theme.typography.body)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .padding(UnifiedTheme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(colors.info)
                                    Text("Invitation Process")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textPrimary)
                                        .fontWeight(.semibold)
                                }
                                
                                Text("An invitation will be sent via Messages app. The nominee will receive a secure link to accept access to this vault.")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                        
                        Button {
                            sendInvite()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Invitation")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(name.isEmpty || isLoading)
                    }
                    .padding(UnifiedTheme.Spacing.lg)
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
            .onAppear {
                nomineeService.configure(modelContext: modelContext)
            }
        }
    }
    
    private func sendInvite() {
        guard let userID = authService.currentUser?.id else {
            errorMessage = "User not authenticated"
            showError = true
            return
        }
        
        isLoading = true
        Task {
            do {
                print("📤 Sending invitation to: \(name)")
                let nominee = try await nomineeService.inviteNominee(
                    name: name,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                    email: email.isEmpty ? nil : email,
                    to: vault,
                    invitedByUserID: userID
                )
                
                print(" Invitation sent successfully")
                print("   Nominee ID: \(nominee.id)")
                print("   Nominee Token: \(nominee.inviteToken)")
                print("   Vault: \(vault.name)")
                
                // Small delay to ensure CloudKit sync starts
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print(" Failed to send invitation: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}


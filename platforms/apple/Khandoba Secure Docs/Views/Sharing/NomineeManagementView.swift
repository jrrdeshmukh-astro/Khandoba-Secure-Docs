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
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var supabaseService: SupabaseService
    
    @StateObject private var nomineeService = NomineeService()
    @State private var showError = false
    @State private var errorMessage = ""
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
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddNominee = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(colors.primary)
                }
            }
            #else
            ToolbarItem(placement: .automatic) {
                Button {
                    showAddNominee = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(colors.primary)
                }
            }
            #endif
        }
        .sheet(isPresented: $showAddNominee) {
            NomineeInvitationView(vault: vault)
                .onDisappear {
                    Task {
                        try? await nomineeService.loadNominees(for: vault)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            // Configure nominee service with current user ID
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
            }
            
            // Configure chat service
            if let userID = authService.currentUser?.id {
                if AppConfig.useSupabase {
                    chatService.configure(supabaseService: supabaseService, userID: userID)
                } else {
                chatService.configure(modelContext: modelContext, userID: userID)
                }
            }
            
            do {
                try await nomineeService.loadNominees(for: vault)
            } catch {
                print(" Failed to load nominees: \(error.localizedDescription)")
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
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var vaultService: VaultService
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    
    @State private var showTransferOwnership = false
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                    
                    Text(nominee.status.displayName)
                        .font(theme.typography.caption)
                        .foregroundColor(statusColor)
                    
                    if nominee.status == .pending {
                        Text("Invited \(nominee.invitedAt, style: .relative)")
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Transfer Ownership button (only for accepted nominees)
                if nominee.status == .accepted || nominee.status == .active {
                    Button {
                        showTransferOwnership = true
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(colors.warning)
                    }
                }
                
                // Chat button (only for accepted/active nominees)
                if nominee.status == .accepted || nominee.status == .active {
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
        .sheet(isPresented: $showTransferOwnership) {
            VaultTransferView(vault: vault, preselectedNominee: nominee)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var statusColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch nominee.status {
        case .pending: return colors.warning
        case .accepted, .active: return colors.success
        case .inactive, .revoked: return colors.textTertiary
        }
    }
}

// MARK: - Nominee Invitation Flow
// Nominee invitations are created via native Apple Pay-style flow
// Flow: User taps "+" → NomineeInvitationView opens → Select contact → Select vault → Face ID → CloudKit sharing


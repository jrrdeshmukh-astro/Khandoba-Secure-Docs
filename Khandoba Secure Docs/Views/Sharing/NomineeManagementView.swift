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
                .onDisappear {
                    // Reload nominees when sheet dismisses
                    Task {
                        try? await nomineeService.loadNominees(for: vault)
                    }
                }
        }
        .task {
            // Configure nominee service with current user ID
            if let userID = authService.currentUser?.id {
                nomineeService.configure(modelContext: modelContext, currentUserID: userID)
            } else {
                nomineeService.configure(modelContext: modelContext)
            }
            
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

// MARK: - AddNomineeView
// Nominee invitations are created via AddNomineeView which generates invite links
// Flow: User taps "+" → AddNomineeView → Create nominee → Get invite link → Share via Messages/Email/etc.


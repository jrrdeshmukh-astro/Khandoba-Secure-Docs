//
//  UnifiedNomineeManagementView.swift
//  Khandoba Secure Docs
//
//  Unified view for managing nominees - combines Access Control and Manage Nominees
//

import SwiftUI
import SwiftData
import CloudKit

struct UnifiedNomineeManagementView: View {
    let vault: Vault
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var chatService: ChatService
    
    @StateObject private var nomineeService = NomineeService()
    @StateObject private var cloudKitSharing = CloudKitSharingService()
    
    @State private var showAddNominee = false
    @State private var showCloudKitSharing = false
    @State private var cloudKitShare: CKShare?
    @State private var selectedNominee: Nominee?
    
    private var isOwner: Bool {
        vault.owner?.id == authService.currentUser?.id
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    // Header Info
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(colors.primary)
                                Text("Nominee Management")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                            }
                            
                            Text("Manage who can access this vault when it's unlocked")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Owner Section
                    if isOwner {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("OWNER")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                                .padding(.horizontal)
                            
                            StandardCard {
                                AccessUserRow(
                                    name: vault.owner?.fullName ?? "Unknown",
                                    role: "Owner",
                                    status: "Active",
                                    isYou: true,
                                    canRevoke: false,
                                    colors: colors,
                                    theme: theme,
                                    onRevoke: {}
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Nominees Section (Apple Cash style - card-based)
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text("NOMINEES")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                            .padding(.horizontal)
                        
                        // Add Nominee Card (Apple Cash style - like "Add Card")
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showAddNominee = true
                            }
                        } label: {
                            HStack(spacing: UnifiedTheme.Spacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    colors.primary.opacity(0.25),
                                                    colors.primary.opacity(0.15)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 52, height: 52)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 26, weight: .semibold))
                                        .foregroundColor(colors.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Add Nominee")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Text("Invite to vault")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(colors.textTertiary)
                            }
                            .padding(22)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                colors.surface,
                                                colors.surface.opacity(0.95)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        colors.primary.opacity(0.4),
                                                        colors.primary.opacity(0.2)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                    .shadow(color: colors.primary.opacity(0.15), radius: 8, x: 0, y: 3)
                            )
                        }
                        .padding(.horizontal)
                        .buttonStyle(PlainButtonStyle())
                        
                        // Nominee Cards (Apple Cash style - like payment method cards)
                        if nomineeService.nominees.isEmpty {
                            VStack(spacing: UnifiedTheme.Spacing.md) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(colors.textTertiary)
                                
                                Text("No Nominees")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                Text("Tap 'Add Nominee' to invite someone")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, UnifiedTheme.Spacing.xl)
                        } else {
                            ForEach(nomineeService.nominees, id: \.id) { nominee in
                                NomineeCardView(
                                    nominee: nominee,
                                    vault: vault,
                                    colors: colors,
                                    theme: theme,
                                    onRemove: {
                                        Task {
                                            await removeNominee(nominee)
                                        }
                                    },
                                    onShare: {
                                        selectedNominee = nominee
                                        Task {
                                            await presentCloudKitSharing()
                                        }
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Access History Button (Owner only)
                    if isOwner {
                        NavigationLink {
                            VaultAccessHistoryView(vault: vault)
                        } label: {
                            StandardCard {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(colors.primary)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Access History")
                                            .font(theme.typography.subheadline)
                                            .foregroundColor(colors.textPrimary)
                                        
                                        Text("View all vault access logs")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(colors.textTertiary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
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
                    // Reload nominees when sheet dismisses
                    Task {
                        try? await nomineeService.loadNominees(for: vault)
                    }
                }
        }
        .sheet(isPresented: $showCloudKitSharing) {
            if let share = cloudKitShare {
                CloudKitSharingView(
                    vault: vault,
                    share: share,
                    container: CKContainer(identifier: AppConfig.cloudKitContainer),
                    isPresented: $showCloudKitSharing
                )
            }
        }
        .task {
            // iOS-ONLY: Using SwiftData/CloudKit exclusively
            // Configure services
            if let userID = authService.currentUser?.id {
                nomineeService.configure(modelContext: modelContext, currentUserID: userID)
            } else {
                nomineeService.configure(modelContext: modelContext)
            }
            cloudKitSharing.configure(modelContext: modelContext)
            
            if let userID = authService.currentUser?.id {
                chatService.configure(modelContext: modelContext, userID: userID)
            }
            
            // Load nominees
            do {
                try await nomineeService.loadNominees(for: vault)
            } catch {
                print("❌ Failed to load nominees: \(error.localizedDescription)")
            }
        }
        .refreshable {
            try? await nomineeService.loadNominees(for: vault)
        }
    }
    
    private func removeNominee(_ nominee: Nominee) async {
        try? await nomineeService.removeNominee(nominee)
    }
    
    private func presentCloudKitSharing() async {
        print("📤 Presenting CloudKit sharing for vault: \(vault.name)")
        
        do {
            if let share = try await cloudKitSharing.getOrCreateShare(for: vault) {
                await MainActor.run {
                    cloudKitShare = share
                    showCloudKitSharing = true
                }
                print("   ✅ CloudKit sharing controller will be presented")
            } else {
                print("   ⚠️ Could not create CloudKit share - using fallback")
                // Fallback: show add nominee view with manual sharing
                await MainActor.run {
                    showAddNominee = true
                }
            }
        } catch {
            print("   ❌ Failed to prepare CloudKit share: \(error.localizedDescription)")
            // Fallback: show add nominee view with manual sharing
            await MainActor.run {
                showAddNominee = true
            }
        }
    }
}

// MARK: - Nominee Card View (Apple Cash Style)

struct NomineeCardView: View {
    let nominee: Nominee
    let vault: Vault
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    let onRemove: () async -> Void
    let onShare: () async -> Void
    
    @EnvironmentObject var chatService: ChatService
    @State private var showRevokeConfirm = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Content
            HStack(spacing: UnifiedTheme.Spacing.md) {
                // Avatar (Apple Cash style)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    statusColor,
                                    statusColor.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(nominee.name)
                        .font(theme.typography.headline)
                        .foregroundColor(colors.textPrimary)
                    
                    HStack(spacing: 8) {
                        // Status badge
                        Text(nominee.status.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.15))
                            .cornerRadius(6)
                        
                        if nominee.status == .pending {
                            Text("Invited \(nominee.invitedAt, style: .relative)")
                                .font(theme.typography.caption2)
                                .foregroundColor(colors.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: UnifiedTheme.Spacing.sm) {
                    // Chat button
                    if nominee.status == .accepted || nominee.status == .active {
                        NavigationLink {
                            SecureNomineeChatView(vault: vault, nominee: nominee)
                        } label: {
                            Image(systemName: "message.fill")
                                .font(.system(size: 18))
                                .foregroundColor(colors.primary)
                                .frame(width: 36, height: 36)
                                .background(colors.primary.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    
                    // Revoke button (swipe to reveal in future)
                    Button {
                        showRevokeConfirm = true
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16))
                            .foregroundColor(colors.error)
                            .frame(width: 36, height: 36)
                            .background(colors.error.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colors.surface,
                                colors.surface.opacity(0.95)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
        }
        .alert("Revoke Access", isPresented: $showRevokeConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Revoke", role: .destructive) {
                Task {
                    await onRemove()
                }
            }
        } message: {
            Text("Revoke access for \(nominee.name)? They will no longer be able to access this vault.")
        }
    }
    
    private var statusColor: Color {
        switch nominee.status {
        case .pending: return colors.warning
        case .accepted, .active: return colors.success
        case .inactive, .revoked: return colors.textTertiary
        }
    }
}

// MARK: - Nominee Management Row (Legacy - kept for compatibility)

struct NomineeManagementRow: View {
    let nominee: Nominee
    let vault: Vault
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    let onRemove: () async -> Void
    let onShare: () async -> Void
    
    @EnvironmentObject var chatService: ChatService
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "person.fill")
                    .foregroundColor(statusColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(nominee.name)
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                
                HStack(spacing: 8) {
                    // Status badge
                    Text(nominee.status.displayName)
                        .font(.caption2)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.15))
                        .cornerRadius(4)
                    
                    if nominee.status == .pending {
                        Text("Invited \(nominee.invitedAt, style: .relative)")
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: UnifiedTheme.Spacing.sm) {
                // Chat button (only for accepted/active nominees)
                if nominee.status == .accepted || nominee.status == .active {
                    NavigationLink {
                        SecureNomineeChatView(vault: vault, nominee: nominee)
                    } label: {
                        Image(systemName: "message.fill")
                            .foregroundColor(colors.primary)
                    }
                }
                
                // Share button (for pending nominees - resend invitation)
                if nominee.status == .pending {
                    Button {
                        Task {
                            await onShare()
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(colors.info)
                    }
                }
                
                // Remove button
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
        .padding()
    }
    
    private var statusColor: Color {
        switch nominee.status {
        case .pending: return colors.warning
        case .accepted, .active: return colors.success
        case .inactive, .revoked: return colors.textTertiary
        }
    }
}

// MARK: - Instruction Step Helper
struct InstructionStep: View {
    let number: String
    let text: String
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(theme.typography.caption)
                .foregroundColor(colors.primary)
                .fontWeight(.semibold)
            Text(text)
                .font(theme.typography.caption)
                .foregroundColor(colors.textSecondary)
        }
    }
}


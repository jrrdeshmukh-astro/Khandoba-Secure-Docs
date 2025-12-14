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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
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
                    
                    // Nominees Section
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        HStack {
                            Text("NOMINEES (\(nomineeService.nominees.count))")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                            
                            Spacer()
                            
                            Button {
                                showAddNominee = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(colors.primary)
                            }
                        }
                        .padding(.horizontal)
                        
                        if nomineeService.nominees.isEmpty {
                            StandardCard {
                                VStack(spacing: UnifiedTheme.Spacing.md) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.largeTitle)
                                        .foregroundColor(colors.textTertiary)
                                    
                                    Text("No Nominees")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Text("Invite people to access this vault")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textSecondary)
                                    
                                    // Invite via iMessage button (Apple Cash style)
                                    #if !APP_EXTENSION
                                    Button {
                                        Task {
                                            await openMessagesForNomination()
                                        }
                                    } label: {
                                        HStack(spacing: UnifiedTheme.Spacing.sm) {
                                            Image(systemName: "message.fill")
                                                .font(.title3)
                                            Text("Invite via iMessage")
                                                .font(theme.typography.headline)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, UnifiedTheme.Spacing.md)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [colors.primary, colors.secondary]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                    }
                                    .padding(.top, UnifiedTheme.Spacing.md)
                                    #endif
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, UnifiedTheme.Spacing.xl)
                            }
                        } else {
                            StandardCard {
                                VStack(spacing: 0) {
                                    ForEach(Array(nomineeService.nominees.enumerated()), id: \.element.id) { index, nominee in
                                        NomineeManagementRow(
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
                                        
                                        if index < nomineeService.nominees.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
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
            // Show info about using iMessage app instead of old flow
            NavigationStack {
                ZStack {
                    colors.background.ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: UnifiedTheme.Spacing.xl) {
                            // Header
                            VStack(spacing: UnifiedTheme.Spacing.md) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(colors.primary)
                                
                                Text("Invite via iMessage")
                                    .font(theme.typography.title)
                                    .foregroundColor(colors.textPrimary)
                            }
                            .padding(.top, UnifiedTheme.Spacing.xl)
                            
                            // Instructions
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                    Text("How to Invite Nominees")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                        InstructionStep(
                                            number: "1",
                                            text: "Open the Messages app",
                                            colors: colors,
                                            theme: theme
                                        )
                                        
                                        InstructionStep(
                                            number: "2",
                                            text: "Start or open a conversation",
                                            colors: colors,
                                            theme: theme
                                        )
                                        
                                        InstructionStep(
                                            number: "3",
                                            text: "Tap the App Store icon (📱) at the bottom",
                                            colors: colors,
                                            theme: theme
                                        )
                                        
                                        InstructionStep(
                                            number: "4",
                                            text: "Select 'Khandoba' → 'Invite to Vault'",
                                            colors: colors,
                                            theme: theme
                                        )
                                        
                                        InstructionStep(
                                            number: "5",
                                            text: "Select vault and enter recipient name",
                                            colors: colors,
                                            theme: theme
                                        )
                                    }
                                }
                                .padding()
                            }
                            .padding(.horizontal)
                            
                            // Note
                            StandardCard {
                                HStack(alignment: .top, spacing: UnifiedTheme.Spacing.sm) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(colors.info)
                                    
                                    Text("All nominee invitations are now handled through the iMessage app for a seamless, secure experience.")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                                .padding()
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
                .navigationTitle("Invite Nominee")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showAddNominee = false
                        }
                        .foregroundColor(colors.primary)
                    }
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
        .alert("Messages App Error", isPresented: $showMessagesError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(messagesErrorMessage)
        }
        .task {
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
    
    @State private var showMessagesError = false
    @State private var messagesErrorMessage = ""
    
    private func openMessagesForNomination() async {
        #if !APP_EXTENSION
        // Open Messages app with vault context
        let success = await MessagesRedirectService.shared.openMessagesAppForNomination(vaultID: vault.id)
        
        if !success {
            // Show error alert if Messages app couldn't be opened
            await MainActor.run {
                messagesErrorMessage = "Unable to open Messages app. Please make sure Messages is installed and try again."
                showMessagesError = true
            }
        }
        #else
        // Not available in extensions
        await MainActor.run {
            messagesErrorMessage = "This feature is not available in extensions."
            showMessagesError = true
        }
        #endif
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

// MARK: - Nominee Management Row

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


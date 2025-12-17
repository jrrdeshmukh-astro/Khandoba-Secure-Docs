//
//  VaultDetailView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Contacts
import MessageUI

struct VaultDetailView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var vaultService: VaultService
    @EnvironmentObject var documentService: DocumentService
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var supabaseService: SupabaseService
    @StateObject private var nomineeService = NomineeService()
    
    @State private var isLoading = false
    @State private var currentNominee: Nominee? // Current user's nominee record if they're a nominee
    @State private var sessionExpirationTimer: Timer?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showUploadSheet = false
    @State private var showDocumentPicker = false
    @State private var showNomineeInvitation = false
    @State private var showTransferOwnership = false
    
    @EnvironmentObject var authService: AuthenticationService
    
    // Face ID gate
    @State private var isBiometricallyUnlocked = false
    @State private var attemptedAutoUnlock = false
    @State private var authInProgress = false
    @State private var localHasActiveSession = false
    
    private var isIntelVault: Bool {
        vault.name == "Intel Vault"
    }
    
    private var isOwner: Bool {
        // If vault has no owner, treat current user as owner (fallback)
        if vault.owner == nil {
            return true
        }
        return vault.owner?.id == authService.currentUser?.id
    }
    
    private var hasPendingDualKeyRequest: Bool {
        guard vault.keyType == "dual" else { return false }
        let requests = vault.dualKeyRequests ?? []
        return requests.contains { $0.status == "pending" }
    }
    
    // Computed properties to simplify type checking
    private var viewColors: UnifiedTheme.Colors {
        theme.colors(for: colorScheme)
    }
    
    private var hasActiveSession: Bool {
        vaultService.hasActiveSession(for: vault.id)
    }
    
    private var hasPendingRequest: Bool {
        hasPendingDualKeyRequest
    }
    
    var body: some View {
        bodyContent
    }
    
    @ViewBuilder
    private var bodyContent: some View {
        let colors = viewColors
        
        ZStack {
            themeColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    if vault.keyType == "dual" && hasPendingRequest {
                        StandardCard {
                            HStack(spacing: UnifiedTheme.Spacing.md) {
                                Image(systemName: "hourglass.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(colors.warning)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Unlock Request Pending")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textPrimary)
                                        .fontWeight(.semibold)
                                    
                                    Text("Waiting for admin approval to unlock vault")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .padding(.horizontal)
                    }
                    
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            HStack {
                                if vault.keyType == "dual" {
                                    HStack(spacing: -4) {
                                        Image(systemName: "key.fill")
                                            .font(.title3)
                                            .foregroundColor(hasActiveSession ? colors.success : colors.error)
                                        Image(systemName: "key.fill")
                                            .font(.title3)
                                            .foregroundColor(hasActiveSession ? colors.success : colors.error)
                                            .rotationEffect(.degrees(20))
                                    }
                                } else {
                                    Image(systemName: hasActiveSession ? "lock.open.fill" : "lock.fill")
                                        .font(.title2)
                                        .foregroundColor(hasActiveSession ? colors.success : colors.error)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(vault.name)
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    HStack(spacing: 4) {
                                        Text(hasActiveSession ? "Unlocked" : "Locked")
                                            .font(theme.typography.subheadline)
                                            .foregroundColor(hasActiveSession ? colors.success : colors.error)
                                        
                                        if vault.keyType == "dual" {
                                            Text("•")
                                                .foregroundColor(colors.textTertiary)
                                            Text("Dual-Key")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.warning)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(colors.warning.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            if !hasActiveSession {
                                Button {
                                    openVault()
                                } label: {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "lock.open.fill")
                                        }
                                        Text(isLoading ? "Unlocking..." : "Unlock Vault")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(isLoading || !isBiometricallyUnlocked)
                            } else {
                                Button {
                                    lockVault()
                                } label: {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                        Text("Lock Vault")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if let session = vaultService.activeSessions[vault.id] {
                        SessionTimerView(session: session) {
                            await extendSession()
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Security & Intelligence")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                            .padding(.horizontal)
                        
                        StandardCard {
                            VStack(spacing: 0) {
                                NavigationLink {
                                    AccessMapView(vault: vault)
                                } label: {
                                    SecurityActionRow(
                                        icon: "map.fill",
                                        title: "Access Map",
                                        subtitle: "View access locations",
                                        color: colors.info
                                    )
                                }
                                
                                Divider()
                                
                                NavigationLink {
                                    EnhancedThreatMonitorView(vault: vault)
                                } label: {
                                    SecurityActionRow(
                                        icon: "shield.checkered",
                                        title: "Threat Monitor",
                                        subtitle: "ML-powered security analysis",
                                        color: colors.warning
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Vault Management - only show for owners
                    if isOwner && !vault.isSystemVault {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Vault Management")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                                .padding(.horizontal)
                            
                            StandardCard {
                                VStack(spacing: 0) {
                                    Button {
                                        showTransferOwnership = true
                                    } label: {
                                        SecurityActionRow(
                                            icon: "arrow.triangle.2.circlepath",
                                            title: "Transfer Ownership",
                                            subtitle: "Transfer vault to another user",
                                            color: colors.warning
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Media Actions - only show for active vaults with active session
                    if hasActiveSession && !vault.isSystemVault && vault.status != "archived" {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Media Actions")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                                .padding(.horizontal)
                            
                            StandardCard {
                                VStack(spacing: 0) {
                                    NavigationLink {
                                        VideoRecordingView(vault: vault)
                                    } label: {
                                        SecurityActionRow(
                                            icon: "video.fill",
                                            title: "Record Video",
                                            subtitle: "",
                                            color: colors.error
                                        )
                                    }
                                    
                                    Divider()
                                    
                                    NavigationLink {
                                        VoiceRecordingView(vault: vault)
                                    } label: {
                                        SecurityActionRow(
                                            icon: "waveform",
                                            title: "Voice Memo",
                                            subtitle: "",
                                            color: colors.secondary
                                        )
                                    }
                                    
                                    Divider()
                                    
                                    NavigationLink {
                                        BulkUploadView(vault: vault)
                                    } label: {
                                        SecurityActionRow(
                                            icon: "square.stack.3d.up.fill",
                                            title: "Bulk Upload",
                                            subtitle: "Upload multiple files",
                                            color: colors.primary
                                        )
                                    }
                                    
                                    Divider()
                                    
                                    NavigationLink {
                                        URLDownloadView(vault: vault)
                                    } label: {
                                        SecurityActionRow(
                                            icon: "link.circle.fill",
                                            title: "Download from URL",
                                            subtitle: "Save assets from public links",
                                            color: colors.info
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Emergency")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                            .padding(.horizontal)
                        
                        StandardCard {
                            NavigationLink {
                                EmergencyAccessView(vault: vault)
                            } label: {
                                SecurityActionRow(
                                    icon: "exclamationmark.triangle.fill",
                                    title: "Emergency Access",
                                    subtitle: "Request emergency protocol",
                                    color: colors.error
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Show pending emergency approvals if user is vault owner
                        if vault.owner?.id == authService.currentUser?.id {
                            StandardCard {
                                NavigationLink {
                                    EmergencyApprovalView()
                                } label: {
                                    SecurityActionRow(
                                        icon: "checkmark.shield.fill",
                                        title: "Emergency Approvals",
                                        subtitle: "Review pending requests",
                                        color: colors.warning
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Documents")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                            .padding(.horizontal)
                        
                        // Archived vaults: show read-only view
                        if vault.status == "archived" {
                            StandardCard {
                                VStack(spacing: UnifiedTheme.Spacing.md) {
                                    Image(systemName: "archivebox.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(colors.textSecondary)
                                    
                                    Text("Vault Archived")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Text("This vault is archived. Documents are read-only. Unarchive the vault to make changes.")
                                        .font(theme.typography.body)
                                        .foregroundColor(colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            }
                            .padding(.horizontal)
                            
                            // Show documents in read-only mode (no upload actions)
                            let archivedDocuments: [Document] = AppConfig.useSupabase 
                                ? documentService.documents.filter { $0.status == "active" }
                                : (vault.documents ?? []).filter { $0.status == "active" }
                            
                            if archivedDocuments.isEmpty {
                                StandardCard {
                                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                                        Image(systemName: "doc")
                                            .font(.largeTitle)
                                            .foregroundColor(colors.textTertiary)
                                        
                                        Text("No Documents")
                                            .font(theme.typography.headline)
                                            .foregroundColor(colors.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, UnifiedTheme.Spacing.xl)
                                }
                                .padding(.horizontal)
                            } else {
                                ForEach(archivedDocuments) { document in
                                    NavigationLink {
                                        DocumentPreviewView(document: document)
                                    } label: {
                                        DocumentRow(document: document)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        } else if !hasActiveSession {
                            StandardCard {
                                VStack(spacing: UnifiedTheme.Spacing.sm) {
                                    Image(systemName: "lock.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(colors.textTertiary)
                                    
                                    Text("Vault is Locked")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Text("Unlock the vault to view documents")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, UnifiedTheme.Spacing.xl)
                            }
                            .padding(.horizontal)
                        } else {
                            // Active vaults: normal document list
                            var documentsToShow: [Document] = AppConfig.useSupabase 
                                ? documentService.documents.filter { $0.status == "active" }
                                : (vault.documents ?? []).filter { $0.status == "active" }
                            
                            // If current user is a nominee with subset access, filter to selected documents only
                            if let nominee = currentNominee, nominee.isSubsetAccess, let selectedIDs = nominee.selectedDocumentIDs {
                                documentsToShow = documentsToShow.filter { selectedIDs.contains($0.id) }
                            }
                            
                            if documentsToShow.isEmpty {
                                StandardCard {
                                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                                        Image(systemName: "doc")
                                            .font(.largeTitle)
                                            .foregroundColor(colors.textTertiary)
                                        
                                        Text("No Documents")
                                            .font(theme.typography.headline)
                                            .foregroundColor(colors.textPrimary)
                                        
                                        Text("Add your first document")
                                            .font(theme.typography.subheadline)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, UnifiedTheme.Spacing.xl)
                                }
                                .padding(.horizontal)
                            } else {
                                ForEach(documentsToShow) { document in
                                    NavigationLink {
                                        DocumentPreviewView(document: document)
                                    } label: {
                                        DocumentRow(document: document)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            
            // Face ID is now handled before navigation in VaultListView
            // If we reach here without an active session, show unlock button
            // Archived vaults don't need unlocking - they're read-only
            if !hasActiveSession && vault.status != "archived" {
                unlockOverlay
            }
        }
        .navigationTitle(vault.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if vault.status == "archived" {
                        Button {
                            Task {
                                do {
                                    try await vaultService.unarchiveVault(vault)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        } label: {
                            Label("Unarchive", systemImage: "archivebox")
                        }
                    } else {
                        Button(role: .destructive) {
                            Task {
                                do {
                                    try await vaultService.archiveVault(vault)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        } label: {
                            Label("Archive", systemImage: "archivebox.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(colors.primary)
                }
            }
        }
        .sheet(isPresented: $showUploadSheet) {
            DocumentUploadView(vault: vault)
        }
        .sheet(isPresented: $showNomineeInvitation) {
            NomineeInvitationView(vault: vault)
        }
        .sheet(isPresented: $showTransferOwnership) {
            UnifiedShareView(vault: vault, mode: .transfer)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Configure nominee service
            if let userID = authService.currentUser?.id {
                if AppConfig.useSupabase {
                    nomineeService.configure(supabaseService: supabaseService, currentUserID: userID, vaultService: vaultService)
                } else if let modelContext = modelContext {
                    nomineeService.configure(modelContext: modelContext, currentUserID: userID, vaultService: vaultService)
                }
            }
            
            // Check if current user is a nominee with subset access
            Task {
                try? await nomineeService.loadNominees(for: vault)
                await MainActor.run {
                    // Match nominee by email (since nominees may not have userID until they accept)
                    if let currentUser = authService.currentUser {
                        currentNominee = nomineeService.nominees.first { nominee in
                            nominee.email == currentUser.email ||
                            (nominee.phoneNumber != nil && nominee.phoneNumber == currentUser.phoneNumber)
                        }
                        
                        // Check session expiration for subset access
                        if let nominee = currentNominee, nominee.isSubsetAccess {
                            checkAndRevokeExpiredSession(nominee: nominee)
                            startSessionExpirationMonitoring(nominee: nominee)
                        }
                    }
                }
            }
            
            // If vault already has an active session, mark as unlocked
            if hasActiveSession {
                isBiometricallyUnlocked = true
            }
            
            // Load documents for this vault (especially important in Supabase mode)
            Task {
                do {
                    try await documentService.loadDocuments(for: vault)
                    // In Supabase mode, populate vault.documents from documentService
                    if AppConfig.useSupabase {
                        await MainActor.run {
                            if vault.documents == nil {
                                vault.documents = []
                            }
                            // Update vault.documents with loaded documents
                            vault.documents = documentService.documents
                        }
                    }
                } catch {
                    print("⚠️ Failed to load documents: \(error.localizedDescription)")
                }
            }
        }
        .onDisappear {
            // Stop session expiration monitoring
            sessionExpirationTimer?.invalidate()
            sessionExpirationTimer = nil
        }
        .onChange(of: hasActiveSession) { oldValue, newValue in
            // Reload documents when vault is unlocked
            if newValue && !oldValue {
                Task {
                    do {
                        try await documentService.loadDocuments(for: vault)
                        if AppConfig.useSupabase {
                            await MainActor.run {
                                if vault.documents == nil {
                                    vault.documents = []
                                }
                                vault.documents = documentService.documents
                            }
                        }
                    } catch {
                        print("⚠️ Failed to load documents after unlock: \(error.localizedDescription)")
                    }
                }
            }
            
            // Handle session expiration - vault was auto-locked
            if !newValue && oldValue {
                print("🔒 Vault session expired - vault auto-locked")
                // Update UI state
                isBiometricallyUnlocked = false
            }
        }
        .task {
            // Periodic check for expired sessions (every 30 seconds)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                
                // Check if current session has expired
                if hasActiveSession {
                    // Verify session is still valid
                    if !vaultService.hasActiveSession(for: vault.id) {
                        // Session expired - update UI
                        await MainActor.run {
                            isBiometricallyUnlocked = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Unlock Overlay UI
    
    private var unlockOverlay: some View {
        let colors = theme.colors(for: colorScheme)
        return ZStack {
            colors.background // solid, no translucency
                .ignoresSafeArea()
            
            VStack(spacing: UnifiedTheme.Spacing.lg) {
                Image(systemName: LocalAuthService.shared.biometricType() == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 48, weight: .regular, design: .rounded))
                    .foregroundColor(colors.primary)
                
                Text("Unlock Vault")
                    .font(theme.typography.title2)
                    .foregroundColor(colors.textPrimary)
                
                Text("Authenticate to view \(vault.name)")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textSecondary)
                
                Button {
                    Task { await promptBiometricsAndOpenIfNeeded() }
                } label: {
                    HStack {
                        if authInProgress {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "lock.open.fill")
                        }
                        Text(authInProgress ? "Authenticating..." : "Unlock with Face ID")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(authInProgress)
                .padding(.horizontal, UnifiedTheme.Spacing.lg)
            }
            .padding()
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.spring(), value: isBiometricallyUnlocked)
        .accessibilityAddTraits(.isModal)
    }
    
    // MARK: - Biometric Flow
    
    // Removed ensureBiometricGate() - Face ID now only triggers on explicit button tap
    // No automatic unlock on vault selection
    
    private func promptBiometricsAndOpenIfNeeded() async {
        guard !authInProgress else { return }
        authInProgress = true
        let reason = "Authenticate to access this vault"
        let success = await LocalAuthService.shared.authenticate(reason: reason)
        await MainActor.run {
            authInProgress = false
            if success {
                isBiometricallyUnlocked = true
                // Always open vault after successful authentication
                openVault()
            } else {
                isBiometricallyUnlocked = false
                errorMessage = "Authentication failed. Please try again."
                showError = true
            }
        }
    }
    
    // MARK: - Existing Actions
    
    private func openVault() {
        guard isBiometricallyUnlocked else {
            // Soft guidance: require Face ID first
            errorMessage = "Authenticate with Face ID to unlock this vault."
            showError = true
            return
        }
        guard !isLoading else {
            print("⚠️ Vault unlock already in progress, ignoring duplicate tap")
            return
        }
        isLoading = true
        
        Task { @MainActor in
            do {
                try await vaultService.openVault(vault)
                try? await Task.sleep(nanoseconds: 100_000_000)
            } catch VaultError.awaitingApproval {
                errorMessage = "Dual-key approval requested. ML is analyzing..."
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
    
    private func lockVault() {
        Task {
            do {
                // Verify vault is currently open before locking
                guard vault.status == "active" || hasActiveSession else {
                    print("⚠️ Vault is already locked")
                    return
                }
                
                try await vaultService.closeVault(vault)
                
                // Update local state
                await MainActor.run {
                    vault.status = "locked"
                    localHasActiveSession = false
                }
                
                print("✅ Vault locked successfully")
            } catch {
                print("❌ Failed to lock vault: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Nominee Subset Access Management
    
    /// Check if nominee session has expired and revoke access
    private func checkAndRevokeExpiredSession(nominee: Nominee) {
        guard let expiresAt = nominee.sessionExpiresAt else { return }
        
        if Date() >= expiresAt {
            // Session expired - revoke access
            Task {
                do {
                    try await nomineeService.removeNominee(nominee, permanently: false)
                    print("⏰ Subset nomination session expired - access revoked")
                    
                    // Show alert to user
                    await MainActor.run {
                        errorMessage = "Your subset access session has expired. Access has been revoked."
                        showError = true
                    }
                } catch {
                    print("❌ Failed to revoke expired nominee access: \(error)")
                }
            }
        }
    }
    
    /// Start monitoring session expiration for subset nominations
    private func startSessionExpirationMonitoring(nominee: Nominee) {
        guard nominee.sessionExpiresAt != nil else { return }
        
        // Check every minute
        sessionExpirationTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                if let currentNominee = self.currentNominee, currentNominee.id == nominee.id {
                    self.checkAndRevokeExpiredSession(nominee: currentNominee)
                }
            }
        }
    }
    
    private func extendSession() async {
        if let session = vaultService.activeSessions[vault.id] {
            session.expiresAt = Date().addingTimeInterval(15 * 60)
            session.wasExtended = true
            
            // Update session in backend
            if AppConfig.useSupabase {
                // Session updates handled by VaultService in Supabase mode
                // No need to manually save
            } else {
            try? modelContext.save()
            }
        }
    }
    
    private func handleImportedDocument(_ url: URL) {
        Task {
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: url)
                let fileName = url.lastPathComponent
                let mimeType = url.mimeType() ?? "application/octet-stream"
                
                _ = try await documentService.uploadDocument(
                    data: data,
                    name: fileName,
                    mimeType: mimeType,
                    to: vault,
                    uploadMethod: .files
                )
                
                showDocumentPicker = false
            } catch {
                print("Failed to import document: \(error)")
                showDocumentPicker = false
            }
        }
    }
    
    private func checkPendingUnlockRequest() -> Bool {
        guard vault.keyType == "dual" else { return false }
        guard let currentUserID = authService.currentUser?.id else { return false }
        
        let requests = vault.dualKeyRequests ?? []
        for request in requests {
            if request.status == "pending" &&
               request.requester?.id == currentUserID {
                return true
            }
        }
        return false
    }
}

struct DocumentRow: View {
    let document: Document
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: iconForDocumentType(document.documentType))
                        .font(.title2)
                        .foregroundColor(colors.primary)
                        .frame(width: 40)
                    
                    if let sourceSinkType = document.sourceSinkType {
                        Circle()
                            .fill(sourceSinkBadgeColor(sourceSinkType))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(colors.surface, lineWidth: 2)
                            )
                            .offset(x: 8, y: -8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: UnifiedTheme.Spacing.xs) {
                        Text(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textSecondary)
                        
                        Text("•")
                            .foregroundColor(colors.textTertiary)
                        
                        Text(document.uploadedAt, style: .date)
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    if !document.aiTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(document.aiTags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(colors.primary.opacity(0.2))
                                        .foregroundColor(colors.primary)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private func iconForDocumentType(_ type: String) -> String {
        switch type {
        case "image": return "photo.fill"
        case "pdf": return "doc.text.fill"
        case "video": return "video.fill"
        case "audio": return "waveform"
        case "text": return "doc.text"
        default: return "doc.fill"
        }
    }
    
    private func sourceSinkBadgeColor(_ type: String) -> Color {
        let colors = theme.colors(for: colorScheme)
        switch type {
        case "source": return colors.info
        case "sink": return colors.success
        case "both": return colors.warning
        default: return colors.textTertiary
        }
    }
}

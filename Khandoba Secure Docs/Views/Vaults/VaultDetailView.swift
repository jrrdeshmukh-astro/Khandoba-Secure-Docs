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
    @State private var currentNominee: Nominee?
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
    
    // MARK: - Computed Properties
    
    private var isIntelVault: Bool {
        vault.name == "Intel Vault"
    }
    
    private var isOwner: Bool {
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
    
    private var viewColors: UnifiedTheme.Colors {
        theme.colors(for: colorScheme)
    }
    
    private var hasActiveSession: Bool {
        vaultService.hasActiveSession(for: vault.id)
    }
    
    private var hasPendingRequest: Bool {
        hasPendingDualKeyRequest
    }
    
    // MARK: - Body
    
    var body: some View {
        bodyContent
    }
    
    @ViewBuilder
    private var bodyContent: some View {
        let colors = viewColors
        let background = colors.background
        
        ZStack {
            background
                .ignoresSafeArea()
            
            scrollContent
            
            if !hasActiveSession {
                unlockOverlay
            }
        }
        .navigationTitle(vault.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            // Toolbar removed - archive functionality no longer available
        }
        .sheet(isPresented: $showUploadSheet) {
            DocumentUploadView(vault: vault)
        }
        .sheet(isPresented: $showNomineeInvitation) {
            AddNomineeView(vault: vault)
        }
        .sheet(isPresented: $showTransferOwnership) {
            UnifiedShareView(vault: vault, mode: .transfer)
        }
        .fileImporter(
            isPresented: $showDocumentPicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    handleImportedDocument(url)
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            configureView()
        }
        .onDisappear {
            sessionExpirationTimer?.invalidate()
            sessionExpirationTimer = nil
        }
        .onChange(of: hasActiveSession) { oldValue, newValue in
            handleSessionChange(oldValue: oldValue, newValue: newValue)
        }
        .task {
            await monitorSessionExpiration()
        }
    }
    
    // MARK: - Scroll Content
    
    @ViewBuilder
    private var scrollContent: some View {
        let colors = viewColors
        
        ScrollView {
            VStack(spacing: UnifiedTheme.Spacing.lg) {
                // Pending unlock request banner
                if vault.keyType == "dual" && hasPendingRequest {
                    pendingRequestBanner(colors: colors)
                }
                
                // Vault status card
                vaultStatusCard(colors: colors)
                
                // Active session timer
                if let session = vaultService.activeSessions[vault.id] {
                    SessionTimerView(session: session) {
                        await extendSession()
                    }
                    .padding(.horizontal)
                }
                
                // Security & Intelligence section
                securityIntelligenceSection(colors: colors)
                
                // Vault Management section (owners only)
                if isOwner && !vault.isSystemVault {
                    vaultManagementSection(colors: colors)
                }
                
                // Media Actions section
                if hasActiveSession && !vault.isSystemVault {
                    mediaActionsSection(colors: colors)
                }
                
                // Emergency section
                emergencySection(colors: colors)
                
                // Documents section
                documentsSection(colors: colors)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func pendingRequestBanner(colors: UnifiedTheme.Colors) -> some View {
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
    
    @ViewBuilder
    private func vaultStatusCard(colors: UnifiedTheme.Colors) -> some View {
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
    }
    
    @ViewBuilder
    private func securityIntelligenceSection(colors: UnifiedTheme.Colors) -> some View {
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
    }
    
    @ViewBuilder
    private func vaultManagementSection(colors: UnifiedTheme.Colors) -> some View {
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
    
    @ViewBuilder
    private func mediaActionsSection(colors: UnifiedTheme.Colors) -> some View {
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
    
    @ViewBuilder
    private func emergencySection(colors: UnifiedTheme.Colors) -> some View {
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
    }
    
    @ViewBuilder
    private func documentsSection(colors: UnifiedTheme.Colors) -> some View {
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
            Text("Documents")
                .font(theme.typography.headline)
                .foregroundColor(colors.textPrimary)
                .padding(.horizontal)
            
            if !hasActiveSession {
                lockedDocumentsView(colors: colors)
            } else {
                activeDocumentsView(colors: colors)
            }
        }
    }
    
    @ViewBuilder
    private func lockedDocumentsView(colors: UnifiedTheme.Colors) -> some View {
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
    }
    
    @ViewBuilder
    private func activeDocumentsView(colors: UnifiedTheme.Colors) -> some View {
        let allDocuments: [Document] = AppConfig.useSupabase
            ? documentService.documents.filter { $0.status == "active" }
            : (vault.documents ?? []).filter { $0.status == "active" }
        
        let documentsToShow: [Document] = {
            if let nominee = currentNominee, nominee.isSubsetAccess, let selectedIDs = nominee.selectedDocumentIDs {
                return allDocuments.filter { selectedIDs.contains($0.id) }
            } else {
                return allDocuments
            }
        }()
        
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
    
    
    // MARK: - Unlock Overlay
    
    private var unlockOverlay: some View {
        let colors = theme.colors(for: colorScheme)
        return ZStack {
            colors.background
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
    
    private func promptBiometricsAndOpenIfNeeded() async {
        guard !authInProgress else { return }
        authInProgress = true
        let reason = "Authenticate to access this vault"
        let success = await LocalAuthService.shared.authenticate(reason: reason)
        await MainActor.run {
            authInProgress = false
            if success {
                isBiometricallyUnlocked = true
                openVault()
            } else {
                isBiometricallyUnlocked = false
                errorMessage = "Authentication failed. Please try again."
                showError = true
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func configureView() {
        if let userID = authService.currentUser?.id {
            if AppConfig.useSupabase {
                nomineeService.configure(supabaseService: supabaseService, currentUserID: userID, vaultService: vaultService)
            } else {
                nomineeService.configure(modelContext: modelContext, currentUserID: userID, vaultService: vaultService)
            }
        }
        
        loadNomineesAndConfigureSubsetAccess()
        
        if hasActiveSession {
            isBiometricallyUnlocked = true
        }
        
        loadDocumentsForVault()
    }
    
    private func loadNomineesAndConfigureSubsetAccess() {
        Task {
            try? await nomineeService.loadNominees(for: vault)
            await MainActor.run {
                updateCurrentNomineeFromLoadedNominees()
            }
        }
    }
    
    private func updateCurrentNomineeFromLoadedNominees() {
        guard let currentUser = authService.currentUser else { return }
        
        currentNominee = findMatchingNominee(for: currentUser)
        
        if let nominee = currentNominee, nominee.isSubsetAccess {
            checkAndRevokeExpiredSession(nominee: nominee)
            startSessionExpirationMonitoring(nominee: nominee)
        }
    }
    
    private func findMatchingNominee(for user: User) -> Nominee? {
        guard let userEmail = user.email else { return nil }
        
        for nominee in nomineeService.nominees {
            if nominee.email == userEmail {
                return nominee
            }
        }
        return nil
    }
    
    private func loadDocumentsForVault() {
        Task {
            do {
                try await documentService.loadDocuments(for: vault)
                if AppConfig.useSupabase {
                    await MainActor.run {
                        updateVaultDocumentsFromService()
                    }
                }
            } catch {
                print("⚠️ Failed to load documents: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateVaultDocumentsFromService() {
        if vault.documents == nil {
            vault.documents = []
        }
        vault.documents = documentService.documents
    }
    
    private func handleSessionChange(oldValue: Bool, newValue: Bool) {
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
        
        if !newValue && oldValue {
            print("🔒 Vault session expired - vault auto-locked")
            isBiometricallyUnlocked = false
        }
    }
    
    private func monitorSessionExpiration() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            if hasActiveSession {
                if !vaultService.hasActiveSession(for: vault.id) {
                    await MainActor.run {
                        isBiometricallyUnlocked = false
                    }
                }
            }
        }
    }
    
    // MARK: - Vault Actions
    
    private func openVault() {
        guard isBiometricallyUnlocked else {
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
                guard hasActiveSession else {
                    print("⚠️ Vault is already locked")
                    return
                }
                
                try await vaultService.closeVault(vault)
                
                await MainActor.run {
                    vault.status = "locked"
                    localHasActiveSession = false
                }
                
                print("✅ Vault locked successfully")
                // Stay on vault detail page - no navigation needed
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
    
    private func checkAndRevokeExpiredSession(nominee: Nominee) {
        guard let expiresAt = nominee.sessionExpiresAt else { return }
        
        if Date() >= expiresAt {
            Task {
                do {
                    try await nomineeService.removeNominee(nominee, permanently: false)
                    print("⏰ Subset nomination session expired - access revoked")
                    
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
    
    private func startSessionExpirationMonitoring(nominee: Nominee) {
        guard nominee.sessionExpiresAt != nil else { return }
        
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
            
            if AppConfig.useSupabase {
                // Session updates handled by VaultService in Supabase mode
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

// MARK: - Document Row View

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

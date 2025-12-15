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
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showUploadSheet = false
    @State private var showDocumentPicker = false
    
    @EnvironmentObject var authService: AuthenticationService
    
    // Face ID gate
    @State private var isBiometricallyUnlocked = false
    @State private var attemptedAutoUnlock = false
    @State private var authInProgress = false
    
    private var isIntelVault: Bool {
        vault.name == "Intel Vault"
    }
    
    private var isOwner: Bool {
        vault.owner?.id == authService.currentUser?.id
    }
    
    private var hasPendingDualKeyRequest: Bool {
        guard vault.keyType == "dual" else { return false }
        let requests = vault.dualKeyRequests ?? []
        return requests.contains { $0.status == "pending" }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let hasActiveSession = vaultService.hasActiveSession(for: vault.id)
        let hasPendingRequest = hasPendingDualKeyRequest
        
        ZStack {
            colors.background
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
                    
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Sharing & Collaboration")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                            .padding(.horizontal)
                        
                        StandardCard {
                            VStack(spacing: 0) {
                                if isOwner {
                                    NavigationLink {
                                        VaultAccessControlView(vault: vault)
                                    } label: {
                                        SecurityActionRow(
                                            icon: "person.3.fill",
                                            title: "Access Control",
                                            subtitle: "Manage user permissions & history",
                                            color: colors.primary
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if hasActiveSession && !vault.isSystemVault {
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
                                            subtitle: "Premium",
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
                                            subtitle: "Premium",
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
                        
                        if !hasActiveSession {
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
                        } else if vault.documents?.isEmpty ?? true {
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
                            ForEach(vault.documents ?? []) { document in
                                if document.status == "active" {
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
            if !hasActiveSession {
                unlockOverlay
            }
        }
        .navigationTitle(vault.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if isOwner {
                #if !APP_EXTENSION
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await openMessagesForNomination()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "message.fill")
                            Text("Invite")
                        }
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.primary)
                    }
                }
                #endif
            }
        }
        .sheet(isPresented: $showUploadSheet) {
            DocumentUploadView(vault: vault)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // If vault already has an active session, mark as unlocked
            if hasActiveSession {
                isBiometricallyUnlocked = true
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
    
    private func openMessagesForNomination() async {
        #if !APP_EXTENSION
        let success = await MessagesRedirectService.shared.openMessagesAppForNomination(vaultID: vault.id)
        if !success {
            await MainActor.run {
                errorMessage = "Unable to open Messages app. Please make sure Messages is installed and try again."
                showError = true
            }
        }
        #else
        await MainActor.run {
            errorMessage = "Inviting via Messages isn’t available in this extension."
            showError = true
        }
        #endif
    }
    
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
                try await vaultService.closeVault(vault)
                print(" Vault locked by owner")
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func extendSession() async {
        if let session = vaultService.activeSessions[vault.id] {
            session.expiresAt = Date().addingTimeInterval(15 * 60)
            session.wasExtended = true
            try? modelContext.save()
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

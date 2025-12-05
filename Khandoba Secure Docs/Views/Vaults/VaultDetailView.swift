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
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showUploadSheet = false
    @State private var showDocumentPicker = false
    @State private var showShareView = false
    @State private var shareMode: ShareMode = .nominee
    
    @EnvironmentObject var authService: AuthenticationService
    
    private var isIntelVault: Bool {
        vault.name == "Intel Vault"
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
                    // Dual-Key Unlock Request Pending Banner
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
                    
                    // Status Card
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            HStack {
                                // Dual-key or single-key icon
                                if vault.keyType == "dual" {
                                    // Two keys icon for dual-key vaults
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
                                        Image(systemName: "lock.open.fill")
                                        Text("Unlock Vault")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Active Session Timer
                    if let session = vaultService.activeSessions[vault.id] {
                        SessionTimerView(session: session) {
                            await extendSession()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Security & Intelligence Section
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
                                
                                Divider()
                                
                                NavigationLink {
                                    AudioIntelReportView(vault: vault)
                                } label: {
                                    SecurityActionRow(
                                        icon: "waveform.badge.magnifyingglass",
                                        title: "Audio Intel Report",
                                        subtitle: "AI analysis of selected documents",
                                        color: colors.primary
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Sharing & Collaboration
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Sharing & Collaboration")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                            .padding(.horizontal)
                        
                        StandardCard {
                            VStack(spacing: 0) {
                                Button {
                                    shareMode = .nominee
                                    showShareView = true
                                } label: {
                                    SecurityActionRow(
                                        icon: "person.badge.plus.fill",
                                        title: "Invite Nominees",
                                        subtitle: "Grant concurrent vault access",
                                        color: colors.info
                                    )
                                }
                                
                                Divider()
                                
                                Button {
                                    shareMode = .transfer
                                    showShareView = true
                                } label: {
                                    SecurityActionRow(
                                        icon: "arrow.triangle.2.circlepath",
                                        title: "Transfer Ownership",
                                        subtitle: "Transfer vault via iMessage",
                                        color: colors.warning
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Media Actions - Hidden for system vaults like Intel Reports
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
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Emergency
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
                    }
                    
                    // Documents Section
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        HStack {
                            Text("Documents")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Spacer()
                            
                            if hasActiveSession {
                                Button {
                                    showUploadSheet = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(colors.primary)
                                }
                            }
                        }
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
        }
        .navigationTitle(vault.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showUploadSheet) {
            DocumentUploadView(vault: vault)
        }
        .sheet(isPresented: $showShareView) {
            UnifiedShareView(vault: vault, mode: shareMode)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func openVault() {
        isLoading = true
        Task {
            do {
                try await vaultService.openVault(vault)
            } catch VaultError.awaitingApproval {
                errorMessage = "Dual-key approval requested. Awaiting admin approval."
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
    
    private func extendSession() async {
        // Extend session by 15 minutes
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
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
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
                // Document Icon with Source/Sink Badge
                ZStack(alignment: .topTrailing) {
                    Image(systemName: iconForDocumentType(document.documentType))
                        .font(.title2)
                        .foregroundColor(colors.primary)
                        .frame(width: 40)
                    
                    // Source/Sink Badge
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
                    
                    // AI Tags
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
        case "source": return colors.info // Blue for source (created by you)
        case "sink": return colors.success // Green for sink (received)
        case "both": return colors.warning // Amber for both
        default: return colors.textTertiary
        }
    }
}


//
//  VaultAccessControlView.swift
//  Khandoba Secure Docs
//
//  Comprehensive vault access management for owners
//

import SwiftUI
import SwiftData

struct VaultAccessControlView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var showAddNominee = false
    @State private var showAccessHistory = false
    @State private var showRevokeConfirm = false
    @State private var nomineeToRevoke: Nominee?
    @State private var shareMode: ShareMode = .nominee
    
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
                                Text("Access Control")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                            }
                            
                            Text("Manage who can access this vault")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Owner Section
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
                                isYou: vault.owner?.id == authService.currentUser?.id,
                                canRevoke: false,
                                colors: colors,
                                theme: theme,
                                onRevoke: {}
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Nominees Section
                    if let nomineeList = vault.nomineeList, !nomineeList.isEmpty {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            HStack {
                                Text("NOMINEES (\(nomineeList.count))")
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
                            
                            StandardCard {
                                VStack(spacing: 0) {
                                    ForEach(Array(nomineeList.enumerated()), id: \.element.id) { index, nominee in
                                        AccessUserRow(
                                            name: nominee.name,
                                            role: "Nominee",
                                            status: nominee.status.capitalized,
                                            isYou: false,
                                            canRevoke: true,
                                            colors: colors,
                                            theme: theme,
                                            onRevoke: {
                                                nomineeToRevoke = nominee
                                                showRevokeConfirm = true
                                            }
                                        )
                                        
                                        if index < nomineeList.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Emergency Access Requests
                    if let emergencyRequests = vault.emergencyRequests?.filter({ $0.status == "approved" }), !emergencyRequests.isEmpty {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("EMERGENCY ACCESS (\(emergencyRequests.count))")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                                .padding(.horizontal)
                            
                            StandardCard {
                                VStack(spacing: 0) {
                                    ForEach(Array(emergencyRequests.enumerated()), id: \.element.id) { index, request in
                                        EmergencyAccessRow(
                                            request: request,
                                            colors: colors,
                                            theme: theme,
                                            onRevoke: {
                                                revokeEmergencyAccess(request)
                                            }
                                        )
                                        
                                        if index < emergencyRequests.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Access History Button
                    Button {
                        showAccessHistory = true
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
                    
                    // Add Nominee Button
                    if vault.nomineeList?.isEmpty ?? true {
                        Button {
                            showAddNominee = true
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Invite Nominee")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Access Control")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddNominee) {
            UnifiedShareView(vault: vault, mode: .nominee)
        }
        .sheet(isPresented: $showAccessHistory) {
            VaultAccessHistoryView(vault: vault)
        }
        .alert("Revoke Access", isPresented: $showRevokeConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Revoke", role: .destructive) {
                if let nominee = nomineeToRevoke {
                    revokeNomineeAccess(nominee)
                }
            }
        } message: {
            if let nominee = nomineeToRevoke {
                Text("Revoke access for \(nominee.name)? They will no longer be able to access this vault.")
            }
        }
    }
    
    private func revokeNomineeAccess(_ nominee: Nominee) {
        nominee.status = "inactive"
        try? modelContext.save()
        print("✅ Access revoked for: \(nominee.name)")
    }
    
    private func revokeEmergencyAccess(_ request: EmergencyAccessRequest) {
        request.status = "revoked"
        try? modelContext.save()
        print("✅ Emergency access revoked")
    }
}

// MARK: - Access User Row

struct AccessUserRow: View {
    let name: String
    let role: String
    let status: String
    let isYou: Bool
    let canRevoke: Bool
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    let onRevoke: () -> Void
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: roleIcon)
                    .foregroundColor(statusColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                    
                    if isYou {
                        Text("(You)")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                
                HStack(spacing: 8) {
                    // Role badge
                    Text(role)
                        .font(.caption2)
                        .foregroundColor(roleColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(roleColor.opacity(0.15))
                        .cornerRadius(4)
                    
                    // Status badge
                    Text(status)
                        .font(.caption2)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Revoke button
            if canRevoke && status != "Inactive" {
                Button {
                    onRevoke()
                } label: {
                    Text("Revoke")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.error)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(colors.error.opacity(0.1))
                        .cornerRadius(UnifiedTheme.CornerRadius.sm)
                }
            }
        }
        .padding()
    }
    
    private var roleIcon: String {
        switch role {
        case "Owner": return "person.circle.fill"
        case "Nominee": return "person.fill"
        case "Emergency": return "bolt.fill"
        default: return "person.fill"
        }
    }
    
    private var roleColor: Color {
        switch role {
        case "Owner": return colors.warning
        case "Nominee": return colors.primary
        case "Emergency": return colors.error
        default: return colors.textSecondary
        }
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "active": return colors.success
        case "pending": return colors.warning
        case "inactive", "revoked": return colors.textTertiary
        default: return colors.textSecondary
        }
    }
}

// MARK: - Emergency Access Row

struct EmergencyAccessRow: View {
    let request: EmergencyAccessRequest
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    let onRevoke: () -> Void
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(colors.error.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "bolt.fill")
                    .foregroundColor(colors.error)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Emergency Access")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                
                HStack {
                    Text("Urgency: \(request.urgency.capitalized)")
                        .font(.caption2)
                        .foregroundColor(colors.error)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(colors.error.opacity(0.15))
                        .cornerRadius(4)
                    
                    Text("Approved \(request.approvedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            Spacer()
            
            Button {
                onRevoke()
            } label: {
                Text("Revoke")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.error)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colors.error.opacity(0.1))
                    .cornerRadius(UnifiedTheme.CornerRadius.sm)
            }
        }
        .padding()
    }
}

// MARK: - Access History View

struct VaultAccessHistoryView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if let logs = vault.accessLogs, !logs.isEmpty {
                    List {
                        ForEach(logs.sorted(by: { $0.timestamp > $1.timestamp })) { log in
                            AccessLogRow(log: log, colors: colors, theme: theme)
                                .listRowBackground(colors.surface)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                } else {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Access History",
                        message: "Access logs will appear here as vault is used"
                    )
                }
            }
            .navigationTitle("Access History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AccessLogRow: View {
    let log: VaultAccessLog
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.md) {
            Image(systemName: accessTypeIcon)
                .foregroundColor(accessTypeColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(log.userName ?? "Unknown User")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                
                HStack(spacing: 8) {
                    Text(log.accessType.capitalized)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                    
                    Text("•")
                        .foregroundColor(colors.textTertiary)
                    
                    Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                if let lat = log.locationLatitude, let lon = log.locationLongitude {
                    Text("📍 \(String(format: "%.4f, %.4f", lat, lon))")
                        .font(.caption2)
                        .foregroundColor(colors.textTertiary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var accessTypeIcon: String {
        switch log.accessType.lowercased() {
        case "opened", "unlocked": return "lock.open.fill"
        case "closed", "locked": return "lock.fill"
        case "uploaded": return "arrow.up.doc.fill"
        case "downloaded": return "arrow.down.doc.fill"
        case "viewed": return "eye.fill"
        case "created": return "plus.circle.fill"
        default: return "circle.fill"
        }
    }
    
    private var accessTypeColor: Color {
        switch log.accessType.lowercased() {
        case "opened", "unlocked": return colors.success
        case "closed", "locked": return colors.error
        case "uploaded", "created": return colors.primary
        case "downloaded", "viewed": return colors.info
        default: return colors.textSecondary
        }
    }
}

#Preview {
    NavigationStack {
        VaultAccessControlView(vault: Vault(name: "Test", vaultDescription: "Test", keyType: "single"))
            .environmentObject(AuthenticationService())
    }
}


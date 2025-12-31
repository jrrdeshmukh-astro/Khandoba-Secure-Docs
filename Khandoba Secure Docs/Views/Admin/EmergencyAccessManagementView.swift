//
//  EmergencyAccessManagementView.swift
//  Khandoba Secure Docs
//
//  Emergency access management admin view
//

import SwiftUI

struct EmergencyAccessManagementView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var emergencyService = EmergencyAccessService.shared
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var selectedRequest: EmergencyAccessRequest?
    @State private var showPendingRequests = true
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack {
                    // Toggle between pending and active
                    Picker("View", selection: $showPendingRequests) {
                        Text("Pending").tag(true)
                        Text("Active").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    List {
                        ForEach(showPendingRequests ? emergencyService.pendingRequests : emergencyService.activeGrants, id: \.id) { request in
                            EmergencyRequestRow(request: request) {
                                selectedRequest = request
                            }
                        }
                    }
                }
                .navigationTitle("Emergency Access")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .sheet(item: $selectedRequest) { request in
            EmergencyRequestDetailView(request: request)
        }
        .onAppear {
            emergencyService.configure(modelContext: modelContext, vaultService: VaultService())
        }
    }
}

private struct EmergencyRequestRow: View {
    let request: EmergencyAccessRequest
    let onTap: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.reason)
                        .font(theme.typography.headline)
                        .lineLimit(2)
                    
                    Text("Urgency: \(request.urgency.capitalized)")
                        .font(theme.typography.caption)
                        .foregroundColor(urgencyColor)
                    
                    Text("Requested: \(DateFormatter.localizedString(from: request.requestedAt, dateStyle: .medium, timeStyle: .short))")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                Text(request.status.capitalized)
                    .font(theme.typography.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(UnifiedTheme.CornerRadius.sm)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var urgencyColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch request.urgency {
        case "critical":
            return colors.error
        case "high":
            return colors.error.opacity(0.8)
        case "medium":
            return colors.warning
        default:
            return colors.info
        }
    }
    
    private var statusColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch request.status {
        case "pending":
            return colors.warning
        case "approved":
            return colors.success
        case "denied":
            return colors.error
        default:
            return colors.textTertiary
        }
    }
}

private struct EmergencyRequestDetailView: View {
    let request: EmergencyAccessRequest
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var emergencyService = EmergencyAccessService.shared
    
    @State private var showApproveConfirmation = false
    @State private var showDenyConfirmation = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Request Details")
                                .font(theme.typography.headline)
                            
                            DetailRow(icon: "text.bubble", iconColor: colors.primary, label: "Reason", value: request.reason)
                            DetailRow(icon: "exclamationmark.triangle", iconColor: colors.warning, label: "Urgency", value: request.urgency.capitalized)
                            DetailRow(icon: "checkmark.circle", iconColor: colors.success, label: "Status", value: request.status.capitalized)
                            DetailRow(icon: "clock", iconColor: colors.textSecondary, label: "Requested", value: DateFormatter.localizedString(from: request.requestedAt, dateStyle: .long, timeStyle: .short))
                            
                            if let expiresAt = request.expiresAt {
                                DetailRow(icon: "clock.badge.xmark", iconColor: colors.error, label: "Expires", value: DateFormatter.localizedString(from: expiresAt, dateStyle: .long, timeStyle: .short))
                            }
                        }
                        .padding()
                    }
                    
                    // Action Buttons
                    if request.status == "pending" {
                        HStack(spacing: UnifiedTheme.Spacing.md) {
                            Button {
                                showDenyConfirmation = true
                            } label: {
                                Text("Deny")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(colors.error)
                            
                            Button {
                                showApproveConfirmation = true
                            } label: {
                                Text("Approve")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else if request.status == "approved" {
                        Button {
                            revokeAccess()
                        } label: {
                            Text("Revoke Access")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(colors.error)
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Emergency Access")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Approve Access", isPresented: $showApproveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Approve") {
                    approveAccess()
                }
            } message: {
                Text("Are you sure you want to approve this emergency access request? Access will expire in 24 hours.")
            }
            .alert("Deny Access", isPresented: $showDenyConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Deny") {
                    denyAccess()
                }
            } message: {
                Text("Are you sure you want to deny this emergency access request?")
            }
        }
    }
    
    private func approveAccess() {
        guard let approverID = authService.currentUser?.id else { return }
        try? emergencyService.approveEmergencyAccess(request, approverID: approverID)
        dismiss()
    }
    
    private func denyAccess() {
        guard let approverID = authService.currentUser?.id else { return }
        try? emergencyService.denyEmergencyAccess(request, approverID: approverID)
        dismiss()
    }
    
    private func revokeAccess() {
        try? emergencyService.revokeEmergencyAccess(request)
        dismiss()
    }
}


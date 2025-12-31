//
//  VaultOpenRequestView.swift
//  Khandoba Secure Docs
//
//  Vault open request admin view
//

import SwiftUI

struct VaultOpenRequestView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var requestService = VaultOpenRequestService.shared
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var selectedRequest: VaultAccessRequest?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                List {
                    ForEach(requestService.pendingRequests, id: \.id) { request in
                        RequestRow(request: request) {
                            selectedRequest = request
                        }
                    }
                }
                .navigationTitle("Vault Open Requests")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .sheet(item: $selectedRequest) { request in
            RequestDetailView(request: request)
        }
        .onAppear {
            requestService.configure(modelContext: modelContext, vaultService: VaultService())
        }
    }
}

private struct RequestRow: View {
    let request: VaultAccessRequest
    let onTap: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.vaultName ?? "Unknown Vault")
                        .font(theme.typography.headline)
                    
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
    
    private var statusColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch request.status {
        case "pending":
            return colors.warning
        case "accepted":
            return colors.success
        case "declined":
            return colors.error
        default:
            return colors.textTertiary
        }
    }
}

private struct RequestDetailView: View {
    let request: VaultAccessRequest
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var requestService = VaultOpenRequestService.shared
    
    @State private var showApproveConfirmation = false
    @State private var showDeclineConfirmation = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Request Details")
                                .font(theme.typography.headline)
                            
                            DetailRow(icon: "lock.shield", iconColor: colors.primary, label: "Vault", value: request.vaultName ?? "Unknown")
                            DetailRow(icon: "person", iconColor: colors.info, label: "Requester", value: request.requesterName ?? "Unknown")
                            DetailRow(icon: "clock", iconColor: colors.textSecondary, label: "Requested", value: DateFormatter.localizedString(from: request.requestedAt, dateStyle: .long, timeStyle: .short))
                            
                            if let message = request.message {
                                DetailRow(icon: "text.bubble", iconColor: colors.primary, label: "Message", value: message)
                            }
                        }
                        .padding()
                    }
                    
                    // Action Buttons
                    HStack(spacing: UnifiedTheme.Spacing.md) {
                        Button {
                            showDeclineConfirmation = true
                        } label: {
                            Text("Decline")
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
                }
                .padding()
            }
            .navigationTitle("Request Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Approve Request", isPresented: $showApproveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Approve") {
                    Task {
                        await approveRequest()
                    }
                }
            } message: {
                Text("Are you sure you want to approve this vault access request?")
            }
            .alert("Decline Request", isPresented: $showDeclineConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Decline") {
                    declineRequest()
                }
            } message: {
                Text("Are you sure you want to decline this vault access request?")
            }
        }
    }
    
    private func approveRequest() async {
        guard let approverID = authService.currentUser?.id else { return }
        try? await requestService.approveRequest(request, approverID: approverID)
        dismiss()
    }
    
    private func declineRequest() {
        guard let approverID = authService.currentUser?.id else { return }
        try? requestService.declineRequest(request, approverID: approverID, reason: nil)
        dismiss()
    }
}


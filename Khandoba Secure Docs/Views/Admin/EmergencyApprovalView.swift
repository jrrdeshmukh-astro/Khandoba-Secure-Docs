//
//  EmergencyApprovalView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct EmergencyApprovalView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @Query(filter: #Predicate<EmergencyAccessRequest> { $0.status == "pending" })
    private var pendingRequests: [EmergencyAccessRequest]
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if pendingRequests.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.shield",
                        title: "No Emergency Requests",
                        message: "All emergency access requests have been processed"
                    )
                } else {
                    List {
                        ForEach(pendingRequests) { request in
                            EmergencyRequestRow(request: request)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(colors.background)
                }
            }
            .navigationTitle("Emergency Requests")
        }
    }
}

struct EmergencyRequestRow: View {
    let request: EmergencyAccessRequest
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var showApproveConfirm = false
    @State private var showDenyConfirm = false
    
    var urgencyColor: Color {
        switch request.urgency {
        case "critical": return .red
        case "high": return .orange
        case "medium": return .yellow
        default: return .green
        }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                // Header
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(urgencyColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.vault?.name ?? "Unknown Vault")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 4) {
                            Text(request.urgency.uppercased())
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(urgencyColor)
                                .cornerRadius(4)
                            
                            Text(request.requestedAt, style: .relative)
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Reason
                VStack(alignment: .leading, spacing: 4) {
                    Text("Emergency Reason:")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                    
                    Text(request.reason)
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                }
                .padding(.vertical, UnifiedTheme.Spacing.xs)
                
                // Actions
                HStack(spacing: UnifiedTheme.Spacing.md) {
                    Button {
                        showApproveConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Approve (24h)")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button {
                        showDenyConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Deny")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .confirmationDialog("Approve Emergency Access", isPresented: $showApproveConfirm) {
            Button("Approve (24-hour access)") {
                approveRequest()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Grant emergency access for 24 hours?")
        }
        .confirmationDialog("Deny Emergency Access", isPresented: $showDenyConfirm) {
            Button("Deny", role: .destructive) {
                denyRequest()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Deny emergency access request?")
        }
    }
    
    private func approveRequest() {
        guard let approverID = authService.currentUser?.id else { return }
        
        request.status = "approved"
        request.approvedAt = Date()
        request.approverID = approverID
        request.expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        
        // Create emergency session
        if let vault = request.vault {
            let session = VaultSession(
                expiresAt: request.expiresAt!
            )
            session.vault = vault
            vault.status = "active"
            
            modelContext.insert(session)
        }
        
        try? modelContext.save()
    }
    
    private func denyRequest() {
        guard let approverID = authService.currentUser?.id else { return }
        
        request.status = "denied"
        request.approvedAt = Date()
        request.approverID = approverID
        
        try? modelContext.save()
    }
}


//
//  DualKeyApprovalView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct DualKeyApprovalView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @Query(filter: #Predicate<DualKeyRequest> { $0.status == "pending" })
    private var pendingRequests: [DualKeyRequest]
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if pendingRequests.isEmpty {
                    EmptyStateView(
                        icon: "key.fill",
                        title: "No Pending Requests",
                        message: "All dual-key access requests have been processed"
                    )
                } else {
                    List {
                        ForEach(pendingRequests) { request in
                            DualKeyRequestRow(request: request)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(colors.background)
                }
            }
            .navigationTitle("Dual-Key Approvals")
        }
    }
}

struct DualKeyRequestRow: View {
    let request: DualKeyRequest
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var showApproveConfirm = false
    @State private var showDenyConfirm = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    HStack(spacing: -2) {
                        Image(systemName: "key.fill")
                        Image(systemName: "key.fill")
                            .rotationEffect(.degrees(15))
                    }
                        .font(.title2)
                        .foregroundColor(colors.warning)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.vault?.name ?? "Unknown Vault")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        Text("Requested \(request.requestedAt, style: .relative)")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Spacer()
                }
                
                if let reason = request.reason {
                    Text(reason)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                        .padding(.vertical, UnifiedTheme.Spacing.xs)
                }
                
                HStack(spacing: UnifiedTheme.Spacing.md) {
                    Button {
                        showApproveConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Approve")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button {
                        showDenyConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Deny")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .confirmationDialog("Approve Request", isPresented: $showApproveConfirm) {
            Button("Approve") {
                approveRequest()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Grant dual-key vault access?")
        }
        .confirmationDialog("Deny Request", isPresented: $showDenyConfirm) {
            Button("Deny", role: .destructive) {
                denyRequest()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Deny dual-key vault access?")
        }
    }
    
    private func approveRequest() {
        guard let approverID = authService.currentUser?.id else { return }
        
        request.status = "approved"
        request.approvedAt = Date()
        request.approverID = approverID
        
        // Create session for the vault
        if let vault = request.vault {
            let session = VaultSession()
            session.vault = vault
            session.user = request.requester
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


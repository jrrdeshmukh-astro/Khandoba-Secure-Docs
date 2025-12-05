//
//  TransferApprovalView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct TransferApprovalView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @Query(filter: #Predicate<VaultTransferRequest> { $0.status == "pending" })
    private var pendingTransfers: [VaultTransferRequest]
    
    @State private var users: [User] = []
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if pendingTransfers.isEmpty {
                    EmptyStateView(
                        icon: "arrow.triangle.2.circlepath",
                        title: "No Transfer Requests",
                        message: "Vault transfer requests will appear here"
                    )
                } else {
                    List {
                        ForEach(pendingTransfers) { transfer in
                            TransferRequestRow(transfer: transfer, users: users)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(colors.background)
                }
            }
            .navigationTitle("Transfer Requests")
        }
        .task {
            let descriptor = FetchDescriptor<User>()
            users = (try? modelContext.fetch(descriptor)) ?? []
        }
    }
}

struct TransferRequestRow: View {
    let transfer: VaultTransferRequest
    let users: [User]
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var showApproveConfirm = false
    @State private var showDenyConfirm = false
    
    var newOwner: User? {
        users.first(where: { $0.id == transfer.newOwnerID })
    }
    
    var currentOwner: User? {
        users.first(where: { $0.id == transfer.requestedByUserID })
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title2)
                        .foregroundColor(colors.warning)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transfer.vault?.name ?? "Unknown Vault")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        Text("Requested \(transfer.requestedAt, style: .relative)")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // Transfer Details
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                    HStack {
                        Text("From:")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        Text(currentOwner?.fullName ?? "Unknown")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textPrimary)
                    }
                    
                    HStack {
                        Text("To:")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        Text(newOwner?.fullName ?? "Unknown")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                    }
                }
                
                if let reason = transfer.reason {
                    Text("Reason: \(reason)")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                        .italic()
                }
                
                // Actions
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
        .confirmationDialog("Approve Transfer", isPresented: $showApproveConfirm) {
            Button("Approve Transfer") {
                approveTransfer()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Transfer vault ownership to \(newOwner?.fullName ?? "new owner")?")
        }
        .confirmationDialog("Deny Transfer", isPresented: $showDenyConfirm) {
            Button("Deny", role: .destructive) {
                denyTransfer()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Deny vault transfer request?")
        }
    }
    
    private func approveTransfer() {
        guard let approverID = authService.currentUser?.id,
              let newOwner = newOwner,
              let vault = transfer.vault else { return }
        
        // Mark approved
        transfer.status = "approved"
        transfer.approvedAt = Date()
        transfer.approverID = approverID
        
        // Transfer ownership
        vault.owner = newOwner
        
        // Ensure ownedVaults exists and add
        newOwner.ownedVaults = (newOwner.ownedVaults ?? []) + [vault]
        
        // Complete the transfer
        transfer.status = "completed"
        
        try? modelContext.save()
    }
    
    private func denyTransfer() {
        guard let approverID = authService.currentUser?.id else { return }
        
        transfer.status = "denied"
        transfer.approvedAt = Date()
        transfer.approverID = approverID
        
        try? modelContext.save()
    }
}


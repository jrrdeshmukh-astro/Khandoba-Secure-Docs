//
//  DualKeyRequestStatusView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct DualKeyRequestStatusView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    
    @State private var myRequests: [DualKeyRequest] = []
    @State private var isLoading = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if myRequests.isEmpty {
                    EmptyStateView(
                        icon: "key.fill",
                        title: "No Access Requests",
                        message: "Your dual-key vault access requests will appear here"
                    )
                } else {
                    List {
                        ForEach(myRequests) { request in
                            DualKeyRequestStatusRow(request: request)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(colors.background)
                }
            }
            .navigationTitle("My Access Requests")
            .refreshable {
                await loadRequests()
            }
        }
        .task {
            await loadRequests()
        }
    }
    
    /// Load dual-key requests from Supabase or SwiftData
    private func loadRequests() async {
        isLoading = true
        defer { isLoading = false }
        
        // Supabase mode
        if AppConfig.useSupabase {
            await loadRequestsFromSupabase()
        } else {
            // SwiftData/CloudKit mode
            await loadRequestsFromSwiftData()
        }
    }
    
    /// Load requests from Supabase
    private func loadRequestsFromSupabase() async {
        guard let userID = authService.currentUser?.id else {
            print("⚠️ Cannot load requests: User not authenticated")
            return
        }
        
        do {
            // Fetch dual-key requests for current user
            let supabaseRequests: [SupabaseDualKeyRequest] = try await supabaseService.fetchAll(
                "dual_key_requests",
                filters: ["requester_id": userID.uuidString],
                orderBy: "requested_at",
                ascending: false
            )
            
            // Fetch all vaults to link to requests
            let supabaseVaults: [SupabaseVault] = try await supabaseService.fetchAll("vaults", filters: nil)
            
            // Convert to DualKeyRequest models and link vaults
            await MainActor.run {
                self.myRequests = supabaseRequests.map { supabaseRequest in
                    let request = DualKeyRequest(reason: supabaseRequest.reason ?? "")
                    request.id = supabaseRequest.id
                    request.requestedAt = supabaseRequest.requestedAt
                    request.status = supabaseRequest.status
                    request.approvedAt = supabaseRequest.approvedAt
                    request.deniedAt = supabaseRequest.deniedAt
                    request.approverID = supabaseRequest.approverID
                    request.mlScore = supabaseRequest.mlScore
                    request.logicalReasoning = supabaseRequest.logicalReasoning
                    request.decisionMethod = supabaseRequest.decisionMethod
                    
                    // Link to vault if available
                    if let vault = supabaseVaults.first(where: { $0.id == supabaseRequest.vaultID }) {
                        let vaultModel = Vault(
                            name: vault.name,
                            vaultDescription: vault.vaultDescription,
                            keyType: vault.keyType
                        )
                        vaultModel.id = vault.id
                        request.vault = vaultModel
                    }
                    
                    return request
                }
            }
            
            print("✅ Loaded \(myRequests.count) dual-key request(s) from Supabase")
        } catch {
            print("❌ Failed to load requests from Supabase: \(error.localizedDescription)")
        }
    }
    
    /// Load requests from SwiftData
    private func loadRequestsFromSwiftData() async {
        do {
            let descriptor = FetchDescriptor<DualKeyRequest>(
                sortBy: [SortDescriptor(\.requestedAt, order: .reverse)]
            )
            
            let allRequests = try modelContext.fetch(descriptor)
            
            await MainActor.run {
                self.myRequests = allRequests.filter { request in
                    request.requester?.id == authService.currentUser?.id
                }
            }
            
            print("✅ Loaded \(myRequests.count) dual-key request(s) from SwiftData")
        } catch {
            print("❌ Failed to load requests from SwiftData: \(error.localizedDescription)")
        }
    }
}

struct DualKeyRequestStatusRow: View {
    let request: DualKeyRequest
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
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
                        .foregroundColor(statusColor)
                    
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
                    
                    // Status Badge
                    Text(request.status.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor)
                        .cornerRadius(UnifiedTheme.CornerRadius.sm)
                }
                
                if let reason = request.reason {
                    Text("Reason: \(reason)")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                // Status Details
                if request.status == "approved", let approvedAt = request.approvedAt {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(colors.success)
                        Text("Approved \(approvedAt, style: .relative)")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.success)
                    }
                } else if request.status == "denied", let approvedAt = request.approvedAt {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(colors.error)
                        Text("Denied \(approvedAt, style: .relative)")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.error)
                    }
                } else if request.status == "pending" {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(colors.warning)
                        Text("Awaiting admin approval...")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.warning)
                    }
                }
            }
        }
    }
    
    private var statusColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch request.status {
        case "pending": return colors.warning
        case "approved": return colors.success
        case "denied": return colors.error
        default: return colors.textTertiary
        }
    }
}


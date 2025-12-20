//
//  VaultRequestsListView.swift
//  Khandoba Secure Docs
//
//  View to show pending vault access requests (like Zelle's activity feed)
//

import SwiftUI
import SwiftData

struct VaultRequestsListView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    
    @StateObject private var requestService = VaultRequestService()
    @StateObject private var nomineeService = NomineeService()
    
    @State private var selectedTab: RequestListTab = .received
    
    enum RequestListTab {
        case received
        case sent
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Selector
                    HStack(spacing: 0) {
                        tabButton("Received", tab: .received, colors: colors)
                        tabButton("Sent", tab: .sent, colors: colors)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Requests List
                    if requestService.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: UnifiedTheme.Spacing.md) {
                                let requests = selectedTab == .received 
                                    ? requestService.receivedRequests 
                                    : requestService.sentRequests
                                
                                if requests.isEmpty {
                                    emptyStateView(colors: colors)
                                } else {
                                    ForEach(requests) { request in
                                        RequestRowView(request: request, requestService: requestService)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Vault Requests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            try? await requestService.loadRequests()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await configureServices()
            try? await requestService.loadRequests()
        }
    }
    
    private func tabButton(_ title: String, tab: RequestListTab, colors: UnifiedTheme.Colors) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: UnifiedTheme.Spacing.xs) {
                Text(title)
                    .font(theme.typography.headline)
                    .foregroundColor(selectedTab == tab ? colors.primary : colors.textSecondary)
                
                Rectangle()
                    .fill(selectedTab == tab ? colors.primary : Color.clear)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func emptyStateView(colors: UnifiedTheme.Colors) -> some View {
        VStack(spacing: UnifiedTheme.Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(colors.textTertiary)
            
            Text(selectedTab == .received 
                 ? "No received requests"
                 : "No sent requests")
                .font(theme.typography.headline)
                .foregroundColor(colors.textSecondary)
            
            Text(selectedTab == .received
                 ? "Vault access requests you receive will appear here"
                 : "Vault access requests you send will appear here")
                .font(theme.typography.body)
                .foregroundColor(colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private func configureServices() async {
        var cloudKitSharing: CloudKitSharingService? = nil
        
        if AppConfig.useSupabase {
            nomineeService.configure(
                supabaseService: supabaseService,
                currentUserID: authService.currentUser?.id
            )
        } else {
            cloudKitSharing = CloudKitSharingService()
            cloudKitSharing?.configure(modelContext: modelContext)

            nomineeService.configure(
                modelContext: modelContext,
                currentUserID: authService.currentUser?.id
            )
        }
        
        requestService.configure(
            modelContext: modelContext,
            currentUserID: authService.currentUser?.id,
            cloudKitSharing: cloudKitSharing,
            nomineeService: nomineeService
        )
    }
}

// MARK: - Request Row View

struct RequestRowView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    let request: VaultAccessRequest
    @ObservedObject var requestService: VaultRequestService
    
    @State private var showAcceptAlert = false
    @State private var showDeclineAlert = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                        Text(request.vaultName ?? "Unknown Vault")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text(request.requestType == "request" ? "Request" : "Send")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    statusBadge(colors: colors)
                }
                
                // Details
                if request.requestType == "request" {
                    Text("From: \(request.requesterName ?? "Unknown")")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                } else {
                    Text("To: \(request.recipientName ?? request.recipientEmail ?? request.recipientPhone ?? "Unknown")")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                }
                
                if let message = request.message, !message.isEmpty {
                    Text(message)
                        .font(theme.typography.body)
                        .foregroundColor(colors.textPrimary)
                        .padding(.top, UnifiedTheme.Spacing.xs)
                }
                
                // Actions (for received pending requests)
                if request.requestType == "request" && request.status == "pending" {
                    HStack(spacing: UnifiedTheme.Spacing.md) {
                        Button {
                            Task {
                                try? await requestService.acceptRequest(request)
                            }
                        } label: {
                            Text("Accept")
                                .font(theme.typography.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.success)
                                .cornerRadius(UnifiedTheme.CornerRadius.md)
                        }
                        
                        Button {
                            Task {
                                try? await requestService.declineRequest(request)
                            }
                        } label: {
                            Text("Decline")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.md)
                        }
                    }
                    .padding(.top, UnifiedTheme.Spacing.sm)
                }
                
                // Timestamp
                Text(request.requestedAt, style: .relative)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textTertiary)
                    .padding(.top, UnifiedTheme.Spacing.xs)
            }
        }
    }
    
    private func statusBadge(colors: UnifiedTheme.Colors) -> some View {
        let (text, color) = statusInfo
        
        return Text(text)
            .font(theme.typography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, UnifiedTheme.Spacing.sm)
            .padding(.vertical, UnifiedTheme.Spacing.xs)
            .background(color)
            .cornerRadius(UnifiedTheme.CornerRadius.sm)
    }
    
    private var statusInfo: (String, Color) {
        switch request.status {
        case "pending":
            return ("Pending", .orange)
        case "accepted":
            return ("Accepted", .green)
        case "declined":
            return ("Declined", .red)
        case "expired":
            return ("Expired", .gray)
        default:
            return ("Unknown", .gray)
        }
    }
}

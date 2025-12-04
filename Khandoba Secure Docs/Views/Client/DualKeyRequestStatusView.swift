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
    
    @Query private var allRequests: [DualKeyRequest]
    
    var myRequests: [DualKeyRequest] {
        allRequests.filter { request in
            request.requester?.id == authService.currentUser?.id
        }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if myRequests.isEmpty {
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
                // Refresh requests
            }
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


//
//  ClientDashboardView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct ClientDashboardView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var vaultService: VaultService
    
    // OPTIMIZATION: Only fetch recent logs (last 50) to prevent hanging
    @Query(sort: \VaultAccessLog.timestamp, order: .reverse)
    private var allAccessLogs: [VaultAccessLog]
    
    @State private var isLoading = false
    @State private var totalDocuments = 0
    @State private var activeSessions = 0
    
    private var accessLogs: [VaultAccessLog] {
        Array(allAccessLogs.prefix(50))
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Header
                        VStack(spacing: UnifiedTheme.Spacing.xs) {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .font(.title2)
                                    .foregroundColor(colors.primary)
                                Text("Khandoba")
                                    .font(theme.typography.title2)
                                    .foregroundColor(colors.textPrimary)
                                    .fontWeight(.bold)
                            }
                            
                            Text("Welcome Back")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                            
                            Text("Your secure vault dashboard")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textTertiary)
                        }
                        .padding(.top, UnifiedTheme.Spacing.md)
                        
                        // Data Protected Card
                        StandardCard {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.title3)
                                    .foregroundColor(colors.success)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Data Protected")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                    
                                    Text(vaultService.formatStorage(vaultService.getTotalStorage()))
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        
                        
                        // Stats Grid with 3D effects
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: UnifiedTheme.Spacing.md) {
                            StatCard(
                                title: "Vaults",
                                value: "\(vaultService.vaults.count)",
                                icon: "lock.shield.fill",
                                color: colors.primary
                            )
                            .floating3D(intensity: 8, duration: 2.5)
                            .depth3D(depth: 15, shadowIntensity: 0.2)
                            
                            StatCard(
                                title: "Documents",
                                value: "\(totalDocuments)",
                                icon: "doc.fill",
                                color: colors.secondary
                            )
                            .floating3D(intensity: 8, duration: 2.7)
                            .depth3D(depth: 15, shadowIntensity: 0.2)
                            
                            StatCard(
                                title: "Active Sessions",
                                value: "\(vaultService.activeSessions.count)",
                                icon: "clock.fill",
                                color: colors.info
                            )
                            
                            StatCard(
                                title: "Storage",
                                value: vaultService.formatStorage(vaultService.getTotalStorage()),
                                icon: "externaldrive.fill",
                                color: colors.success
                            )
                        }
                        .padding(.horizontal)
                        
                        // Pending Dual-Key Requests
                        NavigationLink {
                            DualKeyRequestStatusView()
                        } label: {
                            StandardCard {
                                HStack {
                                    HStack(spacing: -4) {
                                        Image(systemName: "key.fill")
                                        Image(systemName: "key.fill")
                                            .rotationEffect(.degrees(20))
                                    }
                                    .foregroundColor(colors.warning)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("My Access Requests")
                                            .font(theme.typography.subheadline)
                                            .foregroundColor(colors.textPrimary)
                                        
                                        Text("View pending dual-key approvals")
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
                        
                        // Recent Activity
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("Recent Activity")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                                .padding(.horizontal)
                            
                            if accessLogs.isEmpty {
                                StandardCard {
                                    Text("No recent activity")
                                        .font(theme.typography.body)
                                        .foregroundColor(colors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, UnifiedTheme.Spacing.lg)
                                }
                                .padding(.horizontal)
                            } else {
                                ForEach(accessLogs.prefix(5)) { log in
                                    ActivityRow(log: log)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await loadData()
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await vaultService.loadVaults()
            
            // Calculate total documents
            totalDocuments = vaultService.vaults.reduce(0) { $0 + ($1.documents?.count ?? 0) }
        } catch {
            print("Error loading dashboard data: \(error)")
        }
    }
}

struct ActivityRow: View {
    let log: VaultAccessLog
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                Image(systemName: iconForAccessType(log.accessType))
                    .font(.title3)
                    .foregroundColor(colorForAccessType(log.accessType))
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Enhanced description with context
                    Text(descriptionForActivity(log))
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                    
                    // Vault name if available
                    if let vaultName = log.vault?.name {
                        Text(vaultName)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Text(log.timestamp, style: .relative)
                        .font(theme.typography.caption2)
                        .foregroundColor(colors.textTertiary)
                }
                
                Spacer()
            }
        }
    }
    
    private func descriptionForActivity(_ log: VaultAccessLog) -> String {
        let vaultName = log.vault?.name ?? "vault"
        
        switch log.accessType {
        case "opened":
            return "Opened \(vaultName)"
        case "closed":
            return "Closed \(vaultName)"
        case "viewed":
            return "Viewed documents"
        case "modified":
            return "Modified content"
        case "deleted":
            return "Deleted items"
        case "upload":
            // Check if we can infer document type
            if vaultName.lowercased().contains("medical") {
                return "Uploaded medical document"
            } else if vaultName.lowercased().contains("legal") {
                return "Uploaded legal document"
            } else {
                return "Uploaded document to \(vaultName)"
            }
        case "created":
            return "Created new vault"
        default:
            return log.accessType.capitalized
        }
    }
    
    private func iconForAccessType(_ type: String) -> String {
        switch type {
        case "opened": return "lock.open.fill"
        case "closed": return "lock.fill"
        case "viewed": return "eye.fill"
        case "modified": return "pencil.circle.fill"
        case "deleted": return "trash.fill"
        default: return "circle.fill"
        }
    }
    
    private func colorForAccessType(_ type: String) -> Color {
        let colors = theme.colors(for: colorScheme)
        switch type {
        case "opened": return colors.primary
        case "closed": return colors.textTertiary
        case "viewed": return colors.secondary
        case "modified": return colors.warning
        case "deleted": return colors.error
        default: return colors.textTertiary
        }
    }
}


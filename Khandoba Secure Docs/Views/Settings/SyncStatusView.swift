//
//  SyncStatusView.swift
//  Khandoba Secure Docs
//
//  Sync status view
//

import SwiftUI

struct SyncStatusView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncService = EnhancedSyncService.shared
    @StateObject private var cloudKitService = CloudKitAPIService()
    
    @State private var isSyncing = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Sync Status Card
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                Text("Sync Status")
                                    .font(theme.typography.headline)
                                
                                HStack {
                                    StatusIndicator(status: syncService.syncStatus)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(syncService.syncStatus.rawValue)
                                            .font(theme.typography.title2)
                                        
                                        if let lastSync = syncService.lastSyncTime {
                                            Text("Last sync: \(DateFormatter.localizedString(from: lastSync, dateStyle: .none, timeStyle: .medium))")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                    }
                                }
                                
                                if syncService.syncStatus == .syncing {
                                    ProgressView(value: syncService.syncProgress, total: 1.0)
                                }
                            }
                            .padding()
                        }
                        
                        // Network Status
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                Text("Network Status")
                                    .font(theme.typography.headline)
                                
                                HStack {
                                    Image(systemName: syncService.isOnline ? "wifi" : "wifi.slash")
                                        .foregroundColor(syncService.isOnline ? colors.success : colors.error)
                                    
                                    Text(syncService.isOnline ? "Online" : "Offline")
                                        .font(theme.typography.body)
                                }
                            }
                            .padding()
                        }
                        
                        // Conflict Status
                        if syncService.conflictCount > 0 {
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                    Text("Conflicts")
                                        .font(theme.typography.headline)
                                    
                                    Text("\(syncService.conflictCount) conflict(s) detected")
                                        .font(theme.typography.body)
                                        .foregroundColor(colors.warning)
                                }
                                .padding()
                            }
                        }
                        
                        // Sync Button
                        Button {
                            Task {
                                await performSync()
                            }
                        } label: {
                            Text(isSyncing ? "Syncing..." : "Sync Now")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSyncing || !syncService.isOnline)
                        .padding()
                    }
                    .padding()
                }
                .navigationTitle("Sync Status")
                .navigationBarTitleDisplayMode(.large)
                .refreshable {
                    await performSync()
                }
            }
        }
        .onAppear {
            configureServices()
        }
    }
    
    private func configureServices() {
        syncService.configure(
            modelContext: modelContext,
            cloudKitService: cloudKitService
        )
    }
    
    private func performSync() async {
        isSyncing = true
        defer { isSyncing = false }
        
        try? await syncService.performSync()
    }
}

private struct StatusIndicator: View {
    let status: SyncStatus
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack(spacing: UnifiedTheme.Spacing.sm) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            if status == .syncing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }
    
    private var statusColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch status {
        case .synced:
            return colors.success
        case .syncing:
            return colors.info
        case .error, .conflict:
            return colors.error
        case .offline:
            return colors.warning
        case .idle:
            return colors.textTertiary
        }
    }
}


//
//  ConnectedAccountsView.swift
//  Khandoba Secure Docs
//
//  Connected OAuth accounts management view
//

import SwiftUI

struct ConnectedAccountsView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var oauthService = OAuthService.shared
    
    @State private var isConnecting = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                List {
                    Section("iCloud Services") {
                        // iCloud Drive - Always available, uses native file picker
                        HStack(spacing: UnifiedTheme.Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(colors.success)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("iCloud Drive")
                                    .foregroundColor(colors.textPrimary)
                                Text("Access files from iCloud Drive")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text("Connected")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.success)
                        }
                        .listRowBackground(colors.surface)
                        
                        // iCloud Photos - Always available, uses Photos framework
                        HStack(spacing: UnifiedTheme.Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(colors.success)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("iCloud Photos")
                                    .foregroundColor(colors.textPrimary)
                                Text("Access photos from iCloud Photos")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text("Connected")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.success)
                        }
                        .listRowBackground(colors.surface)
                        
                        // iCloud Mail - Always available, uses Mail framework
                        HStack(spacing: UnifiedTheme.Spacing.md) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(colors.success)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("iCloud Mail")
                                    .foregroundColor(colors.textPrimary)
                                Text("Access emails from iCloud Mail")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text("Connected")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.success)
                        }
                        .listRowBackground(colors.surface)
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("iCloud Sync Status")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("All your data (vaults, documents, photos, emails) automatically syncs across your devices using iCloud.")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding(.vertical, UnifiedTheme.Spacing.xs)
                        .listRowBackground(colors.surface)
                    } header: {
                        Text("About iCloud Integration")
                    }
                }
                .navigationTitle("Connected Accounts")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
    }
    
    // iCloud services don't require OAuth - they use native iOS APIs
    // iCloud Drive: Uses UIDocumentPickerViewController
    // iCloud Photos: Uses PHPickerViewController
    // iCloud Mail: Uses MessageUI framework
}

private struct AccountRow: View {
    let provider: OAuthProvider
    let isConnected: Bool
    let onConnect: () async -> Void
    let onDisconnect: () throws -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @State private var isProcessing = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack(spacing: UnifiedTheme.Spacing.md) {
            Image(systemName: isConnected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isConnected ? colors.success : colors.textTertiary)
            
            Text(provider.displayName)
                .foregroundColor(colors.textPrimary)
            
            Spacer()
            
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button(isConnected ? "Disconnect" : "Connect") {
                    Task {
                        isProcessing = true
                        if isConnected {
                            try? onDisconnect()
                        } else {
                            await onConnect()
                        }
                        isProcessing = false
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}


//
//  AdminVaultDetailView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import Combine

struct AdminVaultDetailView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    // Zero-Knowledge Warning
                    StandardCard {
                        HStack(spacing: UnifiedTheme.Spacing.sm) {
                            Image(systemName: "eye.slash.fill")
                                .foregroundColor(colors.warning)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Zero-Knowledge Mode")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textPrimary)
                                    .fontWeight(.semibold)
                                
                                Text("You can only view metadata, not document content")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Vault Metadata
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            MetadataRow(label: "Vault Name", value: vault.name)
                            Divider()
                            MetadataRow(label: "Owner ID", value: vault.owner?.id.uuidString ?? "Unknown")
                            Divider()
                            MetadataRow(label: "Created", value: vault.createdAt.formatted(date: .abbreviated, time: .shortened))
                            Divider()
                            MetadataRow(label: "Status", value: vault.status.capitalized)
                            Divider()
                            MetadataRow(label: "Key Type", value: vault.keyType == "dual" ? "Dual-Key" : "Single-Key")
                            Divider()
                            MetadataRow(label: "Documents", value: "\(vault.documents?.count ?? 0)")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Admin Actions
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Admin Actions")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                            .padding(.horizontal)
                        
                        StandardCard {
                            VStack(spacing: 0) {
                                NavigationLink {
                                    AccessMapView(vault: vault)
                                } label: {
                                    SecurityActionRow(
                                        icon: "map.fill",
                                        title: "Access Map",
                                        subtitle: "View access locations",
                                        color: colors.info
                                    )
                                }
                                
                                Divider()
                                
                                NavigationLink {
                                    ThreatDashboardView(vault: vault)
                                } label: {
                                    SecurityActionRow(
                                        icon: "shield.checkered",
                                        title: "Threat Monitor",
                                        subtitle: "Security analysis",
                                        color: colors.warning
                                    )
                                }
                                
                                Divider()
                                
                                Button {
                                    // Dual-key approval action
                                } label: {
                                    SecurityActionRow(
                                        icon: "key.fill",
                                        title: "Dual-Key Requests",
                                        subtitle: "Approve access requests",
                                        color: colors.primary
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // CRITICAL: No Intel Reports access for admins
                    StandardCard {
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            Image(systemName: "lock.doc.fill")
                                .font(.largeTitle)
                                .foregroundColor(colors.textTertiary)
                            
                            Text("Document Content Restricted")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("Zero-knowledge architecture prevents access to document content and intel reports")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, UnifiedTheme.Spacing.lg)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle(vault.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack {
            Text(label)
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textPrimary)
                .lineLimit(1)
        }
    }
}

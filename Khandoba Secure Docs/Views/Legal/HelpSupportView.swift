//
//  HelpSupportView.swift
//  Khandoba Secure Docs
//
//  Help and support information

import SwiftUI

struct HelpSupportView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                        Text("Help & Support")
                            .font(theme.typography.title)
                            .foregroundColor(colors.textPrimary)
                            .padding(.bottom)
                        
                        SupportSection(
                            title: "Getting Started",
                            items: [
                                "Create your first vault from the Vaults tab",
                                "Upload documents using the + button",
                                "Documents are automatically encrypted with AES-256",
                                "AI automatically names and tags your documents"
                            ]
                        )
                        
                        SupportSection(
                            title: "Vault Types",
                            items: [
                                "Single-Key Vault: Instant access, unlock with biometrics",
                                "Dual-Key Vault: Requires admin approval for enhanced security",
                                "All vaults have 30-minute sessions that auto-lock"
                            ]
                        )
                        
                        SupportSection(
                            title: "Subscription",
                            items: [
                                "Premium: $5.99/month for unlimited access",
                                "Includes unlimited vaults and storage",
                                "Family Sharing with up to 6 people",
                                "Manage in iOS Settings → Subscriptions"
                            ]
                        )
                        
                        SupportSection(
                            title: "Security",
                            items: [
                                "Zero-knowledge architecture: Only you can decrypt your data",
                                "Documents encrypted on your device before storage",
                                "Admins cannot access your document content",
                                "Location tracking for access logging only"
                            ]
                        )
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Contact Support")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            NavigationLink {
                                AdminSupportChatView()
                            } label: {
                                HStack {
                                    Image(systemName: "message.fill")
                                        .foregroundColor(colors.primary)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Live Chat Support")
                                            .font(theme.typography.body)
                                            .foregroundColor(colors.textPrimary)
                                        Text("Chat with an admin")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(colors.textTertiary)
                                }
                                .padding(UnifiedTheme.Spacing.md)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var colors: UnifiedTheme.Colors {
        theme.colors(for: colorScheme)
    }
}

struct SupportSection: View {
    let title: String
    let items: [String]
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
            Text(title)
                .font(theme.typography.headline)
                .foregroundColor(theme.colors(for: colorScheme).textPrimary)
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(theme.colors(for: colorScheme).primary)
                    Text(item)
                        .font(theme.typography.body)
                        .foregroundColor(theme.colors(for: colorScheme).textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.bottom, UnifiedTheme.Spacing.md)
    }
}

struct ContactRow: View {
    let icon: String
    let label: String
    let value: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(theme.colors(for: colorScheme).primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors(for: colorScheme).textSecondary)
                Text(value)
                    .font(theme.typography.body)
                    .foregroundColor(theme.colors(for: colorScheme).textPrimary)
            }
        }
    }
}


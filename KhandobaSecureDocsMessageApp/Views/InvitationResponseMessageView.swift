//
//  InvitationResponseMessageView.swift
//  Khandoba Secure Docs
//
//  Interactive invitation response view (Apple Cash style)
//

import SwiftUI
import Messages

struct InvitationResponseMessageView: View {
    let message: MSMessage
    let conversation: MSConversation
    let token: String?
    let vaultName: String
    let sender: String
    let status: String
    
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.xl) {
                        // Header
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 60))
                                .foregroundColor(colors.primary)
                            
                            Text("Vault Invitation")
                                .font(theme.typography.title)
                                .foregroundColor(colors.textPrimary)
                            
                            if status == "pending" {
                                Text("You've been invited to access a vault")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            } else if status == "accepted" {
                                Text("✅ You've accepted this invitation")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.success)
                                    .multilineTextAlignment(.center)
                            } else if status == "declined" {
                                Text("❌ You've declined this invitation")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.error)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, UnifiedTheme.Spacing.xl)
                        
                        // Invitation Details Card
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                    Text("Vault Name")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                    
                                    Text(vaultName)
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                }
                                
                                Divider()
                                
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                    Text("Invited By")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                    
                                    Text(sender)
                                        .font(theme.typography.body)
                                        .foregroundColor(colors.textPrimary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Buttons (only show if pending)
                        if status == "pending" {
                            VStack(spacing: UnifiedTheme.Spacing.md) {
                                // Accept Button
                                Button {
                                    onAccept()
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Accept Invitation")
                                    }
                                    .font(theme.typography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(colors.success)
                                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                }
                                
                                // Decline Button
                                Button {
                                    onDecline()
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Decline")
                                    }
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(colors.surface)
                                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            // Status Message
                            StandardCard {
                                HStack {
                                    Image(systemName: status == "accepted" ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(status == "accepted" ? colors.success : colors.error)
                                    
                                    Text(status == "accepted" 
                                         ? "Invitation accepted. Open the app to access the vault."
                                         : "Invitation declined.")
                                        .font(theme.typography.body)
                                        .foregroundColor(colors.textPrimary)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Vault Invitation")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

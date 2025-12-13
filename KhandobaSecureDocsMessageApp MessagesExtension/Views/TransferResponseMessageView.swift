//
//  TransferResponseMessageView.swift
//  Khandoba Secure Docs
//
//  Interactive transfer ownership response view
//

import SwiftUI
import Messages

struct TransferResponseMessageView: View {
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
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 60))
                                .foregroundColor(colors.warning)
                            
                            Text("Transfer Ownership")
                                .font(theme.typography.title)
                                .foregroundColor(colors.textPrimary)
                            
                            if status == "pending" {
                                Text("You've been asked to accept vault ownership")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            } else if status == "accepted" {
                                Text("✅ You've accepted this ownership transfer")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.success)
                                    .multilineTextAlignment(.center)
                            } else if status == "declined" {
                                Text("❌ You've declined this ownership transfer")
                                    .font(theme.typography.body)
                                    .foregroundColor(colors.error)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, UnifiedTheme.Spacing.xl)
                        
                        // Warning Card
                        if status == "pending" {
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(colors.warning)
                                        Text("Important")
                                            .font(theme.typography.subheadline)
                                            .foregroundColor(colors.textPrimary)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Text("Accepting this transfer will give you complete ownership of the vault. The current owner will lose all access.")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Transfer Details Card
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
                                    Text("Transferring From")
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
                                        Text("Accept Ownership")
                                    }
                                    .font(theme.typography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(colors.warning)
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
                                         ? "Ownership transfer accepted. Open the app to access the vault."
                                         : "Ownership transfer declined.")
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
            .navigationTitle("Transfer Ownership")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


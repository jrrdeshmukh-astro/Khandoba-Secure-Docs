//
//  MainMenuMessageView.swift
//  Khandoba Secure Docs
//
//  Main menu for iMessage app (invite nominee or share file)
//

import SwiftUI
import Messages

struct MainMenuMessageView: View {
    let conversation: MSConversation
    let onInviteNominee: () -> Void
    let onTransferOwnership: () -> Void
    let onShareFile: () -> Void
    
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
                            
                            Text("Khandoba Secure Docs")
                                .font(theme.typography.title)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("Share vaults and documents securely")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, UnifiedTheme.Spacing.xl)
                        
                        // Action Buttons
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            // Invite Nominee Button
                            Button {
                                onInviteNominee()
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Invite to Vault")
                                            .font(theme.typography.headline)
                                        Text("Send secure vault access")
                                            .font(theme.typography.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(colors.primary)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            }
                            
                            // Transfer Ownership Button
                            Button {
                                onTransferOwnership()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Transfer Ownership")
                                            .font(theme.typography.headline)
                                        Text("Transfer vault ownership")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(colors.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            }
                            
                            // Share File Button
                            Button {
                                onShareFile()
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Share File")
                                            .font(theme.typography.headline)
                                        Text("Send document to vault")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(colors.textPrimary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Info Card
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(colors.info)
                                    Text("About")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textPrimary)
                                        .fontWeight(.semibold)
                                }
                                
                                Text("Invite others to access your vaults, transfer ownership, or share files directly. All sharing is secure and encrypted.")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Khandoba")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

//
//  AppleCashStyleMessageView.swift
//  Khandoba Secure Docs
//
//  Apple Cash-style interactive message view for vault invitations
//

import SwiftUI
import Messages

struct AppleCashStyleMessageView: View {
    let vaultName: String
    let senderName: String
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // Apple Cash style header
            HStack {
                Text("Khandoba Secure Docs")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(colors.textPrimary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(colors.surface)
            
            Divider()
            
            // Main content - Apple Cash style
            VStack(spacing: 24) {
                // Large vault name display (like "$1" in Apple Cash)
                VStack(spacing: 8) {
                    Text(vaultName)
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(colors.textPrimary)
                    
                    Text("Vault Invitation")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(colors.textSecondary)
                }
                .padding(.top, 40)
                
                // Sender info (like "Send to Aai")
                VStack(alignment: .leading, spacing: 8) {
                    Text("From")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(colors.textSecondary)
                    
                    Text(senderName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(colors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                
                // Action buttons (Apple Cash style - Request/Send)
                VStack(spacing: 12) {
                    Button(action: onAccept) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                            Text("Accept")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(colors.primary)
                        .cornerRadius(14)
                    }
                    
                    Button(action: onDecline) {
                        Text("Decline")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(colors.surface)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}

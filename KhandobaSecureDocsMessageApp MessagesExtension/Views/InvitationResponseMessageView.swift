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
        
        // Apple Cash style layout
        VStack(spacing: 0) {
            // Header (Apple Cash style)
            HStack {
                Button(action: {}) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colors.textPrimary)
                        .frame(width: 32, height: 32)
                }
                
                Spacer()
                
                Text("Khandoba Secure Docs")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(colors.surface)
            
            Divider()
            
            // Main content - Apple Cash style
            ScrollView {
                VStack(spacing: 24) {
                    // Large vault name display (like "$1" in Apple Cash)
                    VStack(spacing: 12) {
                        Text(vaultName)
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(colors.textPrimary)
                        
                        Text("Vault Invitation")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(colors.textSecondary)
                    }
                    .padding(.top, 40)
                    
                    // Sender info (like "Send to Aai" in Apple Cash)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(colors.textSecondary)
                        
                        Text(sender)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Status display (if not pending)
                    if status != "pending" {
                        VStack(spacing: 8) {
                            Image(systemName: status == "accepted" ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(status == "accepted" ? colors.success : colors.error)
                            
                            Text(status == "accepted" 
                                 ? "Invitation Accepted"
                                 : "Invitation Declined")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(colors.textPrimary)
                        }
                        .padding(.vertical, 20)
                    }
                    
                    // Action buttons (Apple Cash style - Accept/Decline)
                    if status == "pending" {
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
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}

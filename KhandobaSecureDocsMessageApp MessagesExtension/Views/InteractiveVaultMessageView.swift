//
//  InteractiveVaultMessageView.swift
//  Khandoba Secure Docs
//
//  Interactive message bubble view for vault invitations/transfers - Apple Cash style
//

import SwiftUI
import Messages

struct InteractiveVaultMessageView: View {
    let vault: Vault
    let actionType: MessageActionType
    let status: MessageStatus
    let onTap: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Vault Card Preview (Apple Cash style - card in message)
                VaultCardView(
                    vault: vault,
                    isSelected: false
                ) {
                    onTap()
                }
                .frame(height: 160)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                // Action Info Section
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vault.name)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(actionDescription)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Status indicator
                        if status == .pending {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(colors.primary)
                        } else if status == .accepted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                        } else if status == .declined {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                        }
                    }
                    
                    if status == .pending {
                        Text("Tap to \(actionType == .invite ? "accept" : "respond")")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(colors.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .background(colors.surface)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        status == .pending ? colors.primary.opacity(0.2) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var actionDescription: String {
        switch actionType {
        case .invite:
            return "Vault Invitation"
        case .transfer:
            return "Ownership Transfer"
        case .emergency:
            return "Emergency Access Request"
        }
    }
}

enum MessageActionType {
    case invite
    case transfer
    case emergency
}

enum MessageStatus {
    case pending
    case accepted
    case declined
}

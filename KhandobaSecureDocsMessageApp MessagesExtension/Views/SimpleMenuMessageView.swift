//
//  SimpleMenuMessageView.swift
//  Khandoba Secure Docs
//
//  Simple menu view for iMessage extension
//

import SwiftUI

struct SimpleMenuMessageView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    let onSelectVault: () -> Void
    let onTransfer: () -> Void
    let onEmergency: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 16) {
            Text("Khandoba Secure Docs")
                .font(theme.typography.title)
                .foregroundColor(colors.primary)
                .padding(.top, 20)
            
            Text("What would you like to do?")
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
                .padding(.bottom, 20)
            
            // Menu Options
            VStack(spacing: 12) {
                // Invite Nominee
                Button(action: {
                    onSelectVault()
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 20))
                        Text("Invite Nominee")
                            .font(theme.typography.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(colors.textPrimary)
                    .padding()
                    .background(colors.surface)
                    .cornerRadius(12)
                }
                
                // Transfer Ownership
                Button(action: {
                    onTransfer()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 20))
                        Text("Transfer Ownership")
                            .font(theme.typography.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(colors.textPrimary)
                    .padding()
                    .background(colors.surface)
                    .cornerRadius(12)
                }
                
                // Emergency Protocol
                Button(action: {
                    onEmergency()
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                        Text("Emergency Protocol")
                            .font(theme.typography.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(colors.textPrimary)
                    .padding()
                    .background(colors.surface)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Cancel Button
            Button(action: {
                onCancel()
            }) {
                Text("Cancel")
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.surface)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}

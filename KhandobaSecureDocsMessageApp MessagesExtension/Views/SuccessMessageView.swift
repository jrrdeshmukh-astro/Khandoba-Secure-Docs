//
//  SuccessMessageView.swift
//  Khandoba Secure Docs
//
//  Success confirmation view for iMessage extension
//

import SwiftUI

struct SuccessMessageView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    let message: String
    let vaultName: String?
    let onDismiss: () -> Void
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 24) {
            // Success Icon
            ZStack {
                Circle()
                    .fill(colors.success.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(colors.success)
            }
            .padding(.top, 40)
            
            // Success Message
            VStack(spacing: 8) {
                Text("Success!")
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                
                Text(message)
                    .font(theme.typography.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let vaultName = vaultName {
                    Text(vaultName)
                        .font(theme.typography.headline)
                        .foregroundColor(colors.primary)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Dismiss Button
            Button(action: {
                onDismiss()
            }) {
                Text("Done")
                    .font(theme.typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colors.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}

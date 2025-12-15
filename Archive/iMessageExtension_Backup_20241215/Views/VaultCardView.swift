//
//  VaultCardView.swift
//  Khandoba Secure Docs
//
//  Apple Cash-style vault card component
//

import SwiftUI

struct VaultCardView: View {
    let vault: Vault
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: vault.keyType == "dual" ? "key.fill" : "key")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Vault Name
                Text(vault.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Vault Type
                if vault.keyType == "dual" {
                    Text("Dual-Key Vault")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text("Single-Key Vault")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(20)
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        colors.primary,
                        colors.primary.opacity(0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(color: isSelected ? colors.primary.opacity(0.5) : Color.black.opacity(0.2), radius: isSelected ? 12 : 8, x: 0, y: isSelected ? 6 : 4)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

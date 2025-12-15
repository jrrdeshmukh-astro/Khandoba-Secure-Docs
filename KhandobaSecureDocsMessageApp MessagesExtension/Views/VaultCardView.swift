//
//  VaultCardView.swift
//  Khandoba Secure Docs
//
//  Apple Cash-style vault card component - Enhanced to match Apple Cash cards exactly
//

import SwiftUI

struct VaultCardView: View {
    let vault: Vault
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var cardScale: CGFloat = 1.0
    @State private var shadowRadius: CGFloat = 10
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: onTap) {
            ZStack {
                // Rich gradient background (Apple Cash style - deeper, more vibrant)
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: colors.primary, location: 0.0),
                        .init(color: colors.primary.opacity(0.9), location: 0.3),
                        .init(color: colors.primary.opacity(0.8), location: 0.6),
                        .init(color: colors.primary.opacity(0.7), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(20)
                
                // Radial gradient overlay for depth (like Apple Cash)
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05),
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 300
                )
                .cornerRadius(20)
                
                // Subtle pattern overlay for texture
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.06),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Shine effect (subtle highlight)
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 16) {
                    // Top section with icon and checkmark
                    HStack {
                        ZStack {
                            // Icon background with glow
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 48, height: 48)
                                .blur(radius: 2)
                            
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: vault.keyType == "dual" ? "key.fill" : "key")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        if isSelected {
                            ZStack {
                                // Checkmark background with glow
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .blur(radius: 1)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 28, height: 28)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(colors.primary)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    Spacer()
                    
                    // Vault name (prominent, like card number in Apple Cash)
                    Text(vault.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    
                    // Vault type (like card issuer)
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.95))
                        
                        Text(vault.keyType == "dual" ? "Dual-Key Vault" : "Single-Key Vault")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))
                    }
                    .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 0.5)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.white.opacity(0.6) : Color.clear,
                        lineWidth: isSelected ? 3 : 0
                    )
            )
            .scaleEffect(cardScale)
            .shadow(
                color: isSelected ? colors.primary.opacity(0.5) : Color.black.opacity(0.2),
                radius: shadowRadius,
                x: 0,
                y: isSelected ? 10 : 6
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onChange(of: isSelected) { newValue in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                cardScale = newValue ? 1.05 : 1.0
                shadowRadius = newValue ? 20 : 10
            }
        }
    }
}

//
//  WalletCard.swift
//  Khandoba Secure Docs
//
//  Wallet-style vault card component with unified theme and subtle gradients
//

import SwiftUI

struct WalletCard: View {
    let vault: Vault
    let index: Int
    let totalCount: Int
    let onTap: () -> Void
    let onLongPress: (() -> Void)?
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vaultService: VaultService
    
    @State private var isPressed = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let shadow = UnifiedTheme.Shadow.md(for: colorScheme)
        let hasActiveSession = vaultService.hasActiveSession(for: vault.id)
        let isSharedVault = isVaultShared
        
        // Card stacking effect - offset and scale based on index
        let cardOffset: CGFloat = index == 0 ? 0 : CGFloat(index) * 8
        let cardScale: CGFloat = index == 0 ? 1.0 : max(0.92, 1.0 - CGFloat(index) * 0.04)
        let cardOpacity: Double = index == 0 ? 1.0 : max(0.6, 1.0 - Double(index) * 0.15)
        
        ZStack {
            // Base card with gradient
            RoundedRectangle(cornerRadius: UnifiedTheme.CornerRadius.xl)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Subtle pattern overlay
                    RoundedRectangle(cornerRadius: UnifiedTheme.CornerRadius.xl)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white.opacity(0.1), location: 0),
                                    .init(color: .clear, location: 0.5),
                                    .init(color: .black.opacity(colorScheme == .dark ? 0.1 : 0.05), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
            
            // Content
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                // Header with icon and badges
                HStack {
                    // Vault icon
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: hasActiveSession ? "lock.open.fill" : "lock.shield.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Badges
                    HStack(spacing: UnifiedTheme.Spacing.xs) {
                        if isSharedVault {
                            BadgeView(
                                icon: "person.2.fill",
                                text: "SHARED",
                                backgroundColor: .white.opacity(0.3)
                            )
                        }
                        
                        if vault.keyType == "dual" {
                            BadgeView(
                                icon: "key.fill",
                                text: "DUAL-KEY",
                                backgroundColor: .white.opacity(0.3)
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Vault name
                Text(vault.name)
                    .font(theme.typography.title)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                // Description (if available)
                if let description = vault.vaultDescription, !description.isEmpty {
                    Text(description)
                        .font(theme.typography.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                
                // Footer with document count and status
                HStack {
                    HStack(spacing: UnifiedTheme.Spacing.xs) {
                        Image(systemName: "doc.fill")
                            .font(.caption2)
                        Text("\(vault.documents?.count ?? 0) documents")
                            .font(theme.typography.caption2)
                    }
                    .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    // Status indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(hasActiveSession ? Color.green : Color.white.opacity(0.5))
                            .frame(width: 8, height: 8)
                        Text(hasActiveSession ? "Unlocked" : "Locked")
                            .font(theme.typography.caption2)
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(UnifiedTheme.Spacing.lg)
        }
        .frame(height: 200)
        .scaleEffect(isPressed ? 0.98 : cardScale)
        .offset(y: cardOffset)
        .opacity(cardOpacity)
        .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
        .onTapGesture {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.3) {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            onLongPress?()
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
    
    // Gradient colors based on vault type
    private var gradientColors: [Color] {
        let colors = theme.colors(for: colorScheme)
        
        if vault.keyType == "dual" {
            // Dual-key: warning → tertiary gradient
            return [
                colors.warning.opacity(0.9),
                colors.tertiary.opacity(0.8)
            ]
        } else {
            // Single-key: primary → secondary gradient
            return [
                colors.primary.opacity(0.9),
                colors.secondary.opacity(0.8)
            ]
        }
    }
    
    /// Check if this vault is shared (has active nominees)
    private var isVaultShared: Bool {
        guard let nominees = vault.nomineeList, !nominees.isEmpty else {
            return false
        }
        return nominees.contains { nominee in
            nominee.status == .accepted || nominee.status == .pending
        }
    }
}

// MARK: - Badge View
private struct BadgeView: View {
    let icon: String
    let text: String
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .semibold))
            Text(text)
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(backgroundColor)
        .cornerRadius(4)
    }
}

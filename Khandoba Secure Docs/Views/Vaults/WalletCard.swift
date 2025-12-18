//
//  WalletCard.swift
//  Khandoba Secure Docs
//
//  PassKit-inspired wallet card with rolodex animation
//

import SwiftUI

struct WalletCard: View {
    let vault: Vault
    let index: Int
    let totalCount: Int
    let hasActiveSession: Bool
    let onTap: () -> Void
    let onLongPress: (() -> Void)?
    
    // Animation inputs for rolodex effect
    var rotation: Double = 0
    var scale: CGFloat = 1
    var yOffset: CGFloat = 0
    var z: Double = 0
    var opacity: Double = 1
    
    // Matched transition for navigation
    let namespace: Namespace.ID?
    // Whether this card is the front card (only front card should be source for matched geometry)
    var isFrontCard: Bool = false
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isPressed = false
    
    var body: some View {
        let shadow = UnifiedTheme.Shadow.lg(for: colorScheme)
        
        ZStack {
            // Card background with gradient (PassKit style)
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Subtle pattern overlay
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .white.opacity(0.15), location: 0),
                                    .init(color: .clear, location: 0.5),
                                    .init(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.08), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
            
            // Card content
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                // Header with icon and badges
                HStack {
                    // Vault icon
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.25))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: hasActiveSession ? "lock.open.fill" : "lock.shield.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                Spacer()
                    
                    // Badges
                    HStack(spacing: UnifiedTheme.Spacing.xs) {
                        if isVaultShared {
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
                    .matchedGeometryEffect(
                        id: "title-\(vault.id)",
                        in: namespace ?? Namespace().wrappedValue,
                        isSource: isFrontCard
                    )
                
                // Description (if available)
                if let description = vault.vaultDescription, !description.isEmpty {
                    Text(description)
                        .font(theme.typography.caption)
                        .foregroundColor(.white.opacity(0.85))
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
        .scaleEffect(isPressed ? 0.98 : scale)
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
        .offset(y: yOffset)
        .opacity(opacity)
        .zIndex(z)
        .shadow(
            color: shadow.color.opacity(0.3),
            radius: shadow.radius * 1.5,
            x: shadow.x,
            y: shadow.y + 2
        )
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .animation(
            AnimationStyles.spring,
            value: scale
        )
        .animation(
            AnimationStyles.spring,
            value: rotation
        )
        .animation(
            AnimationStyles.spring,
            value: yOffset
        )
        .animation(
            AnimationStyles.easeInOut,
            value: opacity
        )
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    // Double-tap for unlock (Apple Pay-style)
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    onTap()
                }
        )
        .onLongPressGesture(minimumDuration: 0.3) {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            onLongPress?()
        } onPressingChanged: { pressing in
            withAnimation(AnimationStyles.snap) {
                isPressed = pressing
            }
        }
    }
    
    // Gradient colors based on vault type (PassKit-inspired)
    private var gradientColors: [Color] {
        let colors = theme.colors(for: colorScheme)
        
        if vault.keyType == "dual" {
            // Dual-key: warning → tertiary gradient
            return [
                colors.warning.opacity(0.95),
                colors.tertiary.opacity(0.85)
            ]
        } else {
            // Single-key: primary → secondary gradient
            return [
                colors.primary.opacity(0.95),
                colors.secondary.opacity(0.85)
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

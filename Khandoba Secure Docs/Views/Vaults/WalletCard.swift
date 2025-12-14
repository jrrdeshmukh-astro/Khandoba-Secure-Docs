// WalletCard.swift
import SwiftUI

struct WalletCard: View {
    let vault: Vault
    let index: Int
    let totalCount: Int
    let hasActiveSession: Bool
    let onTap: () -> Void
    let onLongPress: (() -> Void)?
    
    // Animation inputs
    var rotation: Double = 0
    var scale: CGFloat = 1
    var yOffset: CGFloat = 0
    var z: Double = 0
    
    // Matched transition
    let namespace: Namespace.ID?
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let shadow = UnifiedTheme.Shadow.md(for: colorScheme)
        
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
            HStack(spacing: UnifiedTheme.Spacing.sm) {
                Image(systemName: hasActiveSession ? "lock.open.fill" : "lock.fill")
                    .foregroundColor(hasActiveSession ? colors.success : colors.error)
                Text(vault.name)
                    .font(theme.typography.title2)
                    .foregroundColor(colors.textPrimary)
                    .matchedGeometryEffect(id: "title-\(vault.id)", in: namespace ?? Namespace().wrappedValue, isSource: true)
                Spacer()
                if vault.keyType == "dual" {
                    HStack(spacing: -2) {
                        Image(systemName: "key.fill").font(.caption2)
                        Image(systemName: "key.fill").font(.caption2).rotationEffect(.degrees(15))
                    }
                    .foregroundColor(colors.warning)
                    .matchedGeometryEffect(id: "badge-\(vault.id)", in: namespace ?? Namespace().wrappedValue, isSource: true)
                }
            }
            .padding(.top, 8)
            
            HStack(spacing: UnifiedTheme.Spacing.sm) {
                Image(systemName: "doc.fill")
                    .foregroundColor(colors.textSecondary)
                    .font(.caption)
                Text("\(vault.documents?.count ?? 0) documents")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(hasActiveSession ? colors.success : colors.error)
                        .frame(width: 6, height: 6)
                    Text(hasActiveSession ? "Unlocked" : "Locked")
                        .font(theme.typography.caption)
                        .foregroundColor(hasActiveSession ? colors.success : colors.error)
                }
            }
            .padding(.bottom, 4)
        }
        .padding(UnifiedTheme.Spacing.lg)
        .background(colors.surfaceElevated)
        .cornerRadius(UnifiedTheme.CornerRadius.xxl)
        .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
        .scaleEffect(scale)
        .rotation3DEffect(.degrees(rotation), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
        .offset(y: yOffset)
        .zIndex(z)
        .contentShape(RoundedRectangle(cornerRadius: UnifiedTheme.CornerRadius.xxl))
        .onTapGesture { onTap() }
        .onLongPressGesture {
            onLongPress?()
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: rotation)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: scale)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: yOffset)
    }
}

//
//  ThemeModifiers.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import Combine

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        let colors = theme.colors(for: colorScheme)
        let shadow = UnifiedTheme.Shadow.sm(for: colorScheme)
        
        content
            .background(colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        let colors = theme.colors(for: colorScheme)
        
        configuration.label
            .font(theme.typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, UnifiedTheme.Spacing.lg)
            .padding(.vertical, UnifiedTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: UnifiedTheme.CornerRadius.lg)
                    .fill(isEnabled ? colors.primary : colors.textTertiary)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        let colors = theme.colors(for: colorScheme)
        
        configuration.label
            .font(theme.typography.headline)
            .foregroundColor(colors.primary)
            .padding(.horizontal, UnifiedTheme.Spacing.lg)
            .padding(.vertical, UnifiedTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: UnifiedTheme.CornerRadius.lg)
                    .stroke(colors.primary, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self.modifier(CardModifier())
    }
    
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
}

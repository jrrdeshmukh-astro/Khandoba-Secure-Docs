//
//  StandardButton.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct StandardButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let style: ButtonStyleType
    let isEnabled: Bool
    
    enum ButtonStyleType {
        case primary
        case secondary
        case destructive
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyleType = .primary,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.style = style
        self.isEnabled = isEnabled
    }
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: UnifiedTheme.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(theme.typography.headline)
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, UnifiedTheme.Spacing.lg)
            .padding(.vertical, UnifiedTheme.Spacing.md)
            .background(backgroundColor)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
        }
        .disabled(!isEnabled)
    }
    
    private var foregroundColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch style {
        case .primary:
            return .white
        case .secondary:
            return colors.primary
        case .destructive:
            return .white
        }
    }
    
    private var backgroundColor: Color {
        let colors = theme.colors(for: colorScheme)
        if !isEnabled {
            return colors.textTertiary
        }
        switch style {
        case .primary:
            return colors.primary
        case .secondary:
            return Color.clear
        case .destructive:
            return colors.error
        }
    }
}


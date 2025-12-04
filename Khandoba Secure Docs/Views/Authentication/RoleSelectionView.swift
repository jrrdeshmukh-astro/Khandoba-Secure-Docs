//
//  RoleSelectionView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct RoleSelectionView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: UnifiedTheme.Spacing.xl) {
                // Header
                VStack(spacing: UnifiedTheme.Spacing.sm) {
                    Text("Select Your Role")
                        .font(theme.typography.title)
                        .foregroundColor(colors.textPrimary)
                        .fontWeight(.bold)
                    
                    Text("Choose how you want to use the app")
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                }
                .padding(.top, UnifiedTheme.Spacing.xl)
                
                Spacer()
                
                // Role Cards
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    RoleCard(
                        role: .client,
                        isSelected: true
                    ) {
                        authService.switchRole(to: .client)
                    }
                    
                    RoleCard(
                        role: .admin,
                        isSelected: false,
                        isDisabled: !hasAdminRole()
                    ) {
                        if hasAdminRole() {
                            authService.switchRole(to: .admin)
                        }
                    }
                }
                .padding(.horizontal, UnifiedTheme.Spacing.xl)
                
                Spacer()
            }
        }
    }
    
    private func hasAdminRole() -> Bool {
        guard let user = authService.currentUser else { return false }
        return user.roles?.contains { $0.role == .admin && $0.isActive } ?? false
    }
}

struct RoleCard: View {
    let role: Role
    let isSelected: Bool
    var isDisabled: Bool = false
    let action: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let shadow = UnifiedTheme.Shadow.md(for: colorScheme)
        
        Button(action: action) {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isDisabled ? colors.textTertiary.opacity(0.3) : roleColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: role.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(isDisabled ? colors.textTertiary : roleColor)
                }
                
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                    Text(role.displayName)
                        .font(theme.typography.headline)
                        .foregroundColor(isDisabled ? colors.textTertiary : colors.textPrimary)
                    
                    Text(isDisabled ? "Must be assigned separately" : role.description)
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected && !isDisabled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(colors.primary)
                }
            }
            .padding(UnifiedTheme.Spacing.lg)
            .background(colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
            .shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
        }
        .disabled(isDisabled)
    }
    
    private var roleColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch role {
        case .client: return colors.clientColor
        case .admin: return colors.adminColor
        }
    }
}


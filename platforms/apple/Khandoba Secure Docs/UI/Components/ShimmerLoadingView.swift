//
//  ShimmerLoadingView.swift
//  Khandoba Secure Docs
//
//  Created for production 1.0.1 launch
//

import SwiftUI

/// Shimmer effect loading view for skeleton loading
struct ShimmerLoadingView: View {
    let message: String?
    let itemCount: Int
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    init(message: String? = nil, itemCount: Int = 3) {
        self.message = message
        self.itemCount = itemCount
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.md) {
            if let message = message {
                Text(message)
                    .font(theme.typography.body)
                    .foregroundColor(colors.textSecondary)
                    .padding(.bottom, UnifiedTheme.Spacing.sm)
            }
            
            ForEach(0..<itemCount, id: \.self) { index in
                HStack(spacing: UnifiedTheme.Spacing.md) {
                    // Avatar placeholder
                    Circle()
                        .fill(colors.surface)
                        .frame(width: 50, height: 50)
                        .shimmer()
                    
                    // Content placeholder
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colors.surface)
                            .frame(height: 16)
                            .shimmer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colors.surface)
                            .frame(width: 150, height: 12)
                            .shimmer()
                    }
                    
                    Spacer()
                }
                .padding(.vertical, UnifiedTheme.Spacing.xs)
            }
        }
        .padding(UnifiedTheme.Spacing.lg)
    }
}

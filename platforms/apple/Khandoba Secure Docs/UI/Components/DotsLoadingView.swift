//
//  DotsLoadingView.swift
//  Khandoba Secure Docs
//
//  Created for production 1.0.1 launch
//

import SwiftUI

/// Animated dots sequence loading view
struct DotsLoadingView: View {
    let message: String?
    let dotCount: Int
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @State private var animationPhase: Double = 0
    
    init(message: String? = nil, dotCount: Int = 3) {
        self.message = message
        self.dotCount = dotCount
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.md) {
            HStack(spacing: UnifiedTheme.Spacing.sm) {
                ForEach(0..<dotCount, id: \.self) { index in
                    Circle()
                        .fill(colors.primary)
                        .frame(width: 12, height: 12)
                        .scaleEffect(scaleForDot(at: index))
                        .opacity(opacityForDot(at: index))
                }
            }
            
            if let message = message {
                Text(message)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: false)) {
                animationPhase = 1.0
            }
        }
    }
    
    private func scaleForDot(at index: Int) -> CGFloat {
        let delay = Double(index) * 0.2
        let phase = (animationPhase + delay).truncatingRemainder(dividingBy: 1.0)
        return 0.7 + sin(phase * .pi * 2) * 0.3
    }
    
    private func opacityForDot(at index: Int) -> Double {
        let delay = Double(index) * 0.2
        let phase = (animationPhase + delay).truncatingRemainder(dividingBy: 1.0)
        return 0.4 + sin(phase * .pi * 2) * 0.6
    }
}

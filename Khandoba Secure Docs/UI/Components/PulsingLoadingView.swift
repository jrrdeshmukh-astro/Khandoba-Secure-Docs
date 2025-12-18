//
//  PulsingLoadingView.swift
//  Khandoba Secure Docs
//
//  Created for production 1.0.1 launch
//

import SwiftUI

/// Pulsing circle animation loading view
struct PulsingLoadingView: View {
    let message: String?
    let ringCount: Int
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @State private var animationPhase: CGFloat = 0
    
    init(message: String? = nil, ringCount: Int = 3) {
        self.message = message
        self.ringCount = ringCount
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            ZStack {
                // Multiple pulsing rings
                ForEach(0..<ringCount, id: \.self) { index in
                    Circle()
                        .stroke(colors.primary.opacity(0.3), lineWidth: 3)
                        .frame(width: 60 + CGFloat(index * 20), height: 60 + CGFloat(index * 20))
                        .scaleEffect(1.0 + sin(animationPhase + Double(index) * 0.5) * 0.3)
                        .opacity(1.0 - (Double(index) / Double(ringCount)))
                }
                
                // Center circle
                Circle()
                    .fill(colors.primary)
                    .frame(width: 20, height: 20)
                    .pulsing(scale: 1.3, duration: 1.0)
            }
            .frame(width: 120, height: 120)
            
            if let message = message {
                Text(message)
                    .font(theme.typography.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }
}

//
//  ProgressRingView.swift
//  Khandoba Secure Docs
//
//  Created for production 1.0.1 launch
//

import SwiftUI

/// Circular progress ring with animation
struct ProgressRingView: View {
    let progress: Double
    let lineWidth: CGFloat
    let message: String?
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, lineWidth: CGFloat = 8, message: String? = nil) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.message = message
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.md) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(colors.surface, lineWidth: lineWidth)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                colors.primary,
                                colors.primary.opacity(0.7),
                                colors.primary
                            ]),
                            center: .center,
                            angle: .degrees(0)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(LoadingAnimations.spring(), value: animatedProgress)
                
                // Percentage text
                Text("\(Int(animatedProgress * 100))%")
                    .font(theme.typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.textPrimary)
            }
            .frame(width: 100, height: 100)
            
            if let message = message {
                Text(message)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            withAnimation(LoadingAnimations.spring()) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(LoadingAnimations.spring()) {
                animatedProgress = newValue
            }
        }
    }
}

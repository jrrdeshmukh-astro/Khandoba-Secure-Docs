//
//  LoadingAnimations.swift
//  Khandoba Secure Docs
//
//  Created for production 1.0.1 launch
//

import SwiftUI

/// Reusable animation modifiers for loading indicators
struct LoadingAnimations {
    
    /// Pulsing animation
    static func pulsing(scale: CGFloat = 1.0, duration: Double = 1.0) -> Animation {
        Animation.easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
    }
    
    /// Rotating animation
    static func rotating(duration: Double = 1.0) -> Animation {
        Animation.linear(duration: duration)
            .repeatForever(autoreverses: false)
    }
    
    /// Shimmer animation
    static func shimmer(duration: Double = 1.5) -> Animation {
        Animation.linear(duration: duration)
            .repeatForever(autoreverses: false)
    }
    
    /// Fade in/out animation
    static func fadeInOut(duration: Double = 1.0) -> Animation {
        Animation.easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
    }
    
    /// Spring animation for smooth transitions
    static func spring(response: Double = 0.5, dampingFraction: Double = 0.7) -> Animation {
        Animation.spring(response: response, dampingFraction: dampingFraction)
    }
    
    /// Staggered animation delay
    static func staggeredDelay(index: Int, baseDelay: Double = 0.1) -> Double {
        Double(index) * baseDelay
    }
}

/// View modifier for pulsing effect
struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false
    let scale: CGFloat
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1.0)
            .opacity(isPulsing ? 0.6 : 1.0)
            .onAppear {
                withAnimation(LoadingAnimations.pulsing(scale: scale, duration: duration)) {
                    isPulsing = true
                }
            }
    }
}

/// View modifier for shimmer effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                }
            )
            .onAppear {
                withAnimation(LoadingAnimations.shimmer(duration: duration)) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func pulsing(scale: CGFloat = 1.2, duration: Double = 1.0) -> some View {
        modifier(PulsingModifier(scale: scale, duration: duration))
    }
    
    func shimmer(duration: Double = 1.5) -> some View {
        modifier(ShimmerModifier(duration: duration))
    }
}

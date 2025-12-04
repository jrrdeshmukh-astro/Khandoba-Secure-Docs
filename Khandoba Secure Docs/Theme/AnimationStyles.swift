//
//  AnimationStyles.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import SwiftUI

// MARK: - Animation Library

struct AnimationStyles {
    
    // MARK: - Standard Animations
    
    /// Smooth spring animation for interactive elements
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.3)
    
    /// Gentle ease for subtle transitions
    static let easeInOut = Animation.easeInOut(duration: 0.3)
    
    /// Quick snap for immediate feedback
    static let snap = Animation.spring(response: 0.2, dampingFraction: 0.8, blendDuration: 0.1)
    
    /// Smooth slide for navigation
    static let slide = Animation.easeOut(duration: 0.35)
    
    /// Bouncy entrance for notifications
    static let bounce = Animation.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2)
    
    // MARK: - Security-Themed Animations
    
    /// Vault unlock animation (smooth and secure feeling)
    static let vaultUnlock = Animation.interpolatingSpring(stiffness: 100, damping: 15, initialVelocity: 0)
    
    /// Threat alert (urgent feel)
    static let threatAlert = Animation.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.1)
    
    /// Success confirmation (satisfying)
    static let success = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)
    
    // MARK: - Delays
    
    static func delayed(_ delay: Double, animation: Animation = .spring) -> Animation {
        animation.delay(delay)
    }
}

// MARK: - Transition Styles

struct TransitionStyles {
    
    /// Slide from bottom with scale
    static var slideFromBottom: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    /// Fade with scale
    static var fadeScale: AnyTransition {
        .scale(scale: 0.9).combined(with: .opacity)
    }
    
    /// Vault opening (rotate + scale)
    static var vaultOpen: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        )
    }
    
    /// Security alert (slide from top)
    static var alertFromTop: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
}

// MARK: - View Modifiers

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0
        ))
    }
}

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    let color: Color
    let intensity: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: isPulsing ? 8 : 0)
                    .opacity(isPulsing ? 0 : intensity)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}

// MARK: - View Extensions

extension View {
    /// Add shake animation (for errors)
    func shake(trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
    }
    
    /// Add pulse effect (for threats/alerts)
    func pulse(color: Color = .red, intensity: Double = 0.8) -> some View {
        modifier(PulseEffect(color: color, intensity: intensity))
    }
    
    /// Add glow effect (for premium features)
    func glow(color: Color = .blue, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
    
    /// Animated appearance (fade + scale)
    func animatedAppearance(delay: Double = 0) -> some View {
        self.modifier(AnimatedAppearanceModifier(delay: delay))
    }
    
    /// Staggered list appearance
    func staggeredAppearance(index: Int, total: Int = 10) -> some View {
        let delay = Double(index) * (0.6 / Double(total))
        return self.modifier(StaggeredAppearance(delay: delay))
    }
}

struct AnimatedAppearanceModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1.0 : 0.9)
            .onAppear {
                withAnimation(AnimationStyles.spring.delay(delay)) {
                    appeared = true
                }
            }
    }
}

struct StaggeredAppearance: ViewModifier {
    let delay: Double
    @State private var appeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(AnimationStyles.spring.delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Loading Animations

struct LoadingDotsView: View {
    @State private var showDot1 = false
    @State private var showDot2 = false
    @State private var showDot3 = false
    
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .scaleEffect(showDot1 ? 1.0 : 0.5)
                .opacity(showDot1 ? 1.0 : 0.3)
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .scaleEffect(showDot2 ? 1.0 : 0.5)
                .opacity(showDot2 ? 1.0 : 0.3)
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .scaleEffect(showDot3 ? 1.0 : 0.5)
                .opacity(showDot3 ? 1.0 : 0.3)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                showDot1 = true
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(0.2)) {
                showDot2 = true
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(0.4)) {
                showDot3 = true
            }
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

// MARK: - Haptic Feedback

struct HapticManager {
    static let shared = HapticManager()
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Animated Button Style

struct AnimatedButtonStyle: ButtonStyle {
    let color: Color
    let haptic: Bool
    
    init(color: Color = .blue, haptic: Bool = true) {
        self.color = color
        self.haptic = haptic
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && haptic {
                    HapticManager.shared.impact(.light)
                }
            }
    }
}

// MARK: - Security Level Indicator

struct ThreatLevelIndicator: View {
    let level: ThreatLevel
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: index))
                    .frame(width: 6, height: barHeight(for: index))
                    .opacity(animate ? 1.0 : 0.3)
                    .animation(
                        AnimationStyles.spring.delay(Double(index) * 0.1),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [8, 12, 16, 20]
        return heights[index]
    }
    
    private func barColor(for index: Int) -> Color {
        let requiredBars: Int
        
        switch level {
        case .low:
            requiredBars = 1
        case .medium:
            requiredBars = 2
        case .high:
            requiredBars = 3
        case .critical:
            requiredBars = 4
        }
        
        return index < requiredBars ? level.color : Color.gray.opacity(0.3)
    }
}

// MARK: - Vault Opening Animation

struct VaultDoorView: View {
    @Binding var isOpen: Bool
    let colors: UnifiedTheme.Colors
    
    var body: some View {
        ZStack {
            // Vault door (left half)
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.surface)
                .frame(width: 100, height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colors.primary, lineWidth: 3)
                )
                .overlay(
                    Circle()
                        .fill(colors.primary)
                        .frame(width: 30, height: 30)
                        .offset(x: 25)
                )
                .rotation3DEffect(
                    .degrees(isOpen ? -90 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading
                )
            
            // Lock icon
            Image(systemName: isOpen ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 40))
                .foregroundColor(colors.primary)
                .scaleEffect(isOpen ? 1.2 : 1.0)
                .opacity(isOpen ? 0 : 1)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isOpen)
    }
}

// MARK: - Success Checkmark Animation

struct AnimatedCheckmark: View {
    @State private var drawPath = false
    let color: Color
    
    var body: some View {
        Circle()
            .stroke(color, lineWidth: 4)
            .frame(width: 60, height: 60)
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 20, y: 30))
                    path.addLine(to: CGPoint(x: 28, y: 38))
                    path.addLine(to: CGPoint(x: 42, y: 22))
                }
                .trim(from: 0, to: drawPath ? 1 : 0)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .animation(.easeOut(duration: 0.4).delay(0.2), value: drawPath)
            )
            .scaleEffect(drawPath ? 1 : 0.8)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: drawPath)
            .onAppear {
                drawPath = true
            }
    }
}


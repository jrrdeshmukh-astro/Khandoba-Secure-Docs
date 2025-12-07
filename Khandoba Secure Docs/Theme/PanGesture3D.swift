//
//  PanGesture3D.swift
//  Khandoba Secure Docs
//
//  Enhanced 3D Pan Gesture System
//

import SwiftUI

// MARK: - Enhanced 3D Pan Gesture

struct PanGesture3DModifier: ViewModifier {
    @Binding var rotationX: Double
    @Binding var rotationY: Double
    @Binding var rotationZ: Double
    @Binding var offset: CGSize
    @Binding var scale: CGFloat
    
    @State private var lastPanValue: CGSize = .zero
    let sensitivity: CGFloat
    let enableScale: Bool
    let enableZRotation: Bool
    
    init(
        rotationX: Binding<Double> = .constant(0),
        rotationY: Binding<Double> = .constant(0),
        rotationZ: Binding<Double> = .constant(0),
        offset: Binding<CGSize> = .constant(.zero),
        scale: Binding<CGFloat> = .constant(1.0),
        sensitivity: CGFloat = 5.0,
        enableScale: Bool = true,
        enableZRotation: Bool = true
    ) {
        self._rotationX = rotationX
        self._rotationY = rotationY
        self._rotationZ = rotationZ
        self._offset = offset
        self._scale = scale
        self.sensitivity = sensitivity
        self.enableScale = enableScale
        self.enableZRotation = enableZRotation
    }
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let deltaX = value.translation.width - lastPanValue.width
                        let deltaY = value.translation.height - lastPanValue.height
                        
                        // Rotate around Y axis (horizontal pan)
                        rotationY += Double(deltaX / sensitivity)
                        
                        // Rotate around X axis (vertical pan)
                        rotationX -= Double(deltaY / sensitivity)
                        
                        // Optional Z rotation for natural feel
                        if enableZRotation {
                            rotationZ = Double(deltaX / (sensitivity * 4))
                        }
                        
                        // Scale based on distance from center
                        if enableScale {
                            let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                            scale = max(0.9, 1.0 - distance / 2000)
                        }
                        
                        offset = value.translation
                        lastPanValue = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(Animation3D.cardFlip) {
                            rotationX = 0
                            rotationY = 0
                            rotationZ = 0
                            offset = .zero
                            scale = 1.0
                            lastPanValue = .zero
                        }
                    }
            )
    }
}

// MARK: - View Extension

extension View {
    /// Add enhanced 3D pan gesture with rotation and scale
    func pan3D(
        rotationX: Binding<Double> = .constant(0),
        rotationY: Binding<Double> = .constant(0),
        rotationZ: Binding<Double> = .constant(0),
        offset: Binding<CGSize> = .constant(.zero),
        scale: Binding<CGFloat> = .constant(1.0),
        sensitivity: CGFloat = 5.0,
        enableScale: Bool = true,
        enableZRotation: Bool = true
    ) -> some View {
        modifier(
            PanGesture3DModifier(
                rotationX: rotationX,
                rotationY: rotationY,
                rotationZ: rotationZ,
                offset: offset,
                scale: scale,
                sensitivity: sensitivity,
                enableScale: enableScale,
                enableZRotation: enableZRotation
            )
        )
    }
}

// MARK: - Momentum Pan Gesture (for smooth deceleration)

struct MomentumPan3D: ViewModifier {
    @Binding var rotationX: Double
    @Binding var rotationY: Double
    @Binding var offset: CGSize
    
    @State private var velocity: CGSize = .zero
    @State private var lastTranslation: CGSize = .zero
    @State private var lastTime: Date = Date()
    
    let sensitivity: CGFloat
    let friction: CGFloat
    
    init(
        rotationX: Binding<Double> = .constant(0),
        rotationY: Binding<Double> = .constant(0),
        offset: Binding<CGSize> = .constant(.zero),
        sensitivity: CGFloat = 5.0,
        friction: CGFloat = 0.95
    ) {
        self._rotationX = rotationX
        self._rotationY = rotationY
        self._offset = offset
        self.sensitivity = sensitivity
        self.friction = friction
    }
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let now = Date()
                        let timeDelta = now.timeIntervalSince(lastTime)
                        
                        if timeDelta > 0 {
                            let deltaX = value.translation.width - lastTranslation.width
                            let deltaY = value.translation.height - lastTranslation.height
                            
                            // Calculate velocity
                            velocity = CGSize(
                                width: deltaX / CGFloat(timeDelta),
                                height: deltaY / CGFloat(timeDelta)
                            )
                            
                            // Apply rotation
                            rotationY += Double(deltaX / sensitivity)
                            rotationX -= Double(deltaY / sensitivity)
                            
                            offset = value.translation
                            lastTranslation = value.translation
                            lastTime = now
                        }
                    }
                    .onEnded { _ in
                        // Apply momentum
                        applyMomentum()
                    }
            )
    }
    
    private func applyMomentum() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            // Apply friction
            velocity = CGSize(
                width: velocity.width * friction,
                height: velocity.height * friction
            )
            
            // Update rotation
            rotationY += Double(velocity.width / sensitivity)
            rotationX -= Double(velocity.height / sensitivity)
            
            // Stop when velocity is very small
            if abs(velocity.width) < 0.1 && abs(velocity.height) < 0.1 {
                timer.invalidate()
                withAnimation(Animation3D.cardFlip) {
                    rotationX = 0
                    rotationY = 0
                    offset = .zero
                }
            }
        }
        
        RunLoop.current.add(timer, forMode: .common)
    }
}

extension View {
    /// Add momentum-based 3D pan gesture
    func momentumPan3D(
        rotationX: Binding<Double> = .constant(0),
        rotationY: Binding<Double> = .constant(0),
        offset: Binding<CGSize> = .constant(.zero),
        sensitivity: CGFloat = 5.0,
        friction: CGFloat = 0.95
    ) -> some View {
        modifier(
            MomentumPan3D(
                rotationX: rotationX,
                rotationY: rotationY,
                offset: offset,
                sensitivity: sensitivity,
                friction: friction
            )
        )
    }
}


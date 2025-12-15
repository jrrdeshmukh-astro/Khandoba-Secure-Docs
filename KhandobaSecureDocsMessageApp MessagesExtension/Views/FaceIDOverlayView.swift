//
//  FaceIDOverlayView.swift
//  Khandoba Secure Docs
//
//  Face ID overlay matching Apple Pay authentication UI exactly
//

import SwiftUI

struct FaceIDOverlayView: View {
    let biometricType: BiometricType
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var phoneScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Dark background with blur (Apple Pay style)
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onCancel()
                    }
                }
            
            // Main content card (Apple Pay style - circular with phone icon)
            VStack(spacing: 28) {
                // Phone icon with biometric indicator (Apple Pay style)
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)
                        .opacity(max(0, 2.0 - pulseScale))
                    
                    // Middle ring
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                        .frame(width: 120, height: 120)
                    
                    // Phone icon background (circular, like Apple Pay)
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.08)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        // Phone icon (Apple Pay style)
                        Image(systemName: "iphone")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(.white)
                            .scaleEffect(phoneScale)
                        
                        // Biometric indicator overlay (small icon in corner)
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: iconName)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.3))
                                    )
                            }
                            Spacer()
                        }
                        .frame(width: 100, height: 100)
                    }
                }
                .frame(width: 140, height: 140)
                
                // Instruction text (Apple Pay style)
                VStack(spacing: 10) {
                    Text("\(biometricType.displayName)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Double tap to authenticate")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.75),
                                Color.black.opacity(0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 30, x: 0, y: 15)
            )
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Entrance animation (Apple Pay style - smooth spring)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Pulse animation (continuous, like Apple Pay)
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.4
            }
            
            // Subtle phone icon pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                phoneScale = 1.05
            }
        }
    }
    
    private var iconName: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.fill"
        }
    }
}

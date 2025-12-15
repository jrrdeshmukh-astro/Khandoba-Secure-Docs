//
//  HelloWorldMessageView.swift
//  Khandoba Secure Docs
//
//  Simple Hello World view for iMessage extension testing
//

import SwiftUI

struct HelloWorldMessageView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var buttonTapped = false
    @State private var tapCount = 0
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 20) {
            Text("Hello World!")
                .font(theme.typography.title)
                .foregroundColor(colors.primary)
                .padding()
            
            Text("Khandoba iMessage Extension")
                .font(theme.typography.body)
                .foregroundColor(colors.textPrimary)
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.primary)
                .padding()
            
            // Button to test interactions
            Button(action: {
                tapCount += 1
                buttonTapped = true
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }) {
                HStack {
                    Image(systemName: "hand.tap.fill")
                    Text("Tap Me! (\(tapCount))")
                }
                .font(theme.typography.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(colors.primary)
                .cornerRadius(12)
            }
            .padding(.top, 20)
            
            if buttonTapped {
                Text("✅ Button tapped!")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.success)
                    .padding(.top, 10)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.surface)
        .animation(.spring(response: 0.3), value: buttonTapped)
    }
}

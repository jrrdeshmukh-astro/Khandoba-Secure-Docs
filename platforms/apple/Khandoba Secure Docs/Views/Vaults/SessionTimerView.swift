//
//  SessionTimerView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct SessionTimerView: View {
    let session: VaultSession
    let onExtend: () async -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        let progress = timeRemaining / (30 * 60) // 30 minutes total
        
        StandardCard {
            VStack(spacing: UnifiedTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Session")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        Text("\(minutes):\(String(format: "%02d", seconds))")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(timeRemaining < 300 ? colors.error : colors.success) // Red if < 5 min
                    }
                    
                    Spacer()
                    
                    // Circular Progress
                    ZStack {
                        Circle()
                            .stroke(colors.textTertiary.opacity(0.3), lineWidth: 6)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(timeRemaining < 300 ? colors.error : colors.success, lineWidth: 6)
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(progress * 100))%")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textPrimary)
                    }
                }
                
                if timeRemaining < 300 && !session.wasExtended { // < 5 minutes
                    Button {
                        Task {
                            await onExtend()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Extend Session")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                if timeRemaining < 60 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(colors.error)
                            .font(.caption)
                        Text("Session expiring soon!")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.error)
                    }
                }
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        updateTimeRemaining()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        timeRemaining = max(0, session.expiresAt.timeIntervalSinceNow)
        
        if timeRemaining <= 0 {
            timer?.invalidate()
        }
    }
}


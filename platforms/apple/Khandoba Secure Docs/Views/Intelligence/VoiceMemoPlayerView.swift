//
//  VoiceMemoPlayerView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import SwiftUI
import AVFoundation
import Combine

struct VoiceMemoPlayerView: View {
    let document: Document
    @StateObject private var player = VoiceMemoPlayer()
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) private var dismiss
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: UnifiedTheme.Spacing.xl) {
                    Spacer()
                    
                    // Waveform Animation
                    WaveformView(isPlaying: player.isPlaying, color: colors.primary)
                        .frame(height: 100)
                        .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    
                    // Title
                    VStack(spacing: UnifiedTheme.Spacing.xs) {
                        Text(document.name)
                            .font(theme.typography.title2)
                            .foregroundColor(colors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        if let extractedText = document.extractedText, !extractedText.isEmpty {
                            Text(extractedText.prefix(100))
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                    .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    
                    // Progress Slider
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        Slider(
                            value: Binding(
                                get: { player.currentTime },
                                set: { player.seek(to: $0) }
                            ),
                            in: 0...max(player.duration, 0.1)
                        )
                        .tint(colors.primary)
                        
                        HStack {
                            Text(formatTime(player.currentTime))
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                            
                            Spacer()
                            
                            Text(formatTime(player.duration))
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    
                    // Playback Controls
                    HStack(spacing: UnifiedTheme.Spacing.xl) {
                        // Rewind 15s
                        Button {
                            player.skip(-15)
                            #if os(iOS)
                            HapticManager.shared.impact(.light)
                            #endif
                        } label: {
                            Image(systemName: "gobackward.15")
                                .font(.system(size: 32))
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        // Play/Pause
                        Button {
                            if player.isPlaying {
                                player.pause()
                            } else {
                                player.play()
                            }
                            #if os(iOS)
                            HapticManager.shared.impact(.medium)
                            #endif
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(colors.primary)
                                    .frame(width: 70, height: 70)
                                    .shadow(color: colors.primary.opacity(0.3), radius: 10)
                                
                                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(AnimatedButtonStyle(color: colors.primary))
                        
                        // Forward 15s
                        Button {
                            player.skip(15)
                            #if os(iOS)
                            HapticManager.shared.impact(.light)
                            #endif
                        } label: {
                            Image(systemName: "goforward.15")
                                .font(.system(size: 32))
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding(.vertical, UnifiedTheme.Spacing.lg)
                    
                    // Speed Control
                    HStack(spacing: UnifiedTheme.Spacing.md) {
                        Text("Speed:")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                        
                        ForEach([0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                            Button {
                                player.setPlaybackSpeed(speed)
                                HapticManager.shared.selection()
                            } label: {
                                Text("\(speed, specifier: "%.2f")x")
                                    .font(theme.typography.caption)
                                    .foregroundColor(
                                        player.playbackSpeed == speed ? .white : colors.textPrimary
                                    )
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        player.playbackSpeed == speed ? colors.primary : colors.surface
                                    )
                                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(UnifiedTheme.Spacing.xl)
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        player.stop()
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        player.stop()
                        dismiss()
                    }
                }
                #endif
            }
            .onAppear {
                loadAudio()
            }
            .onDisappear {
                player.stop()
            }
        }
    }
    
    private func loadAudio() {
        guard let audioData = document.encryptedFileData else { return }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(document.id.uuidString + ".m4a")
        
        do {
            try audioData.write(to: tempURL)
            player.load(url: tempURL)
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Voice Memo Player

@MainActor
class VoiceMemoPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var playbackSpeed: Double = 1.0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    func load(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.enableRate = true
            
            duration = audioPlayer?.duration ?? 0
            
            // Configure audio session
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            #endif
            
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    func play() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
        #if os(iOS)
        HapticManager.shared.notification(.success)
        #endif
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        currentTime = 0
        stopTimer()
    }
    
    func seek(to time: Double) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    func skip(_ seconds: Double) {
        let newTime = max(0, min(duration, currentTime + seconds))
        seek(to: newTime)
    }
    
    func setPlaybackSpeed(_ speed: Double) {
        playbackSpeed = speed
        audioPlayer?.rate = Float(speed)
        
        if isPlaying {
            audioPlayer?.play()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.updateProgress()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateProgress() {
        currentTime = audioPlayer?.currentTime ?? 0
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            currentTime = 0
            stopTimer()
            #if os(iOS)
        HapticManager.shared.notification(.success)
        #endif
        }
    }
}

// MARK: - Waveform Animation

struct WaveformView: View {
    let isPlaying: Bool
    let color: Color
    
    @State private var amplitudes: [CGFloat] = Array(repeating: 0.3, count: 40)
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<40, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3)
                    .frame(height: amplitudes[index] * 100)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.02),
                        value: amplitudes[index]
                    )
            }
        }
        .onAppear {
            if isPlaying {
                animateWaveform()
            }
        }
        .onChange(of: isPlaying) { _, playing in
            if playing {
                animateWaveform()
            } else {
                resetWaveform()
            }
        }
    }
    
    private func animateWaveform() {
        for index in 0..<40 {
            amplitudes[index] = CGFloat.random(in: 0.2...1.0)
        }
    }
    
    private func resetWaveform() {
        withAnimation {
            amplitudes = Array(repeating: 0.3, count: 40)
        }
    }
}

// MARK: - Mini Player (for background playback)

struct MiniVoiceMemoPlayer: View {
    let document: Document
    @StateObject private var player = VoiceMemoPlayer()
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    @State private var showFullPlayer = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack(spacing: UnifiedTheme.Spacing.md) {
            // Play/Pause Button
            Button {
                if player.isPlaying {
                    player.pause()
                } else {
                    player.play()
                }
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .foregroundColor(colors.primary)
                    .frame(width: 40, height: 40)
                    .background(colors.surface)
                    .clipShape(Circle())
            }
            
            // Progress
            VStack(alignment: .leading, spacing: 4) {
                Text(document.name)
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                
                ProgressView(value: player.currentTime, total: player.duration)
                    .tint(colors.primary)
            }
            
            // Expand Button
            Button {
                showFullPlayer = true
            } label: {
                Image(systemName: "chevron.up")
                    .foregroundColor(colors.textSecondary)
            }
        }
        .padding(UnifiedTheme.Spacing.md)
        .background(colors.surface)
        .cornerRadius(UnifiedTheme.CornerRadius.lg)
        .shadow(color: Color.black.opacity(0.1), radius: 10)
        .sheet(isPresented: $showFullPlayer) {
            VoiceMemoPlayerView(document: document)
        }
    }
}

#Preview {
    VoiceMemoPlayerView(document: Document(
        name: "Security Intelligence Report",
        fileExtension: "m4a",
        mimeType: "audio/m4a",
        fileSize: 1024,
        documentType: "audio"
    ))
}


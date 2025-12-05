//
//  AudioIntelReportView.swift
//  Khandoba Secure Docs
//
//  UI for Audio-to-Audio Intel Reports
//

import SwiftUI
import Combine

struct AudioIntelReportView: View {
    let documents: [Document]
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vaultService: VaultService
    
    @StateObject private var audioIntel = AudioIntelligenceService()
    @State private var debriefAudioURL: URL?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: UnifiedTheme.Spacing.xl) {
                // Header
                VStack(spacing: UnifiedTheme.Spacing.sm) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(colors.primary)
                    
                    Text("Audio Intelligence")
                        .font(theme.typography.title)
                        .foregroundColor(colors.textPrimary)
                    
                    Text("\(documents.count) documents selected")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                if audioIntel.isProcessing {
                    // Processing view
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        ProgressView(value: audioIntel.processingProgress)
                            .tint(colors.primary)
                            .scaleEffect(1.2)
                        
                        Text(audioIntel.currentStep)
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text("\(Int(audioIntel.processingProgress * 100))% complete")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.xl)
                    .padding(.horizontal)
                    
                } else if let audioURL = debriefAudioURL {
                    // Audio player
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        Text("Debrief Ready")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        AudioPlayerView(audioURL: audioURL, colors: colors, theme: theme)
                        
                        Button {
                            Task {
                                await saveToVault(audioURL)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down.doc.fill")
                                Text("Save to Vault")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
                    }
                    
                } else {
                    // Start button
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        Text("Generate audio intelligence debrief from your selected documents")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            Task {
                                await generateIntel()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Generate Debrief")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding(.top, UnifiedTheme.Spacing.xl)
        }
        .navigationTitle("Audio Intel")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            audioIntel.configure(modelContext: modelContext)
        }
    }
    
    private func generateIntel() async {
        do {
            let audioURL = try await audioIntel.generateAudioIntelReport(from: documents)
            debriefAudioURL = audioURL
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func saveToVault(_ audioURL: URL) async {
        // Save to first available vault or create Intel vault
        guard let vault = vaultService.vaults.first else { return }
        
        do {
            let audioData = try Data(contentsOf: audioURL)
            
            let document = Document(
                name: "Intel_Debrief_\(Date().timeIntervalSince1970).m4a",
                mimeType: "audio/m4a",
                fileSize: Int64(audioData.count),
                documentType: "audio",
                isEncrypted: true
            )
            document.encryptedFileData = audioData
            document.vault = vault
            document.sourceSinkType = "source"
            document.aiTags = ["Intel Report", "Audio Debrief", "AI Analysis"]
            
            modelContext.insert(document)
            try modelContext.save()
            
            print("✅ Intel debrief saved to vault")
            dismiss()
            
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Simple Audio Player

struct AudioPlayerView: View {
    let audioURL: URL
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        VStack(spacing: UnifiedTheme.Spacing.md) {
            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(colors.primary)
                .onTapGesture {
                    togglePlayback()
                }
            
            Text(isPlaying ? "Playing..." : "Tap to play")
                .font(theme.typography.caption)
                .foregroundColor(colors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(colors.surface)
        .cornerRadius(UnifiedTheme.CornerRadius.xl)
        .padding(.horizontal)
        .onAppear {
            setupPlayer()
        }
    }
    
    private func setupPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to setup audio player: \(error)")
        }
    }
    
    private func togglePlayback() {
        guard let player = audioPlayer else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
}

#Preview {
    NavigationStack {
        AudioIntelReportView(documents: [])
            .environmentObject(VaultService())
    }
}


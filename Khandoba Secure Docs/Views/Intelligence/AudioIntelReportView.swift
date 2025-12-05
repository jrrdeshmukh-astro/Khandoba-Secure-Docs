//
//  AudioIntelReportView.swift
//  Khandoba Secure Docs
//
//  UI for Audio-to-Audio Intel Reports
//

import SwiftUI
import SwiftData
import Combine
import AVFoundation

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
    @State private var selectedVault: Vault?
    @State private var showVaultPicker = false
    
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
                        
                        // Vault selection
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            Text("Save to:")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                            
                            Button {
                                showVaultPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                    Text(selectedVault?.name ?? "Choose Vault")
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                }
                                .padding()
                                .background(colors.surface)
                                .cornerRadius(UnifiedTheme.CornerRadius.md)
                            }
                            .foregroundColor(colors.textPrimary)
                        }
                        .padding(.horizontal)
                        
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
                        .disabled(selectedVault == nil)
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
        .sheet(isPresented: $showVaultPicker) {
            VaultPickerSheet(selectedVault: $selectedVault, vaultService: vaultService, colors: colors, theme: theme)
        }
        .onAppear {
            audioIntel.configure(modelContext: modelContext)
            // Pre-select first non-system vault
            selectedVault = vaultService.vaults.first { !$0.isSystemVault && $0.name != "Intel Reports" }
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
        // Save to selected vault
        guard let vault = selectedVault else {
            errorMessage = "Please select a vault first"
            showError = true
            return
        }
        
        do {
            print("💾 Saving Intel debrief to vault: \(vault.name)")
            
            // Load audio data
            let audioData = try Data(contentsOf: audioURL)
            print("   Audio size: \(audioData.count) bytes")
            
            // Create document
            let document = Document(
                name: "Intel_Debrief_\(Date().formatted(date: .abbreviated, time: .shortened)).m4a",
                mimeType: "audio/m4a",
                fileSize: Int64(audioData.count),
                documentType: "audio",
                isEncrypted: true
            )
            document.encryptedFileData = audioData
            document.sourceSinkType = "source"
            document.aiTags = ["Intel Report", "Audio Debrief", "AI Analysis"]
            document.status = "active"
            
            // Link to vault
            document.vault = vault
            
            // CRITICAL: Add to vault's documents array
            if vault.documents == nil {
                vault.documents = []
            }
            vault.documents?.append(document)
            
            // Insert and save
            modelContext.insert(document)
            try modelContext.save()
            
            print("✅ Intel debrief saved successfully!")
            print("   Document: \(document.name)")
            print("   Vault: \(vault.name)")
            print("   Tags: \(document.aiTags.joined(separator: ", "))")
            
            // Cleanup temp file
            try? FileManager.default.removeItem(at: audioURL)
            print("   Temp file cleaned up")
            
            dismiss()
            
        } catch {
            print("❌ Save error: \(error)")
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
        audioPlayer = try? AVAudioPlayer(contentsOf: audioURL)
        audioPlayer?.prepareToPlay()
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

// MARK: - Vault Picker Sheet

struct VaultPickerSheet: View {
    @Binding var selectedVault: Vault?
    let vaultService: VaultService
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(userVaults) { vault in
                    Button {
                        selectedVault = vault
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: vault.keyType == "dual" ? "lock.rectangle.stack.fill" : "lock.fill")
                                .foregroundColor(colors.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vault.name)
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textPrimary)
                                
                                if let desc = vault.vaultDescription {
                                    Text(desc)
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedVault?.id == vault.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(colors.success)
                            }
                        }
                    }
                    .listRowBackground(colors.surface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(colors.background)
            .navigationTitle("Choose Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var userVaults: [Vault] {
        vaultService.vaults.filter { !$0.isSystemVault && $0.name != "Intel Reports" }
    }
}

#Preview {
    NavigationStack {
        AudioIntelReportView(documents: [])
            .environmentObject(VaultService())
    }
}


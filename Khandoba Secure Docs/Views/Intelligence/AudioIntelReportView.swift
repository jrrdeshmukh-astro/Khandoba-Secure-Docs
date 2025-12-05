//
//  AudioIntelReportView.swift
//  Khandoba Secure Docs
//
//  Created by AI Assistant on 12/5/25.
//
//  Audio-based Intel Report interface with document selection
//

import SwiftUI
import AVFoundation
import Combine

struct AudioIntelReportView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vaultService: VaultService
    
    @StateObject private var preprocessingService = AudioPreprocessingService()
    @StateObject private var intelligenceService = AudioIntelligenceService()
    
    @State private var selectedDocuments: Set<UUID> = []
    @State private var isProcessing = false
    @State private var audioDebriefURL: URL?
    @State private var showPlayer = false
    @State private var errorMessage: String?
    
    private var documents: [Document] {
        (vault.documents ?? []).filter { $0.status == "active" }
    }
    
    private var selectedDocs: [Document] {
        documents.filter { selectedDocuments.contains($0.id) }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            if isProcessing {
                ProcessingView(
                    preprocessProgress: preprocessingService.processingProgress,
                    analysisProgress: intelligenceService.analysisProgress,
                    currentStep: preprocessingService.currentStep.isEmpty ? 
                        "Analyzing..." : preprocessingService.currentStep,
                    colors: colors,
                    theme: theme
                )
            } else if let debriefURL = audioDebriefURL {
                DebriefPlayerView(
                    audioURL: debriefURL,
                    transcript: intelligenceService.currentReport?.debriefTranscript ?? "",
                    onDismiss: {
                        audioDebriefURL = nil
                        selectedDocuments.removeAll()
                    },
                    colors: colors,
                    theme: theme
                )
            } else {
                DocumentSelectionView(
                    documents: documents,
                    selectedDocuments: $selectedDocuments,
                    onGenerate: generateIntelReport,
                    colors: colors,
                    theme: theme
                )
            }
        }
        .navigationTitle("Audio Intel Report")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func generateIntelReport() {
        guard selectedDocs.count >= 2 else {
            errorMessage = "Select at least 2 documents"
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                // Step 1: Preprocess all documents to audio
                var audioFiles: [(url: URL, document: Document)] = []
                
                for (index, document) in selectedDocs.enumerated() {
                    print("🔄 Processing \(index + 1)/\(selectedDocs.count): \(document.name)")
                    
                    let audioURL = try await preprocessingService.preprocessToAudio(document: document)
                    audioFiles.append((url: audioURL, document: document))
                }
                
                print("✅ All documents preprocessed to audio")
                
                // Step 2: Analyze and generate debrief
                let debriefURL = try await intelligenceService.analyzeAndGenerateDebrief(audioFiles: audioFiles)
                
                // Step 3: Save to Intel Vault
                try await saveToIntelVault(debriefURL: debriefURL)
                
                // Step 4: Show player
                await MainActor.run {
                    audioDebriefURL = debriefURL
                    isProcessing = false
                }
                
                print("✅ Intel Report complete!")
                
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    print("❌ Error: \(error)")
                }
            }
        }
    }
    
    private func saveToIntelVault(debriefURL: URL) async throws {
        guard let user = vaultService.currentUser else { return }
        
        // Find or create Intel Vault
        let descriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.name == "Intel Reports" && $0.owner?.id == user.id }
        )
        
        var intelVault = try modelContext.fetch(descriptor).first
        
        if intelVault == nil {
            intelVault = Vault(
                name: "Intel Reports",
                vaultDescription: "Audio-based intelligence debriefs",
                keyType: "single"
            )
            intelVault?.owner = user
            intelVault?.isSystemVault = true
            modelContext.insert(intelVault!)
            try modelContext.save()
        }
        
        guard let vault = intelVault else { return }
        
        // Save audio file as document
        let audioData = try Data(contentsOf: debriefURL)
        
        let document = Document(
            name: "Intel_Debrief_\(Date().formatted(date: .abbreviated, time: .shortened)).m4a",
            mimeType: "audio/m4a",
            fileSize: Int64(audioData.count),
            documentType: "audio"
        )
        document.encryptedFileData = audioData
        document.vault = vault
        document.sourceSinkType = "source"
        
        // Store metadata
        if let report = intelligenceService.currentReport {
            let metadata: [String: Any] = [
                "transcript": report.debriefTranscript,
                "entityCount": report.entities.count,
                "patternCount": report.patterns.count,
                "sourceDocumentIDs": report.sourceDocuments.map { $0.id.uuidString }
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                document.metadata = jsonString
            }
        }
        
        modelContext.insert(document)
        try modelContext.save()
        
        print("✅ Debrief saved to Intel Vault")
    }
}

// MARK: - Document Selection View

struct DocumentSelectionView: View {
    let documents: [Document]
    @Binding var selectedDocuments: Set<UUID>
    let onGenerate: () -> Void
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Instructions
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(colors.primary)
                
                Text("Select Documents for Intel")
                    .font(theme.typography.title2)
                    .foregroundColor(colors.textPrimary)
                
                Text("Choose 2+ documents to analyze")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
            }
            .padding()
            
            Divider()
            
            // Document list
            List {
                ForEach(documents) { document in
                    Button {
                        toggleSelection(document.id)
                    } label: {
                        HStack {
                            Image(systemName: selectedDocuments.contains(document.id) ? 
                                  "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedDocuments.contains(document.id) ? 
                                               colors.primary : colors.textTertiary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(document.name)
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textPrimary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: documentIcon(for: document.documentType))
                                        .font(.caption)
                                    Text(document.documentType.capitalized)
                                        .font(theme.typography.caption)
                                }
                                .foregroundColor(colors.textSecondary)
                            }
                        }
                    }
                    .listRowBackground(colors.surface)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            // Generate button
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Text("\(selectedDocuments.count) documents selected")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                
                Button {
                    onGenerate()
                } label: {
                    HStack {
                        Image(systemName: "waveform.badge.magnifyingglass")
                        Text("Generate Audio Intel")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedDocuments.count < 2)
            }
            .padding()
            .background(colors.surface)
        }
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedDocuments.contains(id) {
            selectedDocuments.remove(id)
        } else {
            selectedDocuments.insert(id)
        }
    }
    
    private func documentIcon(for type: String) -> String {
        switch type {
        case "image": return "photo"
        case "video": return "video"
        case "audio": return "waveform"
        case "pdf", "document": return "doc.text"
        default: return "doc"
        }
    }
}

// MARK: - Processing View

struct ProcessingView: View {
    let preprocessProgress: Double
    let analysisProgress: Double
    let currentStep: String
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        VStack(spacing: UnifiedTheme.Spacing.xl) {
            ProgressView(value: (preprocessProgress + analysisProgress) / 2.0)
                .tint(colors.primary)
                .scaleEffect(1.2)
            
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Text("Generating Audio Intel")
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                Text(currentStep)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                
                Text("\(Int((preprocessProgress + analysisProgress) / 2.0 * 100))%")
                    .font(theme.typography.title)
                    .foregroundColor(colors.primary)
                    .monospacedDigit()
            }
        }
        .padding()
    }
}

// MARK: - Debrief Player View

struct DebriefPlayerView: View {
    let audioURL: URL
    let transcript: String
    let onDismiss: () -> Void
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var showTranscript = false
    
    var body: some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            // Audio player
            VStack(spacing: UnifiedTheme.Spacing.md) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(colors.primary)
                    .symbolEffect(.variableColor, isActive: isPlaying)
                
                Text("Intel Debrief")
                    .font(theme.typography.title)
                    .foregroundColor(colors.textPrimary)
                
                HStack(spacing: UnifiedTheme.Spacing.xl) {
                    Button {
                        if isPlaying {
                            player?.pause()
                        } else {
                            player?.play()
                        }
                        isPlaying.toggle()
                    } label: {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(colors.primary)
                    }
                    
                    Button {
                        player?.seek(to: .zero)
                        player?.play()
                        isPlaying = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(colors.secondary)
                    }
                }
            }
            .padding()
            
            // Transcript toggle
            Button {
                showTranscript.toggle()
            } label: {
                HStack {
                    Image(systemName: "text.alignleft")
                    Text(showTranscript ? "Hide Transcript" : "Show Transcript")
                }
                .font(theme.typography.subheadline)
                .foregroundColor(colors.primary)
            }
            
            if showTranscript {
                ScrollView {
                    Text(transcript)
                        .font(theme.typography.body)
                        .foregroundColor(colors.textPrimary)
                        .padding()
                }
                .background(colors.surface)
                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Done button
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding()
        }
        .onAppear {
            player = AVPlayer(url: audioURL)
            player?.play()
            isPlaying = true
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

#Preview {
    NavigationStack {
        AudioIntelReportView(vault: Vault(name: "Test", vaultDescription: nil, keyType: "single"))
            .environmentObject(VaultService())
    }
}


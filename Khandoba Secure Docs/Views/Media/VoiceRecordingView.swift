//
//  VoiceRecordingView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import AVFoundation
import Combine

struct VoiceRecordingView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var documentService: DocumentService
    
    @StateObject private var recorder = AudioRecorder()
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showSaveConfirm = false
    @State private var showContentBlocked = false
    @State private var blockedContentReason: String?
    @State private var blockedContentCategories: [ContentCategory] = []
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: UnifiedTheme.Spacing.xl) {
                Spacer()
                
                // Waveform Animation
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(recorder.isRecording ? colors.error : colors.textTertiary)
                            .frame(width: 8)
                            .frame(height: recorder.isRecording ? CGFloat.random(in: 20...100) : 20)
                            .animation(
                                recorder.isRecording ? 
                                    .easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(Double(index) * 0.1) :
                                    .default,
                                value: recorder.isRecording
                            )
                    }
                }
                .frame(height: 100)
                
                // Duration
                Text(formatDuration(recordingDuration))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(colors.textPrimary)
                
                Text(recorder.isRecording ? "Recording..." : "Ready to record")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textSecondary)
                
                Spacer()
                
                // Record Button
                Button {
                    toggleRecording()
                } label: {
                    ZStack {
                        Circle()
                            .fill(recorder.isRecording ? colors.error : colors.primary)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                
                if recordingDuration > 0 && !recorder.isRecording {
                    HStack(spacing: UnifiedTheme.Spacing.lg) {
                        Button {
                            discardRecording()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.title2)
                                Text("Discard")
                                    .font(theme.typography.caption)
                            }
                            .foregroundColor(colors.error)
                        }
                        
                        Button {
                            showSaveConfirm = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                Text("Save to Vault")
                                    .font(theme.typography.caption)
                            }
                            .foregroundColor(colors.success)
                        }
                    }
                    .padding(.top)
                }
                
                // Cost Info
                Text("Voice Memo Recording")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                
                Spacer()
            }
        }
        .navigationTitle("Voice Recording")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(colors.primary)
            }
        }
        .confirmationDialog("Save Recording", isPresented: $showSaveConfirm) {
            Button("Save") {
                saveRecording()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Save this voice recording to the vault?")
        }
        .alert("Content Blocked", isPresented: $showContentBlocked) {
            Button("OK", role: .cancel) { }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text("This audio cannot be saved due to inappropriate content.")
                
                if let reason = blockedContentReason {
                    Text("\nReason: \(reason)")
                        .font(.caption)
                }
                
                if !blockedContentCategories.isEmpty {
                    Text("\nCategories: \(blockedContentCategories.map { $0.rawValue.replacingOccurrences(of: "_", with: " ").capitalized }.joined(separator: ", "))")
                        .font(.caption)
                }
            }
        }
    }
    
    private func toggleRecording() {
        if recorder.isRecording {
            recorder.stopRecording()
            timer?.invalidate()
        } else {
            recordingDuration = 0
            recorder.startRecording()
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordingDuration += 0.1
            }
        }
    }
    
    private func discardRecording() {
        recorder.deleteRecording()
        recordingDuration = 0
    }
    
    private func saveRecording() {
        guard let recordingURL = recorder.recordingURL else { return }
        
        Task {
            do {
                let data = try Data(contentsOf: recordingURL)
                let fileName = "voice_\(Date().timeIntervalSince1970).m4a"
                
                // Premium subscription - unlimited voice recordings
                
                // Upload
                let document = try await documentService.uploadDocument(
                    data: data,
                    name: fileName,
                    mimeType: "audio/m4a",
                    to: vault,
                    uploadMethod: .voiceRecording
                )
                
                print("✅ Voice memo saved successfully: \(document.name)")
                
                // Reload documents for the vault to ensure UI updates
                try await documentService.loadDocuments(for: vault)
                
                await MainActor.run {
                    dismiss()
                }
            } catch let error as DocumentError {
                switch error {
                case .contentBlocked(let severity, let categories, let reason):
                    await MainActor.run {
                        blockedContentReason = reason
                        blockedContentCategories = categories
                        showContentBlocked = true
                    }
                default:
                    print("❌ Error saving recording: \(error.localizedDescription)")
                    await MainActor.run {
                        // Show error to user
                        blockedContentReason = error.localizedDescription
                        showContentBlocked = true
                    }
                }
            } catch {
                print("❌ Error saving recording: \(error.localizedDescription)")
                await MainActor.run {
                    // Show error to user
                    blockedContentReason = error.localizedDescription
                    showContentBlocked = true
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}

// MARK: - Audio Recorder
@MainActor
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingURL: URL?
    
    private var audioRecorder: AVAudioRecorder?
    
    nonisolated override init() {
        super.init()
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            
            recordingURL = url
            isRecording = true
        } catch {
            print("Recording failed: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    func deleteRecording() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
    }
}


//
//  VoiceRecordingView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import AVFoundation
import Combine

internal struct VoiceRecordingView: View {
    let vault: Vault
    
    internal init(vault: Vault) {
        self.vault = vault
    }
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @EnvironmentObject var documentService: DocumentService
    
    #if !os(tvOS)
    @StateObject private var recorder = AudioRecorder()
    #endif
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showSaveConfirm = false
    @State private var showContentBlocked = false
    @State private var blockedContentReason: String?
    @State private var blockedContentCategories: [ContentCategory] = []
    @State private var showFilePicker = false
    
    private var platform = Platform.current
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Group {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if platform.supportsMicrophone {
                    microphoneRecordingView(colors: colors)
                } else {
                    fileUploadView(colors: colors)
                }
            }
            #if os(macOS) || os(tvOS)
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.audio, .mpeg4Audio, .mp3],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            #endif
        }
        .navigationTitle("Voice Recording")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(colors.primary)
            }
            #else
            ToolbarItem(placement: .automatic) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(colors.primary)
            }
            #endif
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
    
    @ViewBuilder
    private func microphoneRecordingView(colors: UnifiedTheme.Colors) -> some View {
        #if os(iOS) || os(macOS)
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
            #if os(iOS)
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
            #elseif os(macOS)
            // macOS: Show file picker option
            Button {
                showFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text("Choose Audio File")
                }
                .padding()
                .background(colors.primary)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            #endif
            
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
        #else
        // tvOS fallback - should not reach here due to platform check in body
        Text("Voice recording not available")
        #endif
    }
    
    @ViewBuilder
    private func fileUploadView(colors: UnifiedTheme.Colors) -> some View {
        // tvOS: File upload only
        VStack(spacing: UnifiedTheme.Spacing.xl) {
            Image(systemName: "mic.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(colors.primary)
            
            Text("Audio Upload")
                .font(theme.typography.title)
                .foregroundColor(colors.textPrimary)
            
            Text("Microphone recording is not available on Apple TV. Please use file upload to add audio files.")
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button {
                showFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text("Choose Audio File")
                }
                .padding()
                .background(colors.primary)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    #if os(macOS) || os(tvOS)
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                Task {
                    await saveAudioFileFromPicker(url)
                }
            }
        case .failure(let error):
            print("File selection failed: \(error)")
        }
    }
    
    private func saveAudioFileFromPicker(_ url: URL) async {
        do {
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            
            let document = try await documentService.uploadDocument(
                data: data,
                name: fileName,
                mimeType: "audio/m4a",
                to: vault,
                uploadMethod: .fileUpload
            )
            
            print("✅ Audio file uploaded: \(document.name)")
            dismiss()
        } catch {
            print("❌ Failed to upload audio file: \(error)")
        }
    }
    #endif
    
    private func toggleRecording() {
        #if !os(tvOS)
        if recorder.isRecording {
            recorder.stopRecording()
            timer?.invalidate()
            timer = nil
        } else {
            recordingDuration = 0
            recorder.startRecording()
            startTimer()
        }
        #endif
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }
    }
    
    private func discardRecording() {
        #if !os(tvOS)
        recorder.deleteRecording()
        #endif
        recordingDuration = 0
        timer?.invalidate()
        timer = nil
    }
    
    private func saveRecording() {
        #if !os(tvOS)
        guard let url = recorder.recordingURL else { return }
        
        Task {
            do {
                let data = try Data(contentsOf: url)
                let fileName = "voice_\(Date().timeIntervalSince1970).m4a"
                
                let document = try await documentService.uploadDocument(
                    data: data,
                    name: fileName,
                    mimeType: "audio/m4a",
                    to: vault,
                    uploadMethod: .voiceRecording
                )
                
                print("✅ Voice memo saved successfully: \(document.name)")
                
                try await documentService.loadDocuments(for: vault)
                
                await MainActor.run {
                    dismiss()
                }
            } catch let error as DocumentError {
                switch error {
                case .contentBlocked(_, let categories, let reason):
                    await MainActor.run {
                        blockedContentReason = reason
                        blockedContentCategories = categories
                        showContentBlocked = true
                    }
                default:
                    print("❌ Error saving recording: \(error.localizedDescription)")
                    await MainActor.run {
                        blockedContentReason = error.localizedDescription
                        showContentBlocked = true
                    }
                }
            } catch {
                print("❌ Error saving recording: \(error.localizedDescription)")
                await MainActor.run {
                    blockedContentReason = error.localizedDescription
                    showContentBlocked = true
                }
            }
        }
        #endif
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
        #if os(iOS)
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
        #endif
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


//
//  VideoRecordingView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import AVFoundation
import Combine

struct VideoRecordingView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var documentService: DocumentService
    
    @StateObject private var camera = CameraViewModel()
    @State private var isRecording = false
    @State private var showPreview = false
    @State private var recordedVideoURL: URL?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Camera Preview
                CameraPreviewView(camera: camera)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                
                // Controls
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    // Recording Indicator
                    if isRecording {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .scaleEffect(isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                            
                            Text("Recording...")
                                .font(theme.typography.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Record Button
                    Button {
                        toggleRecording()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color.red : Color.white)
                                .frame(width: 70, height: 70)
                            
                            if isRecording {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: 30, height: 30)
                            } else {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 60, height: 60)
                            }
                        }
                    }
                    
                    // Cost Info
                    Text("Video Recording")
                        .font(theme.typography.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(UnifiedTheme.Spacing.xl)
                .background(colors.surface.opacity(0.9))
            }
        }
        .navigationTitle("Record Video")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
        .task {
            await camera.checkPermissions()
        }
        .sheet(isPresented: $showPreview) {
            if let videoURL = recordedVideoURL {
                VideoPreviewView(
                    videoURL: videoURL,
                    vault: vault,
                    onSave: { url in
                        await saveVideo(url)
                    },
                    onDiscard: {
                        recordedVideoURL = nil
                        showPreview = false
                    }
                )
            }
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            camera.stopRecording { url in
                recordedVideoURL = url
                showPreview = true
            }
        } else {
            camera.startRecording()
        }
        isRecording.toggle()
    }
    
    private func saveVideo(_ url: URL) async {
        
        do {
            // Premium subscription - unlimited video recording
            
            // Load video data
            let data = try Data(contentsOf: url)
            let fileName = "video_\(Date().timeIntervalSince1970).mp4"
            
            // Upload
            _ = try await documentService.uploadDocument(
                data: data,
                name: fileName,
                mimeType: "video/mp4",
                to: vault,
                uploadMethod: .videoRecording
            )
            
            dismiss()
        } catch {
            print("Error saving video: \(error)")
        }
    }
}

// MARK: - Camera ViewModel
@MainActor
class CameraViewModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var output = AVCaptureMovieFileOutput()
    @Published var preview: AVCaptureVideoPreviewLayer?
    @Published var hasPermission = false
    
    private var recordingCompletion: ((URL) -> Void)?
    
    nonisolated override init() {
        super.init()
    }
    
    func checkPermissions() async {
        // Check video permissions
        let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch videoStatus {
        case .authorized:
            // Check audio permissions for video with sound
            switch audioStatus {
            case .authorized:
                hasPermission = true
                await setupCamera()
            case .notDetermined:
                let audioGranted = await AVCaptureDevice.requestAccess(for: .audio)
                hasPermission = audioGranted
                if audioGranted {
                    await setupCamera()
                }
            default:
                hasPermission = false
            }
        case .notDetermined:
            let videoGranted = await AVCaptureDevice.requestAccess(for: .video)
            if videoGranted {
                let audioGranted = await AVCaptureDevice.requestAccess(for: .audio)
                hasPermission = videoGranted && audioGranted
                if hasPermission {
                    await setupCamera()
                }
            } else {
                hasPermission = false
            }
        default:
            hasPermission = false
        }
    }
    
    func setupCamera() async {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let audioDevice = AVCaptureDevice.default(for: .audio) else {
            return
        }
        
        do {
            // Add video input
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }
            
            // Add audio input for video with sound
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            if session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }
            
            // Add video output
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            // Configure preview
            preview = AVCaptureVideoPreviewLayer(session: session)
            preview?.videoGravity = .resizeAspectFill
            
            // Start session on background thread
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        } catch {
            print("Camera setup failed: \(error)")
        }
    }
    
    func startRecording() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        
        output.startRecording(to: tempURL, recordingDelegate: self)
    }
    
    func stopRecording(completion: @escaping (URL) -> Void) {
        recordingCompletion = completion
        output.stopRecording()
    }
}

extension CameraViewModel: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("Recording error: \(error)")
            } else {
                recordingCompletion?(outputFileURL)
            }
        }
    }
}

// MARK: - Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    let camera: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Add preview layer when camera is set up
        DispatchQueue.main.async {
            if let preview = camera.preview {
                // Remove any existing sublayers
                view.layer.sublayers?.removeAll()
                preview.frame = view.bounds
                view.layer.addSublayer(preview)
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let preview = camera.preview {
                // Ensure preview layer is added
                if preview.superlayer != uiView.layer {
                    uiView.layer.sublayers?.removeAll()
                    uiView.layer.addSublayer(preview)
                }
                // Update frame
                preview.frame = uiView.bounds
            }
        }
    }
}

struct VideoPreviewView: View {
    let videoURL: URL
    let vault: Vault
    let onSave: (URL) async -> Void
    let onDiscard: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // Video Player (simplified - would use AVPlayer in production)
            Rectangle()
                .fill(Color.black)
                .overlay(
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.7))
                )
            
            // Actions
            HStack(spacing: UnifiedTheme.Spacing.lg) {
                Button {
                    onDiscard()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.title)
                        Text("Discard")
                            .font(theme.typography.caption)
                    }
                    .foregroundColor(colors.error)
                }
                
                Spacer()
                
                Button {
                    Task {
                        await onSave(videoURL)
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                        Text("Save to Vault")
                            .font(theme.typography.caption)
                    }
                    .foregroundColor(colors.success)
                }
            }
            .padding(UnifiedTheme.Spacing.xl)
            .background(colors.surface)
        }
    }
}

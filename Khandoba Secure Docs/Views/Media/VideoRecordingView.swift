//
//  VideoRecordingView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
@preconcurrency import AVFoundation
import AVKit
import Combine

internal struct VideoRecordingView: View {
    let vault: Vault
    
    internal init(vault: Vault) {
        self.vault = vault
    }
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @EnvironmentObject var documentService: DocumentService
    
    #if !os(tvOS)
    @StateObject private var camera = CameraViewModel()
    #endif
    @State private var isRecording = false
    @State private var showPreview = false
    @State private var recordedVideoURL: URL?
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
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
                
                if platform.supportsCamera {
                    // Camera recording view (iOS and macOS)
                    cameraRecordingView(colors: colors)
                } else {
                    // File upload view (tvOS)
                    fileUploadView(colors: colors)
                }
            }
            #if os(macOS)
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.movie, .video, .mpeg4Movie, .quickTimeMovie],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            #endif
        }
        .navigationTitle("Record Video")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
            #else
            ToolbarItem(placement: .automatic) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            }
            #endif
        }
        .task {
            #if !os(tvOS)
            await camera.checkPermissions()
            #endif
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
                .alert("Content Blocked", isPresented: $showContentBlocked) {
                    Button("OK", role: .cancel) { }
                } message: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This video cannot be saved due to inappropriate content.")
                        
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
        }
    }
    
    @ViewBuilder
    private func cameraRecordingView(colors: UnifiedTheme.Colors) -> some View {
        #if os(iOS) || os(macOS)
        VStack(spacing: 0) {
            // Camera Preview - Shows LIVE feed immediately
            ZStack {
                Color.black
                
                if camera.hasPermission && camera.preview != nil {
                    #if os(iOS)
                    CameraPreviewView(camera: camera)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    #else
                    Color.black
                    #endif
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        Text(camera.hasPermission ? "Loading camera..." : "Camera access required")
                            .font(theme.typography.body)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Controls
            VStack(spacing: UnifiedTheme.Spacing.lg) {
                    #if os(macOS)
                    // macOS: Show file picker option
                    Button {
                        showFilePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                            Text("Choose Video File")
                        }
                        .padding()
                        .background(colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    #endif
                    
                    // Recording Indicator with Timer
                    if isRecording {
                        VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .scaleEffect(isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isRecording)
                            
                                Text("Recording")
                                .font(theme.typography.subheadline)
                                    .foregroundColor(.white)
                            }
                            
                            // Timer Display
                            Text(formatDuration(recordingDuration))
                                .font(.system(size: 28, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Record Button (iOS only, macOS uses file picker)
                    #if os(iOS)
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
                    #endif
                    
                    // Cost Info
                    Text("Video Recording")
                        .font(theme.typography.caption)
                        .foregroundColor(.white.opacity(0.7))
            }
            .padding(UnifiedTheme.Spacing.xl)
            .background(colors.surface.opacity(0.9))
        }
        #else
        // tvOS fallback - should not reach here due to platform check in body
        Text("Video recording not available")
        #endif
    }
    
    @ViewBuilder
    private func fileUploadView(colors: UnifiedTheme.Colors) -> some View {
        // tvOS: File upload only
        VStack(spacing: UnifiedTheme.Spacing.xl) {
            Image(systemName: "video.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(colors.primary)
            
            Text("Video Upload")
                .font(theme.typography.title)
                .foregroundColor(colors.textPrimary)
            
            Text("Camera recording is not available on Apple TV. Please use file upload to add videos.")
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button {
                showFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "folder")
                    Text("Choose Video File")
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
                    await saveVideo(url)
                }
            }
        case .failure(let error):
            print("File selection failed: \(error)")
        }
    }
    #endif
    
    private func toggleRecording() {
        #if !os(tvOS)
        if isRecording {
            // Stop recording and timer
            stopTimer()
            camera.stopRecording { url in
                recordedVideoURL = url
                showPreview = true
            }
        } else {
            // Start recording and timer
            recordingDuration = 0
            startTimer()
            camera.startRecording()
        }
        isRecording.toggle()
        #endif
    }
    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let deciseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, deciseconds)
    }
    
    private func saveVideo(_ url: URL) async {
        do {
            print(" Saving video recording...")
            
            // Load video data
            let data = try Data(contentsOf: url)
            let fileName = "video_\(Date().timeIntervalSince1970).mp4"
            
            print("    File size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
            print("    Duration: \(formatDuration(recordingDuration))")
            
            //  GENERATE AI TAGS FOR VIDEO
            print("    Generating AI tags...")
            let tags = await NLPTaggingService.generateTags(
                for: data,
                mimeType: "video/mp4",
                documentName: fileName
            )
            
            if !tags.isEmpty {
                print("    Generated \(tags.count) AI tags: \(tags.joined(separator: ", "))")
            } else {
                print("    No AI tags generated")
            }
            
            // Upload with AI tags
            let document = try await documentService.uploadDocument(
                data: data,
                name: fileName,
                mimeType: "video/mp4",
                to: vault,
                uploadMethod: .videoRecording
            )
            
            // Add AI tags to document
            if !tags.isEmpty {
                document.aiTags = tags
                print("   ?? AI tags applied to document")
            }
            
            print("    Video saved successfully to vault: \(vault.name)")
            dismiss()
        } catch let error as DocumentError {
            switch error {
            case .contentBlocked(_, let categories, let reason):
                await MainActor.run {
                    blockedContentReason = reason
                    blockedContentCategories = categories
                    showContentBlocked = true
                }
            default:
                print(" Error saving video: \(error.localizedDescription)")
            }
        } catch {
            print(" Error saving video: \(error.localizedDescription)")
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
            let captureSession = self.session
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
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
#if os(iOS)
struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var camera: CameraViewModel
    
    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        // Update preview layer immediately when available
        if let preview = camera.preview {
            if preview.superlayer != uiView.layer {
                // Remove old layers
                uiView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                // Add preview layer
                uiView.layer.insertSublayer(preview, at: 0)
            }
            // Always update frame to match view bounds
            DispatchQueue.main.async {
                preview.frame = uiView.bounds
            }
        }
    }
}

// Custom UIView for camera preview
class PreviewContainerView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update preview layer frame when view layout changes
        layer.sublayers?.forEach { sublayer in
            if sublayer is AVCaptureVideoPreviewLayer {
                sublayer.frame = bounds
            }
        }
    }
}
#endif

struct VideoPreviewView: View {
    let videoURL: URL
    let vault: Vault
    let onSave: (URL) async -> Void
    let onDiscard: () -> Void
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @StateObject private var playerViewModel = VideoPlayerViewModel()
    @State private var isPlaying = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // Video Player with Live Preview
            ZStack {
                Color.black
                
                #if os(iOS)
                VideoPlayerView(player: playerViewModel.player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                #else
                // Video player not available on this platform
                Text("Video preview not available")
                    .foregroundColor(.white)
                #endif
                
                // Play/Pause Overlay
                if !isPlaying {
                    Button {
                        if playerViewModel.isPlaying {
                            playerViewModel.pause()
                        } else {
                            playerViewModel.play()
                        }
                    } label: {
                        Image(systemName: playerViewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .onAppear {
                playerViewModel.loadVideo(url: videoURL)
                playerViewModel.play()
            }
            .onDisappear {
                playerViewModel.pause()
            }
            
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

// MARK: - Video Player View
#if os(iOS)
struct VideoPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Updates handled by AVPlayer
    }
}
#endif

// MARK: - Video Player ViewModel
@MainActor
class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer
    @Published var isPlaying = false
    
    init() {
        player = AVPlayer()
    }
    
    func loadVideo(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        
        // Observe playback status
        player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isPlaying = self.player.rate != 0
            }
        }
    }
    
    func play() {
        player.play()
        isPlaying = true
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
}

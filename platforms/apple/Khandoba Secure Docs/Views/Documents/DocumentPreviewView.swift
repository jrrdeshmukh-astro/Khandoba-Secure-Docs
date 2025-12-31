//
//  DocumentPreviewView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData
import CoreLocation
import QuickLook
import UniformTypeIdentifiers
import AVFoundation
import AVKit

#if os(iOS)
import UIKit
import PDFKit
#endif

struct DocumentPreviewView: View {
    let document: Document
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var documentService: DocumentService
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var showActions = false
    @State private var showDeleteConfirm = false
    @State private var showRenameSheet = false
    @StateObject private var locationService = LocationService()
    @State private var previewURL: URL?
    @State private var decryptedData: Data? // Store decrypted data for audio player
    @State private var isLoading = false
    @State private var isContentVisible = false // Secure preview - content hidden by default
    @State private var isScreenCaptured = false
    @State private var screenCaptureTimer: Timer?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Secure Preview with Screenshot Prevention
                if let previewURL = previewURL {
                    // Audio and video files don't need secure preview - show immediately
                    let isAudioOrVideo = document.documentType == "audio" || document.mimeType?.hasPrefix("audio/") == true ||
                                        document.documentType == "video" || document.mimeType?.hasPrefix("video/") == true
                    
                    // For audio/video: always show content (no secure preview needed)
                    // For other files: require explicit "Show Content" button
                    let shouldShowContent = isAudioOrVideo || (isContentVisible && !isScreenCaptured)
                    
                    if shouldShowContent {
                        // Show content - use specialized players for audio/video, QuickLook for others
                        if document.documentType == "audio" || document.mimeType?.hasPrefix("audio/") == true {
                            // Audio playback - no secure preview needed
                            if let decryptedData = decryptedData {
                                AudioPlayerPreviewView(document: document, audioData: decryptedData)
                            } else {
                                ProgressView("Loading audio...")
                            }
                        } else if document.documentType == "video" || document.mimeType?.hasPrefix("video/") == true {
                            // Video playback - no secure preview needed
                            if let decryptedData = decryptedData {
                                VideoPlayerPreviewView(document: document, videoData: decryptedData, videoURL: previewURL)
                            } else {
                                ProgressView("Loading video...")
                            }
                        } else {
                            #if os(iOS)
                            QuickLookPreviewView(url: previewURL)
                                .overlay(
                                    // Screenshot prevention overlay (monitors continuously)
                                    SecurePreviewOverlay(isScreenCaptured: $isScreenCaptured)
                                )
                            #else
                            // QuickLook wrapper not available on macOS in this file; show simple message
                            VStack(spacing: UnifiedTheme.Spacing.md) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 48))
                                Text("Preview available on iOS")
                                Text(previewURL.lastPathComponent)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            #endif
                        }
                    } else {
                        // Secure overlay - content hidden (only for non-audio/video files)
                        SecurePreviewOverlay(
                            isScreenCaptured: $isScreenCaptured,
                            onShowContent: {
                                isContentVisible = true
                            },
                            showButton: !isContentVisible
                        )
                    }
                } else if isLoading {
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading document...")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        Image(systemName: "doc.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(colors.textTertiary)
                        Text("Unable to load document")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        Text("The document could not be loaded for preview")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Document Info Bar
                DocumentInfoBar(document: document)
                    .background(colors.surface)
            }
        }
        .navigationTitle(document.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    // Print option (only export allowed)
                    Button {
                        printDocument()
                    } label: {
                        Label("Print", systemImage: "printer.fill")
                    }
                    
                    Divider()
                    
                    Button {
                        showRenameSheet = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    NavigationLink {
                        DocumentVersionHistoryView(document: document)
                    } label: {
                        Label("Version History", systemImage: "clock.arrow.circlepath")
                    }
                    
                    NavigationLink {
                        RedactionView(document: document)
                    } label: {
                        Label("Redact (HIPAA/CUI)", systemImage: "eye.slash.fill")
                    }
                    .disabled(!isRedactionSupported(document: document))
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(colors.primary)
                }
            }
            #endif
        }
        .sheet(isPresented: $showRenameSheet) {
            RenameDocumentView(document: document)
        }
        .confirmationDialog("Delete Document", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                deleteDocument()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone")
        }
        .task {
            // Start screen capture monitoring (only for non-audio/video files)
            let isAudioOrVideo = document.documentType == "audio" || document.mimeType?.hasPrefix("audio/") == true ||
                                document.documentType == "video" || document.mimeType?.hasPrefix("video/") == true
            if !isAudioOrVideo {
                startScreenCaptureMonitoring()
            }
            
            // Load document for preview
            await loadDocumentForPreview()
            
            // Auto-show content for audio/video files (no secure preview needed)
            if isAudioOrVideo {
                isContentVisible = true
            }
            
            // Log document preview
            await logDocumentPreview()
        }
        .onDisappear {
            // Stop screen capture monitoring
            stopScreenCaptureMonitoring()
            
            // Hide content when leaving view
            isContentVisible = false
            
            // Clean up temporary file
            if let url = previewURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
        .onChange(of: isScreenCaptured) { oldValue, newValue in
            // Hide content immediately if screen capture detected
            if newValue {
                isContentVisible = false
                print("🚫 Screen capture detected - hiding secure content")
            }
        }
    }
    
    /// Load document data and prepare for QuickLook preview
    private func loadDocumentForPreview() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // iOS-ONLY: Using SwiftData/CloudKit exclusively
            guard let encryptedData = document.encryptedFileData else {
                print("⚠️ Document has no encrypted file data")
                return
            }
            
            // Decrypt the document
            let documentData = try EncryptionService.decryptDocument(
                encryptedData,
                documentID: document.id
            )
            
            guard let data = documentData else {
                print("⚠️ Failed to get document data")
                return
            }
            
            // Determine file extension
            let fileExtension = document.fileExtension ?? {
                // Infer from mime type or document type
                if let mimeType = document.mimeType {
                    return UTType(mimeType: mimeType)?.preferredFilenameExtension
                }
                switch document.documentType {
                case "image": return "jpg"
                case "pdf": return "pdf"
                case "video": return "mp4"
                case "audio": return "m4a"
                case "text": return "txt"
                default: return "bin"
                }
            }()
            
            // Create temporary file for QuickLook
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(document.id.uuidString)
                .appendingPathExtension(fileExtension ?? "bin")
            
            try data.write(to: tempURL)
            
            await MainActor.run {
                self.previewURL = tempURL
                // Store decrypted data for audio and video players
                if document.documentType == "audio" || document.mimeType?.hasPrefix("audio/") == true ||
                   document.documentType == "video" || document.mimeType?.hasPrefix("video/") == true {
                    self.decryptedData = data
                }
            }
            
            print("✅ Document loaded for preview: \(document.name)")
        } catch {
            print("❌ Failed to load document for preview: \(error.localizedDescription)")
        }
    }
    
    private func logDocumentPreview() async {
        guard let vault = document.vault else { return }
        
        // Get current location
        await locationService.requestLocationPermission()
        let location = await locationService.getCurrentLocation()
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively - Create access log
        let accessLog = VaultAccessLog(
            accessType: "previewed",
            userID: authService.currentUser?.id,
            userName: authService.currentUser?.fullName
        )
        accessLog.vault = vault
        accessLog.documentID = document.id
        accessLog.documentName = document.name
        
        if let location = location {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
        }
        
        modelContext.insert(accessLog)
        try? modelContext.save()
        
        print("📄 Document preview logged: \(document.name)")
    }
    
    private func deleteDocument() {
        Task {
            try? await documentService.deleteDocument(document)
            dismiss()
        }
    }
    
    // MARK: - Print Functionality
    
    private func printDocument() {
        guard let previewURL = previewURL else {
            print("⚠️ Cannot print: Document not loaded")
            return
        }
        
        #if os(iOS)
        // Create print info
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = document.name
        printInfo.duplex = .none
        
        // Create print controller
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.printingItem = previewURL
        
        // Present print dialog
        if UIApplication.shared.connectedScenes.first is UIWindowScene {
            printController.present(animated: true) { controller, completed, error in
                if let error = error {
                    print("❌ Print error: \(error.localizedDescription)")
                } else if completed {
                    print("✅ Document sent to printer")
                }
            }
        }
        #else
        // Print functionality not available on this platform
        print("⚠️ Print functionality is only available on iOS")
        #endif
    }
    
    // MARK: - Screenshot Prevention
    
    private func startScreenCaptureMonitoring() {
        #if os(iOS)
        // Check immediately
        checkScreenCapture()
        
        // Monitor continuously (every 0.5 seconds)
        screenCaptureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] _ in
            checkScreenCapture()
        }
        
        // Listen for screen capture notifications
        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [self] _ in
            checkScreenCapture()
        }
        #endif
    }
    
    private func stopScreenCaptureMonitoring() {
        #if os(iOS)
        screenCaptureTimer?.invalidate()
        screenCaptureTimer = nil
        NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
        #endif
    }
    
    private func checkScreenCapture() {
        #if os(iOS)
        // Check if we're in an app extension
        let isExtension = Bundle.main.bundlePath.hasSuffix(".appex")
        if isExtension {
            return // Screen capture detection not available in extensions
        }
        
        // Get screen capture status using window scene (iOS 26+ compatible)
        var captured = false
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            // screen is not optional in UIWindowScene, so we can access it directly
            captured = windowScene.screen.isCaptured
        } else {
            if #available(iOS 26.0, *) {
                captured = false
            } else {
                captured = UIScreen.main.isCaptured
            }
        }
        
        if captured && !isScreenCaptured {
            // Screen capture just started - hide content immediately
            Task { @MainActor in
                isContentVisible = false
                isScreenCaptured = true
                print("🚫 Screen capture detected - content hidden")
            }
        }
        
        isScreenCaptured = captured
        #endif
    }
    
    /// Check if document format supports HIPAA-compliant redaction
    private func isRedactionSupported(document: Document) -> Bool {
        // Only PDF and image formats support proper redaction
        guard let mimeType = document.mimeType?.lowercased() else {
            // Fallback to document type
            return document.documentType == "pdf" || document.documentType == "image"
        }
        
        // Supported MIME types for redaction
        let supportedMimeTypes = [
            "application/pdf",
            "image/png",
            "image/jpeg",
            "image/jpg",
            "image/heic",
            "image/heif"
        ]
        
        return supportedMimeTypes.contains(mimeType) || 
               document.documentType == "pdf" || 
               document.documentType == "image"
    }
}

// MARK: - Image Preview
struct ImagePreviewView: View {
    let document: Document
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            #if os(iOS)
            if let data = document.encryptedFileData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1.0 {
                                    withAnimation {
                                        scale = 1.0
                                        lastScale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView("Loading image...")
            }
            #else
            if let data = document.encryptedFileData,
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1.0 {
                                    withAnimation {
                                        scale = 1.0
                                        lastScale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView("Loading image...")
            }
            #endif
        }
    }
}

// MARK: - PDF Preview
struct PDFDocumentPreviewView: View {
    let document: Document
    
    var body: some View {
        #if os(iOS)
        if let data = document.encryptedFileData {
            PDFKitView(data: data)
        } else {
            ProgressView("Loading PDF...")
        }
        #else
        // macOS fallback
        Text("PDF preview available on iOS")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }
}

#if os(iOS)
struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        if let pdfDocument = PDFDocument(data: data) {
            pdfView.document = pdfDocument
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Updates handled by PDFView
    }
}
#endif

// MARK: - Video Preview
struct VideoPlayerPreviewView: View {
    let document: Document
    let videoData: Data // Decrypted video data
    let videoURL: URL // Temporary file URL
    
    @State private var player: AVPlayer?
    
    var body: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ProgressView("Loading video...")
                    .onAppear {
                        loadVideo()
                    }
            }
        }
    }
    
    private func loadVideo() {
        // Use the provided videoURL (already contains decrypted data)
        // AVPlayer needs a file URL, not raw data
        player = AVPlayer(url: videoURL)
        print("✅ Video player initialized with URL: \(videoURL.lastPathComponent)")
    }
}

// MARK: - Audio Preview
struct AudioPlayerPreviewView: View {
    let document: Document
    let audioData: Data // Decrypted audio data
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.xl) {
            Spacer()
            
            // Waveform visualization
            Image(systemName: "waveform")
                .font(.system(size: 80))
                .foregroundColor(colors.primary)
                .opacity(isPlaying ? 1.0 : 0.5)
            
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Text(document.name)
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                Text(formatTime(currentTime))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(colors.textSecondary)
                
                Text("/ \(formatTime(duration))")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textTertiary)
            }
            
            // Progress Bar
            ProgressView(value: duration > 0 ? currentTime / duration : 0)
                .tint(colors.primary)
                .padding(.horizontal, UnifiedTheme.Spacing.xl)
            
            // Play/Pause Button
            Button {
                togglePlayback()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(colors.primary)
            }
            
            Spacer()
        }
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            player?.stop()
            timer?.invalidate()
        }
    }
    
    private func setupAudioPlayer() {
        do {
            player = try AVAudioPlayer(data: audioData)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
            print("✅ Audio player initialized - Duration: \(duration) seconds")
        } catch {
            print("❌ Audio player error: \(error.localizedDescription)")
        }
    }
    
    private func togglePlayback() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            timer?.invalidate()
        } else {
            player.play()
            startTimer()
        }
        
        isPlaying.toggle()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            currentTime = player?.currentTime ?? 0
            
            if currentTime >= duration {
                isPlaying = false
                timer?.invalidate()
                currentTime = 0
                player?.currentTime = 0
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Markdown/Text Preview
struct MarkdownPreviewView: View {
    let document: Document
    
    @State private var markdownText: String = ""
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading markdown...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        loadMarkdown()
                    }
            } else {
                MarkdownTextView(markdown: markdownText)
            }
        }
    }
    
    private func loadMarkdown() {
        guard let data = document.encryptedFileData else {
            isLoading = false
            return
        }
        
        // Try to decode as UTF-8 string
        if let text = String(data: data, encoding: .utf8) {
            markdownText = text
        } else if let text = String(data: data, encoding: .utf16) {
            markdownText = text
        } else {
            markdownText = "Unable to decode text content"
        }
        
        isLoading = false
    }
}

// MARK: - Unsupported Preview
struct UnsupportedDocPreviewView: View {
    let document: Document
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 60))
                .foregroundColor(colors.textTertiary)
            
            Text("Preview Not Available")
                .font(theme.typography.title2)
                .foregroundColor(colors.textPrimary)
            
            Text("This file type cannot be previewed")
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
            
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                HStack {
                    Text("Type:")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                    Spacer()
                    Text(document.mimeType ?? "Unknown")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textPrimary)
                }
                
                HStack {
                    Text("Size:")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textPrimary)
                }
            }
            .padding()
            .background(colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
        }
        .padding()
    }
}

// MARK: - Document Info Bar
struct DocumentInfoBar: View {
    let document: Document
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.sm) {
            // Source/Sink indicator
            if let sourceSinkType = document.sourceSinkType {
                HStack(spacing: 4) {
                    Image(systemName: sourceSinkIcon(sourceSinkType))
                        .font(.caption)
                        .foregroundColor(sourceSinkColor(sourceSinkType))
                    
                    Text(sourceSinkType.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(sourceSinkColor(sourceSinkType))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(sourceSinkColor(sourceSinkType).opacity(0.2))
                .cornerRadius(UnifiedTheme.CornerRadius.sm)
            }
            
            // AI Tags
            if !document.aiTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(document.aiTags.prefix(5), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(colors.primary.opacity(0.2))
                                .foregroundColor(colors.primary)
                                .cornerRadius(UnifiedTheme.CornerRadius.sm)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Metadata
            HStack {
                Text(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))
                Text("•")
                Text(document.uploadedAt, style: .date)
            }
            .font(theme.typography.caption)
            .foregroundColor(colors.textSecondary)
        }
        .padding(.vertical, UnifiedTheme.Spacing.sm)
    }
    
    private func sourceSinkIcon(_ type: String) -> String {
        switch type {
        case "source": return "camera.fill"
        case "sink": return "square.and.arrow.down.fill"
        case "both": return "arrow.triangle.2.circlepath"
        default: return "doc.fill"
        }
    }
    
    private func sourceSinkColor(_ type: String) -> Color {
        let colors = theme.colors(for: colorScheme)
        switch type {
        case "source": return colors.info
        case "sink": return colors.success
        case "both": return colors.warning
        default: return colors.textTertiary
        }
    }
}

// MARK: - Rename Sheet
struct RenameDocumentView: View {
    let document: Document
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var documentService: DocumentService
    
    @State private var newName: String
    @State private var isLoading = false
    
    init(document: Document) {
        self.document = document
        _newName = State(initialValue: document.name)
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    TextField("Document name", text: $newName)
                        .font(theme.typography.body)
                        .padding(UnifiedTheme.Spacing.md)
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Rename Document")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRename()
                    }
                    .disabled(newName.isEmpty || newName == document.name || isLoading)
                }
                #else
                ToolbarItem {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem {
                    Button("Save") { saveRename() }
                        .disabled(newName.isEmpty || newName == document.name || isLoading)
                }
                #endif
            }
        }
    }
    
    private func saveRename() {
        isLoading = true
        Task {
            try? await documentService.renameDocument(document, newName: newName)
            dismiss()
        }
    }
    
    /// Check if document format supports HIPAA-compliant redaction
    private func isRedactionSupported(document: Document) -> Bool {
        // Only PDF and image formats support proper redaction
        guard let mimeType = document.mimeType?.lowercased() else {
            // Fallback to document type
            return document.documentType == "pdf" || document.documentType == "image"
        }
        
        // Supported MIME types for redaction
        let supportedMimeTypes = [
            "application/pdf",
            "image/png",
            "image/jpeg",
            "image/jpg",
            "image/heic",
            "image/heif"
        ]
        
        return supportedMimeTypes.contains(mimeType) || 
               document.documentType == "pdf" || 
               document.documentType == "image"
    }
}

// MARK: - Secure Preview Overlay

struct SecurePreviewOverlay: View {
    @Binding var isScreenCaptured: Bool
    var onShowContent: (() -> Void)?
    var showButton: Bool = true
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @State private var showGrepButton = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            // Solid background to prevent screenshot
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: UnifiedTheme.Spacing.xl) {
                Image(systemName: isScreenCaptured ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 60))
                    .foregroundColor(isScreenCaptured ? colors.error : colors.warning)
                
                if isScreenCaptured {
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        Text("Screen Capture Detected")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.error)
                        
                        Text("Content hidden for security. Stop screen recording to view document.")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        Text("Secure Preview")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text("Content is hidden to prevent screenshots and screen recording. Tap 'Show Content' to view the document.")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if showButton {
                            Button {
                                onShowContent?()
                            } label: {
                                HStack {
                                    Image(systemName: "eye.fill")
                                    Text("Show Content")
                                }
                                .font(theme.typography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, UnifiedTheme.Spacing.xl)
                                .padding(.vertical, UnifiedTheme.Spacing.md)
                                .background(colors.primary)
                                .cornerRadius(UnifiedTheme.CornerRadius.md)
                            }
                            .padding(.top, UnifiedTheme.Spacing.md)
                        }
                        
                        // Optional: Grep button for text search
                        Button {
                            showGrepButton.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search Text")
                            }
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                        }
                        .padding(.top, UnifiedTheme.Spacing.sm)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - QuickLook Preview Wrapper
#if os(iOS)
struct QuickLookPreviewView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        
        init(url: URL) {
            self.url = url
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
        }
    }
}
#endif


//
//  DocumentPreviewView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import PDFKit
import AVKit

struct DocumentPreviewView: View {
    let document: Document
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var documentService: DocumentService
    
    @State private var showActions = false
    @State private var showDeleteConfirm = false
    @State private var showRenameSheet = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Preview based on document type
                if document.documentType == "image" {
                    ImagePreviewView(document: document)
                } else if document.documentType == "pdf" {
                    PDFDocumentPreviewView(document: document)
                } else if document.documentType == "video" {
                    VideoPlayerPreviewView(document: document)
                } else if document.documentType == "audio" {
                    AudioPlayerPreviewView(document: document)
                } else {
                    UnsupportedDocPreviewView(document: document)
                }
                
                // Document Info Bar
                DocumentInfoBar(document: document)
                    .background(colors.surface)
            }
        }
        .navigationTitle(document.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
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
                        Label("Redact (HIPAA)", systemImage: "eye.slash.fill")
                    }
                    
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
    }
    
    private func deleteDocument() {
        Task {
            try? await documentService.deleteDocument(document)
            dismiss()
        }
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
        }
    }
}

// MARK: - PDF Preview
struct PDFDocumentPreviewView: View {
    let document: Document
    
    var body: some View {
        if let data = document.encryptedFileData {
            PDFKitView(data: data)
        } else {
            ProgressView("Loading PDF...")
        }
    }
}

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

// MARK: - Video Preview
struct VideoPlayerPreviewView: View {
    let document: Document
    
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
        guard let data = document.encryptedFileData else { return }
        
        // Write to temp file for AVPlayer
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(document.id.uuidString)
            .appendingPathExtension("mp4")
        
        try? data.write(to: tempURL)
        player = AVPlayer(url: tempURL)
    }
}

// MARK: - Audio Preview
struct AudioPlayerPreviewView: View {
    let document: Document
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
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
        guard let data = document.encryptedFileData else { return }
        
        do {
            player = try AVAudioPlayer(data: data)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
        } catch {
            print("Audio player error: \(error)")
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

// MARK: - Unsupported Preview
struct UnsupportedDocPreviewView: View {
    let document: Document
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
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
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
}


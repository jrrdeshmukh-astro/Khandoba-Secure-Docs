//
//  BulkOperationsView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import PDFKit

struct BulkUploadView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var documentService: DocumentService
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedFiles: [URL] = []
    @State private var selectedFileData: [URL: Data] = [:] // Store file data for preview
    @State private var isShowingFilePicker = false
    @State private var uploadProgress: [String: Double] = [:]
    @State private var isUploading = false
    @State private var completedUploads = 0
    @State private var failedUploads = 0
    @State private var showPreview = false
    @State private var previewFile: URL?
    
    // Computed property to avoid type-checking timeout
    private var allowedFileTypes: [UTType] {
        var types: [UTType] = []
        
        // Images
        types.append(contentsOf: [.png, .jpeg, .heic, .gif, .bmp, .tiff])
        
        // Documents
        types.append(.pdf)
        
        // Office Documents
        if let docx = UTType(filenameExtension: "docx") { types.append(docx) }
        if let doc = UTType(filenameExtension: "doc") { types.append(doc) }
        if let xlsx = UTType(filenameExtension: "xlsx") { types.append(xlsx) }
        if let xls = UTType(filenameExtension: "xls") { types.append(xls) }
        if let pptx = UTType(filenameExtension: "pptx") { types.append(pptx) }
        if let ppt = UTType(filenameExtension: "ppt") { types.append(ppt) }
        
        // Text
        types.append(contentsOf: [.text, .plainText, .rtf])
        
        // Archives
        if let zip = UTType(filenameExtension: "zip") { types.append(zip) }
        if let rar = UTType(filenameExtension: "rar") { types.append(rar) }
        
        // Media
        types.append(contentsOf: [.video, .movie, .mpeg4Movie, .quickTimeMovie])
        types.append(contentsOf: [.audio, .mp3, .mpeg4Audio])
        
        // Fallback - allows any file type
        types.append(.data)
        
        return types
    }
    
    private var totalSelectedCount: Int {
        selectedPhotos.count + selectedFiles.count
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Photo Picker
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 20,
                            matching: .images
                        ) {
                            StandardCard {
                                VStack(spacing: UnifiedTheme.Spacing.sm) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 40))
                                        .foregroundColor(colors.primary)
                                    
                                    Text("Select Photos")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Text("Choose up to 20 photos to upload")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, UnifiedTheme.Spacing.xl)
                            }
                        }
                        .padding(.horizontal)
                        
                        // File Picker
                        Button {
                            isShowingFilePicker = true
                        } label: {
                            StandardCard {
                                VStack(spacing: UnifiedTheme.Spacing.sm) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 40))
                                        .foregroundColor(colors.info)
                                    
                                    Text("Select Files")
                                        .font(theme.typography.headline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Text("PDFs, DOCX, XLSX, and more")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, UnifiedTheme.Spacing.xl)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Selected Items Preview
                        if totalSelectedCount > 0 {
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                    HStack {
                                        Image(systemName: totalSelectedCount == selectedPhotos.count ? "photo.stack" : "doc.on.doc.fill")
                                            .foregroundColor(colors.info)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(totalSelectedCount) item\(totalSelectedCount == 1 ? "" : "s") selected")
                                                .font(theme.typography.subheadline)
                                                .foregroundColor(colors.textPrimary)
                                            
                                            if selectedPhotos.count > 0 && selectedFiles.count > 0 {
                                                Text("\(selectedPhotos.count) photos, \(selectedFiles.count) files")
                                                    .font(theme.typography.caption)
                                                    .foregroundColor(colors.textSecondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Text("Premium: Unlimited")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.success)
                                    }
                                    
                                    // File List Preview
                                    if !selectedFiles.isEmpty {
                                        Divider()
                                        
                                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                            Text("Selected Files:")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                            
                                            ForEach(Array(selectedFiles.enumerated()), id: \.offset) { index, url in
                                                HStack {
                                                    Image(systemName: iconForFile(url))
                                                        .foregroundColor(colors.primary)
                                                        .frame(width: 24)
                                                    
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(url.lastPathComponent)
                                                            .font(theme.typography.body)
                                                            .foregroundColor(colors.textPrimary)
                                                            .lineLimit(1)
                                                        
                                                        if let fileSize = getFileSize(url) {
                                                            Text(fileSize)
                                                                .font(theme.typography.caption)
                                                                .foregroundColor(colors.textSecondary)
                                                        }
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    Button {
                                                        previewFile = url
                                                        showPreview = true
                                                    } label: {
                                                        Image(systemName: "eye.fill")
                                                            .foregroundColor(colors.primary)
                                                    }
                                                    
                                                    Button {
                                                        selectedFiles.remove(at: index)
                                                        selectedFileData.removeValue(forKey: url)
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(colors.textTertiary)
                                                    }
                                                }
                                                .padding(.vertical, 4)
                                            }
                                        }
                                    }
                                    
                                    // Photo Count (if any)
                                    if !selectedPhotos.isEmpty {
                                        if !selectedFiles.isEmpty {
                                            Divider()
                                        }
                                        
                                        HStack {
                                            Image(systemName: "photo.stack")
                                                .foregroundColor(colors.primary)
                                            Text("\(selectedPhotos.count) photo\(selectedPhotos.count == 1 ? "" : "s") selected")
                                                .font(theme.typography.caption)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    
                        // Upload Progress
                        if isUploading {
                            VStack(spacing: UnifiedTheme.Spacing.sm) {
                                ProgressView(value: Double(completedUploads + failedUploads), total: Double(totalSelectedCount)) {
                                    Text("Uploading...")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textPrimary)
                                }
                                
                                HStack {
                                    Text("Completed: \(completedUploads)")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.success)
                                    
                                    Spacer()
                                    
                                    if failedUploads > 0 {
                                        Text("Failed: \(failedUploads)")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.error)
                                    }
                                }
                            }
                            .padding()
                            .background(colors.surface)
                            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Bulk Upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isUploading ? "Cancel Upload" : "Close") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .fileImporter(
                isPresented: $isShowingFilePicker,
                allowedContentTypes: allowedFileTypes,
                allowsMultipleSelection: true
            ) { result in
                Task {
                    await handleFileSelection(result)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Upload Button
                if totalSelectedCount > 0 && !isUploading {
                    Button {
                        uploadAll()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Upload \(totalSelectedCount) Item\(totalSelectedCount == 1 ? "" : "s")")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding()
                    .background(colors.surface)
                }
            }
            .sheet(isPresented: $showPreview) {
                if let previewFile = previewFile {
                    FilePreviewSheet(fileURL: previewFile, fileName: previewFile.lastPathComponent)
                }
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            for url in urls {
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    print(" Failed to access security-scoped resource: \(url.lastPathComponent)")
                    continue
                }
                
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                // Load file data for preview
                if let data = try? Data(contentsOf: url) {
                    selectedFileData[url] = data
                    print(" Loaded file data: \(url.lastPathComponent) (\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)))")
                } else {
                    print(" Failed to load file data: \(url.lastPathComponent)")
                }
            }
            
            selectedFiles.append(contentsOf: urls)
            print(" Added \(urls.count) file(s) to selection")
        case .failure(let error):
            print(" File selection failed: \(error.localizedDescription)")
        }
    }
    
    private func uploadAll() {
        isUploading = true
        completedUploads = 0
        failedUploads = 0
        
        Task {
            // Upload photos
            for (index, photo) in selectedPhotos.enumerated() {
                do {
                    if let data = try await photo.loadTransferable(type: Data.self) {
                        let fileName = "photo_\(Date().timeIntervalSince1970)_\(index).jpg"
                        
                        _ = try await documentService.uploadDocument(
                            data: data,
                            name: fileName,
                            mimeType: "image/jpeg",
                            to: vault,
                            uploadMethod: .photos
                        )
                        
                        completedUploads += 1
                    }
                } catch {
                    failedUploads += 1
                    print("Upload failed for photo \(index): \(error)")
                }
            }
            
            // Upload files
            for (index, url) in selectedFiles.enumerated() {
                do {
                    let fileName = url.lastPathComponent
                    
                    // Start accessing security-scoped resource
                    guard url.startAccessingSecurityScopedResource() else {
                        print(" Failed to access security-scoped resource: \(fileName)")
                        failedUploads += 1
                        continue
                    }
                    
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    
                    // Try to get data from cache first, otherwise load from URL
                    let data: Data
                    if let cachedData = selectedFileData[url] {
                        data = cachedData
                        print(" Using cached data for: \(fileName)")
                    } else if let loadedData = try? Data(contentsOf: url) {
                        data = loadedData
                        selectedFileData[url] = loadedData
                        print(" Loaded data from URL: \(fileName)")
                    } else {
                        print(" Failed to read file data: \(fileName)")
                        failedUploads += 1
                        continue
                    }
                    
                    let fileExtension = url.pathExtension.lowercased()
                    
                    // Determine MIME type
                    let mimeType = mimeTypeForExtension(fileExtension) ?? "application/octet-stream"
                    
                    print("📤 Uploading: \(fileName) (\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)))")
                    
                    _ = try await documentService.uploadDocument(
                        data: data,
                        name: fileName,
                        mimeType: mimeType,
                        to: vault,
                        uploadMethod: .files
                    )
                    
                    print(" Uploaded: \(fileName)")
                    completedUploads += 1
                } catch {
                    failedUploads += 1
                    print(" Upload failed for file \(index) (\(url.lastPathComponent)): \(error.localizedDescription)")
                }
            }
            
            isUploading = false
            
            // Auto-dismiss if all succeeded
            if failedUploads == 0 {
                dismiss()
            }
        }
    }
    
    private func mimeTypeForExtension(_ ext: String) -> String? {
        switch ext.lowercased() {
        // Images
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic": return "image/heic"
        case "gif": return "image/gif"
        case "bmp": return "image/bmp"
        case "tiff", "tif": return "image/tiff"
        
        // Documents
        case "pdf": return "application/pdf"
        case "docx": return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "doc": return "application/msword"
        case "xlsx": return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "xls": return "application/vnd.ms-excel"
        case "pptx": return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "ppt": return "application/vnd.ms-powerpoint"
        
        // Text
        case "txt": return "text/plain"
        case "rtf": return "application/rtf"
        
        // Archives
        case "zip": return "application/zip"
        case "rar": return "application/x-rar-compressed"
        
        // Video
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "avi": return "video/x-msvideo"
        
        // Audio
        case "m4a": return "audio/mp4"
        case "mp3": return "audio/mpeg"
        case "wav": return "audio/wav"
        
        default: return nil
        }
    }
    
    // MARK: - Preview Helpers
    
    private func iconForFile(_ url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "doc", "docx": return "doc.text.fill"
        case "xls", "xlsx": return "tablecells.fill"
        case "ppt", "pptx": return "rectangle.stack.fill"
        case "jpg", "jpeg", "png", "heic", "gif": return "photo.fill"
        case "mp4", "mov", "avi": return "video.fill"
        case "mp3", "m4a", "wav": return "music.note"
        case "zip", "rar": return "archivebox.fill"
        case "txt", "rtf": return "text.alignleft"
        default: return "doc.fill"
        }
    }
    
    private func getFileSize(_ url: URL) -> String? {
        // Try to get file size from cached data
        if let data = selectedFileData[url] {
            return ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
        }
        
        // Try to get from file attributes
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attributes[.size] as? Int64 {
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
        
        return nil
    }
}

// MARK: - File Preview Sheet

struct FilePreviewSheet: View {
    let fileURL: URL
    let fileName: String
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var fileData: Data?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading preview...")
                } else if let errorMessage = errorMessage {
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(colors.error)
                        Text("Preview Unavailable")
                            .font(theme.typography.headline)
                        Text(errorMessage)
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if let data = fileData {
                    ScrollView {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            // File Info
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                    HStack {
                                        Image(systemName: iconForFile(fileURL))
                                            .foregroundColor(colors.primary)
                                        Text(fileName)
                                            .font(theme.typography.headline)
                                            .foregroundColor(colors.textPrimary)
                                    }
                                    
                                    Text(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Preview based on file type
                            if fileName.lowercased().hasSuffix(".pdf") {
                                if let pdfDocument = PDFDocument(data: data) {
                                    PDFKitView(data: data)
                                        .frame(height: 600)
                                } else {
                                    Text("Unable to load PDF")
                                        .foregroundColor(colors.error)
                                }
                            } else if let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 400)
                            } else {
                                // Text preview
                                if let text = String(data: data, encoding: .utf8) {
                                    Text(text)
                                        .font(theme.typography.body)
                                        .foregroundColor(colors.textPrimary)
                                        .padding()
                                } else {
                                    Text("Preview not available for this file type")
                                        .foregroundColor(colors.textSecondary)
                                        .padding()
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .task {
                await loadFileData()
            }
        }
    }
    
    private func loadFileData() async {
        isLoading = true
        
        guard fileURL.startAccessingSecurityScopedResource() else {
            await MainActor.run {
                errorMessage = "Unable to access file"
                isLoading = false
            }
            return
        }
        
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            await MainActor.run {
                fileData = data
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func iconForFile(_ url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.fill"
        case "doc", "docx": return "doc.text.fill"
        case "xls", "xlsx": return "tablecells.fill"
        case "ppt", "pptx": return "rectangle.stack.fill"
        case "jpg", "jpeg", "png", "heic", "gif": return "photo.fill"
        default: return "doc.fill"
        }
    }
}


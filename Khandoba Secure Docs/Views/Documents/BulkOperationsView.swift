//
//  BulkOperationsView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct BulkUploadView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var documentService: DocumentService
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedFiles: [URL] = []
    @State private var isShowingFilePicker = false
    @State private var uploadProgress: [String: Double] = [:]
    @State private var isUploading = false
    @State private var completedUploads = 0
    @State private var failedUploads = 0
    
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
                        
                        // Selected Items Count
                        if totalSelectedCount > 0 {
                            StandardCard {
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
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            selectedFiles.append(contentsOf: urls)
        case .failure(let error):
            print("File selection failed: \(error)")
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
                    
                    if let data = try? Data(contentsOf: url) {
                        let fileExtension = url.pathExtension.lowercased()
                        
                        // Determine MIME type
                        let mimeType = mimeTypeForExtension(fileExtension) ?? "application/octet-stream"
                        
                        _ = try await documentService.uploadDocument(
                            data: data,
                            name: fileName,
                            mimeType: mimeType,
                            to: vault,
                            uploadMethod: .files
                        )
                        
                        completedUploads += 1
                    } else {
                        failedUploads += 1
                        print("Failed to read file: \(fileName)")
                    }
                } catch {
                    failedUploads += 1
                    print("Upload failed for file \(index): \(error)")
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
}


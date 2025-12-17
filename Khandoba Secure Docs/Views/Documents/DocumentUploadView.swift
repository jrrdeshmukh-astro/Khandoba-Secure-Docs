//
//  DocumentUploadView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import Combine

struct DocumentUploadView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var documentService: DocumentService
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedDocument: URL?
    @State private var isShowingDocumentPicker = false
    @State private var isShowingCamera = false
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var capturedImage: UIImage?
    @State private var showContentBlocked = false
    @State private var blockedContentReason: String?
    @State private var blockedContentCategories: [ContentCategory] = []
    
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
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: UnifiedTheme.Spacing.xl) {
                    Text("Upload Document")
                        .font(theme.typography.title2)
                        .foregroundColor(colors.textPrimary)
                        .padding(.top, UnifiedTheme.Spacing.xl)
                    
                    // Upload Options
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        // Camera (Source)
                        Button {
                            isShowingCamera = true
                        } label: {
                            UploadOptionCard(
                                icon: "camera.fill",
                                title: "Camera",
                                subtitle: "Take photo (Source)",
                                badge: "SOURCE",
                                badgeColor: colors.info
                            )
                        }
                        
                        // Photos (Source)
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            UploadOptionCard(
                                icon: "photo.fill",
                                title: "Photos",
                                subtitle: "Select from library (Source)",
                                badge: "SOURCE",
                                badgeColor: colors.info
                            )
                        }
                        .onChange(of: selectedPhoto) { oldValue, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self),
                                   let fileName = await getFileName(from: newValue) {
                                    await uploadDocument(
                                        data: data,
                                        name: fileName,
                                        mimeType: "image/jpeg",
                                        method: .photos
                                    )
                                }
                            }
                        }
                        
                        // Files (Sink)
                        Button {
                            isShowingDocumentPicker = true
                        } label: {
                            UploadOptionCard(
                                icon: "folder.fill",
                                title: "Files",
                                subtitle: "Browse files (Sink)",
                                badge: "SINK",
                                badgeColor: colors.success
                            )
                        }
                    }
                    .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    
                    if isUploading {
                        ProgressView(value: documentService.uploadProgress) {
                            Text("Uploading...")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textSecondary)
                        }
                        .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    }
                    
                    Spacer()
                    
                    // Cost Info
                    StandardCard {
                        HStack {
                            Text("Unlimited uploads")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.success)
                            
                            Spacer()
                            
                            Text("Unlimited uploads")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.primary)
                        }
                    }
                    .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    .padding(.bottom, UnifiedTheme.Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .fileImporter(
                isPresented: $isShowingDocumentPicker,
                allowedContentTypes: allowedFileTypes,
                allowsMultipleSelection: false
            ) { result in
                Task {
                    await handleFileSelection(result)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Content Blocked", isPresented: $showContentBlocked) {
                Button("OK", role: .cancel) { }
            } message: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This content cannot be uploaded due to inappropriate material.")
                    
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
    
    private func getFileName(from item: PhotosPickerItem?) async -> String? {
        return "photo_\(Date().timeIntervalSince1970).jpg"
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                if let data = try? Data(contentsOf: url) {
                    let fileName = url.lastPathComponent
                    let fileExtension = url.pathExtension.lowercased()
                    
                    // Determine MIME type from file extension
                    let mimeType = mimeTypeForExtension(fileExtension) ?? "application/octet-stream"
                    
                    await uploadDocument(
                        data: data,
                        name: fileName,
                        mimeType: mimeType,
                        method: .files
                    )
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
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
        case "md", "markdown": return "text/markdown"
        
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
        
        default: return nil // Will be handled as "other" type
        }
    }
    
    private func uploadDocument(
        data: Data,
        name: String,
        mimeType: String,
        method: UploadMethod
    ) async {
        
        isUploading = true
        
        do {
            // All features included - unlimited uploads
            
            // Upload document
            _ = try await documentService.uploadDocument(
                data: data,
                name: name,
                mimeType: mimeType,
                to: vault,
                uploadMethod: method
            )
            
            dismiss()
        } catch let error as DocumentError {
            switch error {
            case .contentBlocked(let severity, let categories, let reason):
                blockedContentReason = reason
                blockedContentCategories = categories
                showContentBlocked = true
            default:
                errorMessage = error.localizedDescription
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isUploading = false
    }
}

struct UploadOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var badge: String? = nil
    var badgeColor: Color? = nil
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        StandardCard {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(colors.primary.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(colors.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(title)
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        if let badge = badge, let badgeColor = badgeColor {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(badgeColor)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(subtitle)
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(colors.textTertiary)
            }
        }
    }
}


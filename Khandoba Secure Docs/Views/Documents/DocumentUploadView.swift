//
//  DocumentUploadView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

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
                            Text("Premium: Unlimited uploads")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.success)
                            
                            Spacer()
                            
                            Text("Premium: Unlimited uploads")
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
                allowedContentTypes: [.pdf, .png, .jpeg, .heic, .video, .audio, .text, .data],
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
                    let mimeType = url.pathExtension
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
    
    private func uploadDocument(
        data: Data,
        name: String,
        mimeType: String,
        method: UploadMethod
    ) async {
        
        isUploading = true
        
        do {
            // Premium subscription - unlimited uploads
            
            // Upload document
            _ = try await documentService.uploadDocument(
                data: data,
                name: name,
                mimeType: mimeType,
                to: vault,
                uploadMethod: method
            )
            
            dismiss()
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


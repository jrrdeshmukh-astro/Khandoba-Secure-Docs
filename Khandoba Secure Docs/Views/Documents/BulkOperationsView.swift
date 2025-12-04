//
//  BulkOperationsView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import PhotosUI

struct BulkUploadView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var documentService: DocumentService
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var uploadProgress: [String: Double] = [:]
    @State private var isUploading = false
    @State private var completedUploads = 0
    @State private var failedUploads = 0
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
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
                    
                    // Selected Photos Count
                    if !selectedPhotos.isEmpty {
                        StandardCard {
                            HStack {
                                Image(systemName: "photo.stack")
                                    .foregroundColor(colors.info)
                                
                                Text("\(selectedPhotos.count) photos selected")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textPrimary)
                                
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
                            ProgressView(value: Double(completedUploads + failedUploads), total: Double(selectedPhotos.count)) {
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
                    
                    // Upload Button
                    if !selectedPhotos.isEmpty && !isUploading {
                        Button {
                            uploadPhotos()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Upload \(selectedPhotos.count) Photos")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(false)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
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
        }
    }
    
    private func uploadPhotos() {
        isUploading = true
        completedUploads = 0
        failedUploads = 0
        
        Task {
            for (index, photo) in selectedPhotos.enumerated() {
                do {
                    if let data = try await photo.loadTransferable(type: Data.self) {
                        let fileName = "photo_\(Date().timeIntervalSince1970)_\(index).jpg"
                        
                        // Premium subscription - unlimited uploads
                        
                        // Upload
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
            
            isUploading = false
            
            // Auto-dismiss if all succeeded
            if failedUploads == 0 {
                dismiss()
            }
        }
    }
}


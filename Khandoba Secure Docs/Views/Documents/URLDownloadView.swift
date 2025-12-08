//
//  URLDownloadView.swift
//  Khandoba Secure Docs
//
//  View for downloading assets from public URLs and saving to vaults
//

import SwiftUI
import SwiftData

struct URLDownloadView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var documentService: DocumentService
    
    @StateObject private var downloadService = URLAssetDownloadService()
    
    @State private var urlString = ""
    @State private var isValidURL = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var downloadedFileName = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Header
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(colors.primary)
                            
                            Text("Download from URL")
                                .font(theme.typography.title)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("Enter a public URL to download images, videos, or documents")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, UnifiedTheme.Spacing.xl)
                        
                        // Vault Info
                        StandardCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(colors.primary)
                                    Text("Saving to Vault")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textSecondary)
                                }
                                
                                Text(vault.name)
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // URL Input
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                Text("URL")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textPrimary)
                                    .fontWeight(.semibold)
                                
                                TextField("https://example.com/image.jpg", text: $urlString)
                                    .font(theme.typography.body)
                                    .keyboardType(.URL)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(UnifiedTheme.Spacing.md)
                                    .background(colors.surface)
                                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                                    .onChange(of: urlString) { oldValue, newValue in
                                        validateURL(newValue)
                                    }
                                
                                if !urlString.isEmpty && !isValidURL {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(colors.error)
                                            .font(.caption)
                                        Text("Please enter a valid URL")
                                            .font(theme.typography.caption)
                                            .foregroundColor(colors.error)
                                    }
                                }
                            }
                        }
                        
                        // Supported Types Info
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(colors.info)
                                    Text("Supported Formats")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textPrimary)
                                        .fontWeight(.semibold)
                                }
                                
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                    SupportedFormatRow(icon: "photo.fill", text: "Images (JPEG, PNG, HEIC, GIF, WebP)", colors: colors)
                                    SupportedFormatRow(icon: "video.fill", text: "Videos (MP4, MOV, WebM)", colors: colors)
                                    SupportedFormatRow(icon: "doc.fill", text: "Documents (PDF, TXT)", colors: colors)
                                    SupportedFormatRow(icon: "waveform", text: "Audio (MP3, WAV, M4A)", colors: colors)
                                }
                            }
                        }
                        
                        // Download Progress
                        if downloadService.isDownloading {
                            StandardCard {
                                VStack(spacing: UnifiedTheme.Spacing.md) {
                                    ProgressView(value: downloadService.downloadProgress)
                                        .progressViewStyle(.linear)
                                        .tint(colors.primary)
                                    
                                    Text("Downloading... \(Int(downloadService.downloadProgress * 100))%")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                        }
                        
                        // Download Button
                        Button {
                            downloadAndSave()
                        } label: {
                            HStack {
                                if downloadService.isDownloading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Download & Save")
                                }
                            }
                            .font(theme.typography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(UnifiedTheme.Spacing.md)
                            .background(isValidURL && !downloadService.isDownloading ? colors.primary : colors.surface)
                            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        .disabled(!isValidURL || downloadService.isDownloading)
                        .padding(.bottom, UnifiedTheme.Spacing.xl)
                    }
                    .padding(UnifiedTheme.Spacing.md)
                }
            }
            .navigationTitle("Download from URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        downloadService.cancelDownload()
                        dismiss()
                    }
                    .foregroundColor(colors.textPrimary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Successfully downloaded and saved '\(downloadedFileName)' to vault")
            }
        }
    }
    
    private func validateURL(_ urlString: String) {
        guard !urlString.isEmpty else {
            isValidURL = false
            return
        }
        
        // Basic URL validation
        if let url = URL(string: urlString),
           let scheme = url.scheme,
           (scheme == "http" || scheme == "https"),
           url.host != nil {
            isValidURL = true
        } else {
            isValidURL = false
        }
    }
    
    private func downloadAndSave() {
        guard isValidURL else { return }
        
        Task {
            do {
                // Download the asset
                let (data, mimeType, fileName) = try await downloadService.downloadAsset(from: urlString)
                
                // Upload to vault using DocumentService
                documentService.configure(modelContext: modelContext)
                let document = try await documentService.uploadDocument(
                    data: data,
                    name: fileName,
                    mimeType: mimeType,
                    to: vault,
                    uploadMethod: .urlDownload // Classify as sink (downloaded from external source)
                )
                
                await MainActor.run {
                    downloadedFileName = document.name
                    showSuccess = true
                }
                
                print("✅ Successfully downloaded and saved: \(fileName)")
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
                print("❌ Error downloading asset: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Supporting Views

struct SupportedFormatRow: View {
    let icon: String
    let text: String
    let colors: UnifiedTheme.Colors
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(colors.primary)
                .frame(width: 20)
            Text(text)
                .font(theme.typography.caption)
                .foregroundColor(colors.textSecondary)
        }
    }
    
    @Environment(\.unifiedTheme) var theme
}


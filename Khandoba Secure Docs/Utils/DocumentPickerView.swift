//
//  DocumentPickerView.swift
//  Khandoba Secure Docs
//
//  Import documents from external apps (WhatsApp, etc.)

import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    let vault: Vault
    let onDocumentPicked: (URL) -> Void
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Support all common document types including media from WhatsApp
        let supportedTypes: [UTType] = [
            .pdf,
            .image,
            .movie,
            .audio,
            .text,
            .plainText,
            .rtf,
            .zip,
            .data
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                parent.onDismiss()
                return
            }
            
            // File is copied to temp location, we can access it
            parent.onDocumentPicked(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onDismiss()
        }
    }
}

// SwiftUI wrapper for easier usage
struct DocumentImportButton: View {
    let vault: Vault
    @EnvironmentObject var documentService: DocumentService
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showPicker = false
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button {
            showPicker = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(colors.primary)
                Text("Import from Other Apps")
                    .font(theme.typography.body)
                    .foregroundColor(colors.textPrimary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
        }
        .disabled(isUploading)
        .sheet(isPresented: $showPicker) {
            DocumentPickerView(
                vault: vault,
                onDocumentPicked: { url in
                    handleImportedDocument(url)
                },
                onDismiss: {
                    showPicker = false
                }
            )
        }
        .alert("Upload Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isUploading {
                ZStack {
                    Color.black.opacity(0.3)
                    ProgressView("Importing...")
                        .padding()
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                }
            }
        }
    }
    
    private func handleImportedDocument(_ url: URL) {
        isUploading = true
        showPicker = false
        
        Task {
            do {
                // Start accessing security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    throw DocumentImportError.accessDenied
                }
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                // Read the file data
                let data = try Data(contentsOf: url)
                let fileName = url.lastPathComponent
                let mimeType = url.mimeType() ?? "application/octet-stream"
                
                // Upload to vault (marked as "sink" type - from external source)
                _ = try await documentService.uploadDocument(
                    data: data,
                    name: fileName,
                    mimeType: mimeType,
                    to: vault,
                    uploadMethod: .files
                )
                
                isUploading = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isUploading = false
            }
        }
    }
}

// Helper extension to get MIME type
extension URL {
    func mimeType() -> String? {
        if let typeID = try? resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
           let utType = UTType(typeID) {
            return utType.preferredMIMEType
        }
        // Fallback to file extension
        let ext = pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic": return "image/heic"
        case "gif": return "image/gif"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "pdf": return "application/pdf"
        case "txt": return "text/plain"
        default: return "application/octet-stream"
        }
    }
}

enum DocumentImportError: Error, LocalizedError {
    case accessDenied
    case invalidData
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Cannot access the selected file. Please try again."
        case .invalidData:
            return "The selected file appears to be corrupted or invalid."
        case .uploadFailed:
            return "Failed to upload the document. Please try again."
        }
    }
}


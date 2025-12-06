//
//  ShareExtensionView.swift
//  Khandoba Secure Docs Share Extension
//
//  SwiftUI view for the share extension
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ShareExtensionView: View {
    let extensionContext: NSExtensionContext
    let onComplete: () -> Void
    
    @State private var sharedItems: [SharedItem] = []
    @State private var availableVaults: [Vault] = []
    @State private var selectedVault: Vault?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var saveProgress: Double = 0
    
    // App Group identifier for sharing data between app and extension
    private let appGroupIdentifier = "group.com.khandoba.securedocs"
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading...")
                } else if sharedItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("No items to share")
                            .font(.headline)
                        Text("Please select images, videos, or files to share")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Shared items preview
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Items to Save")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(sharedItems) { item in
                                    SharedItemRow(item: item)
                                }
                            }
                            .padding(.vertical)
                            
                            // Vault selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Vault")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                if availableVaults.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "lock.shield")
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                        Text("No vaults available")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Please create a vault in the main app first")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                } else {
                                    ForEach(availableVaults) { vault in
                                        VaultSelectionRow(
                                            vault: vault,
                                            isSelected: selectedVault?.id == vault.id
                                        ) {
                                            selectedVault = vault
                                        }
                                    }
                                }
                            }
                            .padding(.vertical)
                            
                            // Save button
                            if let selectedVault = selectedVault {
                                Button {
                                    saveItems()
                                } label: {
                                    HStack {
                                        if isSaving {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "square.and.arrow.down")
                                            Text("Save to Vault")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isSaving ? Color.gray : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .disabled(isSaving || selectedVault == nil)
                                .padding(.horizontal)
                                
                                if isSaving {
                                    ProgressView(value: saveProgress)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Save to Khandoba")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onComplete()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .task {
            await loadSharedItems()
            await loadVaults()
        }
    }
    
    // MARK: - Load Shared Items
    
    private func loadSharedItems() async {
        guard let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        var items: [SharedItem] = []
        
        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            
            for attachment in attachments {
                // Handle images
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    if let data = try? await attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) as? Data,
                       let image = UIImage(data: data) {
                        items.append(SharedItem(
                            id: UUID(),
                            type: .image,
                            data: data,
                            name: "image_\(Date().timeIntervalSince1970).jpg",
                            mimeType: "image/jpeg"
                        ))
                    } else if let url = try? await attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) as? URL,
                              let data = try? Data(contentsOf: url) {
                        items.append(SharedItem(
                            id: UUID(),
                            type: .image,
                            data: data,
                            name: url.lastPathComponent,
                            mimeType: mimeTypeForURL(url)
                        ))
                    }
                }
                // Handle videos
                else if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    if let url = try? await attachment.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) as? URL,
                       let data = try? Data(contentsOf: url) {
                        items.append(SharedItem(
                            id: UUID(),
                            type: .video,
                            data: data,
                            name: url.lastPathComponent,
                            mimeType: "video/mp4"
                        ))
                    }
                }
                // Handle URLs
                else if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = try? await attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) as? URL {
                        // Try to load as image/video if it's a file URL
                        if url.isFileURL {
                            if let data = try? Data(contentsOf: url) {
                                let type = determineType(from: url)
                                items.append(SharedItem(
                                    id: UUID(),
                                    type: type,
                                    data: data,
                                    name: url.lastPathComponent,
                                    mimeType: mimeTypeForURL(url)
                                ))
                            }
                        } else {
                            // Web URL - save as text document
                            let urlString = url.absoluteString
                            if let data = urlString.data(using: .utf8) {
                                items.append(SharedItem(
                                    id: UUID(),
                                    type: .text,
                                    data: data,
                                    name: "\(url.host ?? "link")_\(Date().timeIntervalSince1970).txt",
                                    mimeType: "text/plain"
                                ))
                            }
                        }
                    }
                }
                // Handle files
                else if attachment.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
                    if let url = try? await attachment.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) as? URL,
                       let data = try? Data(contentsOf: url) {
                        items.append(SharedItem(
                            id: UUID(),
                            type: .file,
                            data: data,
                            name: url.lastPathComponent,
                            mimeType: mimeTypeForURL(url)
                        ))
                    }
                }
            }
        }
        
        await MainActor.run {
            sharedItems = items
            isLoading = false
        }
    }
    
    // MARK: - Load Vaults
    
    private func loadVaults() async {
        // Load vaults from shared App Group storage
        // Since SwiftData doesn't work in extensions, we'll use UserDefaults
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        // Get vault data from shared storage
        // Note: This requires the main app to sync vault info to UserDefaults
        if let vaultData = sharedDefaults.data(forKey: "available_vaults"),
           let vaults = try? JSONDecoder().decode([VaultInfo].self, from: vaultData) {
            await MainActor.run {
                // Convert to Vault objects (simplified for extension)
                // In a real implementation, you'd need to persist vaults differently
                availableVaults = vaults.map { info in
                    let vault = Vault(name: info.name)
                    vault.id = info.id
                    return vault
                }
                
                // Select first vault by default
                if selectedVault == nil, let firstVault = availableVaults.first {
                    selectedVault = firstVault
                }
            }
        }
    }
    
    // MARK: - Save Items
    
    private func saveItems() {
        guard let selectedVault = selectedVault else { return }
        
        isSaving = true
        saveProgress = 0
        
        Task {
            do {
                // Save items to shared storage for main app to process
                guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
                    throw ShareExtensionError.appGroupNotAvailable
                }
                
                // Create pending uploads
                var pendingUploads: [[String: Any]] = []
                
                for (index, item) in sharedItems.enumerated() {
                    let uploadInfo: [String: Any] = [
                        "id": UUID().uuidString,
                        "vaultID": selectedVault.id.uuidString,
                        "data": item.data.base64EncodedString(),
                        "name": item.name,
                        "mimeType": item.mimeType,
                        "uploadMethod": "share_extension",
                        "timestamp": Date().timeIntervalSince1970
                    ]
                    pendingUploads.append(uploadInfo)
                    
                    saveProgress = Double(index + 1) / Double(sharedItems.count)
                }
                
                // Save to shared defaults
                if let uploadsData = try? JSONSerialization.data(withJSONObject: pendingUploads) {
                    sharedDefaults.set(uploadsData, forKey: "pending_share_uploads")
                    sharedDefaults.synchronize()
                    
                    // Notify main app
                    let notification = NotificationCenter.default
                    notification.post(name: NSNotification.Name("ShareExtensionDidSaveItems"), object: nil)
                }
                
                await MainActor.run {
                    isSaving = false
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSaving = false
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineType(from url: URL) -> SharedItemType {
        let ext = url.pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "heic", "gif", "bmp"].contains(ext) {
            return .image
        } else if ["mp4", "mov", "avi", "m4v"].contains(ext) {
            return .video
        } else if ["pdf"].contains(ext) {
            return .file
        } else {
            return .file
        }
    }
    
    private func mimeTypeForURL(_ url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "heic": return "image/heic"
        case "gif": return "image/gif"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "pdf": return "application/pdf"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Supporting Types

struct SharedItem: Identifiable {
    let id: UUID
    let type: SharedItemType
    let data: Data
    let name: String
    let mimeType: String
}

enum SharedItemType {
    case image
    case video
    case text
    case file
    
    var icon: String {
        switch self {
        case .image: return "photo"
        case .video: return "video"
        case .text: return "doc.text"
        case .file: return "doc"
        }
    }
}

// VaultInfo is defined in ShareExtensionService.swift

struct SharedItemRow: View {
    let item: SharedItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(ByteCountFormatter.string(fromByteCount: Int64(item.data.count), countStyle: .file))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct VaultSelectionRow: View {
    let vault: Vault
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.blue)
                
                Text(vault.name)
                    .font(.body)
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
}

enum ShareExtensionError: LocalizedError {
    case appGroupNotAvailable
    case noVaultSelected
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .appGroupNotAvailable:
            return "Unable to access shared storage"
        case .noVaultSelected:
            return "Please select a vault"
        case .saveFailed:
            return "Failed to save items"
        }
    }
}


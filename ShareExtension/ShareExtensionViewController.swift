//
//  ShareExtensionViewController.swift
//  Khandoba Secure Docs
//
//  Share Extension for importing media from other apps
//

import UIKit
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import MobileCoreServices

class ShareExtensionViewController: UIViewController {
    private var hostingController: UIHostingController<ShareExtensionView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get shared items from extension context
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            showError("No items to share")
            return
        }
        
        // Load shared items
        loadSharedItems(from: inputItems) { [weak self] items in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if items.isEmpty {
                    self.showError("No supported items found")
                    return
                }
                
                // Create SwiftUI view
                let shareView = ShareExtensionView(
                    sharedItems: items,
                    onComplete: { [weak self] in
                        self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                    },
                    onCancel: { [weak self] in
                        self?.extensionContext?.cancelRequest(completionHandler: nil)
                    }
                )
                
                let hostingController = UIHostingController(rootView: shareView)
                self.addChild(hostingController)
                self.view.addSubview(hostingController.view)
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                    hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
                ])
                hostingController.didMove(toParent: self)
                self.hostingController = hostingController
            }
        }
    }
    
    private func loadSharedItems(from inputItems: [NSExtensionItem], completion: @escaping ([SharedItem]) -> Void) {
        var sharedItems: [SharedItem] = []
        let group = DispatchGroup()
        
        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            
            for attachment in attachments {
                group.enter()
                
                // Check if it's an image
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { data, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("Error loading image: \(error.localizedDescription)")
                            return
                        }
                        
                        if let image = data as? UIImage {
                            if let imageData = image.jpegData(compressionQuality: 0.8) {
                                sharedItems.append(SharedItem(
                                    data: imageData,
                                    type: .image,
                                    name: "Image_\(Date().timeIntervalSince1970).jpg",
                                    mimeType: "image/jpeg"
                                ))
                            }
                        } else if let url = data as? URL {
                            if let imageData = try? Data(contentsOf: url) {
                                sharedItems.append(SharedItem(
                                    data: imageData,
                                    type: .image,
                                    name: url.lastPathComponent,
                                    mimeType: url.mimeType() ?? "image/jpeg"
                                ))
                            }
                        } else if let data = data as? Data {
                            sharedItems.append(SharedItem(
                                data: data,
                                type: .image,
                                name: "Image_\(Date().timeIntervalSince1970).jpg",
                                mimeType: "image/jpeg"
                            ))
                        }
                    }
                }
                // Check if it's a video
                else if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { data, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("Error loading video: \(error.localizedDescription)")
                            return
                        }
                        
                        if let url = data as? URL {
                            if let videoData = try? Data(contentsOf: url) {
                                sharedItems.append(SharedItem(
                                    data: videoData,
                                    type: .video,
                                    name: url.lastPathComponent,
                                    mimeType: url.mimeType() ?? "video/mp4"
                                ))
                            }
                        }
                    }
                }
                // Check if it's a file
                else if attachment.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) { data, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("Error loading file: \(error.localizedDescription)")
                            return
                        }
                        
                        if let url = data as? URL {
                            if let fileData = try? Data(contentsOf: url) {
                                sharedItems.append(SharedItem(
                                    data: fileData,
                                    type: .file,
                                    name: url.lastPathComponent,
                                    mimeType: url.mimeType() ?? "application/octet-stream"
                                ))
                            }
                        } else if let data = data as? Data {
                            sharedItems.append(SharedItem(
                                data: data,
                                type: .file,
                                name: "File_\(Date().timeIntervalSince1970)",
                                mimeType: "application/octet-stream"
                            ))
                        }
                    }
                }
                // Check if it's a URL
                else if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("Error loading URL: \(error.localizedDescription)")
                            return
                        }
                        
                        if let url = data as? URL {
                            // For URLs, we'll create a text document with the URL
                            if let urlData = url.absoluteString.data(using: .utf8) {
                                sharedItems.append(SharedItem(
                                    data: urlData,
                                    type: .url,
                                    name: "\(url.host ?? "Link")_\(Date().timeIntervalSince1970).txt",
                                    mimeType: "text/plain"
                                ))
                            }
                        }
                    }
                } else {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(sharedItems)
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.extensionContext?.cancelRequest(completionHandler: nil)
        })
        present(alert, animated: true)
    }
}

// MARK: - Shared Item Model

struct SharedItem: Identifiable {
    let id = UUID()
    let data: Data
    let type: ItemType
    let name: String
    let mimeType: String
    
    enum ItemType {
        case image
        case video
        case file
        case url
        
        var icon: String {
            switch self {
            case .image: return "photo.fill"
            case .video: return "video.fill"
            case .file: return "doc.fill"
            case .url: return "link"
            }
        }
    }
}

// MARK: - SwiftUI Share Extension View

struct ShareExtensionView: View {
    let sharedItems: [SharedItem]
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    @State private var selectedVault: Vault?
    @State private var vaults: [Vault] = []
    @State private var isLoading = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var uploadedCount = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading vaults...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if vaults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Vaults Available")
                            .font(.headline)
                        Text("Please create a vault in the app first")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Shared Items Preview
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Items to Import")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(sharedItems) { item in
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
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top)
                            
                            // Vault Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Vault")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(vaults) { vault in
                                    Button {
                                        selectedVault = vault
                                    } label: {
                                        HStack {
                                            Image(systemName: selectedVault?.id == vault.id ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedVault?.id == vault.id ? .blue : .secondary)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(vault.name)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                                if let description = vault.vaultDescription {
                                                    Text(description)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        .background(selectedVault?.id == vault.id ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
                                        .cornerRadius(10)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Upload Button
                            if let vault = selectedVault {
                                Button {
                                    uploadItems(to: vault)
                                } label: {
                                    HStack {
                                        if isUploading {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "arrow.up.circle.fill")
                                            Text("Import to \(vault.name)")
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isUploading ? Color.gray : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .disabled(isUploading || selectedVault == nil)
                                .padding(.horizontal)
                                
                                if isUploading {
                                    ProgressView(value: uploadProgress)
                                        .padding(.horizontal)
                                    
                                    Text("Uploaded \(uploadedCount) of \(sharedItems.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Import to Khandoba")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadVaults()
            }
        }
    }
    
    private func loadVaults() {
        isLoading = true
        
        // Load vaults from shared container
        Task {
            do {
                // Create model container for extension
                let schema = Schema([Vault.self, User.self])
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
                
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                let context = container.mainContext
                
                // Fetch vaults
                let descriptor = FetchDescriptor<Vault>(
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                
                let fetchedVaults = try context.fetch(descriptor)
                
                await MainActor.run {
                    vaults = fetchedVaults.filter { !$0.isSystemVault }
                    isLoading = false
                    
                    // Auto-select first vault if available
                    if selectedVault == nil, let firstVault = vaults.first {
                        selectedVault = firstVault
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load vaults: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func uploadItems(to vault: Vault) {
        guard !isUploading else { return }
        
        isUploading = true
        uploadProgress = 0
        uploadedCount = 0
        
        Task {
            do {
                // Create model container and document service
                let schema = Schema([Vault.self, Document.self, User.self])
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
                
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                let context = container.mainContext
                
                // Reload vault from context
                let vaultDescriptor = FetchDescriptor<Vault>(
                    predicate: #Predicate { $0.id == vault.id }
                )
                
                guard let vaultInContext = try context.fetch(vaultDescriptor).first else {
                    throw NSError(domain: "ShareExtension", code: 1, userInfo: [NSLocalizedDescriptionKey: "Vault not found"])
                }
                
                // Upload each item
                for (index, item) in sharedItems.enumerated() {
                    // Create document
                    let document = Document(
                        name: item.name,
                        fileExtension: (item.name as NSString).pathExtension,
                        mimeType: item.mimeType,
                        fileSize: Int64(item.data.count),
                        documentType: item.type == .image ? "image" : (item.type == .video ? "video" : "other")
                    )
                    
                    document.encryptedFileData = item.data
                    document.isEncrypted = true
                    document.sourceSinkType = "sink" // Imported from external app
                    document.vault = vaultInContext
                    
                    context.insert(document)
                    
                    uploadedCount = index + 1
                    uploadProgress = Double(uploadedCount) / Double(sharedItems.count)
                }
                
                try context.save()
                
                await MainActor.run {
                    isUploading = false
                    // Small delay to show completion
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onComplete()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to upload: \(error.localizedDescription)"
                    showError = true
                    isUploading = false
                }
            }
        }
    }
}

// MARK: - URL Extension

extension URL {
    func mimeType() -> String? {
        if let uti = UTType(filenameExtension: pathExtension) {
            return uti.preferredMIMEType
        }
        return nil
    }
}


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
                        let error = NSError(domain: "ShareExtension", code: 0, userInfo: [NSLocalizedDescriptionKey: "User cancelled"])
                        self?.extensionContext?.cancelRequest(withError: error)
                    }
                )
                
                let hostingController = UIHostingController(rootView: shareView)
                self.addChild(hostingController)
                hostingController.view.frame = self.view.bounds
                hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.view.addSubview(hostingController.view)
                hostingController.didMove(toParent: self)
                
                self.hostingController = hostingController
            }
        }
    }
    
    // MARK: - Load Shared Items
    
    private func loadSharedItems(from inputItems: [NSExtensionItem], completion: @escaping ([SharedItem]) -> Void) {
        var sharedItems: [SharedItem] = []
        let group = DispatchGroup()
        
        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            
            for attachment in attachments {
                group.enter()
                
                // Check content type
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { (data, error) in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("❌ Error loading image: \(error.localizedDescription)")
                            return
                        }
                        
                        if let url = data as? URL {
                            if let imageData = try? Data(contentsOf: url),
                               let image = UIImage(data: imageData) {
                                let mimeType = url.mimeType() ?? "image/jpeg"
                                sharedItems.append(SharedItem(
                                    data: imageData,
                                    mimeType: mimeType,
                                    name: url.lastPathComponent
                                ))
                            }
                        } else if let image = data as? UIImage,
                                  let imageData = image.jpegData(compressionQuality: 0.8) {
                            sharedItems.append(SharedItem(
                                data: imageData,
                                mimeType: "image/jpeg",
                                name: "image_\(Date().timeIntervalSince1970).jpg"
                            ))
                        }
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { (data, error) in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("❌ Error loading video: \(error.localizedDescription)")
                            return
                        }
                        
                        if let url = data as? URL {
                            if let videoData = try? Data(contentsOf: url) {
                                let mimeType = url.mimeType() ?? "video/mp4"
                                sharedItems.append(SharedItem(
                                    data: videoData,
                                    mimeType: mimeType,
                                    name: url.lastPathComponent
                                ))
                            }
                        }
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) { (data, error) in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("❌ Error loading file: \(error.localizedDescription)")
                            return
                        }
                        
                        if let url = data as? URL {
                            if let fileData = try? Data(contentsOf: url) {
                                let mimeType = url.mimeType() ?? "application/octet-stream"
                                sharedItems.append(SharedItem(
                                    data: fileData,
                                    mimeType: mimeType,
                                    name: url.lastPathComponent
                                ))
                            }
                        } else if let fileData = data as? Data {
                            sharedItems.append(SharedItem(
                                data: fileData,
                                mimeType: "application/octet-stream",
                                name: "file_\(Date().timeIntervalSince1970)"
                            ))
                        }
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (data, error) in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("❌ Error loading text: \(error.localizedDescription)")
                            return
                        }
                        
                        if let text = data as? String,
                           let textData = text.data(using: .utf8) {
                                sharedItems.append(SharedItem(
                                data: textData,
                                mimeType: "text/plain",
                                name: "note_\(Date().timeIntervalSince1970).txt"
                                ))
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
            let error = NSError(domain: "ShareExtension", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
            self?.extensionContext?.cancelRequest(withError: error)
        })
        present(alert, animated: true)
    }
}

// MARK: - Shared Item Model

struct SharedItem {
    let data: Data
    let mimeType: String
    let name: String
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
    @State private var colorScheme: ColorScheme = .dark
    
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
                } else if isUploading {
                    VStack(spacing: 16) {
                        ProgressView(value: uploadProgress)
                        Text("Uploading \(uploadedCount) of \(sharedItems.count) items...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Items summary
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(sharedItems.count) item(s) to upload")
                                    .font(.headline)
                                
                                ForEach(Array(sharedItems.enumerated()), id: \.offset) { index, item in
                                    HStack {
                                        Image(systemName: iconForMimeType(item.mimeType))
                                            Text(item.name)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                        Spacer()
                                            Text(ByteCountFormatter.string(fromByteCount: Int64(item.data.count), countStyle: .file))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            
                            // Vault selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select Vault")
                                    .font(.headline)
                                
                                if vaults.isEmpty {
                                    VStack(spacing: 8) {
                                        Text("No vaults available")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Text("Create a vault in the main app first")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                ForEach(vaults) { vault in
                                    Button {
                                        selectedVault = vault
                                    } label: {
                                        HStack {
                                            Image(systemName: selectedVault?.id == vault.id ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(selectedVault?.id == vault.id ? .blue : .gray)
                                                Text(vault.name)
                                                    .foregroundColor(.primary)
                                            Spacer()
                                        }
                                        .padding()
                                            .background(selectedVault?.id == vault.id ? Color.blue.opacity(0.1) : Color(.systemBackground))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                                    }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            
                            // Upload button
                                Button {
                                uploadItems()
                                } label: {
                                Text("Upload to Vault")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedVault != nil ? Color.blue : Color.gray)
                                    .cornerRadius(12)
                                }
                            .disabled(selectedVault == nil || isUploading)
                            .padding()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Khandoba")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
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
    
    private func iconForMimeType(_ mimeType: String) -> String {
        if mimeType.hasPrefix("image/") {
            return "photo"
        } else if mimeType.hasPrefix("video/") {
            return "video"
        } else if mimeType.hasPrefix("audio/") {
            return "music.note"
        } else if mimeType == "application/pdf" {
            return "doc.fill"
        } else {
            return "doc"
        }
    }
    
    private func loadVaults() {
        isLoading = true
        
        Task {
            do {
                // Create ModelContainer for ShareExtension with same schema as main app
                // Use App Group to share data with main app
                let schema = Schema([
                    User.self,
                    UserRole.self,
                    Vault.self,
                    VaultSession.self,
                    VaultAccessLog.self,
                    DualKeyRequest.self,
                    Document.self,
                    DocumentVersion.self,
                    ChatMessage.self,
                    Nominee.self,
                    VaultTransferRequest.self,
                    EmergencyAccessRequest.self
                ])
                
                // Use App Group URL for shared storage
                let appGroupIdentifier = "group.com.khandoba.securedocs"
                let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
                
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    url: appGroupURL?.appendingPathComponent("KhandobaSecureDocs.store"),
                    cloudKitDatabase: .automatic
                )
                
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                let context = container.mainContext
                
                print("📦 ShareExtension: ModelContainer created")
                print("   App Group: \(appGroupIdentifier)")
                print("   Store URL: \(appGroupURL?.appendingPathComponent("KhandobaSecureDocs.store").path ?? "nil")")
                
                // Fetch vaults with a small delay to allow CloudKit sync
                // CloudKit might need a moment to sync vaults from main app
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                let descriptor = FetchDescriptor<Vault>(
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                
                let fetchedVaults = try context.fetch(descriptor)
                
                print("📦 ShareExtension: Found \(fetchedVaults.count) vault(s)")
                
                await MainActor.run {
                    vaults = fetchedVaults.filter { !$0.isSystemVault }
                    isLoading = false
                    
                    print("📦 ShareExtension: \(vaults.count) non-system vault(s) available")
                    
                    // Auto-select first vault if available
                    if selectedVault == nil, let firstVault = vaults.first {
                        selectedVault = firstVault
                        print("📦 ShareExtension: Auto-selected vault: \(firstVault.name)")
                    }
                    
                    if vaults.isEmpty {
                        print("⚠️ ShareExtension: No vaults available - user may need to create vaults in main app first")
                    }
                }
            } catch {
                print("❌ ShareExtension: Failed to load vaults: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to load vaults. Please ensure you have created at least one vault in the main app. Error: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func uploadItems() {
        guard let vault = selectedVault else { return }
        
        isUploading = true
        uploadedCount = 0
        
        Task {
            do {
                // Create ModelContainer with same configuration as loadVaults
                let schema = Schema([
                    User.self,
                    UserRole.self,
                    Vault.self,
                    VaultSession.self,
                    VaultAccessLog.self,
                    DualKeyRequest.self,
                    Document.self,
                    DocumentVersion.self,
                    ChatMessage.self,
                    Nominee.self,
                    VaultTransferRequest.self,
                    EmergencyAccessRequest.self
                ])
                
                // Use App Group URL for shared storage
                let appGroupIdentifier = "group.com.khandoba.securedocs"
                let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
                
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    url: appGroupURL?.appendingPathComponent("KhandobaSecureDocs.store"),
                    cloudKitDatabase: .automatic
                )
                
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                let context = container.mainContext
                
                // Reload vault from context
                let vaultID = vault.id
                let vaultDescriptor = FetchDescriptor<Vault>(
                    predicate: #Predicate { vault in vault.id == vaultID }
                )
                
                guard let vaultInContext = try context.fetch(vaultDescriptor).first else {
                    throw NSError(domain: "ShareExtension", code: 1, userInfo: [NSLocalizedDescriptionKey: "Vault not found"])
                }
                
                // Upload each item
                for (index, item) in sharedItems.enumerated() {
                    // Create document
                    let document = Document(
                        name: item.name,
                        mimeType: item.mimeType,
                        documentType: documentTypeForMimeType(item.mimeType)
                    )
                    
                    // Encrypt and store file data
                    document.encryptedFileData = item.data // In production, encrypt this
                    document.fileSize = Int64(item.data.count)
                    document.uploadedAt = Date()
                    document.sourceSinkType = "sink" // Shared from external app
                    
                    // Add to vault
                    document.vault = vaultInContext
                    if vaultInContext.documents == nil {
                        vaultInContext.documents = []
                    }
                    vaultInContext.documents?.append(document)
                    
                    context.insert(document)
                    try context.save()
                    
                    uploadedCount = index + 1
                    uploadProgress = Double(uploadedCount) / Double(sharedItems.count)
                }
                
                await MainActor.run {
                    isUploading = false
                        onComplete()
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                    errorMessage = "Upload failed: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func documentTypeForMimeType(_ mimeType: String) -> String {
        if mimeType.hasPrefix("image/") {
            return "image"
        } else if mimeType.hasPrefix("video/") {
            return "video"
        } else if mimeType.hasPrefix("audio/") {
            return "audio"
        } else if mimeType == "application/pdf" {
            return "pdf"
        } else if mimeType.hasPrefix("text/") {
            return "text"
        } else {
            return "file"
    }
}
}



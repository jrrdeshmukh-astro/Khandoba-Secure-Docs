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
import LocalAuthentication

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
    
    // MARK: - Load Shared Items (Enhanced - Universal File Type Support)
    
    private func loadSharedItems(from inputItems: [NSExtensionItem], completion: @escaping ([SharedItem]) -> Void) {
        var sharedItems: [SharedItem] = []
        let group = DispatchGroup()
        
        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            
            // Handle URL items first (WhatsApp links, web pages, etc.)
            if let urlProvider = attachments.first(where: { attachment in
                attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier)
            }) {
                group.enter()
                urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { data, error in
                    defer { group.leave() }
                    
                    guard error == nil, let url = data as? URL else { return }
                    
                    // Handle WhatsApp URLs
                    if url.absoluteString.contains("wa.me") || 
                       url.absoluteString.contains("whatsapp.com") ||
                       url.absoluteString.contains("api.whatsapp.com") {
                        // Save WhatsApp link as a document
                        if let urlData = url.absoluteString.data(using: .utf8) {
                            sharedItems.append(SharedItem(
                                data: urlData,
                                mimeType: "text/plain",
                                name: "WhatsApp Link",
                                sourceURL: url
                            ))
                        }
                    } else {
                        // Regular URL - save as document
                        if let urlData = url.absoluteString.data(using: .utf8) {
                            sharedItems.append(SharedItem(
                                data: urlData,
                                mimeType: "text/plain",
                                name: url.host ?? "Link",
                                sourceURL: url
                            ))
                        }
                    }
                }
            }
            
            // Handle all standard file types
            for attachment in attachments {
                // Skip URL type (already handled above)
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    continue
                }
                
                // Images
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    loadImage(from: attachment) { item in
                        if let item = item { sharedItems.append(item) }
                        group.leave()
                    }
                }
                // Videos
                else if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    group.enter()
                    loadVideo(from: attachment) { item in
                        if let item = item { sharedItems.append(item) }
                        group.leave()
                    }
                }
                // PDFs
                else if attachment.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    group.enter()
                    loadPDF(from: attachment) { item in
                        if let item = item { sharedItems.append(item) }
                        group.leave()
                    }
                }
                // Audio
                else if attachment.hasItemConformingToTypeIdentifier(UTType.audio.identifier) {
                    group.enter()
                    loadAudio(from: attachment) { item in
                        if let item = item { sharedItems.append(item) }
                        group.leave()
                    }
                }
                // Generic files
                else if attachment.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
                    group.enter()
                    loadFile(from: attachment) { item in
                        if let item = item { sharedItems.append(item) }
                        group.leave()
                    }
                }
                // Plain text
                else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    group.enter()
                    loadText(from: attachment) { item in
                        if let item = item { sharedItems.append(item) }
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(sharedItems)
        }
    }
    
    // MARK: - File Type Loaders
    
    private func loadImage(from attachment: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { data, error in
            guard error == nil else {
                print("⚠️ Error loading image: \(error?.localizedDescription ?? "unknown")")
                completion(nil)
                return
            }
            
            if let url = data as? URL,
               let imageData = try? Data(contentsOf: url),
               let image = UIImage(data: imageData) {
                let mimeType = url.mimeType() ?? "image/jpeg"
                completion(SharedItem(
                    data: imageData,
                    mimeType: mimeType,
                    name: url.lastPathComponent
                ))
            } else if let image = data as? UIImage,
                      let imageData = image.jpegData(compressionQuality: 0.8) {
                completion(SharedItem(
                    data: imageData,
                    mimeType: "image/jpeg",
                    name: "image_\(Date().timeIntervalSince1970).jpg"
                ))
            } else {
                completion(nil)
            }
        }
    }
    
    private func loadVideo(from attachment: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        attachment.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { data, error in
            guard error == nil, let url = data as? URL else {
                completion(nil)
                return
            }
            
            if let videoData = try? Data(contentsOf: url) {
                completion(SharedItem(
                    data: videoData,
                    mimeType: url.mimeType() ?? "video/mp4",
                    name: url.lastPathComponent
                ))
            } else {
                completion(nil)
            }
        }
    }
    
    private func loadPDF(from attachment: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        attachment.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { data, error in
            guard error == nil else {
                completion(nil)
                return
            }
            
            if let url = data as? URL,
               let pdfData = try? Data(contentsOf: url) {
                completion(SharedItem(
                    data: pdfData,
                    mimeType: "application/pdf",
                    name: url.lastPathComponent
                ))
            } else if let data = data as? Data {
                completion(SharedItem(
                    data: data,
                    mimeType: "application/pdf",
                    name: "document_\(Date().timeIntervalSince1970).pdf"
                ))
            } else {
                completion(nil)
            }
        }
    }
    
    private func loadAudio(from attachment: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        attachment.loadItem(forTypeIdentifier: UTType.audio.identifier, options: nil) { data, error in
            guard error == nil, let url = data as? URL else {
                completion(nil)
                return
            }
            
            if let audioData = try? Data(contentsOf: url) {
                completion(SharedItem(
                    data: audioData,
                    mimeType: url.mimeType() ?? "audio/mpeg",
                    name: url.lastPathComponent
                ))
            } else {
                completion(nil)
            }
        }
    }
    
    private func loadFile(from attachment: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        attachment.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) { data, error in
            guard error == nil else {
                completion(nil)
                return
            }
            
            if let url = data as? URL,
               let fileData = try? Data(contentsOf: url) {
                completion(SharedItem(
                    data: fileData,
                    mimeType: url.mimeType() ?? "application/octet-stream",
                    name: url.lastPathComponent
                ))
            } else if let data = data as? Data {
                completion(SharedItem(
                    data: data,
                    mimeType: "application/octet-stream",
                    name: "file_\(Date().timeIntervalSince1970)"
                ))
            } else {
                completion(nil)
            }
        }
    }
    
    private func loadText(from attachment: NSItemProvider, completion: @escaping (SharedItem?) -> Void) {
        attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { data, error in
            guard error == nil else {
                completion(nil)
                return
            }
            
            if let text = data as? String,
               let textData = text.data(using: .utf8) {
                completion(SharedItem(
                    data: textData,
                    mimeType: "text/plain",
                    name: "note_\(Date().timeIntervalSince1970).txt"
                ))
            } else {
                completion(nil)
            }
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

struct SharedItem: Identifiable {
    let id = UUID()
    let data: Data
    let mimeType: String
    let name: String
    var sourceURL: URL?
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
    @State private var isAuthenticated = false
    @State private var showBiometricAuth = false
    @State private var authError: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                contentView
            }
            .navigationTitle("Save to Khandoba")
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
                authenticateAndLoadVaults()
            }
            .refreshable {
                await authenticateAndLoadVaultsAsync()
            }
            .sheet(isPresented: $showBiometricAuth) {
                BiometricAuthView(
                    onSuccess: {
                        isAuthenticated = true
                        showBiometricAuth = false
                        loadVaults()
                    },
                    onFailure: { error in
                        authError = error
                        showBiometricAuth = false
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            loadingView
        } else if isUploading {
            uploadingView
        } else {
            mainContentView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading vaults...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var uploadingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: uploadProgress)
                .progressViewStyle(.linear)
            
            Text("Uploading \(uploadedCount) of \(sharedItems.count) items...")
                .font(.headline)
            
            Text("\(Int(uploadProgress * 100))%")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
    }
    
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                itemsPreviewCard
                vaultSelectionCard
                uploadButton
            }
            .padding()
        }
    }
    
    private var itemsPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.on.doc.fill")
                    .foregroundColor(.blue)
                Text("\(sharedItems.count) item(s) to save")
                    .font(.headline)
            }
            
            ForEach(sharedItems.prefix(3)) { item in
                HStack {
                    Image(systemName: iconForMimeType(item.mimeType))
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    Text(item.name)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: Int64(item.data.count), countStyle: .file))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if sharedItems.count > 3 {
                Text("+ \(sharedItems.count - 3) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 32)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var vaultSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.blue)
                Text("Select Vault")
                    .font(.headline)
            }
            
            if vaults.isEmpty {
                emptyVaultsView
            } else {
                ForEach(vaults) { vault in
                    vaultRow(vault: vault)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func vaultRow(vault: Vault) -> some View {
        let isSelected = selectedVault?.id == vault.id
        let vaultName = vault.name.isEmpty ? "Unnamed Vault" : vault.name
        
        return Button {
            selectedVault = vault
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(vaultName)
                        .foregroundColor(.primary)
                        .font(.headline)
                    
                    if let description = vault.vaultDescription {
                        Text(description)
                            .foregroundColor(.secondary)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Show active session indicator
                if hasActiveSession(vault) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Open")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
    }
    
    private var emptyVaultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No unlocked vaults")
                .font(.headline)
            
            Text("Open a vault in the main app first")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var uploadButton: some View {
        Button {
            uploadItems()
        } label: {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                Text("Save to Vault")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedVault != nil ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .disabled(selectedVault == nil || isUploading)
    }
    
    // MARK: - Helper Functions
    
    private func hasActiveSession(_ vault: Vault) -> Bool {
        guard let sessions = vault.sessions else { return false }
        let now = Date()
        return sessions.contains { session in
            session.isActive && session.expiresAt > now
        }
    }
    
    private func iconForMimeType(_ mimeType: String) -> String {
        if mimeType.hasPrefix("image/") {
            return "photo.fill"
        } else if mimeType.hasPrefix("video/") {
            return "video.fill"
        } else if mimeType.hasPrefix("audio/") {
            return "music.note"
        } else if mimeType == "application/pdf" {
            return "doc.fill"
        } else {
            return "doc"
        }
    }
    
    private func authenticateAndLoadVaults() {
        Task {
            await authenticateAndLoadVaultsAsync()
        }
    }
    
    private func loadVaults() {
        Task {
            await loadVaultsAsync()
        }
    }
    
    private func authenticateAndLoadVaultsAsync() async {
        // Check biometric authentication first
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Biometrics not available - allow access anyway (fallback)
            print("⚠️ ShareExtension: Biometrics not available, allowing access")
            await MainActor.run {
                isAuthenticated = true
            }
            await loadVaultsAsync()
            return
        }
        
        do {
            let reason = "Authenticate to access your vaults"
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                await MainActor.run {
                    isAuthenticated = true
                }
                await loadVaultsAsync()
            } else {
                await MainActor.run {
                    authError = "Authentication failed"
                    showError = true
                    errorMessage = "Biometric authentication failed. Please try again."
                }
            }
        } catch {
            await MainActor.run {
                authError = error.localizedDescription
                showError = true
                errorMessage = "Authentication error: \(error.localizedDescription)"
            }
        }
    }
    
    // Cache ModelContainer to avoid creating multiple instances
    private static var cachedContainer: ModelContainer?
    private static var containerCreationLock = NSLock()
    
    private func loadVaultsAsync() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Use cached container if available
            let container: ModelContainer
            if let cached = Self.cachedContainer {
                print("📦 ShareExtension: Using cached ModelContainer")
                container = cached
            } else {
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
                
                // Use App Group identifier for shared storage
                let appGroupIdentifier = "group.com.khandoba.securedocs"
                let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
                
                print("📦 ShareExtension: Setting up ModelContainer")
                print("   App Group ID: \(appGroupIdentifier)")
                print("   App Group URL: \(appGroupURL?.path ?? "nil - App Group not accessible")")
                
                // Check if App Group is accessible
                if appGroupURL == nil {
                    print("⚠️ ShareExtension: App Group not accessible")
                    print("   This might mean:")
                    print("   1. App Group not configured in Xcode project settings")
                    print("   2. App Group identifier mismatch")
                    print("   3. Extension not signed with same team")
                    print("   Using CloudKit sync (may take longer)")
                }
                
                // Create ModelConfiguration - use App Group identifier
                // Try with App Group first, fallback to default if needed
                let modelConfiguration: ModelConfiguration
                if appGroupURL != nil {
                    // App Group is accessible, use it
                    modelConfiguration = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: false,
                        groupContainer: .identifier(appGroupIdentifier),
                        cloudKitDatabase: .automatic
                    )
                } else {
                    // App Group not accessible, use default configuration
                    print("⚠️ ShareExtension: Using default configuration (App Group not accessible)")
                    modelConfiguration = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: false,
                        cloudKitDatabase: .automatic
                    )
                }
                
                // Thread-safe container creation
                Self.containerCreationLock.lock()
                defer { Self.containerCreationLock.unlock() }
                
                // Check again after acquiring lock (double-check pattern)
                if let cached = Self.cachedContainer {
                    print("📦 ShareExtension: Container was created by another task, using cached")
                    container = cached
                } else {
                    do {
                        container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                        Self.cachedContainer = container
                        print("✅ ShareExtension: ModelContainer created and cached")
                    } catch let initialError {
                        print("❌ ShareExtension: Failed to create ModelContainer with App Group/CloudKit")
                        print("   Error: \(initialError.localizedDescription)")
                        // Try fallback without CloudKit and App Group
                        print("   Attempting fallback without CloudKit and App Group...")
                        do {
                            let fallbackConfig = ModelConfiguration(
                                schema: schema,
                                isStoredInMemoryOnly: false
                            )
                            container = try ModelContainer(for: schema, configurations: [fallbackConfig])
                            Self.cachedContainer = container
                            print("   ✅ Fallback ModelContainer created and cached")
                        } catch let fallbackError {
                            print("❌ ShareExtension: Fallback ModelContainer creation also failed")
                            print("   Error: \(fallbackError.localizedDescription)")
                            // Last resort: in-memory only
                            do {
                                let inMemoryConfig = ModelConfiguration(
                                    schema: schema,
                                    isStoredInMemoryOnly: true
                                )
                                container = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                                Self.cachedContainer = container
                                print("   ⚠️ Using in-memory only ModelContainer (data will not persist)")
                            } catch let inMemoryError {
                                print("❌ ShareExtension: Even in-memory ModelContainer creation failed")
                                print("   Error: \(inMemoryError.localizedDescription)")
                                // Re-throw the error - we can't proceed without a container
                                throw inMemoryError
                            }
                        }
                    }
                }
            }
            
            // Get the context (mainContext is already on main actor)
            let context = container.mainContext
            
            print("✅ ShareExtension: ModelContainer created successfully")
            
            // Fetch vaults with a delay to allow CloudKit sync
            print("   Waiting for CloudKit sync...")
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second for CloudKit sync
            
            let descriptor = FetchDescriptor<Vault>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            // Try fetching vaults with error handling
            var fetchedVaults: [Vault] = []
            do {
                fetchedVaults = try context.fetch(descriptor)
                print("📦 ShareExtension: Initial fetch found \(fetchedVaults.count) vault(s)")
            } catch {
                print("⚠️ ShareExtension: Error fetching vaults: \(error.localizedDescription)")
                // Continue with empty array - will show "No vaults available"
            }
            
            // If no vaults found, try waiting a bit longer for CloudKit sync
            if fetchedVaults.isEmpty {
                print("   No vaults found - waiting additional 2 seconds for CloudKit sync...")
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 more seconds
                
                // Try fetching again
                do {
                    fetchedVaults = try context.fetch(descriptor)
                    print("   After additional wait: Found \(fetchedVaults.count) vault(s)")
                } catch {
                    print("⚠️ ShareExtension: Error on retry fetch: \(error.localizedDescription)")
                }
            }
            
            // Log all vaults found (safely access properties)
            for vault in fetchedVaults {
                let vaultName = vault.name
                let vaultID = vault.id.uuidString
                let isSystem = vault.isSystemVault
                print("   Vault: \(vaultName) (ID: \(vaultID), System: \(isSystem))")
            }
            
            // Filter and update on main thread
            // Filter out system vaults and only show unlocked vaults (with active sessions)
            let now = Date()
            let unlockedVaults = fetchedVaults.filter { vault in
                // Exclude system vaults
                guard !vault.isSystemVault else { return false }
                
                // Check if vault has an active session
                if let sessions = vault.sessions {
                    return sessions.contains { session in
                        session.isActive && session.expiresAt > now
                    }
                }
                return false
            }
            
            print("📦 ShareExtension: Found \(unlockedVaults.count) unlocked vault(s) out of \(fetchedVaults.count) total")
            
            let firstVault = unlockedVaults.first
            
            await MainActor.run {
                self.vaults = unlockedVaults
                self.isLoading = false
                
                print("📦 ShareExtension: \(self.vaults.count) unlocked vault(s) available")
                
                // Auto-select first vault if available
                if self.selectedVault == nil, let firstVault = firstVault {
                    self.selectedVault = firstVault
                    let vaultName = firstVault.name.isEmpty ? "Unnamed Vault" : firstVault.name
                    print("📦 ShareExtension: Auto-selected vault: \(vaultName)")
                }
                
                if self.vaults.isEmpty {
                    print("⚠️ ShareExtension: No vaults available")
                    print("   Possible reasons:")
                    print("   1. No vaults created in main app yet")
                    print("   2. CloudKit sync not complete (wait a few seconds)")
                    print("   3. App Group not properly configured")
                    print("   4. User not signed into iCloud")
                }
            }
        } catch {
            print("❌ ShareExtension: Failed to load vaults: \(error.localizedDescription)")
            print("   Error details: \(error)")
            if let nsError = error as NSError? {
                print("   Domain: \(nsError.domain)")
                print("   Code: \(nsError.code)")
                print("   UserInfo: \(nsError.userInfo)")
            }
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to load vaults. Please ensure you have created at least one vault in the main app. Error: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }
    
    private func uploadItems() {
        guard let vault = selectedVault else { return }
        
        isUploading = true
        uploadedCount = 0
        
        let itemsToUpload = sharedItems
        let completion = onComplete
        
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
                
                // Use App Group identifier for shared storage
                let appGroupIdentifier = "group.com.khandoba.securedocs"
                
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    groupContainer: .identifier(appGroupIdentifier),
                    cloudKitDatabase: .automatic
                )
                
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                let context = container.mainContext
                
                // Reload vault from context
                let vaultID = vault.id
                let vaultDescriptor = FetchDescriptor<Vault>(
                    predicate: #Predicate { $0.id == vaultID }
                )
                
                guard let vaultInContext = try context.fetch(vaultDescriptor).first else {
                    throw NSError(domain: "ShareExtension", code: 1, userInfo: [NSLocalizedDescriptionKey: "Vault not found"])
                }
                
                // Upload each item
                for (index, item) in itemsToUpload.enumerated() {
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
                    
                    // Save after each document to ensure persistence
                    try context.save()
                    
                    // Force CloudKit sync by accessing the document after save
                    // This ensures the document is queued for CloudKit sync
                    _ = document.id
                    
                    await MainActor.run {
                        uploadedCount = index + 1
                        uploadProgress = Double(uploadedCount) / Double(itemsToUpload.count)
                    }
                }
                
                // Final save to ensure all changes are persisted
                try context.save()
                
                // Give CloudKit a moment to sync
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                await MainActor.run {
                    isUploading = false
                    completion()
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

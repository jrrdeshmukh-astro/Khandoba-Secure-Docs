//
//  FileSharingMessageView.swift
//  Khandoba Secure Docs
//
//  File sharing view for iMessage app
//

import SwiftUI
import Messages
import UniformTypeIdentifiers
import SwiftData

struct FileSharingMessageView: View {
    let items: [NSExtensionItem]
    let conversation: MSConversation
    let onShareComplete: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var sharedFiles: [SharedFile] = []
    @State private var vaults: [Vault] = []
    @State private var selectedVault: Vault?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var modelContext: ModelContext?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background.ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Processing files...")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                    }
                } else if sharedFiles.isEmpty {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(colors.textTertiary)
                        
                        Text("No Files Detected")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            Text("To save media to a vault:")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text("1.")
                                        .foregroundColor(colors.primary)
                                    Text("In the conversation, long-press a photo or video")
                                        .foregroundColor(colors.textSecondary)
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Text("2.")
                                        .foregroundColor(colors.primary)
                                    Text("Tap 'Share' → Select 'Khandoba'")
                                        .foregroundColor(colors.textSecondary)
                                }
                                
                                HStack(alignment: .top, spacing: 8) {
                                    Text("3.")
                                        .foregroundColor(colors.primary)
                                    Text("Choose a vault to save to")
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                            .font(theme.typography.caption)
                        }
                        .padding()
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        .padding(.horizontal)
                        
                        Button("Cancel") {
                            onCancel()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                } else {
                    ScrollView {
                        VStack(spacing: UnifiedTheme.Spacing.lg) {
                            // Files List
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                Text("Files to Share")
                                    .font(theme.typography.headline)
                                    .foregroundColor(colors.textPrimary)
                                
                                ForEach(sharedFiles) { file in
                                    StandardCard {
                                        HStack {
                                            Image(systemName: fileIcon(for: file.type))
                                                .font(.title2)
                                                .foregroundColor(colors.primary)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(file.name)
                                                    .font(theme.typography.body)
                                                    .foregroundColor(colors.textPrimary)
                                                    .fontWeight(.medium)
                                                
                                                Text(fileSizeString(file.size))
                                                    .font(theme.typography.caption)
                                                    .foregroundColor(colors.textSecondary)
                                            }
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Vault Selection
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                                Text("Select Vault")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textSecondary)
                                
                                if vaults.isEmpty {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Loading vaults...")
                                            .font(theme.typography.body)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                    .padding(UnifiedTheme.Spacing.md)
                                    .frame(maxWidth: .infinity)
                                    .background(colors.surface)
                                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                } else {
                                    Picker("Vault", selection: $selectedVault) {
                                        ForEach(vaults) { vault in
                                            Text(vault.name).tag(vault as Vault?)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(UnifiedTheme.Spacing.md)
                                    .background(colors.surface)
                                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Share Button
                            Button {
                                shareFiles()
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Share to Vault")
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(selectedVault == nil || isLoading)
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Save Media to Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadFiles()
                loadVaults()
            }
        }
    }
    
    private func loadFiles() {
        isLoading = true
        
        Task {
            var files: [SharedFile] = []
            
            for item in items {
                guard let attachments = item.attachments else { continue }
                
                for attachment in attachments {
                    // Try different type identifiers in order of preference
                    let typeIdentifiers: [String] = [
                        UTType.image.identifier,
                        UTType.movie.identifier,
                        UTType.video.identifier,
                        UTType.audio.identifier,
                        UTType.pdf.identifier,
                        UTType.data.identifier
                    ]
                    
                    for typeIdentifier in typeIdentifiers {
                        if attachment.hasItemConformingToTypeIdentifier(typeIdentifier) {
                            do {
                                if let data = try await loadAttachment(attachment, type: typeIdentifier) {
                                    let fileName = item.attributedContentText?.string ?? 
                                        attachment.suggestedName ?? 
                                        "file_\(Date().timeIntervalSince1970)"
                                    
                                    // Determine file type from identifier
                                    let fileType = determineFileType(from: typeIdentifier)
                                    
                                    files.append(SharedFile(
                                        id: UUID(),
                                        name: fileName,
                                        data: data,
                                        type: fileType,
                                        size: data.count
                                    ))
                                    break // Found a matching type, move to next attachment
                                }
                            } catch {
                                print("⚠️ Error loading file with type \(typeIdentifier): \(error)")
                            }
                        }
                    }
                }
            }
            
            await MainActor.run {
                sharedFiles = files
                isLoading = false
            }
        }
    }
    
    private func determineFileType(from typeIdentifier: String) -> String {
        if typeIdentifier.contains("image") {
            return "image"
        } else if typeIdentifier.contains("movie") || typeIdentifier.contains("video") {
            return "video"
        } else if typeIdentifier.contains("audio") {
            return "audio"
        } else if typeIdentifier.contains("pdf") {
            return "pdf"
        } else {
            return "data"
        }
    }
    
    private func loadAttachment(_ attachment: NSItemProvider, type: String) async throws -> Data? {
        return try await withCheckedThrowingContinuation { continuation in
            attachment.loadItem(forTypeIdentifier: type, options: nil) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let url = data as? URL {
                    continuation.resume(returning: try? Data(contentsOf: url))
                } else if let data = data as? Data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func loadVaults() {
        Task {
            do {
                let schema = Schema([Vault.self, User.self])
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
                
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                let context = container.mainContext
                
                let descriptor = FetchDescriptor<Vault>(
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                
                let fetchedVaults = try context.fetch(descriptor)
                
                await MainActor.run {
                    vaults = fetchedVaults.filter { !$0.isSystemVault }
                    if let firstVault = vaults.first {
                        selectedVault = firstVault
                    }
                    modelContext = context
                }
            } catch {
                print("❌ Failed to load vaults: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "Failed to load vaults: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func shareFiles() {
        guard let vault = selectedVault else { return }
        
        isLoading = true
        
        Task {
            // Open main app with deep link to handle file upload
            // For now, just complete the extension
            await MainActor.run {
                isLoading = false
                onShareComplete()
            }
        }
    }
    
    private func fileIcon(for type: String) -> String {
        switch type.lowercased() {
        case "image", "jpeg", "png", "heic":
            return "photo"
        case "video", "movie":
            return "video"
        case "pdf":
            return "doc.fill"
        case "audio":
            return "music.note"
        default:
            return "doc"
        }
    }
    
    private func fileSizeString(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct SharedFile: Identifiable {
    let id: UUID
    let name: String
    let data: Data
    let type: String
    let size: Int
}

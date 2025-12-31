//
//  CloudStorageSourceView.swift
//  Khandoba Secure Docs
//
//  Cloud storage source configuration view
//

import SwiftUI

struct CloudStorageSourceView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var cloudStorageService = CloudStorageService.shared
    
    @State private var selectedProvider: CloudStorageProvider = .googleDrive
    @State private var isConnecting = false
    @State private var selectedFiles: [CloudFile] = []
    @State private var showFilePicker = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                Form {
                    Section("Cloud Storage Provider") {
                        Picker("Provider", selection: $selectedProvider) {
                            ForEach(CloudStorageProvider.allCases, id: \.self) { provider in
                                Text(provider.displayName).tag(provider)
                            }
                        }
                    }
                    
                    Section {
                        if cloudStorageService.connectedProviders.contains(selectedProvider) {
                            Button("Browse Files") {
                                showFilePicker = true
                            }
                        } else {
                            Button {
                                Task {
                                    await connectProvider()
                                }
                            } label: {
                                HStack {
                                    if isConnecting {
                                        ProgressView()
                                    } else {
                                        Text("Connect \(selectedProvider.displayName)")
                                    }
                                }
                            }
                            .disabled(isConnecting)
                        }
                    }
                }
                .navigationTitle("Cloud Storage")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showFilePicker) {
            CloudFilePickerView(
                provider: selectedProvider,
                selectedFiles: $selectedFiles
            )
        }
    }
    
    private func connectProvider() async {
        isConnecting = true
        defer { isConnecting = false }
        
        do {
            try await cloudStorageService.connectProvider(selectedProvider)
        } catch {
            print("Failed to connect cloud storage: \(error)")
        }
    }
}

private struct CloudFilePickerView: View {
    let provider: CloudStorageProvider
    @Binding var selectedFiles: [CloudFile]
    @Environment(\.dismiss) var dismiss
    @StateObject private var cloudStorageService = CloudStorageService.shared
    
    @State private var files: [CloudFile] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(files) { file in
                    FileRow(file: file, isSelected: selectedFiles.contains { $0.id == file.id }) {
                        if selectedFiles.contains(where: { $0.id == file.id }) {
                            selectedFiles.removeAll { $0.id == file.id }
                        } else {
                            selectedFiles.append(file)
                        }
                    }
                }
            }
            .navigationTitle("Select Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadFiles()
            }
        }
    }
    
    private func loadFiles() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            files = try await cloudStorageService.listFiles(provider: provider)
        } catch {
            print("Failed to load files: \(error)")
        }
    }
}

private struct FileRow: View {
    let file: CloudFile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: file.isFolder ? "folder.fill" : "doc.fill")
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                VStack(alignment: .leading) {
                    Text(file.name)
                    if let size = file.size {
                        Text(formatFileSize(size))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}


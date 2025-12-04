//
//  DocumentSearchView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct DocumentSearchView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vaultService: VaultService
    @EnvironmentObject var documentService: DocumentService
    
    @State private var searchText = ""
    @State private var searchResults: [Document] = []
    @State private var isSearching = false
    @State private var isSelectionMode = false
    @State private var selectedDocumentIDs: Set<UUID> = []
    @State private var showFilters = false
    @State private var filterType: DocumentFilterType = .all
    @State private var selectedTags: Set<String> = []
    @State private var isCompilingReport = false
    @State private var showSuccessAlert = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(colors.textSecondary)
                        
                        TextField("Search documents...", text: $searchText)
                            .font(theme.typography.body)
                            .textFieldStyle(.plain)
                            .onChange(of: searchText) { oldValue, newValue in
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                loadAllDocuments()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(colors.textTertiary)
                            }
                        }
                    }
                    .padding(UnifiedTheme.Spacing.md)
                    .background(colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                    .padding(.horizontal)
                    .padding(.vertical, UnifiedTheme.Spacing.sm)
                    
                    // Results
                    if isSearching {
                        LoadingView("Searching...")
                    } else if searchResults.isEmpty && !searchText.isEmpty {
                        EmptyStateView(
                            icon: "doc.questionmark",
                            title: "No Results",
                            message: "Try adjusting your search query"
                        )
                    } else if searchResults.isEmpty {
                        EmptyStateView(
                            icon: "lock.fill",
                            title: "No Documents",
                            message: "Unlock vaults to access documents. Documents only appear from vaults with active sessions."
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: UnifiedTheme.Spacing.sm) {
                                ForEach(filteredResults()) { document in
                                    HStack(spacing: UnifiedTheme.Spacing.md) {
                                        if isSelectionMode {
                                            Button {
                                                toggleSelection(document.id)
                                            } label: {
                                                Image(systemName: selectedDocumentIDs.contains(document.id) ?
                                                    "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(selectedDocumentIDs.contains(document.id) ?
                                                        colors.primary : colors.textTertiary)
                                                    .font(.title2)
                                            }
                                            .padding(.leading)
                                        }
                                        
                                        NavigationLink {
                                            DocumentPreviewView(document: document)
                                        } label: {
                                            DocumentRow(document: document)
                                        }
                                        .disabled(isSelectionMode)
                                    }
                                    .padding(.horizontal, isSelectionMode ? 0 : UnifiedTheme.Spacing.md)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle(isSelectionMode ? "\(selectedDocumentIDs.count) Selected" : "Documents")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectionMode {
                        Button("Cancel") {
                            isSelectionMode = false
                            selectedDocumentIDs.removeAll()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSelectionMode {
                        Button {
                            compileIntelReport()
                        } label: {
                            Label("Compile Intel Report", systemImage: "brain")
                        }
                        .disabled(selectedDocumentIDs.count < 2 || isCompilingReport)
                    } else {
                        Menu {
                            Button {
                                showFilters = true
                            } label: {
                                Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                            }
                            
                            Button {
                                isSelectionMode = true
                            } label: {
                                Label("Select for Intel Report", systemImage: "checkmark.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .onAppear {
                loadAllDocuments()
            }
            .sheet(isPresented: $showFilters) {
                DocumentFilterView(
                    filterType: $filterType,
                    selectedTags: $selectedTags,
                    searchText: $searchText,
                    allTags: getAllTags()
                )
            }
            .alert("Intel Report Created", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {
                    isSelectionMode = false
                    selectedDocumentIDs.removeAll()
                }
            } message: {
                Text("Intel report has been compiled and saved to your Intel Vault.")
            }
            .overlay {
                if isCompilingReport {
                    ZStack {
                        Color.black.opacity(0.5)
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Compiling Intel Report...")
                                .font(theme.typography.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(UnifiedTheme.Spacing.xl)
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                    }
                    .ignoresSafeArea()
                }
            }
        }
    }
    
    private func loadAllDocuments() {
        isSearching = true
        
        // Get documents only from unlocked vaults (with active sessions)
        var allDocuments: [Document] = []
        for vault in vaultService.vaults {
            // Only show documents from vaults with active sessions
            if vaultService.hasActiveSession(for: vault.id),
               let documents = vault.documents {
                allDocuments.append(contentsOf: documents)
            }
        }
        
        // Sort by most recent first
        searchResults = allDocuments.sorted { $0.uploadedAt > $1.uploadedAt }
        
        isSearching = false
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            loadAllDocuments()
            return
        }
        
        isSearching = true
        
        // Get only unlocked vaults (with active sessions)
        let unlockedVaults = vaultService.vaults.filter { vault in
            vaultService.hasActiveSession(for: vault.id)
        }
        
        // Search documents only in unlocked vaults
        searchResults = documentService.searchDocuments(query: searchText, in: unlockedVaults)
        
        isSearching = false
    }
    
    private func filteredResults() -> [Document] {
        var results = searchResults
        
        // Apply filter type
        if filterType != .all {
            results = results.filter { document in
                switch filterType {
                case .source:
                    return document.sourceSinkType == "source"
                case .sink:
                    return document.sourceSinkType == "sink"
                case .text:
                    return document.documentType == "text"
                case .image:
                    return document.documentType == "image"
                case .video:
                    return document.documentType == "video"
                case .audio:
                    return document.documentType == "audio"
                case .pdf:
                    return document.mimeType?.contains("pdf") ?? false
                default:
                    return true
                }
            }
        }
        
        // Apply tag filters
        if !selectedTags.isEmpty {
            results = results.filter { document in
                selectedTags.isSubset(of: Set(document.aiTags))
            }
        }
        
        return results
    }
    
    private func getAllTags() -> [String] {
        let allTags = searchResults.flatMap { $0.aiTags }
        return Array(Set(allTags)).sorted()
    }
    
    private func toggleSelection(_ documentID: UUID) {
        if selectedDocumentIDs.contains(documentID) {
            selectedDocumentIDs.remove(documentID)
        } else {
            selectedDocumentIDs.insert(documentID)
        }
    }
    
    private func compileIntelReport() {
        let selected = searchResults.filter { selectedDocumentIDs.contains($0.id) }
        
        guard selected.count >= 2 else { return }
        
        isCompilingReport = true
        
        Task { @MainActor in
            do {
                guard let currentUser = vaultService.currentUser,
                      let modelContext = documentService.modelContext else {
                    isCompilingReport = false
                    print("No current user or context found")
                    return
                }
                
                let intelService = IntelReportService()
                intelService.configure(modelContext: modelContext, vaultService: vaultService)
                
                // Use NEW clean method - generates pure insights
                let vaults = vaultService.vaults
                _ = await intelService.generateIntelReport(for: vaults)
                
                isCompilingReport = false
                showSuccessAlert = true
            } catch {
                isCompilingReport = false
                print("Failed to compile Intel report: \(error)")
            }
        }
    }
}


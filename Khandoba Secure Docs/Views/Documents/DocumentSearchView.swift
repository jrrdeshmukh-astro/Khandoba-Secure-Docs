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
    
    // Computed property for selected documents
    private var selectedDocuments: [Document] {
        searchResults.filter { selectedDocumentIDs.contains($0.id) }
    }
    
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
                            if isSelectionMode {
                                // List view for selection mode
                                LazyVStack(spacing: UnifiedTheme.Spacing.sm) {
                                    ForEach(filteredResults()) { document in
                                        HStack(spacing: UnifiedTheme.Spacing.md) {
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
                                            
                                            NavigationLink {
                                                DocumentPreviewView(document: document)
                                            } label: {
                                                DocumentRow(document: document)
                                            }
                                            .disabled(isSelectionMode)
                                        }
                                        .padding(.horizontal, UnifiedTheme.Spacing.md)
                                    }
                                }
                                .padding(.vertical)
                            } else {
                                // 3D Grid view for normal mode
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: UnifiedTheme.Spacing.md),
                                        GridItem(.flexible(), spacing: UnifiedTheme.Spacing.md)
                                    ],
                                    spacing: UnifiedTheme.Spacing.lg
                                ) {
                                    ForEach(Array(filteredResults().enumerated()), id: \.element.id) { index, document in
                                        NavigationLink {
                                            DocumentPreviewView(document: document)
                                        } label: {
                                            DocumentCard3D(
                                                document: document,
                                                colors: colors,
                                                theme: theme
                                            )
                                            .staggeredAppearance(index: index, total: filteredResults().count)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(UnifiedTheme.Spacing.md)
                            }
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
                        // Text Intel Report
                        NavigationLink {
                            TextIntelReportView(documents: selectedDocuments)
                        } label: {
                            Label("Intel Report", systemImage: "doc.text.magnifyingglass")
                        }
                        .disabled(selectedDocumentIDs.count < 2)
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
    
    // Intel Report compilation - ARCHIVED
}


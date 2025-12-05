//
//  TextIntelReportView.swift
//  Khandoba Secure Docs
//
//  Text-based Intel Reports - Reliable and readable
//

import SwiftUI
import SwiftData
import Combine

struct TextIntelReportView: View {
    let documents: [Document]
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vaultService: VaultService
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var textIntel = TextIntelligenceService()
    @StateObject private var graphService = ReasoningGraphService()
    @StateObject private var chatService = IntelChatService()
    
    @State private var debriefText: String = ""
    @State private var selectedVault: Vault?
    @State private var showVaultPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedTab: IntelTab = .debrief
    @State private var intelligenceData: IntelligenceData?
    
    enum IntelTab: String, CaseIterable {
        case debrief = "Debrief"
        case graph = "Graph"
        case chat = "Chat"
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: UnifiedTheme.Spacing.sm) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(colors.primary)
                    
                    Text("Intelligence Report")
                        .font(theme.typography.title)
                        .foregroundColor(colors.textPrimary)
                    
                    Text("\(documents.count) documents selected")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
                .padding()
                .background(colors.surface)
                
                Divider()
                
                if textIntel.isProcessing {
                    // Processing view
                    ProcessingView(service: textIntel, colors: colors, theme: theme)
                        .frame(maxHeight: .infinity)
                    
                } else if !debriefText.isEmpty {
                    // Tabbed interface
                    VStack(spacing: 0) {
                        // Tab selector
                        HStack(spacing: 0) {
                            ForEach(IntelTab.allCases, id: \.self) { tab in
                                Button {
                                    selectedTab = tab
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(tab.rawValue)
                                            .font(theme.typography.subheadline)
                                            .foregroundColor(selectedTab == tab ? colors.primary : colors.textSecondary)
                                        
                                        Rectangle()
                                            .fill(selectedTab == tab ? colors.primary : Color.clear)
                                            .frame(height: 2)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .background(colors.surface)
                        
                        Divider()
                        
                        // Tab content
                        TabView(selection: $selectedTab) {
                            // Debrief Tab
                            debriefTab(colors: colors)
                                .tag(IntelTab.debrief)
                            
                            // Graph Tab
                            if let graph = graphService.graph {
                                ReasoningGraphView(graph: graph)
                                    .tag(IntelTab.graph)
                            } else {
                                EmptyStateView(
                                    icon: "network",
                                    title: "No Graph Available",
                                    message: "Graph will be generated with the report"
                                )
                                .tag(IntelTab.graph)
                            }
                            
                            // Chat Tab
                            IntelChatView(chatService: chatService)
                                .tag(IntelTab.chat)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                    
                } else {
                    // Start button
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        Image(systemName: "sparkles.rectangle.stack")
                            .font(.system(size: 60))
                            .foregroundColor(colors.primary.opacity(0.3))
                        
                        Text("Generate intelligence debrief from your selected documents using AI-powered analysis")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                            IntelFeatureItem(icon: "eye.fill", text: "Vision AI analyzes images", colors: colors, theme: theme)
                            IntelFeatureItem(icon: "waveform", text: "Speech recognition transcribes audio", colors: colors, theme: theme)
                            IntelFeatureItem(icon: "brain.head.profile", text: "NLP extracts entities and topics", colors: colors, theme: theme)
                            IntelFeatureItem(icon: "function", text: "Formal logic draws conclusions", colors: colors, theme: theme)
                        }
                        .padding()
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        .padding(.horizontal)
                        
                        Button {
                            Task {
                                await generateIntel()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Generate Debrief")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
        }
        .navigationTitle("Intel Report")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showVaultPicker) {
            VaultPickerSheet(selectedVault: $selectedVault, vaultService: vaultService, colors: colors, theme: theme)
        }
        .onAppear {
            textIntel.configure(modelContext: modelContext)
            graphService.configure(modelContext: modelContext)
            // Pre-select first non-system vault
            selectedVault = vaultService.vaults.first { !$0.isSystemVault && $0.name != "Intel Reports" }
        }
    }
    
    private func generateIntel() async {
        do {
            // Generate debrief
            let debrief = try await textIntel.generateTextIntelReport(from: documents)
            debriefText = debrief
            
            // Generate graph
            if let intel = textIntel.intelligenceData {
                intelligenceData = intel
                let graph = await graphService.generateGraph(from: convertToGraphData(intel))
                
                // Configure chat
                let privilege = determinePrivilege()
                chatService.configure(
                    modelContext: modelContext,
                    graph: graph,
                    intelligence: intel,
                    privilege: privilege
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func debriefTab(colors: UnifiedTheme.Colors) -> some View {
        ScrollView {
            VStack(spacing: UnifiedTheme.Spacing.lg) {
                // Beautiful markdown rendering
                MarkdownTextView(markdown: debriefText)
                
                Divider()
                
                // Save section
                VStack(spacing: UnifiedTheme.Spacing.sm) {
                    Text("Save to:")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                    
                    Button {
                        showVaultPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text(selectedVault?.name ?? "Choose Vault")
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .padding()
                        .background(colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.md)
                    }
                    .foregroundColor(colors.textPrimary)
                    
                    Button {
                        Task {
                            await saveToVault()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Save to Vault")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedVault == nil)
                }
                .padding()
            }
        }
    }
    
    private func convertToGraphData(_ intel: TextIntelligenceService.IntelligenceData) -> IntelligenceData {
        let docs = intel.timeline.map { event in
            DocumentData(
                name: event.document,
                type: event.type,
                date: event.date,
                entities: Array(intel.entities),
                text: event.summary
            )
        }
        
        // Convert logical insights
        var insights: [LogicalInsight] = []
        for deductive in textIntel.logicalInsights?.deductive ?? [] {
            insights.append(LogicalInsight(
                type: .deductive,
                description: deductive,
                confidence: 0.9
            ))
        }
        for inductive in textIntel.logicalInsights?.inductive ?? [] {
            insights.append(LogicalInsight(
                type: .inductive,
                description: inductive,
                confidence: 0.7
            ))
        }
        for abductive in textIntel.logicalInsights?.abductive ?? [] {
            insights.append(LogicalInsight(
                type: .abductive,
                description: abductive,
                confidence: 0.8
            ))
        }
        for temporal in textIntel.logicalInsights?.temporal ?? [] {
            insights.append(LogicalInsight(
                type: .temporal,
                description: temporal,
                confidence: 0.85
            ))
        }
        
        return IntelligenceData(
            documents: docs,
            entities: Array(intel.entities),
            topics: Array(intel.topics),
            insights: insights,
            timeline: intel.timeline.map { event in
                TimelineEvent(
                    date: event.date,
                    description: event.summary,
                    documentName: event.document
                )
            }
        )
    }
    
    private func determinePrivilege() -> UserPrivilege {
        // Determine user privilege based on vault ownership
        if let vault = selectedVault,
           vault.owner?.id == authService.currentUser?.id {
            return .owner
        }
        return .viewer
    }
    
    private func saveToVault() async {
        guard let vault = selectedVault else {
            errorMessage = "Please select a vault first"
            showError = true
            return
        }
        
        do {
            print("💾 Saving text Intel debrief to vault: \(vault.name)")
            
            // Convert debrief to data (preserve markdown formatting)
            guard let textData = debriefText.data(using: .utf8) else {
                throw IntelError.conversionFailed
            }
            
            print("   Text size: \(textData.count) bytes")
            
            // Create document with markdown extension
            let document = Document(
                name: "Intel_Report_\(Date().formatted(date: .abbreviated, time: .shortened)).md",
                fileExtension: "md",
                mimeType: "text/markdown",
                fileSize: Int64(textData.count),
                documentType: "text"
            )
            document.encryptedFileData = textData
            document.sourceSinkType = "source"
            document.aiTags = ["Intel Report", "Text Debrief", "AI Analysis", "Formal Logic", "Graph Theory"]
            document.status = "active"
            document.extractedText = debriefText
            
            // Link to vault
            document.vault = vault
            
            // Add to vault's documents array
            if vault.documents == nil {
                vault.documents = []
            }
            vault.documents?.append(document)
            
            // Insert and save
            modelContext.insert(document)
            try modelContext.save()
            
            print("✅ Text Intel debrief saved successfully!")
            print("   Document: \(document.name)")
            print("   Vault: \(vault.name)")
            print("   Size: \(ByteCountFormatter.string(fromByteCount: document.fileSize, countStyle: .file))")
            
            dismiss()
            
        } catch {
            print("❌ Save error: \(error)")
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Processing View

struct ProcessingView: View {
    @ObservedObject var service: TextIntelligenceService
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        VStack(spacing: UnifiedTheme.Spacing.xl) {
            ProgressView(value: service.processingProgress)
                .tint(colors.primary)
                .scaleEffect(1.2)
                .padding(.horizontal, UnifiedTheme.Spacing.xxl)
            
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                Text(service.currentStep)
                    .font(theme.typography.headline)
                    .foregroundColor(colors.textPrimary)
                
                Text("\(Int(service.processingProgress * 100))% complete")
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.xs) {
                ProcessStep(number: 1, title: "Converting media to text", isComplete: service.processingProgress > 0.2, colors: colors, theme: theme)
                ProcessStep(number: 2, title: "Extracting entities & metadata", isComplete: service.processingProgress > 0.4, colors: colors, theme: theme)
                ProcessStep(number: 3, title: "Applying logical reasoning", isComplete: service.processingProgress > 0.6, colors: colors, theme: theme)
                ProcessStep(number: 4, title: "Generating debrief", isComplete: service.processingProgress > 0.8, colors: colors, theme: theme)
            }
            .padding()
            .background(colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
            .padding(.horizontal)
        }
    }
}

struct ProcessStep: View {
    let number: Int
    let title: String
    let isComplete: Bool
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.sm) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isComplete ? colors.success : colors.textTertiary)
            
            Text("\(number). \(title)")
                .font(theme.typography.caption)
                .foregroundColor(isComplete ? colors.textPrimary : colors.textSecondary)
        }
    }
}

struct IntelFeatureItem: View {
    let icon: String
    let text: String
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack(spacing: UnifiedTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(colors.primary)
                .frame(width: 20)
            
            Text(text)
                .font(theme.typography.caption)
                .foregroundColor(colors.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        TextIntelReportView(documents: [])
            .environmentObject(VaultService())
    }
}


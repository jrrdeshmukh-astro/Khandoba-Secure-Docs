//
//  IngestionDashboardView.swift
//  Khandoba Secure Docs
//
//  Ingestion dashboard view
//

import SwiftUI

struct IngestionDashboardView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var ingestionService = IntelligentIngestionService.shared
    
    @State private var isIngesting = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        // Status Card
                        if let status = ingestionService.activeIngestions[vault.id] {
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                    Text("Ingestion Status")
                                        .font(theme.typography.headline)
                                    
                                    HStack {
                                        Text(status.rawValue)
                                            .font(theme.typography.title2)
                                        
                                        Spacer()
                                        
                                        if status == .running {
                                            ProgressView()
                                        }
                                    }
                                    
                                    if let progress = ingestionService.ingestionProgress[vault.id] {
                                        ProgressView(value: progress, total: 1.0)
                                    }
                                }
                                .padding()
                            }
                        }
                        
                        // Topic Info
                        if let topic = ingestionService.getTopic(for: vault.id) {
                            StandardCard {
                                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                    Text("Topic: \(topic.topicName)")
                                        .font(theme.typography.headline)
                                    
                                    if let description = topic.topicDescription {
                                        Text(description)
                                            .font(theme.typography.body)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Total Ingested")
                                                .font(theme.typography.caption)
                                            Text("\(topic.totalIngested)")
                                                .font(theme.typography.title2)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text("Relevant")
                                                .font(theme.typography.caption)
                                            Text("\(topic.relevantCount)")
                                                .font(theme.typography.title2)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text("Learning Score")
                                                .font(theme.typography.caption)
                                            Text("\(Int(topic.learningScore * 100))%")
                                                .font(theme.typography.title2)
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        
                        // Start Ingestion Button
                        Button {
                            Task {
                                await startIngestion()
                            }
                        } label: {
                            Text(isIngesting ? "Ingesting..." : "Start Ingestion")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isIngesting)
                        .padding()
                    }
                    .padding()
                }
                .navigationTitle("Ingestion Dashboard")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .onAppear {
            configureService()
        }
    }
    
    private func configureService() {
        ingestionService.configure(
            modelContext: modelContext,
            emailService: EmailIntegrationService.shared,
            cloudStorageService: CloudStorageService.shared,
            documentService: DocumentService(),
            learningAgentService: LearningAgentService.shared,
            complianceEngineService: ComplianceEngineService.shared
        )
    }
    
    private func startIngestion() async {
        isIngesting = true
        defer { isIngesting = false }
        
        try? await ingestionService.startIngestion(for: vault.id)
    }
}


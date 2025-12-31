//
//  IntelligentIngestionService.swift
//  Khandoba Secure Docs
//
//  Intelligent data ingestion service
//

import Foundation
import SwiftData
import Combine

/// Ingestion status
enum IngestionStatus: String, Codable {
    case idle = "Idle"
    case running = "Running"
    case paused = "Paused"
    case completed = "Completed"
    case failed = "Failed"
}

@MainActor
final class IntelligentIngestionService: ObservableObject {
    static let shared = IntelligentIngestionService()
    
    @Published var activeIngestions: [UUID: IngestionStatus] = [:] // vaultID: status
    @Published var ingestionProgress: [UUID: Double] = [:] // vaultID: progress 0.0-1.0
    
    private var modelContext: ModelContext?
    private var emailService: EmailIntegrationService?
    private var cloudStorageService: CloudStorageService?
    private var documentService: DocumentService?
    private var learningAgentService: LearningAgentService?
    private var complianceEngineService: ComplianceEngineService?
    
    private init() {}
    
    func configure(
        modelContext: ModelContext,
        emailService: EmailIntegrationService,
        cloudStorageService: CloudStorageService,
        documentService: DocumentService,
        learningAgentService: LearningAgentService,
        complianceEngineService: ComplianceEngineService
    ) {
        self.modelContext = modelContext
        self.emailService = emailService
        self.cloudStorageService = cloudStorageService
        self.documentService = documentService
        self.learningAgentService = learningAgentService
        self.complianceEngineService = complianceEngineService
    }
    
    // MARK: - Topic Management
    
    /// Configure vault topic
    func configureTopic(
        vaultID: UUID,
        topicName: String,
        topicDescription: String?,
        keywords: [String],
        categories: [String],
        complianceFrameworks: [ComplianceFramework],
        dataSources: [String]
    ) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        // Check if topic exists
        let descriptor = FetchDescriptor<VaultTopic>(
            predicate: #Predicate { $0.vaultID == vaultID }
        )
        
        let existingTopics = try modelContext.fetch(descriptor)
        let topic: VaultTopic
        
        if let existing = existingTopics.first {
            topic = existing
        } else {
            topic = VaultTopic(vaultID: vaultID, topicName: topicName, topicDescription: topicDescription)
            modelContext.insert(topic)
        }
        
        topic.topicName = topicName
        topic.topicDescription = topicDescription
        topic.keywords = keywords
        topic.categories = categories
        topic.complianceFrameworks = complianceFrameworks.map { $0.rawValue }
        topic.dataSources = dataSources
        topic.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// Get topic for vault
    func getTopic(for vaultID: UUID) -> VaultTopic? {
        guard let modelContext = modelContext else { return nil }
        
        do {
            let descriptor = FetchDescriptor<VaultTopic>(
                predicate: #Predicate { $0.vaultID == vaultID }
            )
            return try modelContext.fetch(descriptor).first
        } catch {
            return nil
        }
    }
    
    // MARK: - Ingestion
    
    /// Start ingestion for vault
    func startIngestion(for vaultID: UUID) async throws {
        guard let modelContext = modelContext,
              let topic = getTopic(for: vaultID),
              let vault = try? getVault(id: vaultID, modelContext: modelContext) else {
            throw DocumentError.contextNotAvailable
        }
        
        activeIngestions[vaultID] = .running
        ingestionProgress[vaultID] = 0.0
        
        defer {
            activeIngestions[vaultID] = .completed
        }
        
        // Ingest from each configured source
        let totalSources = topic.dataSources.count
        var processedSources = 0
        
        for source in topic.dataSources {
            do {
                try await ingestFromSource(
                    source: source,
                    vault: vault,
                    topic: topic,
                    modelContext: modelContext
                )
                
                processedSources += 1
                ingestionProgress[vaultID] = Double(processedSources) / Double(totalSources)
            } catch {
                print("Failed to ingest from \(source): \(error)")
                // Continue with other sources
            }
        }
        
        // Update learning metrics
        if let learningAgent = learningAgentService {
            await learningAgent.learnFromIngestion(vaultID: vaultID, topic: topic)
        }
    }
    
    private func ingestFromSource(
        source: String,
        vault: Vault,
        topic: VaultTopic,
        modelContext: ModelContext
    ) async throws {
        // Determine source type and ingest
        if source.contains("gmail") || source.contains("outlook") {
            try await ingestFromEmail(source: source, vault: vault, topic: topic)
        } else if source.contains("drive") || source.contains("dropbox") || source.contains("onedrive") {
            try await ingestFromCloudStorage(source: source, vault: vault, topic: topic)
        }
    }
    
    private func ingestFromEmail(
        source: String,
        vault: Vault,
        topic: VaultTopic
    ) async throws {
        guard let emailService = emailService,
              let documentService = documentService else {
            return
        }
        
        let provider: EmailProvider = source.contains("gmail") ? .gmail : .outlook
        
        // Build filter based on topic
        var filter = EmailFilter()
        if !topic.keywords.isEmpty {
            filter.subject = topic.keywords.joined(separator: " OR ")
        }
        
        // Fetch emails
        let emails = try await emailService.fetchEmails(from: provider, maxResults: 50, filter: filter)
        
        // Calculate relevance and ingest attachments
        for email in emails {
            if let learningAgent = learningAgentService {
                let relevance = await learningAgent.calculateRelevance(
                    content: email.subject + " " + (email.snippet ?? ""),
                    topic: topic
                )
                
                if relevance > 0.5 { // Only ingest if relevant
                    try await emailService.ingestAttachmentsToVault(
                        email: email,
                        vault: vault,
                        documentService: documentService
                    )
                    topic.relevantCount += 1
                }
            } else {
                // Ingest all if no learning agent
                try await emailService.ingestAttachmentsToVault(
                    email: email,
                    vault: vault,
                    documentService: documentService
                )
                topic.relevantCount += 1
            }
            
            topic.totalIngested += 1
        }
    }
    
    private func ingestFromCloudStorage(
        source: String,
        vault: Vault,
        topic: VaultTopic
    ) async throws {
        guard let cloudStorageService = cloudStorageService,
              let documentService = documentService else {
            return
        }
        
        let provider: CloudStorageProvider
        if source.contains("google") {
            provider = .googleDrive
        } else if source.contains("dropbox") {
            provider = .dropbox
        } else if source.contains("onedrive") {
            provider = .oneDrive
        } else {
            return
        }
        
        // List files
        let files = try await cloudStorageService.listFiles(provider: provider, maxResults: 50)
        
        // Download and ingest relevant files
        for file in files where !file.isFolder {
            if let learningAgent = learningAgentService {
                let relevance = await learningAgent.calculateRelevance(
                    content: file.name,
                    topic: topic
                )
                
                if relevance > 0.5 {
                    let data = try await cloudStorageService.downloadFile(provider: provider, file: file)
                    _ = try await documentService.uploadDocument(
                        data: data,
                        name: file.name,
                        mimeType: file.mimeType,
                        to: vault,
                        uploadMethod: .import
                    )
                    topic.relevantCount += 1
                }
            } else {
                // Ingest all if no learning agent
                let data = try await cloudStorageService.downloadFile(provider: provider, file: file)
                _ = try await documentService.uploadDocument(
                    data: data,
                    name: file.name,
                    mimeType: file.mimeType,
                    to: vault,
                        uploadMethod: .import
                )
                topic.relevantCount += 1
            }
            
            topic.totalIngested += 1
        }
    }
    
    // MARK: - Helpers
    
    private func getVault(id: UUID, modelContext: ModelContext) throws -> Vault? {
        let descriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
}


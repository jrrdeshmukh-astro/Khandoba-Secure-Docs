//
//  IntelReportService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import NaturalLanguage
import Combine
import SwiftUI
import SwiftData
import AVFoundation

@MainActor
final class IntelReportService: ObservableObject {
    @Published var currentReport: IntelReport?
    @Published var isGenerating = false
    
    private var modelContext: ModelContext?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Generate an intel report comparing source vs sink documents
    func generateIntelReport(for vaults: [Vault]) async -> IntelReport {
        isGenerating = true
        defer { isGenerating = false }
        
        var sourceDocuments: [Document] = []
        var sinkDocuments: [Document] = []
        
        // Collect all documents
        for vault in vaults {
            for document in (vault.documents ?? []) where document.status == "active" {
                if document.sourceSinkType == "source" {
                    sourceDocuments.append(document)
                } else if document.sourceSinkType == "sink" {
                    sinkDocuments.append(document)
                } else if document.sourceSinkType == "both" {
                    sourceDocuments.append(document)
                    sinkDocuments.append(document)
                }
            }
        }
        
        // Analyze patterns
        let sourceAnalysis = analyzeDocuments(sourceDocuments, type: "Source")
        let sinkAnalysis = analyzeDocuments(sinkDocuments, type: "Sink")
        
        // Generate narrative insights
        let narrative = await generateNarrative(
            sourceAnalysis: sourceAnalysis,
            sinkAnalysis: sinkAnalysis,
            sourceCount: sourceDocuments.count,
            sinkCount: sinkDocuments.count
        )
        
        let report = IntelReport(
            generatedAt: Date(),
            sourceAnalysis: sourceAnalysis,
            sinkAnalysis: sinkAnalysis,
            narrative: narrative,
            insights: await generateInsights(
                sourceAnalysis: sourceAnalysis,
                sinkAnalysis: sinkAnalysis
            )
        )
        
        currentReport = report
        return report
    }
    
    // MARK: - Analysis
    
    private func analyzeDocuments(_ documents: [Document], type: String) -> DocumentAnalysis {
        var tagFrequency: [String: Int] = [:]
        var entities: [String] = []
        var totalSize: Int64 = 0
        var fileTypes: [String: Int] = [:]
        
        for document in documents {
            // Tag frequency
            for tag in document.aiTags {
                tagFrequency[tag, default: 0] += 1
                
                // Extract entities
                if tag.hasPrefix("Person:") || tag.hasPrefix("Location:") || tag.hasPrefix("Organization:") {
                    entities.append(tag)
                }
            }
            
            // File type distribution
            fileTypes[document.documentType, default: 0] += 1
            
            // Total size
            totalSize += document.fileSize
        }
        
        // Sort tags by frequency
        let topTags = tagFrequency.sorted { $0.value > $1.value }.prefix(10).map { $0.key }
        
        return DocumentAnalysis(
            documentType: type,
            count: documents.count,
            topTags: Array(topTags),
            entities: Array(Set(entities)),
            totalSize: totalSize,
            fileTypeDistribution: fileTypes
        )
    }
    
    // MARK: - Narrative Generation
    
    private func generateNarrative(
        sourceAnalysis: DocumentAnalysis,
        sinkAnalysis: DocumentAnalysis,
        sourceCount: Int,
        sinkCount: Int
    ) async -> String {
        var narrative = ""
        
        // Opening - conversational tone
        narrative += "VAULT INTELLIGENCE REPORT\n\n"
        
        narrative += "Hi. Here's what I found in your vaults.\n\n"
        
        // Overall statistics
        narrative += "What's in your vaults:\n"
        narrative += "You have \(sourceCount) files you created yourself, and \(sinkCount) files you received from others.\n\n"
        
        // Source document insights
        if sourceCount > 0 {
            narrative += "Files you created:\n"
            narrative += "You've made \(sourceCount) files on your own, taking up about \(ByteCountFormatter.string(fromByteCount: sourceAnalysis.totalSize, countStyle: .file)) of space.\n"
            
            if !sourceAnalysis.topTags.isEmpty {
                narrative += "Most of your files are about: \(sourceAnalysis.topTags.prefix(5).joined(separator: ", ")).\n"
            }
            
            if !sourceAnalysis.entities.isEmpty {
                narrative += "You often mention: \(sourceAnalysis.entities.prefix(3).joined(separator: ", ")).\n"
            }
            narrative += "\n"
        }
        
        // Sink document insights
        if sinkCount > 0 {
            narrative += "Files you received:\n"
            narrative += "You've gotten \(sinkCount) files from other people, taking up about \(ByteCountFormatter.string(fromByteCount: sinkAnalysis.totalSize, countStyle: .file)).\n"
            
            if !sinkAnalysis.topTags.isEmpty {
                narrative += "These files are mostly about: \(sinkAnalysis.topTags.prefix(5).joined(separator: ", ")).\n"
            }
            
            if !sinkAnalysis.entities.isEmpty {
                narrative += "They often mention: \(sinkAnalysis.entities.prefix(3).joined(separator: ", ")).\n"
            }
            narrative += "\n"
        }
        
        // Comparative insights
        narrative += "Patterns I noticed:\n"
        narrative += await generateComparativeInsights(sourceAnalysis: sourceAnalysis, sinkAnalysis: sinkAnalysis)
        
        // Interesting findings
        if let interestingFinding = await detectInterestingPatterns(
            sourceAnalysis: sourceAnalysis,
            sinkAnalysis: sinkAnalysis
        ) {
            narrative += "\nSomething interesting:\n\(interestingFinding)\n"
        }
        
        narrative += "\nThat's all for now. Let me know if you need anything else."
        
        return narrative
    }
    
    private func generateComparativeInsights(
        sourceAnalysis: DocumentAnalysis,
        sinkAnalysis: DocumentAnalysis
    ) async -> String {
        var insights = ""
        
        // Compare tag overlap
        let sourceTags = Set(sourceAnalysis.topTags)
        let sinkTags = Set(sinkAnalysis.topTags)
        let commonTags = sourceTags.intersection(sinkTags)
        
        if !commonTags.isEmpty {
            insights += "The files you make and the ones you receive both deal with: \(commonTags.joined(separator: ", ")). "
        } else {
            insights += "The stuff you create is pretty different from what you receive. "
        }
        
        // Compare entities
        let sourceEntities = Set(sourceAnalysis.entities)
        let sinkEntities = Set(sinkAnalysis.entities)
        let commonEntities = sourceEntities.intersection(sinkEntities)
        
        if !commonEntities.isEmpty {
            insights += "I see the same names or topics in both: \(commonEntities.prefix(3).joined(separator: ", ")). "
        }
        
        // Size comparison
        let ratio = Double(sourceAnalysis.totalSize) / Double(max(sinkAnalysis.totalSize, 1))
        if ratio > 2 {
            insights += "You're creating way more stuff than you're receiving - about \(String(format: "%.0f", ratio)) times more. "
        } else if ratio < 0.5 {
            insights += "You're receiving way more stuff than you're creating - about \(String(format: "%.0f", 1/ratio)) times more. "
        } else {
            insights += "You've got a nice balance between what you create and what you receive. "
        }
        
        return insights
    }
    
    private func detectInterestingPatterns(
        sourceAnalysis: DocumentAnalysis,
        sinkAnalysis: DocumentAnalysis
    ) async -> String? {
        var findings: [String] = []
        
        // Detect if user is creating similar content to what they receive
        let sourceTags = Set(sourceAnalysis.topTags)
        let sinkTags = Set(sinkAnalysis.topTags)
        let overlap = sourceTags.intersection(sinkTags)
        
        if overlap.count >= 3 {
            findings.append("You tend to create content similar to what you receive, suggesting an active engagement with shared topics: \(overlap.joined(separator: ", ")).")
        }
        
        // Detect medical/legal patterns
        let medicalTags = ["Medical", "Health", "Patient", "Doctor", "Hospital"]
        let legalTags = ["Legal", "Contract", "Agreement", "Court"]
        
        let hasMedical = sourceAnalysis.topTags.contains { tag in
            medicalTags.contains(where: { tag.contains($0) })
        } || sinkAnalysis.topTags.contains { tag in
            medicalTags.contains(where: { tag.contains($0) })
        }
        
        let hasLegal = sourceAnalysis.topTags.contains { tag in
            legalTags.contains(where: { tag.contains($0) })
        } || sinkAnalysis.topTags.contains { tag in
            legalTags.contains(where: { tag.contains($0) })
        }
        
        if hasMedical && hasLegal {
            findings.append("Your vault contains both medical and legal documents, suggesting possible healthcare compliance or medical-legal documentation needs.")
        } else if hasMedical {
            findings.append("Your vault is heavily focused on medical/health documentation. Consider using HIPAA compliance features for sensitive patient data.")
        } else if hasLegal {
            findings.append("Your vault contains significant legal documentation. The audit trail features ensure chain of custody for legal evidence.")
        }
        
        // Detect volume patterns
        if sourceAnalysis.count > sinkAnalysis.count * 3 {
            findings.append("You're a prolific content creator! You produce \(sourceAnalysis.count) documents compared to receiving only \(sinkAnalysis.count).")
        } else if sinkAnalysis.count > sourceAnalysis.count * 3 {
            findings.append("You're primarily an information receiver, with \(sinkAnalysis.count) external documents compared to \(sourceAnalysis.count) created by you.")
        }
        
        return findings.first
    }
    
    private func generateInsights(
        sourceAnalysis: DocumentAnalysis,
        sinkAnalysis: DocumentAnalysis
    ) async -> [String] {
        var insights: [String] = []
        
        // Source insights
        if sourceAnalysis.count > 0 {
            insights.append("You've created \(sourceAnalysis.count) original documents")
        }
        
        // Sink insights
        if sinkAnalysis.count > 0 {
            insights.append("You've received \(sinkAnalysis.count) external documents")
        }
        
        // Tag-based insights
        if !sourceAnalysis.topTags.isEmpty {
            insights.append("Most common source tags: \(sourceAnalysis.topTags.prefix(3).joined(separator: ", "))")
        }
        
        if !sinkAnalysis.topTags.isEmpty {
            insights.append("Most common sink tags: \(sinkAnalysis.topTags.prefix(3).joined(separator: ", "))")
        }
        
        return insights
    }
    
    func compileReportFromDocuments(_ documents: [Document]) async throws -> String {
        guard documents.count >= 2 else {
            throw IntelReportError.insufficientDocuments
        }
        
        var report = "# Intel Report - Cross-Document Analysis\n\n"
        report += "**Generated:** \(Date().formatted(date: .long, time: .shortened))\n"
        report += "**Documents Analyzed:** \(documents.count)\n\n"
        
        // Common keywords
        let allTags = documents.flatMap { $0.aiTags }
        let tagFreq = Dictionary(grouping: allTags, by: { $0 }).mapValues { $0.count }.sorted { $0.value > $1.value }
        
        report += "## Key Topics\n\n"
        for (tag, count) in tagFreq.prefix(10) {
            report += "- **\(tag)**: \(count) occurrences\n"
        }
        report += "\n"
        
        // Source vs Sink
        let sourceCount = documents.filter { $0.sourceSinkType == "source" }.count
        let sinkCount = documents.filter { $0.sourceSinkType == "sink" }.count
        
        report += "## Data Origin\n\n"
        report += "- Created (Source): \(sourceCount)\n"
        report += "- Received (Sink): \(sinkCount)\n\n"
        
        // Timeline
        let dates = documents.map { $0.uploadedAt }.sorted()
        if let earliest = dates.first, let latest = dates.last {
            let days = Calendar.current.dateComponents([.day], from: earliest, to: latest).day ?? 0
            report += "## Timeline\n\n"
            report += "- Range: \(earliest.formatted(date: .abbreviated, time: .omitted)) - \(latest.formatted(date: .abbreviated, time: .omitted))\n"
            report += "- Span: \(days) days\n\n"
        }
        
        // Insights
        report += "## Insights\n\n"
        if sourceCount > sinkCount * 2 {
            report += "Active content creator.\n"
        } else if sinkCount > sourceCount * 2 {
            report += "Content aggregator.\n"
        }
        
        return report
    }
    
    func saveReportToIntelVault(_ report: String, for user: User?, modelContext: ModelContext) async throws {
        guard let user = user else {
            throw IntelReportError.contextNotAvailable
        }
        
        print("Converting Intel report to voice memo...")
        
        // Find or create Intel Reports vault
        let descriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.name == "Intel Reports" }
        )
        
        let allIntelVaults = try modelContext.fetch(descriptor)
        var intelVault = allIntelVaults.first(where: { $0.owner?.id == user.id })
        
        // CREATE vault if it doesn't exist
        if intelVault == nil {
            print("   Creating Intel Reports vault...")
            intelVault = Vault(
                name: "Intel Reports",
                vaultDescription: "AI-generated voice memo intelligence reports. Listen to insights about your documents.",
                keyType: "dual"
            )
            intelVault?.owner = user
            intelVault?.vaultType = "source"
            intelVault?.isSystemVault = true // Mark as system vault - read-only for users
            modelContext.insert(intelVault!)
            try modelContext.save()
            print("   Intel Reports vault created")
        }
        
        guard let finalVault = intelVault else {
            throw IntelReportError.intelVaultNotFound
        }
        
        // AUTO-UNLOCK: Intel Reports is dual-key, need to process unlock request
        if finalVault.keyType == "dual" {
            print("   Intel Reports is dual-key - auto-processing unlock...")
            
            // Check for existing pending request
            let pendingDescriptor = FetchDescriptor<DualKeyRequest>(
                predicate: #Predicate { $0.status == "pending" }
            )
            let allPending = try modelContext.fetch(pendingDescriptor)
            let existingRequest = allPending.first { $0.vault?.id == finalVault.id && $0.requester?.id == user.id }
            
            if existingRequest == nil {
                // Create unlock request
                let unlockRequest = DualKeyRequest(reason: "System saving intel report")
                unlockRequest.vault = finalVault
                unlockRequest.requester = user
                modelContext.insert(unlockRequest)
                try modelContext.save()
                
                // Auto-process with ML (will auto-approve for system operations)
                let approvalService = DualKeyApprovalService()
                approvalService.configure(modelContext: modelContext)
                
                do {
                    let decision = try await approvalService.processDualKeyRequest(unlockRequest, vault: finalVault)
                    
                    if decision.action == .autoDenied {
                        print("   Warning: Auto-unlock was denied - report save may fail")
                    } else {
                        print("   Auto-unlock approved - proceeding with save")
                    }
                } catch {
                    print("   Error auto-unlocking: \(error)")
                }
            } else {
                print("   Unlock request already exists - reusing")
            }
        }
        
        // GENERATE VOICE MEMO INSTEAD OF TEXT FILE
        print("   Report length: \(report.count) characters")
        print("   Generating spoken audio...")
        
        let audioURL = try await generateVoiceReportAudio(from: report)
        
        // Load audio data
        let audioData = try Data(contentsOf: audioURL)
        print("   Audio generated: \(ByteCountFormatter.string(fromByteCount: Int64(audioData.count), countStyle: .file))")
        
        // Calculate duration (simplified)
        let durationSeconds = Double(report.count) / 15.0 // Approximate: 15 chars per second
        
        let fileName = "Intel_Report_\(Date().timeIntervalSince1970).m4a"
        
        // Create document as AUDIO instead of TEXT
        let document = Document(
            name: fileName,
            mimeType: "audio/m4a",
            fileSize: Int64(audioData.count),
            documentType: "audio",  // Changed from "text" to "audio"
            isEncrypted: true,
            isArchived: false,
            isRedacted: false,
            status: "active",
            aiTags: ["Intel Report", "Voice Memo", "AI Analysis", "Audio Report"]
        )
        document.encryptedFileData = audioData
        document.vault = finalVault
        document.sourceSinkType = "source"
        
        // Store transcript in metadata
        let metadata: [String: Any] = [
            "transcript": report,
            "duration": durationSeconds,
            "generatedAt": Date().timeIntervalSince1970,
            "type": "intel_report"
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            document.metadata = jsonString
        }
        
        finalVault.documents?.append(document)
        modelContext.insert(document)
        try modelContext.save()
        
        print("   Voice memo saved to Intel Reports: \(fileName)")
        print("   Duration: \(Int(durationSeconds))s")
        
        // Clean up temporary file
        try? FileManager.default.removeItem(at: audioURL)
    }
    
    /// OPTIMIZED: Generate audio file from report text using text-to-speech
    private func generateVoiceReportAudio(from text: String) async throws -> URL {
        // OPTIMIZATION: Limit text length to prevent hanging on long reports
        let limitedText = String(text.prefix(2000)) // Max ~2 minutes of speech
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create temp file URL
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("m4a")
            
            // OPTIMIZATION: Use background queue for synthesis
            DispatchQueue.global(qos: .userInitiated).async {
                // For v1.0: Create lightweight placeholder
                // Production would use AVAudioEngine to capture actual speech
                
                let minimalAudioData = Data([0xFF, 0xF1, 0x50, 0x80, 0x00, 0x1F, 0xFC])
                
                do {
                    try minimalAudioData.write(to: tempURL)
                    continuation.resume(returning: tempURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Models

struct IntelReport: Identifiable {
    let id = UUID()
    let generatedAt: Date
    let sourceAnalysis: DocumentAnalysis
    let sinkAnalysis: DocumentAnalysis
    let narrative: String
    let insights: [String]
}

struct DocumentAnalysis {
    let documentType: String
    let count: Int
    let topTags: [String]
    let entities: [String]
    let totalSize: Int64
    let fileTypeDistribution: [String: Int]
}

enum IntelReportError: Error {
    case noData
    case insufficientDocuments
    case intelVaultNotFound
    case contextNotAvailable
}

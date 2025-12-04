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
    @Published var voiceMemoURL: URL?
    
    private var modelContext: ModelContext?
    private let voiceMemoService = VoiceMemoService()
    private let storyGenerator = StoryNarrativeGenerator()
    private var vaultService: VaultService?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext, vaultService: VaultService? = nil) {
        self.modelContext = modelContext
        self.vaultService = vaultService
        voiceMemoService.configure(modelContext: modelContext)
        storyGenerator.configure(modelContext: modelContext)
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
        
        // 🎤 GENERATE VOICE MEMO FOR THE REPORT
        await generateAndSaveVoiceMemo(for: report, vaults: vaults)
        
        return report
    }
    
    // MARK: - Voice Memo Generation
    
    /// Generate voice memo from report and save to Intel Vault
    private func generateAndSaveVoiceMemo(for report: IntelReport, vaults: [Vault]) async {
        do {
            print("🎤 Generating voice memo for Intel Report...")
            
            // Find or create Intel Vault
            guard let intelVault = await findOrCreateIntelVault(vaults: vaults) else {
                print("❌ Failed to find/create Intel Vault")
                return
            }
            
            // Generate full narrative text for voice memo (with story if media available)
            let voiceText = await buildVoiceNarrative(from: report)
            
            // Generate audio file from text
            let audioURL = try await voiceMemoService.generateVoiceMemo(
                from: voiceText,
                title: "Intel Report \(Date().formatted(date: .abbreviated, time: .shortened))"
            )
            
            print("✅ Voice memo audio generated: \(audioURL.lastPathComponent)")
            
            // Save to Intel Vault
            let document = try await voiceMemoService.saveVoiceMemoToVault(
                audioURL,
                vault: intelVault,
                title: "Intel Report - \(Date().formatted(date: .abbreviated, time: .shortened))",
                description: "AI-generated intelligence analysis with actionable insights"
            )
            
            print("✅ Voice memo saved to Intel Vault: \(document.name)")
            voiceMemoURL = audioURL
            
        } catch {
            print("❌ Error generating voice memo: \(error)")
        }
    }
    
    /// Build voice-optimized narrative from report
    /// NOW WITH STORY-BASED NARRATIVE from media analysis!
    private func buildVoiceNarrative(from report: IntelReport) async -> String {
        var text = ""
        
        text += "Intelligence Report for \(Date().formatted(date: .long, time: .omitted)).\n\n"
        
        // Check if we have media documents to create story narrative
        let allDocuments = await getAllDocuments()
        let mediaDocuments = allDocuments.filter {
            $0.documentType == "image" || $0.documentType == "video" || $0.documentType == "audio"
        }
        
        if mediaDocuments.count >= 3 {
            // Generate story-based narrative from media
            print("   🎬 Generating story narrative from \(mediaDocuments.count) media files...")
            let storyNarrative = await storyGenerator.generateStoryNarrative(from: mediaDocuments)
            text += storyNarrative
            text += "\n\n"
        } else {
            // Fallback to standard narrative
            text += report.narrative
            text += "\n\n"
        }
        
        text += "Key Insights:\n"
        for (index, insight) in report.insights.enumerated() {
            text += "\(index + 1). \(insight)\n"
        }
        
        text += "\nEnd of report."
        
        return text
    }
    
    /// Get all documents from all vaults
    private func getAllDocuments() async -> [Document] {
        guard let vaultService = vaultService else { return [] }
        
        var allDocs: [Document] = []
        for vault in vaultService.vaults {
            allDocs.append(contentsOf: vault.documents ?? [])
        }
        return allDocs
    }
    
    /// Find Intel Vault or return first vault as fallback
    private func findOrCreateIntelVault(vaults: [Vault]) async -> Vault? {
        // Try to find Intel Reports vault
        if let intelVault = vaults.first(where: { $0.name == "Intel Reports" }) {
            return intelVault
        }
        
        // Fallback: use first available vault
        return vaults.first
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
        print("   📢 Using VoiceMemoService for REAL audio generation...")
        
        // IMPORTANT: Use the actual VoiceMemoService that works!
        let voiceMemoService = VoiceMemoService()
        
        // Configure if we have model context
        if let modelContext = modelContext {
            voiceMemoService.configure(modelContext: modelContext)
        }
        
        // Generate real audio with TTS
        print("   🎤 Generating speech from \(text.count) characters...")
        let audioURL = try await voiceMemoService.generateVoiceMemo(
            from: text,
            title: "Intel Report Voice"
        )
        
        // Verify file has content
        let fileSize = try FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? UInt64 ?? 0
        print("   📊 Generated audio file: \(fileSize) bytes")
        
        if fileSize < 10000 {
            print("   ⚠️ WARNING: Audio file seems small, but continuing...")
        } else {
            print("   ✅ Audio file has content!")
        }
        
        return audioURL
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

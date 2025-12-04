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
        
        // Opening
        narrative += "📊 Intel Report Summary\n\n"
        
        // Overall statistics
        narrative += "Your vault contains \(sourceCount) source documents (created by you) and \(sinkCount) sink documents (received from others).\n\n"
        
        // Source document insights
        if sourceCount > 0 {
            narrative += "🎯 Source Data Analysis:\n"
            narrative += "You've created \(sourceCount) original documents, totaling \(ByteCountFormatter.string(fromByteCount: sourceAnalysis.totalSize, countStyle: .file)).\n"
            
            if !sourceAnalysis.topTags.isEmpty {
                narrative += "Common themes in your created content include: \(sourceAnalysis.topTags.prefix(5).joined(separator: ", ")).\n"
            }
            
            if !sourceAnalysis.entities.isEmpty {
                narrative += "Key entities mentioned: \(sourceAnalysis.entities.prefix(3).joined(separator: ", ")).\n"
            }
            narrative += "\n"
        }
        
        // Sink document insights
        if sinkCount > 0 {
            narrative += "📥 Sink Data Analysis:\n"
            narrative += "You've received \(sinkCount) documents from external sources, totaling \(ByteCountFormatter.string(fromByteCount: sinkAnalysis.totalSize, countStyle: .file)).\n"
            
            if !sinkAnalysis.topTags.isEmpty {
                narrative += "External content primarily contains: \(sinkAnalysis.topTags.prefix(5).joined(separator: ", ")).\n"
            }
            
            if !sinkAnalysis.entities.isEmpty {
                narrative += "External entities include: \(sinkAnalysis.entities.prefix(3).joined(separator: ", ")).\n"
            }
            narrative += "\n"
        }
        
        // Comparative insights
        narrative += "🔍 Pattern Analysis:\n"
        narrative += await generateComparativeInsights(sourceAnalysis: sourceAnalysis, sinkAnalysis: sinkAnalysis)
        
        // Interesting findings
        if let interestingFinding = await detectInterestingPatterns(
            sourceAnalysis: sourceAnalysis,
            sinkAnalysis: sinkAnalysis
        ) {
            narrative += "\n💡 Interesting Finding:\n\(interestingFinding)\n"
        }
        
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
            insights += "Both source and sink documents share common themes: \(commonTags.joined(separator: ", ")). "
        } else {
            insights += "Your created content and received content have distinctly different themes. "
        }
        
        // Compare entities
        let sourceEntities = Set(sourceAnalysis.entities)
        let sinkEntities = Set(sinkAnalysis.entities)
        let commonEntities = sourceEntities.intersection(sinkEntities)
        
        if !commonEntities.isEmpty {
            insights += "Common entities across both types: \(commonEntities.prefix(3).joined(separator: ", ")). "
        }
        
        // Size comparison
        let ratio = Double(sourceAnalysis.totalSize) / Double(max(sinkAnalysis.totalSize, 1))
        if ratio > 2 {
            insights += "You create significantly more content than you receive (ratio: \(String(format: "%.1f", ratio)):1). "
        } else if ratio < 0.5 {
            insights += "You receive significantly more content than you create (ratio: 1:\(String(format: "%.1f", 1/ratio))). "
        } else {
            insights += "You have a balanced mix of created and received content. "
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
        
        // Simplified predicate to avoid SwiftData complexity
        let descriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.name == "Intel Vault" }
        )
        
        let allIntelVaults = try modelContext.fetch(descriptor)
        guard let intelVault = allIntelVaults.first(where: { $0.owner?.id == user.id }) else {
            throw IntelReportError.intelVaultNotFound
        }
        
        let reportData = report.data(using: .utf8) ?? Data()
        let fileName = "Intel_Report_\(Date().timeIntervalSince1970).md"
        
        let document = Document(
            name: fileName,
            mimeType: "text/markdown",
            fileSize: Int64(reportData.count),
            documentType: "text",
            isEncrypted: true,
            isArchived: false,
            isRedacted: false,
            status: "active",
            aiTags: ["Intel Report", "AI Analysis"]
        )
        document.encryptedFileData = reportData
        document.vault = intelVault
        document.sourceSinkType = "source"
        
        intelVault.documents?.append(document)
        modelContext.insert(document)
        try modelContext.save()
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

//
//  IntelReportService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class IntelReportService: ObservableObject {
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    
    nonisolated init() {}
    
    // iOS-ONLY: Using SwiftData/CloudKit exclusively
    func configure(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    // MARK: - Cross-Reference Intel Report Generation
    
    /// Generate cross-reference Intel Report comparing shared documents with anti-vault documents
    func generateCrossReferenceReport(
        sharedDocuments: [Document],
        antiVaultDocuments: [Document],
        settings: ThreatDetectionSettings
    ) async throws -> CrossReferenceIntelReport {
        print("📊 Generating cross-reference Intel Report...")
        isLoading = true
        defer { isLoading = false }
        
        var contentDiscrepancies: [ContentDiscrepancy] = []
        var metadataMismatches: [MetadataMismatch] = []
        var accessPatternAnomalies: [AccessPatternAnomaly] = []
        var geographicInconsistencies: [GeographicInconsistency] = []
        var editHistoryDiscrepancies: [EditHistoryDiscrepancy] = []
        
        // Match documents by name or hash
        let matchedPairs = matchDocuments(sharedDocuments: sharedDocuments, antiVaultDocuments: antiVaultDocuments)
        
        // Analyze each matched pair
        for (sharedDoc, antiDoc) in matchedPairs {
            // Content discrepancies
            if settings.detectContentDiscrepancies {
                if let discrepancy = try await detectContentDiscrepancies(doc1: sharedDoc, doc2: antiDoc) {
                    contentDiscrepancies.append(discrepancy)
                }
            }
            
            // Metadata mismatches
            if settings.detectMetadataMismatches {
                if let mismatch = detectMetadataMismatches(doc1: sharedDoc, doc2: antiDoc) {
                    metadataMismatches.append(mismatch)
                }
            }
            
            // Edit history discrepancies
            if settings.detectEditHistoryDiscrepancies {
                if let discrepancy = detectEditHistoryDiscrepancies(doc1: sharedDoc, doc2: antiDoc) {
                    editHistoryDiscrepancies.append(discrepancy)
                }
            }
        }
        
        // Access pattern anomalies (analyze all documents together)
        if settings.detectAccessPatternAnomalies {
            accessPatternAnomalies = analyzeAccessPatterns(documents: sharedDocuments + antiVaultDocuments)
        }
        
        // Geographic inconsistencies
        if settings.detectGeographicInconsistencies {
            geographicInconsistencies = detectGeographicInconsistencies(sharedDocuments: sharedDocuments, antiVaultDocuments: antiVaultDocuments)
        }
        
        let report = CrossReferenceIntelReport(
            sharedDocuments: sharedDocuments,
            antiVaultDocuments: antiVaultDocuments,
            contentDiscrepancies: contentDiscrepancies,
            metadataMismatches: metadataMismatches,
            accessPatternAnomalies: accessPatternAnomalies,
            geographicInconsistencies: geographicInconsistencies,
            editHistoryDiscrepancies: editHistoryDiscrepancies
        )
        
        print("✅ Cross-reference Intel Report generated: \(contentDiscrepancies.count) content discrepancies, \(metadataMismatches.count) metadata mismatches")
        return report
    }
    
    // MARK: - Content Discrepancy Detection
    
    private func detectContentDiscrepancies(doc1: Document, doc2: Document) async throws -> ContentDiscrepancy? {
        // Compare file hashes
        if let hash1 = doc1.fileHash, let hash2 = doc2.fileHash {
            if hash1 != hash2 {
                return ContentDiscrepancy(
                    documentID: doc1.id,
                    type: "complete_mismatch",
                    description: "File hash mismatch - documents have different content",
                    details: [
                        "shared_hash": hash1,
                        "antivault_hash": hash2,
                        "shared_name": doc1.name,
                        "antivault_name": doc2.name
                    ]
                )
            }
        }
        
        // Compare file sizes
        if abs(doc1.fileSize - doc2.fileSize) > 100 { // More than 100 bytes difference
            return ContentDiscrepancy(
                documentID: doc1.id,
                type: "significant_difference",
                description: "File size mismatch - possible content modification",
                details: [
                    "shared_size": String(doc1.fileSize),
                    "antivault_size": String(doc2.fileSize),
                    "difference": String(abs(doc1.fileSize - doc2.fileSize))
                ]
            )
        }
        
        // Compare extracted text (if available)
        if let text1 = doc1.extractedText, let text2 = doc2.extractedText {
            let similarity = calculateTextSimilarity(text1: text1, text2: text2)
            if similarity < 0.9 { // Less than 90% similar
                return ContentDiscrepancy(
                    documentID: doc1.id,
                    type: similarity < 0.5 ? "complete_mismatch" : "significant_difference",
                    description: "Text content mismatch - documents have different text",
                    details: [
                        "similarity": String(format: "%.2f", similarity),
                        "shared_text_length": String(text1.count),
                        "antivault_text_length": String(text2.count)
                    ]
                )
            }
        }
        
        return nil
    }
    
    private func calculateTextSimilarity(text1: String, text2: String) -> Double {
        // Simple similarity calculation using longest common subsequence
        let lcs = longestCommonSubsequence(text1, text2)
        let maxLength = max(text1.count, text2.count)
        return maxLength > 0 ? Double(lcs) / Double(maxLength) : 0.0
    }
    
    private func longestCommonSubsequence(_ s1: String, _ s2: String) -> Int {
        let chars1 = Array(s1)
        let chars2 = Array(s2)
        let m = chars1.count
        let n = chars2.count
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 1...m {
            for j in 1...n {
                if chars1[i - 1] == chars2[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1] + 1
                } else {
                    dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
                }
            }
        }
        
        return dp[m][n]
    }
    
    // MARK: - Metadata Mismatch Detection
    
    private func detectMetadataMismatches(doc1: Document, doc2: Document) -> MetadataMismatch? {
        // Check timestamp manipulation
        let timeDiff = abs(doc1.createdAt.timeIntervalSince(doc2.createdAt))
        if timeDiff > 3600 { // More than 1 hour difference
            return MetadataMismatch(
                documentID: doc1.id,
                type: "timestamp_manipulation",
                description: "Creation timestamp mismatch - possible timestamp manipulation",
                details: [
                    "shared_timestamp": doc1.createdAt.ISO8601Format(),
                    "antivault_timestamp": doc2.createdAt.ISO8601Format(),
                    "difference_seconds": String(Int(timeDiff))
                ]
            )
        }
        
        // Check checksum mismatch
        if let hash1 = doc1.fileHash, let hash2 = doc2.fileHash, hash1 != hash2 {
            return MetadataMismatch(
                documentID: doc1.id,
                type: "checksum_mismatch",
                description: "File checksum mismatch - file content has been modified",
                details: [
                    "shared_hash": hash1,
                    "antivault_hash": hash2
                ]
            )
        }
        
        // Check author change
        if let author1 = doc1.author, let author2 = doc2.author, author1 != author2 {
            return MetadataMismatch(
                documentID: doc1.id,
                type: "author_change",
                description: "Author metadata mismatch",
                details: [
                    "shared_author": author1,
                    "antivault_author": author2
                ]
            )
        }
        
        return nil
    }
    
    // MARK: - Access Pattern Analysis
    
    private func analyzeAccessPatterns(documents: [Document]) -> [AccessPatternAnomaly] {
        var anomalies: [AccessPatternAnomaly] = []
        
        // Group documents by upload time
        let sortedDocs = documents.sorted { $0.uploadedAt < $1.uploadedAt }
        
        // Check for rapid access pattern
        for i in 0..<sortedDocs.count - 1 {
            let timeDiff = sortedDocs[i + 1].uploadedAt.timeIntervalSince(sortedDocs[i].uploadedAt)
            if timeDiff < 60 { // Less than 1 minute between uploads
                anomalies.append(AccessPatternAnomaly(
                    type: "rapid_access",
                    description: "Rapid document access pattern detected",
                    details: [
                        "time_difference": String(Int(timeDiff)),
                        "document1": sortedDocs[i].name,
                        "document2": sortedDocs[i + 1].name
                    ]
                ))
            }
        }
        
        // Check for unusual access times (night time)
        let nightDocs = documents.filter { isNightTime($0.uploadedAt) }
        if nightDocs.count > documents.count / 2 {
            anomalies.append(AccessPatternAnomaly(
                type: "unusual_time",
                description: "Unusual access time pattern - majority of documents accessed at night",
                details: [
                    "night_access_count": String(nightDocs.count),
                    "total_count": String(documents.count)
                ]
            ))
        }
        
        return anomalies
    }
    
    private func isNightTime(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 22 || hour < 6 // 10 PM to 6 AM
    }
    
    // MARK: - Geographic Inconsistency Detection
    
    private func detectGeographicInconsistencies(sharedDocuments: [Document], antiVaultDocuments: [Document]) -> [GeographicInconsistency] {
        let inconsistencies: [GeographicInconsistency] = []
        
        // This would require location data from access logs
        // For now, return empty array - would be populated with actual location tracking
        // In a real implementation, this would analyze VaultAccessLog entries
        
        return inconsistencies
    }
    
    // MARK: - Edit History Discrepancy Detection
    
    private func detectEditHistoryDiscrepancies(doc1: Document, doc2: Document) -> EditHistoryDiscrepancy? {
        let versions1 = doc1.versions ?? []
        let versions2 = doc2.versions ?? []
        
        // Check for missing edits
        if versions1.count > versions2.count + 1 {
            return EditHistoryDiscrepancy(
                documentID: doc1.id,
                type: "missing_edits",
                description: "Shared document has more edit versions than anti-vault document",
                details: [
                    "shared_versions": String(versions1.count),
                    "antivault_versions": String(versions2.count),
                    "difference": String(versions1.count - versions2.count)
                ]
            )
        }
        
        // Check for extra edits
        if versions2.count > versions1.count + 1 {
            return EditHistoryDiscrepancy(
                documentID: doc1.id,
                type: "extra_edits",
                description: "Anti-vault document has more edit versions than shared document",
                details: [
                    "shared_versions": String(versions1.count),
                    "antivault_versions": String(versions2.count),
                    "difference": String(versions2.count - versions1.count)
                ]
            )
        }
        
        // Check timestamp mismatches in versions
        if let lastMod1 = doc1.lastModifiedAt, let lastMod2 = doc2.lastModifiedAt {
            let timeDiff = abs(lastMod1.timeIntervalSince(lastMod2))
            if timeDiff > 3600 { // More than 1 hour
                return EditHistoryDiscrepancy(
                    documentID: doc1.id,
                    type: "timestamp_mismatch",
                    description: "Last modification timestamp mismatch",
                    details: [
                        "shared_timestamp": lastMod1.ISO8601Format(),
                        "antivault_timestamp": lastMod2.ISO8601Format(),
                        "difference_seconds": String(Int(timeDiff))
                    ]
                )
            }
        }
        
        return nil
    }
    
    // MARK: - Document Matching
    
    private func matchDocuments(sharedDocuments: [Document], antiVaultDocuments: [Document]) -> [(Document, Document)] {
        var pairs: [(Document, Document)] = []
        
        for sharedDoc in sharedDocuments {
            // Try to match by name first
            if let match = antiVaultDocuments.first(where: { $0.name == sharedDoc.name }) {
                pairs.append((sharedDoc, match))
                continue
            }
            
            // Try to match by hash
            if let hash = sharedDoc.fileHash,
               let match = antiVaultDocuments.first(where: { $0.fileHash == hash }) {
                pairs.append((sharedDoc, match))
                continue
            }
            
            // Try to match by similar name (fuzzy matching)
            if let match = antiVaultDocuments.first(where: { 
                levenshteinDistance($0.name, sharedDoc.name) < 3
            }) {
                pairs.append((sharedDoc, match))
            }
        }
        
        return pairs
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let chars1 = Array(s1)
        let chars2 = Array(s2)
        let m = chars1.count
        let n = chars2.count
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            dp[i][0] = i
        }
        for j in 0...n {
            dp[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                if chars1[i - 1] == chars2[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    dp[i][j] = min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]) + 1
                }
            }
        }
        
        return dp[m][n]
    }
}

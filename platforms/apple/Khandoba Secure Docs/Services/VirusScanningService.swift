//
//  VirusScanningService.swift
//  Khandoba Secure Docs
//
//  Enhanced virus scanning service combining iOS + Web security features
//

import Foundation
import SwiftData
import Combine
import UniformTypeIdentifiers
import CryptoKit

@MainActor
final class VirusScanningService: ObservableObject {
    @Published var scanResults: [VirusScanResult] = []
    @Published var quarantinedDocuments: [QuarantinedDocument] = []
    @Published var isScanning = false
    
    private var modelContext: ModelContext?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadQuarantinedDocuments()
        }
    }
    
    // MARK: - Virus Scanning
    
    /// Scan a document for viruses and malware
    func scanDocument(_ document: Document) async throws -> VirusScanResult {
        guard let modelContext = modelContext else {
            throw VirusScanError.contextNotAvailable
        }
        
        isScanning = true
        defer { isScanning = false }
        
        print("🔍 Scanning document: \(document.name)")
        
        // Get document data
        guard let encryptedData = document.encryptedFileData else {
            throw VirusScanError.documentDataNotFound
        }
        
        // Decrypt document (in real implementation, this would be done securely)
        // For now, we'll scan the encrypted data and metadata
        
        var threats: [ThreatSignature] = []
        var riskScore: Double = 0.0
        
        // 1. File Type Analysis
        let fileTypeRisk = analyzeFileType(document: document)
        riskScore += fileTypeRisk.score
        if fileTypeRisk.isThreat {
            threats.append(ThreatSignature(
                type: .suspiciousFileType,
                severity: fileTypeRisk.severity,
                description: "Suspicious file type: \(document.fileExtension ?? "unknown")",
                confidence: fileTypeRisk.confidence
            ))
        }
        
        // 2. File Size Analysis
        let sizeRisk = analyzeFileSize(document: document)
        riskScore += sizeRisk.score
        if sizeRisk.isThreat {
            threats.append(ThreatSignature(
                type: .suspiciousSize,
                severity: sizeRisk.severity,
                description: "Unusually large file size: \(formatBytes(document.fileSize))",
                confidence: sizeRisk.confidence
            ))
        }
        
        // 3. File Name Analysis
        let nameRisk = analyzeFileName(document: document)
        riskScore += nameRisk.score
        if nameRisk.isThreat {
            threats.append(ThreatSignature(
                type: .suspiciousName,
                severity: nameRisk.severity,
                description: "Suspicious file name pattern detected",
                confidence: nameRisk.confidence
            ))
        }
        
        // 4. Content Analysis (if text-based)
        if let extractedText = document.extractedText {
            let contentRisk = analyzeContent(text: extractedText)
            riskScore += contentRisk.score
            if contentRisk.isThreat {
                threats.append(ThreatSignature(
                    type: .maliciousContent,
                    severity: contentRisk.severity,
                    description: "Malicious content patterns detected",
                    confidence: contentRisk.confidence
                ))
            }
        }
        
        // 5. Hash-based Detection (compare against known malware hashes)
        let hashRisk = await checkKnownThreatHashes(data: encryptedData)
        riskScore += hashRisk.score
        if hashRisk.isThreat {
            threats.append(ThreatSignature(
                type: .knownMalware,
                severity: .critical,
                description: "File matches known malware signature",
                confidence: 1.0
            ))
        }
        
        // 6. Metadata Analysis
        let metadataRisk = analyzeMetadata(document: document)
        riskScore += metadataRisk.score
        if metadataRisk.isThreat {
            threats.append(ThreatSignature(
                type: .suspiciousMetadata,
                severity: metadataRisk.severity,
                description: "Suspicious metadata detected",
                confidence: metadataRisk.confidence
            ))
        }
        
        // Calculate final risk score (0-100)
        let finalRiskScore = min(100.0, riskScore)
        
        // Determine if document should be quarantined
        let shouldQuarantine = finalRiskScore >= 50.0 || threats.contains { $0.severity == .critical }
        
        let result = VirusScanResult(
            documentID: document.id,
            documentName: document.name,
            riskScore: finalRiskScore,
            threats: threats,
            isInfected: shouldQuarantine,
            scannedAt: Date(),
            scanDuration: 0.0 // Would be calculated in real implementation
        )
        
        // If infected, quarantine immediately
        if shouldQuarantine {
            try await quarantineDocument(document, reason: "Virus scan detected threats", modelContext: modelContext)
        }
        
        // Save scan result
        await saveScanResult(result, modelContext: modelContext)
        
        print("✅ Scan complete: \(document.name) - Risk: \(finalRiskScore)% - Infected: \(shouldQuarantine)")
        
        return result
    }
    
    /// Scan all documents in a vault
    func scanVault(_ vault: Vault) async throws -> [VirusScanResult] {
        guard let documents = vault.documents else {
            return []
        }
        
        var results: [VirusScanResult] = []
        
        for document in documents {
            do {
                let result = try await scanDocument(document)
                results.append(result)
            } catch {
                print("⚠️ Failed to scan document \(document.name): \(error.localizedDescription)")
            }
        }
        
        return results
    }
    
    // MARK: - Threat Analysis
    
    private func analyzeFileType(document: Document) -> (score: Double, isThreat: Bool, severity: ThreatSeverity, confidence: Double) {
        // High-risk file types
        let highRiskExtensions: Set<String> = [
            "exe", "bat", "cmd", "com", "pif", "scr", "vbs", "js", "jar",
            "app", "dmg", "pkg", "deb", "rpm", "msi", "sh", "bin"
        ]
        
        let mediumRiskExtensions: Set<String> = [
            "zip", "rar", "7z", "tar", "gz", "doc", "docx", "xls", "xlsx",
            "ppt", "pptx", "pdf"
        ]
        
        guard let ext = document.fileExtension?.lowercased() else {
            return (0.0, false, .low, 0.0)
        }
        
        if highRiskExtensions.contains(ext) {
            return (30.0, true, .high, 0.8)
        } else if mediumRiskExtensions.contains(ext) {
            return (10.0, false, .medium, 0.5)
        }
        
        return (0.0, false, .low, 0.0)
    }
    
    private func analyzeFileSize(document: Document) -> (score: Double, isThreat: Bool, severity: ThreatSeverity, confidence: Double) {
        // Suspiciously large files (>100MB) or suspiciously small files (<1KB for non-text)
        let fileSize = document.fileSize
        
        if fileSize > 100_000_000 { // >100MB
            return (15.0, true, .medium, 0.6)
        } else if fileSize < 1024 && document.documentType != "text" {
            return (10.0, true, .low, 0.4)
        }
        
        return (0.0, false, .low, 0.0)
    }
    
    private func analyzeFileName(document: Document) -> (score: Double, isThreat: Bool, severity: ThreatSeverity, confidence: Double) {
        let name = document.name.lowercased()
        
        // Suspicious patterns
        let suspiciousPatterns = [
            "virus", "malware", "trojan", "worm", "spyware", "keylogger",
            "password", "secret", "confidential", "private", "hidden",
            "system", "admin", "root", "install", "setup", "update"
        ]
        
        var threatCount = 0
        for pattern in suspiciousPatterns {
            if name.contains(pattern) {
                threatCount += 1
            }
        }
        
        if threatCount >= 2 {
            return (20.0, true, .medium, 0.7)
        } else if threatCount == 1 {
            return (5.0, false, .low, 0.3)
        }
        
        return (0.0, false, .low, 0.0)
    }
    
    private func analyzeContent(text: String) -> (score: Double, isThreat: Bool, severity: ThreatSeverity, confidence: Double) {
        let lowerText = text.lowercased()
        
        // Malicious content patterns
        let maliciousPatterns = [
            "eval(", "exec(", "system(", "shell_exec", "base64_decode",
            "javascript:", "vbscript:", "<script", "onerror=", "onload="
        ]
        
        var threatCount = 0
        for pattern in maliciousPatterns {
            if lowerText.contains(pattern) {
                threatCount += 1
            }
        }
        
        if threatCount >= 3 {
            return (40.0, true, .critical, 0.9)
        } else if threatCount >= 1 {
            return (20.0, true, .high, 0.7)
        }
        
        return (0.0, false, .low, 0.0)
    }
    
    private func checkKnownThreatHashes(data: Data) async -> (score: Double, isThreat: Bool, severity: ThreatSeverity, confidence: Double) {
        // In a real implementation, this would check against a database of known malware hashes
        // For now, we'll use a simple hash check
        
        let hash = data.sha256()
        
        // Known threat hashes (example - in production, this would be a database)
        let knownThreatHashes: Set<String> = [
            // This would be populated from a threat intelligence database
        ]
        
        if knownThreatHashes.contains(hash) {
            return (100.0, true, .critical, 1.0)
        }
        
        return (0.0, false, .low, 0.0)
    }
    
    private func analyzeMetadata(document: Document) -> (score: Double, isThreat: Bool, severity: ThreatSeverity, confidence: Double) {
        // Check for suspicious metadata patterns
        // Missing timestamps, unusual creation dates, etc.
        
        var riskScore = 0.0
        
        // Check creation date (suspicious if very old or future date)
        if let createdAt = document.createdAt {
            let age = Date().timeIntervalSince(createdAt)
            if age < 0 { // Future date
                riskScore += 10.0
            } else if age > 31536000 * 20 { // >20 years old
                riskScore += 5.0
            }
        }
        
        // Check if document has no extracted text but claims to be text-based
        if document.documentType == "text" && (document.extractedText?.isEmpty ?? true) {
            riskScore += 15.0
        }
        
        if riskScore >= 20.0 {
            return (riskScore, true, .medium, 0.6)
        } else if riskScore > 0 {
            return (riskScore, false, .low, 0.4)
        }
        
        return (0.0, false, .low, 0.0)
    }
    
    // MARK: - Quarantine Management
    
    /// Quarantine an infected document
    func quarantineDocument(_ document: Document, reason: String, modelContext: ModelContext) async throws {
        let quarantined = QuarantinedDocument(
            documentID: document.id,
            documentName: document.name,
            vaultID: document.vault?.id,
            quarantinedAt: Date(),
            reason: reason,
            riskScore: 0.0 // Would be from scan result
        )
        
        // Mark document as quarantined
        // In a real implementation, you'd move the file to a secure quarantine location
        
        quarantinedDocuments.append(quarantined)
        await saveQuarantinedDocuments()
        
        print("🚨 Document quarantined: \(document.name) - Reason: \(reason)")
    }
    
    /// Restore a quarantined document
    func restoreDocument(_ documentID: UUID) async throws {
        guard let index = quarantinedDocuments.firstIndex(where: { $0.documentID == documentID }) else {
            throw VirusScanError.documentNotQuarantined
        }
        
        quarantinedDocuments.remove(at: index)
        await saveQuarantinedDocuments()
        
        print("✅ Document restored from quarantine: \(documentID)")
    }
    
    /// Delete a quarantined document permanently
    func deleteQuarantinedDocument(_ documentID: UUID, modelContext: ModelContext) async throws {
        guard let index = quarantinedDocuments.firstIndex(where: { $0.documentID == documentID }) else {
            throw VirusScanError.documentNotQuarantined
        }
        
        // Delete the actual document
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.id == documentID }
        )
        
        if let document = try? modelContext.fetch(descriptor).first {
            modelContext.delete(document)
            try modelContext.save()
        }
        
        quarantinedDocuments.remove(at: index)
        await saveQuarantinedDocuments()
        
        print("🗑️ Quarantined document deleted: \(documentID)")
    }
    
    // MARK: - Helper Methods
    
    private func loadQuarantinedDocuments() async {
        // Load from persistent storage
        // Implementation would load from UserDefaults or SwiftData
    }
    
    private func saveQuarantinedDocuments() async {
        // Save to persistent storage
        // Implementation would save to UserDefaults or SwiftData
    }
    
    private func saveScanResult(_ result: VirusScanResult, modelContext: ModelContext) async {
        scanResults.append(result)
        // Could also save to SwiftData for audit trail
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Models

struct VirusScanResult: Identifiable, Codable {
    let id: UUID
    let documentID: UUID
    let documentName: String
    let riskScore: Double
    let threats: [ThreatSignature]
    let isInfected: Bool
    let scannedAt: Date
    let scanDuration: Double
    
    init(documentID: UUID, documentName: String, riskScore: Double, threats: [ThreatSignature], isInfected: Bool, scannedAt: Date, scanDuration: Double) {
        self.id = UUID()
        self.documentID = documentID
        self.documentName = documentName
        self.riskScore = riskScore
        self.threats = threats
        self.isInfected = isInfected
        self.scannedAt = scannedAt
        self.scanDuration = scanDuration
    }
}

struct ThreatSignature: Codable {
    let type: ThreatType
    let severity: ThreatSeverity
    let description: String
    let confidence: Double
}

enum ThreatType: String, Codable {
    case suspiciousFileType = "Suspicious File Type"
    case suspiciousSize = "Suspicious Size"
    case suspiciousName = "Suspicious Name"
    case maliciousContent = "Malicious Content"
    case knownMalware = "Known Malware"
    case suspiciousMetadata = "Suspicious Metadata"
}

enum ThreatSeverity: String, Codable, Comparable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    private var severityLevel: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    static func < (lhs: ThreatSeverity, rhs: ThreatSeverity) -> Bool {
        lhs.severityLevel < rhs.severityLevel
    }
}

struct QuarantinedDocument: Identifiable, Codable {
    let id: UUID
    let documentID: UUID
    let documentName: String
    let vaultID: UUID?
    let quarantinedAt: Date
    let reason: String
    let riskScore: Double
    
    init(documentID: UUID, documentName: String, vaultID: UUID?, quarantinedAt: Date, reason: String, riskScore: Double) {
        self.id = UUID()
        self.documentID = documentID
        self.documentName = documentName
        self.vaultID = vaultID
        self.quarantinedAt = quarantinedAt
        self.reason = reason
        self.riskScore = riskScore
    }
}

enum VirusScanError: LocalizedError {
    case contextNotAvailable
    case documentDataNotFound
    case documentNotQuarantined
    case scanFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Virus scanning service not configured"
        case .documentDataNotFound:
            return "Document data not found"
        case .documentNotQuarantined:
            return "Document is not quarantined"
        case .scanFailed:
            return "Virus scan failed"
        }
    }
}

// MARK: - Extensions

extension Data {
    func sha256() -> String {
        let hash = SHA256.hash(data: self)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}


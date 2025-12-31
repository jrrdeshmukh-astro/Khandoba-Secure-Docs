//
//  ComplianceDetectionService.swift
//  Khandoba Secure Docs
//
//  Service to automatically detect compliance regime needs based on user data
//  Replaces Role Selection with intelligent compliance detection
//

import Foundation
import SwiftData
import Combine
import NaturalLanguage

@MainActor
final class ComplianceDetectionService: ObservableObject {
    @Published var detectedRecommendations: [ComplianceRecommendation] = []
    @Published var isDetecting = false
    
    private var modelContext: ModelContext?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Compliance Detection
    
    /// Detect compliance regime needs for a user based on their data
    func detectComplianceRegime(for user: User, vaults: [Vault], documents: [Document]) async -> [ComplianceRecommendation] {
        isDetecting = true
        defer { isDetecting = false }
        
        print("🔍 Detecting compliance regime needs for user: \(user.fullName)")
        
        var recommendations: [ComplianceRecommendation] = []
        
        // 1. Detect PHI (HIPAA requirement)
        let hasPHI = await detectPHI(in: documents)
        if hasPHI {
            recommendations.append(ComplianceRecommendation(
                framework: .hipaa,
                priority: .required,
                confidence: 0.85,
                reason: "Protected Health Information (PHI) detected in documents",
                requirements: [
                    "Implement access controls",
                    "Enable audit logging",
                    "Encrypt data at rest and in transit",
                    "Implement breach notification procedures"
                ]
            ))
        }
        
        // 2. Detect Financial Data (FINRA requirement)
        let hasFinancialData = await detectFinancialData(in: documents)
        if hasFinancialData {
            recommendations.append(ComplianceRecommendation(
                framework: .finra,
                priority: .required,
                confidence: 0.80,
                reason: "Financial data and trading information detected",
                requirements: [
                    "Implement record retention policies",
                    "Enable transaction monitoring",
                    "Implement customer data protection",
                    "Enable audit trails"
                ]
            ))
        }
        
        // 3. Detect Government/Defense Data (DFARS requirement)
        let hasGovernmentData = await detectGovernmentDefenseData(in: documents)
        if hasGovernmentData {
            recommendations.append(ComplianceRecommendation(
                framework: .dfars,
                priority: .required,
                confidence: 0.90,
                reason: "Government or defense-related data detected",
                requirements: [
                    "Implement NIST 800-171 controls",
                    "Enable Controlled Unclassified Information (CUI) protection",
                    "Implement incident response procedures",
                    "Enable security assessment capabilities"
                ]
            ))
        }
        
        // 4. Detect High-Security Content (NIST 800-53 requirement)
        let hasHighSecurityContent = await detectHighSecurityContent(in: documents, vaults: vaults)
        if hasHighSecurityContent {
            recommendations.append(ComplianceRecommendation(
                framework: .nist80053,
                priority: .recommended,
                confidence: 0.75,
                reason: "High-security content and sensitive data detected",
                requirements: [
                    "Implement access control policies",
                    "Enable continuous monitoring",
                    "Implement security assessment procedures",
                    "Enable incident response capabilities"
                ]
            ))
        }
        
        // 5. Detect Service Organization (SOC 2 requirement)
        let isServiceOrganization = await detectServiceOrganization(user: user, vaults: vaults)
        if isServiceOrganization {
            recommendations.append(ComplianceRecommendation(
                framework: .soc2,
                priority: .recommended,
                confidence: 0.70,
                reason: "Service organization patterns detected",
                requirements: [
                    "Implement security controls",
                    "Enable availability monitoring",
                    "Implement processing integrity controls",
                    "Enable confidentiality and privacy controls"
                ]
            ))
        }
        
        // 6. Detect International Operations (ISO 27001 requirement)
        let hasInternationalOperations = await detectInternationalOperations(user: user, documents: documents)
        if hasInternationalOperations {
            recommendations.append(ComplianceRecommendation(
                framework: .iso27001,
                priority: .optional,
                confidence: 0.65,
                reason: "International operations or data detected",
                requirements: [
                    "Implement information security management system",
                    "Enable risk assessment procedures",
                    "Implement security controls",
                    "Enable continuous improvement"
                ]
            ))
        }
        
        // Sort by priority and confidence
        recommendations.sort { first, second in
            if first.priority != second.priority {
                return first.priority.rawValue > second.priority.rawValue
            }
            return first.confidence > second.confidence
        }
        
        await MainActor.run {
            self.detectedRecommendations = recommendations
        }
        
        print("✅ Compliance detection complete - Found \(recommendations.count) recommendation(s)")
        
        return recommendations
    }
    
    // MARK: - Detection Helpers
    
    private func detectPHI(in documents: [Document]) async -> Bool {
        // PHI indicators: SSN, medical records, health insurance, patient data
        let phiKeywords = [
            "ssn", "social security", "medical record", "patient", "diagnosis",
            "treatment", "prescription", "health insurance", "hipaa", "phi",
            "protected health", "medical history", "healthcare", "hospital"
        ]
        
        for document in documents {
            // Check document name
            if let name = document.name.lowercased(),
               phiKeywords.contains(where: { name.contains($0) }) {
                return true
            }
            
            // Check extracted text
            if let text = document.extractedText?.lowercased() {
                for keyword in phiKeywords {
                    if text.contains(keyword) {
                        return true
                    }
                }
            }
            
            // Check AI tags
            if let tags = document.aiTags {
                for tag in tags {
                    if phiKeywords.contains(where: { tag.lowercased().contains($0) }) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func detectFinancialData(in documents: [Document]) async -> Bool {
        // Financial indicators: trading, securities, investment, banking, tax
        let financialKeywords = [
            "trading", "securities", "investment", "portfolio", "broker",
            "finra", "sec", "tax return", "w-2", "1099", "bank statement",
            "financial statement", "balance sheet", "income statement"
        ]
        
        for document in documents {
            if let name = document.name.lowercased(),
               financialKeywords.contains(where: { name.contains($0) }) {
                return true
            }
            
            if let text = document.extractedText?.lowercased() {
                for keyword in financialKeywords {
                    if text.contains(keyword) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func detectGovernmentDefenseData(in documents: [Document]) async -> Bool {
        // Government/Defense indicators: classified, CUI, government contract, defense
        let governmentKeywords = [
            "classified", "cui", "controlled unclassified", "government contract",
            "defense", "military", "dod", "dfars", "nist 800-171", "federal",
            "contractor", "subcontractor"
        ]
        
        for document in documents {
            if let name = document.name.lowercased(),
               governmentKeywords.contains(where: { name.contains($0) }) {
                return true
            }
            
            if let text = document.extractedText?.lowercased() {
                for keyword in governmentKeywords {
                    if text.contains(keyword) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func detectHighSecurityContent(in documents: [Document], vaults: [Vault]) async -> Bool {
        // High-security indicators: dual-key vaults, high threat levels, sensitive data
        let hasDualKeyVaults = vaults.contains { $0.keyType == .dual }
        let hasHighThreatVaults = vaults.contains { $0.threatLevel == .high || $0.threatLevel == .critical }
        
        if hasDualKeyVaults || hasHighThreatVaults {
            return true
        }
        
        // Check for sensitive keywords
        let sensitiveKeywords = [
            "confidential", "secret", "proprietary", "restricted", "sensitive",
            "private", "internal", "classified"
        ]
        
        for document in documents {
            if let name = document.name.lowercased(),
               sensitiveKeywords.contains(where: { name.contains($0) }) {
                return true
            }
        }
        
        return false
    }
    
    private func detectServiceOrganization(user: User, vaults: [Vault]) async -> Bool {
        // Service organization indicators: multiple vaults, shared vaults, nominee access
        let hasMultipleVaults = vaults.count > 3
        let hasSharedVaults = vaults.contains { $0.isShared }
        
        // Check for service-related keywords in user profile
        let serviceKeywords = ["service", "provider", "organization", "company", "business"]
        let userProfile = (user.fullName + " " + (user.email ?? "")).lowercased()
        let hasServiceKeywords = serviceKeywords.contains(where: { userProfile.contains($0) })
        
        return hasMultipleVaults || hasSharedVaults || hasServiceKeywords
    }
    
    private func detectInternationalOperations(user: User, documents: [Document]) async -> Bool {
        // International indicators: multiple countries, international keywords
        let internationalKeywords = [
            "international", "global", "europe", "asia", "multinational",
            "cross-border", "gdpr", "international trade"
        ]
        
        // Check user email domain (could indicate international operations)
        if let email = user.email?.lowercased(),
           !email.contains(".com") || email.contains(".uk") || email.contains(".eu") {
            return true
        }
        
        // Check documents
        for document in documents {
            if let name = document.name.lowercased(),
               internationalKeywords.contains(where: { name.contains($0) }) {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Models

struct ComplianceRecommendation: Identifiable, Codable {
    let id: UUID
    let framework: ComplianceFramework
    let priority: CompliancePriority
    let confidence: Double // 0.0 - 1.0
    let reason: String
    let requirements: [String]
    
    init(framework: ComplianceFramework, priority: CompliancePriority, confidence: Double, reason: String, requirements: [String]) {
        self.id = UUID()
        self.framework = framework
        self.priority = priority
        self.confidence = confidence
        self.reason = reason
        self.requirements = requirements
    }
}

enum ComplianceFramework: String, Codable, CaseIterable {
    case soc2 = "SOC 2"
    case hipaa = "HIPAA"
    case nist80053 = "NIST 800-53"
    case iso27001 = "ISO 27001"
    case dfars = "DFARS"
    case finra = "FINRA"
    
    var description: String {
        switch self {
        case .soc2:
            return "Service Organization Control 2 - Security, availability, processing integrity, confidentiality, and privacy"
        case .hipaa:
            return "Health Insurance Portability and Accountability Act - Healthcare data protection"
        case .nist80053:
            return "NIST Special Publication 800-53 - Security and privacy controls for federal systems"
        case .iso27001:
            return "ISO/IEC 27001 - Information security management system"
        case .dfars:
            return "Defense Federal Acquisition Regulation Supplement - Defense contractor requirements"
        case .finra:
            return "Financial Industry Regulatory Authority - Financial services compliance"
        }
    }
    
    var icon: String {
        switch self {
        case .soc2: return "shield.checkered"
        case .hipaa: return "cross.case.fill"
        case .nist80053: return "lock.shield.fill"
        case .iso27001: return "globe"
        case .dfars: return "shield.lefthalf.filled"
        case .finra: return "dollarsign.circle.fill"
        }
    }
}

enum CompliancePriority: String, Codable, Comparable {
    case optional = "Optional"
    case recommended = "Recommended"
    case required = "Required"
    
    var rawValue: Int {
        switch self {
        case .optional: return 1
        case .recommended: return 2
        case .required: return 3
        }
    }
    
    static func < (lhs: CompliancePriority, rhs: CompliancePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}


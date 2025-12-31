//
//  ComplianceDetectionService.swift
//  Khandoba Secure Docs
//
//  Automatic compliance regime detection based on user data
//

import Foundation
import SwiftData
import NaturalLanguage
import Combine

/// Compliance detection result
struct ComplianceRecommendation: Identifiable {
    let id = UUID()
    let framework: ComplianceFramework
    let confidence: Double // 0.0 to 1.0
    let reason: String
    let priority: Priority
    
    enum Priority: String {
        case required = "Required"
        case recommended = "Recommended"
        case optional = "Optional"
    }
}

/// Industry indicators
enum IndustryIndicator: String {
    case healthcare = "Healthcare"
    case financial = "Financial"
    case government = "Government"
    case defense = "Defense"
    case technology = "Technology"
    case general = "General"
}

@MainActor
final class ComplianceDetectionService: ObservableObject {
    static let shared = ComplianceDetectionService()
    
    @Published var recommendations: [ComplianceRecommendation] = []
    @Published var detectedIndustry: IndustryIndicator?
    @Published var isAnalyzing = false
    
    private var modelContext: ModelContext?
    private let phiService = PHIDetectionService.shared
    
    private init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Main Detection Function
    
    /// Analyze user data and determine required compliance frameworks
    func detectComplianceRegime() async throws -> [ComplianceRecommendation] {
        guard let modelContext = modelContext else {
            throw ComplianceDetectionError.contextNotAvailable
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        var recommendations: [ComplianceRecommendation] = []
        
        // 1. Analyze documents for PHI
        let hasPHI = await detectPHI()
        
        // 2. Analyze vault names and document content for industry indicators
        let industry = await detectIndustry()
        detectedIndustry = industry
        
        // 3. Analyze document types and keywords
        let documentAnalysis = await analyzeDocuments()
        
        // 4. Check for financial data
        let hasFinancialData = await detectFinancialData()
        
        // 5. Check for government/defense indicators
        let hasGovernmentData = await detectGovernmentData()
        
        // 6. Generate recommendations based on findings
        
        // HIPAA - Required if PHI detected or healthcare industry
        if hasPHI || industry == .healthcare {
            recommendations.append(ComplianceRecommendation(
                framework: .hipaa,
                confidence: hasPHI ? 0.95 : 0.75,
                reason: hasPHI ? "PHI detected in documents" : "Healthcare industry indicators found",
                priority: .required
            ))
        }
        
        // FINRA - Required if financial data detected
        if hasFinancialData || industry == .financial {
            recommendations.append(ComplianceRecommendation(
                framework: .finra,
                confidence: hasFinancialData ? 0.90 : 0.70,
                reason: hasFinancialData ? "Financial data detected" : "Financial industry indicators found",
                priority: .required
            ))
        }
        
        // DFARS - Required if government/defense data detected
        if hasGovernmentData || industry == .defense || industry == .government {
            recommendations.append(ComplianceRecommendation(
                framework: .dfars,
                confidence: hasGovernmentData ? 0.95 : 0.80,
                reason: hasGovernmentData ? "Government/defense data detected" : "Government/defense industry indicators found",
                priority: .required
            ))
        }
        
        // NIST 800-53 - Recommended for government, defense, or high-security data
        if hasGovernmentData || industry == .government || industry == .defense || documentAnalysis.hasHighSecurityData {
            recommendations.append(ComplianceRecommendation(
                framework: .nist80053,
                confidence: 0.75,
                reason: "High-security or government data detected",
                priority: .recommended
            ))
        }
        
        // ISO 27001 - Recommended for all (general security best practices)
        recommendations.append(ComplianceRecommendation(
            framework: .iso27001,
            confidence: 0.60,
            reason: "General information security best practices",
            priority: .recommended
        ))
        
        // SOC 2 - Recommended for all (service organization controls)
        recommendations.append(ComplianceRecommendation(
            framework: .soc2,
            confidence: 0.65,
            reason: "Service organization control best practices",
            priority: .recommended
        ))
        
        // Sort by priority and confidence
        recommendations.sort { first, second in
            if first.priority == .required && second.priority != .required {
                return true
            } else if first.priority != .required && second.priority == .required {
                return false
            }
            return first.confidence > second.confidence
        }
        
        self.recommendations = recommendations
        return recommendations
    }
    
    // MARK: - Detection Methods
    
    /// Detect PHI in documents
    private func detectPHI() async -> Bool {
        guard let modelContext = modelContext else { return false }
        
        do {
            let descriptor = FetchDescriptor<Document>(
                sortBy: [SortDescriptor(\.uploadedAt, order: .reverse)]
            )
            let documents = try modelContext.fetch(descriptor)
            
            // Check recent documents (last 50) for PHI
            for document in documents.prefix(50) {
                if let encryptedData = document.encryptedFileData {
                    // Decrypt and check for PHI
                    // For now, check if document has PHI tags
                    if !document.aiTags.filter({ $0.lowercased().contains("phi") || $0.lowercased().contains("medical") || $0.lowercased().contains("patient") }).isEmpty {
                        return true
                    }
                }
            }
        } catch {
            print("Error detecting PHI: \(error)")
        }
        
        return false
    }
    
    /// Detect industry from vault names and document content
    private func detectIndustry() async -> IndustryIndicator {
        guard let modelContext = modelContext else { return .general }
        
        var industryScores: [IndustryIndicator: Int] = [
            .healthcare: 0,
            .financial: 0,
            .government: 0,
            .defense: 0,
            .technology: 0,
            .general: 0
        ]
        
        do {
            // Analyze vault names
            let vaultDescriptor = FetchDescriptor<Vault>()
            let vaults = try modelContext.fetch(vaultDescriptor)
            
            for vault in vaults {
                let name = vault.name.lowercased()
                
                // Healthcare indicators
                if name.contains("medical") || name.contains("health") || name.contains("patient") || 
                   name.contains("hipaa") || name.contains("phi") || name.contains("hospital") {
                    industryScores[.healthcare, default: 0] += 3
                }
                
                // Financial indicators
                if name.contains("financial") || name.contains("bank") || name.contains("investment") ||
                   name.contains("finra") || name.contains("securities") || name.contains("trading") {
                    industryScores[.financial, default: 0] += 3
                }
                
                // Government indicators
                if name.contains("government") || name.contains("federal") || name.contains("state") ||
                   name.contains("public") || name.contains("agency") {
                    industryScores[.government, default: 0] += 3
                }
                
                // Defense indicators
                if name.contains("defense") || name.contains("military") || name.contains("dfars") ||
                   name.contains("classified") || name.contains("security clearance") {
                    industryScores[.defense, default: 0] += 3
                }
                
                // Technology indicators
                if name.contains("tech") || name.contains("software") || name.contains("development") {
                    industryScores[.technology, default: 0] += 1
                }
            }
            
            // Analyze document content
            let documentDescriptor = FetchDescriptor<Document>(
                sortBy: [SortDescriptor(\.uploadedAt, order: .reverse)]
            )
            let documents = try modelContext.fetch(documentDescriptor)
            
            for document in documents.prefix(100) {
                let name = document.name.lowercased()
                let tags = document.aiTags.joined(separator: " ").lowercased()
                
                // Healthcare
                if name.contains("medical") || name.contains("patient") || name.contains("diagnosis") ||
                   tags.contains("medical") || tags.contains("healthcare") || tags.contains("phi") {
                    industryScores[.healthcare, default: 0] += 1
                }
                
                // Financial
                if name.contains("financial") || name.contains("bank") || name.contains("statement") ||
                   tags.contains("financial") || tags.contains("banking") || tags.contains("investment") {
                    industryScores[.financial, default: 0] += 1
                }
                
                // Government
                if name.contains("government") || name.contains("federal") || name.contains("contract") ||
                   tags.contains("government") || tags.contains("federal") {
                    industryScores[.government, default: 0] += 1
                }
                
                // Defense
                if name.contains("defense") || name.contains("military") || name.contains("classified") ||
                   tags.contains("defense") || tags.contains("military") {
                    industryScores[.defense, default: 0] += 1
                }
            }
            
            // Return industry with highest score
            if let maxIndustry = industryScores.max(by: { $0.value < $1.value }),
               maxIndustry.value > 0 {
                return maxIndustry.key
            }
        } catch {
            print("Error detecting industry: \(error)")
        }
        
        return .general
    }
    
    /// Analyze documents for content patterns
    private func analyzeDocuments() async -> (hasHighSecurityData: Bool, hasSensitiveData: Bool) {
        guard let modelContext = modelContext else { return (false, false) }
        
        var hasHighSecurityData = false
        var hasSensitiveData = false
        
        do {
            let descriptor = FetchDescriptor<Document>(
                sortBy: [SortDescriptor(\.uploadedAt, order: .reverse)]
            )
            let documents = try modelContext.fetch(descriptor)
            
            for document in documents.prefix(100) {
                let name = document.name.lowercased()
                let tags = document.aiTags.joined(separator: " ").lowercased()
                
                // High security indicators
                if name.contains("classified") || name.contains("top secret") || name.contains("confidential") ||
                   tags.contains("classified") || tags.contains("secret") || tags.contains("confidential") {
                    hasHighSecurityData = true
                }
                
                // Sensitive data indicators
                if name.contains("ssn") || name.contains("social security") || name.contains("credit card") ||
                   tags.contains("ssn") || tags.contains("pii") || tags.contains("sensitive") {
                    hasSensitiveData = true
                }
            }
        } catch {
            print("Error analyzing documents: \(error)")
        }
        
        return (hasHighSecurityData, hasSensitiveData)
    }
    
    /// Detect financial data
    private func detectFinancialData() async -> Bool {
        guard let modelContext = modelContext else { return false }
        
        do {
            let descriptor = FetchDescriptor<Document>(
                sortBy: [SortDescriptor(\.uploadedAt, order: .reverse)]
            )
            let documents = try modelContext.fetch(descriptor)
            
            let financialKeywords = ["financial", "bank", "investment", "securities", "trading", "portfolio", 
                                   "statement", "account", "transaction", "finra", "sec", "broker"]
            
            for document in documents.prefix(100) {
                let name = document.name.lowercased()
                let tags = document.aiTags.joined(separator: " ").lowercased()
                
                if financialKeywords.contains(where: { name.contains($0) || tags.contains($0) }) {
                    return true
                }
            }
        } catch {
            print("Error detecting financial data: \(error)")
        }
        
        return false
    }
    
    /// Detect government/defense data
    private func detectGovernmentData() async -> Bool {
        guard let modelContext = modelContext else { return false }
        
        do {
            let descriptor = FetchDescriptor<Document>(
                sortBy: [SortDescriptor(\.uploadedAt, order: .reverse)]
            )
            let documents = try modelContext.fetch(descriptor)
            
            let governmentKeywords = ["government", "federal", "state", "defense", "military", "classified",
                                     "dfars", "contract", "agency", "public sector", "security clearance"]
            
            for document in documents.prefix(100) {
                let name = document.name.lowercased()
                let tags = document.aiTags.joined(separator: " ").lowercased()
                
                if governmentKeywords.contains(where: { name.contains($0) || tags.contains($0) }) {
                    return true
                }
            }
        } catch {
            print("Error detecting government data: \(error)")
        }
        
        return false
    }
}

// MARK: - Errors

enum ComplianceDetectionError: LocalizedError {
    case contextNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Model context is not available."
        }
    }
}


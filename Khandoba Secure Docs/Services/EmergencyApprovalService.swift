//
//  EmergencyApprovalService.swift
//  Khandoba Secure Docs
//
//  Hybrid ML+Manual emergency approval service
//  ML suggests approval, but requires manual confirmation
//

import Foundation
import SwiftData
import Combine

@MainActor
final class EmergencyApprovalService: ObservableObject {
    @Published var pendingRequests: [EmergencyAccessRequest] = []
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    private let mlThreatService = MLThreatAnalysisService()
    
    // iOS-ONLY: Using SwiftData/CloudKit exclusively
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Load Pending Requests
    
    func loadPendingRequests() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw ApprovalError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<EmergencyAccessRequest>(
            predicate: #Predicate { $0.status == "pending" },
            sortBy: [SortDescriptor(\.requestedAt, order: .reverse)]
        )
        
        let requests = try modelContext.fetch(descriptor)
        pendingRequests = requests
        
        print("📋 Loaded \(requests.count) pending emergency request(s)")
    }
    
    // MARK: - ML-Assisted Approval Analysis
    
    /// Analyze emergency request and provide ML confidence score
    func analyzeEmergencyRequest(_ request: EmergencyAccessRequest) async -> ApprovalRecommendation {
        guard let vault = request.vault else {
            return ApprovalRecommendation(
                shouldApprove: false,
                confidence: 0.0,
                reasoning: "Vault not found",
                riskFactors: []
            )
        }
        
        // Get ML threat analysis - combine multiple metrics
        let geoMetrics = await mlThreatService.analyzeGeoClassification(for: vault)
        let tagMetrics = mlThreatService.analyzeTagPatterns(for: vault)
        let accessMetrics = await mlThreatService.analyzeAccessPatterns(for: vault)
        
        // Calculate overall risk score (0.0 to 1.0)
        let overallRiskScore = (geoMetrics.riskScore + tagMetrics.riskScore + accessMetrics.riskScore) / 3.0
        
        // Analyze request characteristics
        var riskFactors: [String] = []
        var confidence: Double = 0.5 // Start neutral
        
        // Urgency-based confidence adjustment
        switch request.urgency.lowercased() {
        case "critical":
            confidence += 0.2 // Higher confidence for critical
        case "high":
            confidence += 0.1
        case "medium":
            // No change
            break
        case "low":
            confidence -= 0.1 // Lower confidence for low urgency
        default:
            break
        }
        
        // Reason analysis (basic NLP)
        let reason = request.reason.lowercased()
        let positiveKeywords = ["medical", "emergency", "urgent", "critical", "immediate", "accident", "hospital"]
        let negativeKeywords = ["test", "demo", "check", "just", "curious"]
        
        let hasPositiveKeywords = positiveKeywords.contains { reason.contains($0) }
        let hasNegativeKeywords = negativeKeywords.contains { reason.contains($0) }
        
        if hasPositiveKeywords {
            confidence += 0.15
        }
        if hasNegativeKeywords {
            confidence -= 0.2
            riskFactors.append("Reason contains non-emergency keywords")
        }
        
        // Threat metrics influence
        if overallRiskScore > 0.7 {
            confidence -= 0.2
            riskFactors.append("High threat risk detected in vault")
        } else if overallRiskScore < 0.3 {
            confidence += 0.1
        }
        
        // Time since request (recent requests get slight boost)
        let hoursSinceRequest = Date().timeIntervalSince(request.requestedAt) / 3600
        if hoursSinceRequest < 1 {
            confidence += 0.05 // Very recent
        } else if hoursSinceRequest > 24 {
            confidence -= 0.1 // Stale request
            riskFactors.append("Request is more than 24 hours old")
        }
        
        // Clamp confidence between 0 and 1
        confidence = max(0.0, min(1.0, confidence))
        
        let shouldApprove = confidence >= 0.6 // Threshold for recommendation
        
        let reasoning = buildReasoning(
            confidence: confidence,
            urgency: request.urgency,
            threatScore: overallRiskScore,
            riskFactors: riskFactors
        )
        
        return ApprovalRecommendation(
            shouldApprove: shouldApprove,
            confidence: confidence,
            reasoning: reasoning,
            riskFactors: riskFactors
        )
    }
    
    private func buildReasoning(confidence: Double, urgency: String, threatScore: Double, riskFactors: [String]) -> String {
        var parts: [String] = []
        
        if confidence >= 0.7 {
            parts.append("High confidence recommendation")
        } else if confidence >= 0.5 {
            parts.append("Moderate confidence recommendation")
        } else {
            parts.append("Low confidence - review carefully")
        }
        
        parts.append("Urgency: \(urgency.capitalized)")
        parts.append("Vault threat score: \(String(format: "%.1f", threatScore))")
        
        if !riskFactors.isEmpty {
            parts.append("Risk factors: \(riskFactors.joined(separator: ", "))")
        }
        
        return parts.joined(separator: ". ")
    }
    
    // MARK: - Approve Emergency Request
    
    func approveEmergencyRequest(_ request: EmergencyAccessRequest, approverID: UUID) async throws {
        guard let vault = request.vault else {
            throw ApprovalError.vaultNotFound
        }
        
        // Generate identification pass code
        let passCode = UUID().uuidString
        let expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw ApprovalError.contextNotAvailable
        }
        
        // Update request status
        request.status = "approved"
        request.approvedAt = Date()
        request.approverID = approverID
        request.expiresAt = expiresAt
        request.passCode = passCode
        
        // Create EmergencyAccessPass record
        let accessPass = EmergencyAccessPass(
            vaultID: vault.id,
            requesterID: request.requesterID ?? UUID(),
            emergencyRequestID: request.id,
            expiresAt: expiresAt
        )
        accessPass.passCode = passCode
        accessPass.emergencyRequest = request
        request.accessPass = accessPass
        
        modelContext.insert(accessPass)
        
        // Grant nominee read-only access
        // Find the nominee who requested this (if any)
        if let requesterID = request.requesterID,
           let nominees = vault.nomineeList {
            // Find nominee by requester ID or create temporary access
            for nominee in nominees {
                if nominee.invitedByUserID == requesterID || nominee.id == requesterID {
                    // Grant temporary active status
                    nominee.status = .active
                    nominee.lastActiveAt = Date()
                    print("✅ Granted emergency access to nominee: \(nominee.name)")
                    break
                }
            }
        }
        
        try modelContext.save()
        print("✅ Emergency request approved: \(request.id)")
        print("   Pass Code: \(passCode)")
        print("   Expires at: \(expiresAt.formatted())")
        
        // Reload pending requests
        try await loadPendingRequests()
    }
    
    // MARK: - Verify Emergency Access Pass
    
    func verifyEmergencyPass(passCode: String, vaultID: UUID) async throws -> EmergencyAccessPass? {
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw ApprovalError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<EmergencyAccessPass>(
            predicate: #Predicate { pass in
                pass.passCode == passCode && pass.vaultID == vaultID
            }
        )
        
        guard let pass = try? modelContext.fetch(descriptor).first,
              pass.isValid else {
            return nil
        }
        
        return pass
    }
    
    // MARK: - Use Emergency Pass (Mark as Used)
    
    func useEmergencyPass(_ pass: EmergencyAccessPass) async throws {
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw ApprovalError.contextNotAvailable
        }
        
        pass.usedAt = Date()
        pass.isActive = false
        
        try modelContext.save()
    }
    
    // MARK: - Deny Emergency Request
    
    func denyEmergencyRequest(_ request: EmergencyAccessRequest, approverID: UUID, reason: String? = nil) async throws {
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw ApprovalError.contextNotAvailable
        }
        
        request.status = "denied"
        request.approverID = approverID
        
        try modelContext.save()
        print("❌ Emergency request denied: \(request.id)")
        
        // Reload pending requests
        try await loadPendingRequests()
    }
}

// MARK: - Approval Recommendation

struct ApprovalRecommendation {
    let shouldApprove: Bool
    let confidence: Double // 0.0 to 1.0
    let reasoning: String
    let riskFactors: [String]
    
    var confidencePercentage: Int {
        Int(confidence * 100)
    }
    
    var confidenceLevel: String {
        if confidence >= 0.8 {
            return "High"
        } else if confidence >= 0.6 {
            return "Moderate"
        } else if confidence >= 0.4 {
            return "Low"
        } else {
            return "Very Low"
        }
    }
}

// MARK: - Approval Errors

enum ApprovalError: LocalizedError {
    case contextNotAvailable
    case vaultNotFound
    case requestNotFound
    case alreadyProcessed
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Model context not available"
        case .vaultNotFound:
            return "Vault not found"
        case .requestNotFound:
            return "Emergency request not found"
        case .alreadyProcessed:
            return "Request has already been processed"
        }
    }
}

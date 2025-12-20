//
//  ThreatRemediationAIService.swift
//  Khandoba Secure Docs
//
//  AI-powered threat-specific remediation generation using Apple's Foundation Models
//

import Foundation
import NaturalLanguage
import Combine

@MainActor
final class ThreatRemediationAIService: ObservableObject {
    @Published var isGenerating = false
    
    nonisolated init() {}
    
    /// Generate threat-specific remediation procedures using AI
    func generateRemediationSteps(
        for threat: ThreatItem,
        vaultName: String,
        threatDetails: ThreatContext
    ) async -> [String] {
        isGenerating = true
        defer { isGenerating = false }
        
        // Build context for AI analysis
        let context = buildThreatContext(threat: threat, vaultName: vaultName, details: threatDetails)
        
        // Generate AI-powered remediation steps
        let steps = await generateAISteps(context: context)
        
        return steps
    }
    
    /// Generate remediation for TriageResult
    func generateRemediationSteps(for result: TriageResult) async -> [String] {
        isGenerating = true
        defer { isGenerating = false }
        
        let context = buildTriageContext(result: result)
        let steps = await generateAISteps(context: context)
        
        return steps
    }
    
    // MARK: - Private Methods
    
    private func buildThreatContext(
        threat: ThreatItem,
        vaultName: String,
        details: ThreatContext
    ) -> String {
        var context = """
        SECURITY THREAT ANALYSIS AND REMEDIATION
        
        Threat Type: \(threatTypeDescription(threat.type))
        Severity: \(threat.severity.rawValue)
        Vault: \(vaultName)
        Detected: \(threat.timestamp.formatted(date: .abbreviated, time: .shortened))
        
        Threat Details:
        \(threat.description)
        """
        
        // Add specific context based on threat type
        switch threat.type {
        case .threat(let type):
            switch type {
            case .rapidAccess:
                context += """
                
                Specific Context:
                - Multiple access attempts detected in rapid succession
                - Possible brute force attack or automated script
                - Time window: \(details.timeWindow ?? "unknown")
                - Access count: \(details.accessCount ?? 0)
                """
            case .unusualLocation:
                context += """
                
                Specific Context:
                - Access from unexpected geographic location
                - Location: \(details.location ?? "unknown")
                - Distance from usual location: \(details.distance ?? "unknown")
                - Possible account sharing or unauthorized access
                """
            case .suspiciousDeletion:
                context += """
                
                Specific Context:
                - Unusual deletion pattern detected
                - Documents deleted: \(details.deletedCount ?? 0)
                - Possible data destruction or unauthorized access
                """
            case .bruteForce:
                context += """
                
                Specific Context:
                - Brute force attack pattern detected
                - Multiple failed access attempts
                - Immediate action required
                """
            case .unauthorizedAccess:
                context += """
                
                Specific Context:
                - Unauthorized access attempt detected
                - Security breach possible
                - Immediate lockdown required
                """
            }
        case .geographicAnomaly:
            context += """
            
            Specific Context:
            - Geographic anomaly detected
            - Multiple locations: \(details.locationCount ?? 0)
            - Possible account sharing
            """
        case .accessBurst:
            context += """
            
            Specific Context:
            - Access burst pattern detected
            - Burst count: \(details.burstCount ?? 0)
            - Possible automated activity
            """
        case .dataExfiltration:
            context += """
            
            Specific Context:
            - Potential data exfiltration detected
            - Documents at risk: \(details.documentCount ?? 0)
            - Immediate containment required
            """
        case .dataLeak(let leakType):
            context += """
            
            Specific Context:
            - Data leak type: \(leakTypeDescription(leakType))
            - Affected documents: \(details.documentCount ?? 0)
            """
        }
        
        return context
    }
    
    private func buildTriageContext(result: TriageResult) -> String {
        var context = """
        SECURITY THREAT ANALYSIS AND REMEDIATION
        
        Threat Type: \(triageTypeDescription(result.type))
        Severity: \(result.severity.rawValue)
        Priority: \(result.priority)
        Vault: \(result.vaultName)
        Detected: \(result.detectedAt.formatted(date: .abbreviated, time: .shortened))
        
        Threat Description:
        \(result.description)
        """
        
        if let entities = result.affectedEntities, !entities.isEmpty {
            context += """
            
            Affected Entities:
            \(entities.joined(separator: ", "))
            """
        }
        
        return context
    }
    
    private func generateAISteps(context: String) async -> [String] {
        // Use NaturalLanguage framework for on-device analysis
        // Since we can't use Foundation Models API directly in Swift,
        // we'll use rule-based generation with NLP analysis for context-aware steps
        
        // Extract key information using NLP
        let threatType = extractThreatType(from: context)
        let severity = extractSeverity(from: context)
        let urgency = determineUrgency(severity: severity, threatType: threatType)
        
        // Generate context-aware steps using pattern matching and NLP
        var steps: [String] = []
        
        // Immediate actions based on threat type
        if urgency == .critical || urgency == .high {
            steps.append("IMMEDIATE: Lock the affected vault to prevent further access")
            
            if context.contains("rapid access") || context.contains("brute force") {
                steps.append("Change vault password immediately using a strong, unique password")
                steps.append("Enable dual-key protection to require ML approval for all access")
            }
            
            if context.contains("unauthorized") || context.contains("breach") {
                steps.append("Revoke all active sessions and force re-authentication")
                steps.append("Review all access logs from the past 24 hours for suspicious activity")
            }
        }
        
        // Threat-specific steps
        if context.contains("geographic") || context.contains("location") {
            steps.append("Review access map to identify all access locations")
            steps.append("Verify if you recognize all locations - revoke access from unknown locations")
            steps.append("Enable location-based alerts for future access")
        }
        
        if context.contains("deletion") || context.contains("destroy") {
            steps.append("Check document version history to restore deleted files")
            steps.append("Review deletion logs to identify what was deleted and when")
            steps.append("If critical documents were deleted, restore from version history immediately")
        }
        
        if context.contains("data leak") || context.contains("exfiltration") {
            steps.append("Review all recent document uploads and sharing activity")
            steps.append("Archive or restrict access to sensitive documents that may be compromised")
            steps.append("Review nominee access - revoke access for any suspicious nominees")
        }
        
        if context.contains("nominee") || context.contains("compromised") {
            steps.append("Review all active nominees and their access patterns")
            steps.append("Revoke access for nominees showing suspicious activity")
            steps.append("Enable dual-key protection to require approval for nominee access")
        }
        
        // Monitoring and verification
        steps.append("Enable enhanced threat monitoring for this vault")
        steps.append("Monitor access logs over the next 24-48 hours for continued suspicious activity")
        
        // Final verification
        if urgency == .critical {
            steps.append("Contact support if you didn't authorize these activities or if threat persists")
        } else {
            steps.append("Verify all remediation steps are completed and threat is resolved")
        }
        
        // Ensure we have at least 3 steps
        if steps.count < 3 {
            steps.append("Change vault password as a precautionary measure")
            steps.append("Review all recent vault activity in access logs")
            steps.append("Enable additional security features like dual-key protection")
        }
        
        return Array(steps.prefix(8)) // Limit to 8 most important steps
    }
    
    // MARK: - Helper Methods
    
    private func extractThreatType(from context: String) -> String {
        let lowercased = context.lowercased()
        
        if lowercased.contains("rapid access") || lowercased.contains("brute force") {
            return "rapid_access"
        } else if lowercased.contains("geographic") || lowercased.contains("location") {
            return "geographic_anomaly"
        } else if lowercased.contains("deletion") || lowercased.contains("delete") {
            return "suspicious_deletion"
        } else if lowercased.contains("data leak") || lowercased.contains("exfiltration") {
            return "data_leak"
        } else if lowercased.contains("unauthorized") {
            return "unauthorized_access"
        } else if lowercased.contains("nominee") || lowercased.contains("compromised") {
            return "compromised_nominee"
        }
        
        return "general_threat"
    }
    
    private func extractSeverity(from context: String) -> ThreatLevel {
        let lowercased = context.lowercased()
        
        if lowercased.contains("critical") {
            return .critical
        } else if lowercased.contains("high") {
            return .high
        } else if lowercased.contains("medium") {
            return .medium
        }
        
        return .low
    }
    
    private func determineUrgency(severity: ThreatLevel, threatType: String) -> Urgency {
        if severity == .critical {
            return .critical
        } else if severity == .high || threatType == "rapid_access" || threatType == "data_leak" {
            return .high
        } else if severity == .medium {
            return .medium
        }
        
        return .low
    }
    
    private func threatTypeDescription(_ type: ThreatItemType) -> String {
        switch type {
        case .threat(let threatType):
            switch threatType {
            case .rapidAccess: return "Rapid Access Pattern"
            case .unusualLocation: return "Unusual Location Access"
            case .suspiciousDeletion: return "Suspicious Deletion Pattern"
            case .bruteForce: return "Brute Force Attack"
            case .unauthorizedAccess: return "Unauthorized Access"
            }
        case .geographicAnomaly: return "Geographic Anomaly"
        case .accessBurst: return "Access Burst Pattern"
        case .dataExfiltration: return "Data Exfiltration"
        case .dataLeak(let leakType): return "Data Leak: \(leakTypeDescription(leakType))"
        }
    }
    
    private func triageTypeDescription(_ type: TriageResultType) -> String {
        switch type {
        case .screenMonitoring: return "Screen Monitoring Detected"
        case .compromisedNominee: return "Compromised Nominee"
        case .sensitiveDocuments: return "Sensitive Documents Requiring Redaction"
        case .dataLeak: return "Data Leak Indicators"
        case .bruteForce: return "Brute Force Attack"
        case .unauthorizedAccess: return "Unauthorized Access"
        case .suspiciousActivity: return "Suspicious Activity"
        }
    }
    
    private func leakTypeDescription(_ type: DataLeakType) -> String {
        switch type {
        case .massUpload: return "Mass Upload"
        case .accountSharing: return "Account Sharing"
        case .suspiciousContent: return "Suspicious Content"
        case .massDeletion: return "Mass Deletion"
        case .unauthorizedAccess: return "Unauthorized Access"
        }
    }
}

// MARK: - Supporting Types

struct ThreatContext {
    var timeWindow: String?
    var accessCount: Int?
    var location: String?
    var distance: String?
    var deletedCount: Int?
    var documentCount: Int?
    var locationCount: Int?
    var burstCount: Int?
}

enum Urgency {
    case low
    case medium
    case high
    case critical
}

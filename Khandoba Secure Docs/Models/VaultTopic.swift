//
//  VaultTopic.swift
//  Khandoba Secure Docs
//
//  Vault topic configuration for intelligent ingestion
//

import Foundation
import SwiftData

@Model
final class VaultTopic {
    var id: UUID = UUID()
    var vaultID: UUID
    var topicName: String
    var topicDescription: String?
    var keywords: [String] = []
    var categories: [String] = []
    var complianceFrameworks: [String] = [] // ComplianceFramework rawValues
    var dataSources: [String] = [] // Provider names
    var isActive: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Learning metrics
    var totalIngested: Int = 0
    var relevantCount: Int = 0
    var learningScore: Double = 0.0 // 0.0 to 1.0
    
    init(
        vaultID: UUID,
        topicName: String,
        topicDescription: String? = nil
    ) {
        self.vaultID = vaultID
        self.topicName = topicName
        self.topicDescription = topicDescription
    }
}


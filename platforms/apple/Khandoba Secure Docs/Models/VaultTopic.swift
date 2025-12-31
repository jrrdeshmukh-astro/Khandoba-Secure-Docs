//
//  VaultTopic.swift
//  Khandoba Secure Docs
//
//  Model for vault topic configuration (keywords, categories, data sources)
//

import Foundation
import SwiftData

@Model
final class VaultTopic {
    var id: UUID
    var vaultID: UUID
    var topicName: String
    var keywords: [String]
    var categories: [String]
    var dataSources: [String] // e.g., "icloud_drive", "icloud_photos", "icloud_mail"
    var complianceFrameworks: [String] // e.g., "HIPAA", "SOC2", "NIST"
    var totalIngested: Int
    var relevantCount: Int
    var learningScore: Double // 0.0 - 1.0
    var createdAt: Date
    var updatedAt: Date
    
    // Relationship to Vault - using UUID to avoid circular dependency
    // vaultID is already declared above (line 14)
    
    init(
        id: UUID = UUID(),
        vaultID: UUID,
        topicName: String,
        keywords: [String] = [],
        categories: [String] = [],
        dataSources: [String] = [],
        complianceFrameworks: [String] = [],
        totalIngested: Int = 0,
        relevantCount: Int = 0,
        learningScore: Double = 0.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vaultID = vaultID
        self.topicName = topicName
        self.keywords = keywords
        self.categories = categories
        self.dataSources = dataSources
        self.complianceFrameworks = complianceFrameworks
        self.totalIngested = totalIngested
        self.relevantCount = relevantCount
        self.learningScore = learningScore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


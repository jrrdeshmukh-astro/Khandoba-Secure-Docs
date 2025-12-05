//
//  User.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var appleUserID: String
    var fullName: String = ""
    var email: String?
    var profilePictureData: Data?
    var createdAt: Date = Date()
    var lastActiveAt: Date = Date()
    var isActive: Bool = true
    
    // Role relationships
    @Relationship(deleteRule: .cascade, inverse: \UserRole.user)
    var roles: [UserRole]?
    
    // Vaults owned by this user
    @Relationship(deleteRule: .cascade, inverse: \Vault.owner)
    var ownedVaults: [Vault]?
    
    // Chat messages
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.sender)
    var sentMessages: [ChatMessage]?
    
    // Subscription status
    var isPremiumSubscriber: Bool = false
    var subscriptionExpiryDate: Date?
    
    init(
        id: UUID = UUID(),
        appleUserID: String,
        fullName: String,
        email: String? = nil,
        profilePictureData: Data? = nil,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.appleUserID = appleUserID
        self.fullName = fullName
        self.email = email
        self.profilePictureData = profilePictureData
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.isActive = isActive
        self.roles = []
        self.ownedVaults = []
        self.sentMessages = []
    }
}

// MARK: - Role Enum
enum Role: String, Codable, CaseIterable {
    case client = "client"
    // Admin role removed - everything runs on ML autopilot
    // Support provided by LLM chat instead
    
    var displayName: String {
        return "User"
    }
    
    var description: String {
        return "Full app access with ML-powered automation"
    }
    
    var iconName: String {
        return "person.circle.fill"
    }
}

@Model
final class UserRole {
    @Attribute(.unique) var id: UUID
    var roleRawValue: String = "client"
    var assignedAt: Date = Date()
    var isActive: Bool = true
    
    var user: User?
    
    var role: Role {
        get { Role(rawValue: roleRawValue) ?? .client }
        set { roleRawValue = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        role: Role,
        assignedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.roleRawValue = role.rawValue
        self.assignedAt = assignedAt
        self.isActive = isActive
    }
}


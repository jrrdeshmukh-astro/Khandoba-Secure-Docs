//
//  SupabaseUser.swift
//  Khandoba Secure Docs
//
//  Created for Supabase Migration
//

import Foundation

struct SupabaseUser: Codable, Identifiable {
    let id: UUID
    let appleUserID: String
    var fullName: String
    var email: String?
    var profilePictureURL: String? // URL to Supabase Storage
    let createdAt: Date
    var lastActiveAt: Date
    var isActive: Bool
    var isPremiumSubscriber: Bool
    var subscriptionExpiryDate: Date?
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case appleUserID = "apple_user_id"
        case fullName = "full_name"
        case email
        case profilePictureURL = "profile_picture_url"
        case createdAt = "created_at"
        case lastActiveAt = "last_active_at"
        case isActive = "is_active"
        case isPremiumSubscriber = "is_premium_subscriber"
        case subscriptionExpiryDate = "subscription_expiry_date"
        case updatedAt = "updated_at"
    }
    
    // Convert from SwiftData User model
    init(from user: User) {
        self.id = user.id
        self.appleUserID = user.appleUserID
        self.fullName = user.fullName
        self.email = user.email
        self.profilePictureURL = nil // Will be set when uploading to Supabase Storage
        self.createdAt = user.createdAt
        self.lastActiveAt = user.lastActiveAt
        self.isActive = user.isActive
        self.isPremiumSubscriber = user.isPremiumSubscriber
        self.subscriptionExpiryDate = user.subscriptionExpiryDate
        self.updatedAt = Date()
    }
    
    // Standard init
    init(
        id: UUID = UUID(),
        appleUserID: String,
        fullName: String,
        email: String? = nil,
        profilePictureURL: String? = nil,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        isActive: Bool = true,
        isPremiumSubscriber: Bool = false,
        subscriptionExpiryDate: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.appleUserID = appleUserID
        self.fullName = fullName
        self.email = email
        self.profilePictureURL = profilePictureURL
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.isActive = isActive
        self.isPremiumSubscriber = isPremiumSubscriber
        self.subscriptionExpiryDate = subscriptionExpiryDate
        self.updatedAt = updatedAt
    }
}

struct SupabaseUserRole: Codable, Identifiable {
    let id: UUID
    let userID: UUID
    var roleRawValue: String
    let assignedAt: Date
    var isActive: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case roleRawValue = "role_raw_value"
        case assignedAt = "assigned_at"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
    
    var role: Role {
        get { Role(rawValue: roleRawValue) ?? .client }
        set { roleRawValue = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        userID: UUID,
        role: Role = .client,
        assignedAt: Date = Date(),
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.roleRawValue = role.rawValue
        self.assignedAt = assignedAt
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

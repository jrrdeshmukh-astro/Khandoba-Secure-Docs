//
//  SupabaseChatMessage.swift
//  Khandoba Secure Docs
//
//  Created for Supabase Migration
//

import Foundation

struct SupabaseChatMessage: Codable, Identifiable {
    let id: UUID
    let senderID: UUID
    var messageText: String
    var isFromSystem: Bool
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderID = "sender_id"
        case messageText = "message_text"
        case isFromSystem = "is_from_system"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Convert from SwiftData ChatMessage model
    init(from message: ChatMessage) {
        self.id = message.id
        self.senderID = message.sender?.id ?? message.senderID ?? UUID()
        self.messageText = message.content
        self.isFromSystem = false // ChatMessage doesn't have this field, default to false
        self.createdAt = message.timestamp
        self.updatedAt = Date()
    }
    
    // Standard init
    init(
        id: UUID = UUID(),
        senderID: UUID,
        messageText: String,
        isFromSystem: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.senderID = senderID
        self.messageText = messageText
        self.isFromSystem = isFromSystem
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

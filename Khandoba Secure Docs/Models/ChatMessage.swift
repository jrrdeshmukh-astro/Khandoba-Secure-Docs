//
//  ChatMessage.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var content: String
    var timestamp: Date
    var isRead: Bool
    var isEncrypted: Bool
    
    var sender: User?
    var senderID: UUID?
    var receiverID: UUID?
    var conversationID: String // Unique ID for client-admin conversation
    
    init(
        id: UUID = UUID(),
        content: String,
        timestamp: Date = Date(),
        isRead: Bool = false,
        isEncrypted: Bool = true,
        senderID: UUID? = nil,
        receiverID: UUID? = nil,
        conversationID: String
    ) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isRead = isRead
        self.isEncrypted = isEncrypted
        self.senderID = senderID
        self.receiverID = receiverID
        self.conversationID = conversationID
    }
}


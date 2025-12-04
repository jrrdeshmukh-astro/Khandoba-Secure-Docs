//
//  ChatService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

final class ChatService: ObservableObject {
    @Published var conversations: [String: [ChatMessage]] = [:]
    @Published var unreadCounts: [String: Int] = [:]
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    private var currentUserID: UUID?
    
    init() {}
    
    func configure(modelContext: ModelContext, userID: UUID) {
        self.modelContext = modelContext
        self.currentUserID = userID
    }
    
    func loadConversations() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<ChatMessage>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let messages = try modelContext.fetch(descriptor)
        
        // Group by conversation
        var grouped: [String: [ChatMessage]] = [:]
        for message in messages {
            if grouped[message.conversationID] == nil {
                grouped[message.conversationID] = []
            }
            grouped[message.conversationID]?.append(message)
        }
        
        // Sort each conversation by timestamp
        for (conversationID, messages) in grouped {
            grouped[conversationID] = messages.sorted { $0.timestamp < $1.timestamp }
        }
        
        self.conversations = grouped
        
        // Calculate unread counts
        updateUnreadCounts()
    }
    
    func sendMessage(
        content: String,
        to receiverID: UUID,
        conversationID: String
    ) async throws {
        guard let modelContext = modelContext, let currentUserID = currentUserID else {
            throw ChatError.contextNotAvailable
        }
        
        let message = ChatMessage(
            content: content,
            senderID: currentUserID,
            receiverID: receiverID,
            conversationID: conversationID
        )
        
        modelContext.insert(message)
        try modelContext.save()
        
        // Update local conversations
        if conversations[conversationID] == nil {
            conversations[conversationID] = []
        }
        conversations[conversationID]?.append(message)
    }
    
    func markAsRead(conversationID: String) async throws {
        guard let modelContext = modelContext, let currentUserID = currentUserID else { return }
        
        if let messages = conversations[conversationID] {
            for message in messages where message.receiverID == currentUserID && !message.isRead {
                message.isRead = true
            }
            try modelContext.save()
            
            updateUnreadCounts()
        }
    }
    
    func getConversationID(with userID: UUID) -> String {
        guard let currentUserID = currentUserID else { return "" }
        
        // Create consistent conversation ID
        let ids = [currentUserID, userID].map { $0.uuidString }.sorted()
        return ids.joined(separator: "-")
    }
    
    private func updateUnreadCounts() {
        guard let currentUserID = currentUserID else { return }
        
        var counts: [String: Int] = [:]
        for (conversationID, messages) in conversations {
            let unreadCount = messages.filter { $0.receiverID == currentUserID && !$0.isRead }.count
            counts[conversationID] = unreadCount
        }
        self.unreadCounts = counts
    }
}

enum ChatError: LocalizedError {
    case contextNotAvailable
    case messageSendFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Chat system not available"
        case .messageSendFailed:
            return "Failed to send message"
        }
    }
}

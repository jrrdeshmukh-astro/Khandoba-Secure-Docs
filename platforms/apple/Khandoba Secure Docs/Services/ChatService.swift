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
import CryptoKit

final class ChatService: ObservableObject {
    @Published var conversations: [String: [ChatMessage]] = [:]
    @Published var unreadCounts: [String: Int] = [:]
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    private var currentUserID: UUID?
    
    init() {}
    
    // SwiftData/CloudKit mode (iOS-only)
    func configure(modelContext: ModelContext, userID: UUID) {
        self.modelContext = modelContext
        self.currentUserID = userID
    }
    
    func loadConversations() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            print("❌ ChatService: ModelContext not available")
            return
        }
        
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
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext, let currentUserID = currentUserID else {
            throw ChatError.contextNotAvailable
        }
        
        // Encrypt message content
        let encryptedContent = try encryptMessage(content: content, conversationID: conversationID)
        
        let message = ChatMessage(
            content: encryptedContent,
            senderID: currentUserID,
            receiverID: receiverID,
            conversationID: conversationID
        )
        message.isEncrypted = true
        
        // Load sender user for relationship
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == currentUserID }
        )
        if let sender = try? modelContext.fetch(userDescriptor).first {
            message.sender = sender
        }
        
        modelContext.insert(message)
        try modelContext.save()
        
        // Update local conversations
        if conversations[conversationID] == nil {
            conversations[conversationID] = []
        }
        conversations[conversationID]?.append(message)
    }
    
    // MARK: - Encryption
    
    private func encryptMessage(content: String, conversationID: String) throws -> String {
        guard let data = content.data(using: .utf8) else {
            throw ChatError.messageSendFailed
        }
        
        // Generate or retrieve conversation key
        let key = try getOrCreateConversationKey(conversationID: conversationID)
        
        // Encrypt using AES-256-GCM
        let encrypted = try EncryptionService.encrypt(data: data, key: key)
        
        // Return base64 encoded encrypted data
        return encrypted.ciphertext.base64EncodedString()
    }
    
    func decryptMessage(_ encryptedContent: String, conversationID: String) throws -> String {
        // Check if message is encrypted (base64 format)
        guard let encryptedData = Data(base64Encoded: encryptedContent) else {
            // If not base64, assume it's plain text (backward compatibility or unencrypted)
            return encryptedContent
        }
        
        // Retrieve conversation key
        let key = try getOrCreateConversationKey(conversationID: conversationID)
        
        // Decrypt - AES-GCM stores nonce and tag in the combined data
        let encrypted = EncryptedData(
            ciphertext: encryptedData,
            nonce: Data(),
            tag: Data()
        )
        
        do {
            let decryptedData = try EncryptionService.decrypt(encryptedData: encrypted, key: key)
            return String(data: decryptedData, encoding: .utf8) ?? encryptedContent
        } catch {
            // If decryption fails, return original (might be unencrypted legacy message)
            print(" Failed to decrypt message, returning as-is: \(error.localizedDescription)")
            return encryptedContent
        }
    }
    
    private func getOrCreateConversationKey(conversationID: String) throws -> SymmetricKey {
        let keyIdentifier = "chat-\(conversationID)"
        
        // Try to retrieve existing key
        do {
            let existingKey = try EncryptionService.retrieveKey(identifier: keyIdentifier)
            return existingKey
        } catch {
            // Key doesn't exist, generate new one
            let newKey = EncryptionService.generateKey()
            try EncryptionService.storeKey(newKey, identifier: keyIdentifier)
            return newKey
        }
    }
    
    // MARK: - Nominee Chat
    
    func getNomineeConversationID(vaultID: UUID, nomineeID: UUID) -> String {
        return "vault-\(vaultID.uuidString)-nominee-\(nomineeID.uuidString)"
    }
    
    func loadNomineeConversations(for vault: Vault) async throws {
        guard let nominees = vault.nomineeList else { return }
        
        for nominee in nominees where nominee.status == .accepted || nominee.status == .active {
            let conversationID = getNomineeConversationID(vaultID: vault.id, nomineeID: nominee.id)
            
            // Load messages for this conversation
            guard let modelContext = modelContext else { continue }
            
            let descriptor = FetchDescriptor<ChatMessage>(
                predicate: #Predicate { $0.conversationID == conversationID },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            
            let messages = try? modelContext.fetch(descriptor)
            if let messages = messages, !messages.isEmpty {
                conversations[conversationID] = messages.sorted { $0.timestamp < $1.timestamp }
            }
        }
        
        updateUnreadCounts()
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
    case serviceNotConfigured
    case userNotFound
    case messageSendFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Chat system not available"
        case .serviceNotConfigured:
            return "Service not configured. Please ensure Supabase is properly initialized."
        case .userNotFound:
            return "User not found"
        case .messageSendFailed:
            return "Failed to send message"
        }
    }
}

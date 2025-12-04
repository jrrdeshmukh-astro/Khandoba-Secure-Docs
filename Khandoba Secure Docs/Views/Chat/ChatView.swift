//
//  ChatView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct ChatView: View {
    let conversationID: String
    let otherUserID: UUID
    let otherUserName: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var messageText = ""
    @State private var isLoading = false
    
    var messages: [ChatMessage] {
        chatService.conversations[conversationID] ?? []
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // Chat Header
            VStack(spacing: UnifiedTheme.Spacing.xs) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(colors.primary.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Text(String(otherUserName.prefix(1)))
                            .font(theme.typography.headline)
                            .foregroundColor(colors.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(otherUserName)
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        Text("Admin")
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(colors.surface)
            }
            
            Divider()
            
            // Messages
            ScrollView {
                LazyVStack(spacing: UnifiedTheme.Spacing.sm) {
                    ForEach(messages) { message in
                        ChatBubble(
                            message: message,
                            isFromCurrentUser: message.senderID == authService.currentUser?.id
                        )
                    }
                }
                .padding()
            }
            .background(colors.background)
            
            // Message Input
            HStack(spacing: UnifiedTheme.Spacing.sm) {
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .font(theme.typography.body)
                    .lineLimit(1...5)
                    .padding(.horizontal, UnifiedTheme.Spacing.md)
                    .padding(.vertical, UnifiedTheme.Spacing.sm)
                    .background(colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(messageText.isEmpty ? colors.textTertiary : colors.primary)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(colors.surface)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            try? await chatService.loadConversations()
            try? await chatService.markAsRead(conversationID: conversationID)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let message = messageText
        messageText = ""
        
        Task {
            try? await chatService.sendMessage(
                content: message,
                to: otherUserID,
                conversationID: conversationID
            )
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(theme.typography.body)
                    .foregroundColor(isFromCurrentUser ? .white : colors.textPrimary)
                    .padding(.horizontal, UnifiedTheme.Spacing.md)
                    .padding(.vertical, UnifiedTheme.Spacing.sm)
                    .background(isFromCurrentUser ? colors.primary : colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                
                Text(message.timestamp, style: .time)
                    .font(theme.typography.caption2)
                    .foregroundColor(colors.textTertiary)
            }
            .frame(maxWidth: 250, alignment: isFromCurrentUser ? .trailing : .leading)
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
}


//
//  AdminChatInboxView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct AdminChatInboxView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.modelContext) private var modelContext
    
    @State private var users: [User] = []
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if chatService.conversations.isEmpty {
                    EmptyStateView(
                        icon: "message",
                        title: "No Messages",
                        message: "Client messages will appear here"
                    )
                } else {
                    List {
                        ForEach(Array(chatService.conversations.keys), id: \.self) { conversationID in
                            if let messages = chatService.conversations[conversationID],
                               let lastMessage = messages.last,
                               let otherUserID = getOtherUserID(from: conversationID) {
                                NavigationLink {
                                    if let user = users.first(where: { $0.id == otherUserID }) {
                                        ChatView(
                                            conversationID: conversationID,
                                            otherUserID: otherUserID,
                                            otherUserName: user.fullName
                                        )
                                    }
                                } label: {
                                    ConversationRow(
                                        conversationID: conversationID,
                                        lastMessage: lastMessage,
                                        otherUser: users.first(where: { $0.id == otherUserID }),
                                        unreadCount: chatService.unreadCounts[conversationID] ?? 0
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(colors.background)
                }
            }
            .navigationTitle("Messages")
            .refreshable {
                try? await chatService.loadConversations()
            }
        }
        .task {
            try? await chatService.loadConversations()
            await loadUsers()
        }
    }
    
    private func loadUsers() async {
        let descriptor = FetchDescriptor<User>()
        users = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func getOtherUserID(from conversationID: String) -> UUID? {
        let ids = conversationID.split(separator: "-")
        guard ids.count == 2 else { return nil }
        
        let firstID = UUID(uuidString: String(ids[0]))
        let secondID = UUID(uuidString: String(ids[1]))
        
        if firstID == authService.currentUser?.id {
            return secondID
        } else {
            return firstID
        }
    }
}

struct ConversationRow: View {
    let conversationID: String
    let lastMessage: ChatMessage
    let otherUser: User?
    let unreadCount: Int
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack(spacing: UnifiedTheme.Spacing.md) {
            // Avatar
            if let imageData = otherUser?.profilePictureData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(colors.primary.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if let name = otherUser?.fullName {
                        Text(String(name.prefix(1)))
                            .font(theme.typography.headline)
                            .foregroundColor(colors.primary)
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(colors.primary)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(otherUser?.fullName ?? "Unknown User")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                    .fontWeight(unreadCount > 0 ? .semibold : .regular)
                
                Text(lastMessage.content)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(lastMessage.timestamp, style: .time)
                    .font(theme.typography.caption2)
                    .foregroundColor(colors.textTertiary)
                
                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(colors.primary)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, UnifiedTheme.Spacing.xs)
    }
}


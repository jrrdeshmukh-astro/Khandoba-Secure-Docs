//
//  AdminSupportChatView.swift
//  Khandoba Secure Docs
//
//  Live chat support with admin

import SwiftUI
import SwiftData

struct AdminSupportChatView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var chatService: ChatService
    
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var conversationID = UUID()
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Messages List
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: UnifiedTheme.Spacing.md) {
                                ForEach(messages) { message in
                                    SupportChatBubbleView(message: message, currentUserID: authService.currentUser?.id)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) { _ in
                            if let lastMessage = messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input Area
                    HStack(spacing: UnifiedTheme.Spacing.sm) {
                        TextField("Type your message...", text: $messageText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(UnifiedTheme.Spacing.md)
                            .background(colors.surface)
                            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            .lineLimit(1...5)
                        
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title)
                                .foregroundColor(messageText.isEmpty ? colors.textTertiary : colors.primary)
                        }
                        .disabled(messageText.isEmpty || isLoading)
                    }
                    .padding()
                    .background(colors.background)
                }
            }
            .navigationTitle("Support Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadMessages()
            }
        }
    }
    
    private func loadMessages() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let currentUser = authService.currentUser else { return }
            
            // Fetch support conversation messages
            let descriptor = FetchDescriptor<ChatMessage>(
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            
            messages = try modelContext.fetch(descriptor)
            
            // Send welcome message if first time
            if messages.isEmpty {
                let welcomeMessage = ChatMessage(
                    content: "Hello! Welcome to Khandoba Secure Docs support. How can we help you today?",
                    timestamp: Date(),
                    isRead: false,
                    conversationID: "support_\(currentUser.id.uuidString)"
                )
                welcomeMessage.sender = nil // System message
                modelContext.insert(welcomeMessage)
                try modelContext.save()
                messages.append(welcomeMessage)
            }
        } catch {
            print("Failed to load support chat: \(error)")
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty, let currentUser = authService.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                let message = ChatMessage(
                    content: messageText,
                    timestamp: Date(),
                    isRead: false,
                    conversationID: "support_\(currentUser.id.uuidString)"
                )
                message.sender = currentUser
                
                modelContext.insert(message)
                try modelContext.save()
                
                messages.append(message)
                messageText = ""
                
                // Auto-reply from admin (in production, admins would reply via their dashboard)
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                
                let adminReply = ChatMessage(
                    content: "Thank you for your message. An admin will respond shortly.",
                    timestamp: Date(),
                    isRead: false,
                    conversationID: "support_\(currentUser.id.uuidString)"
                )
                adminReply.sender = nil // System message
                modelContext.insert(adminReply)
                try modelContext.save()
                
                messages.append(adminReply)
            } catch {
                print("Failed to send message: \(error)")
            }
            
            isLoading = false
        }
    }
}

// Separate bubble view to avoid redeclaration
struct SupportChatBubbleView: View {
    let message: ChatMessage
    let currentUserID: UUID?
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    private var isCurrentUser: Bool {
        guard let currentUserID = currentUserID,
              let senderID = message.sender?.id else { return false }
        return senderID == currentUserID
    }
    
    private var isSystem: Bool {
        message.sender == nil
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack {
            if isCurrentUser { Spacer(minLength: 50) }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isSystem && !isCurrentUser {
                    Text("Admin Support")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Text(message.content)
                    .font(theme.typography.body)
                    .foregroundColor(isCurrentUser ? .white : colors.textPrimary)
                    .padding(UnifiedTheme.Spacing.md)
                    .background(
                        isSystem ? colors.surface :
                        isCurrentUser ? colors.primary : colors.surface
                    )
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(theme.typography.caption2)
                    .foregroundColor(colors.textTertiary)
            }
            
            if !isCurrentUser { Spacer(minLength: 50) }
        }
    }
}


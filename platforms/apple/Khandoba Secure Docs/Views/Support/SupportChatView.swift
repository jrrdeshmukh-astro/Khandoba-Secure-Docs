//
//  SupportChatView.swift
//  Khandoba Secure Docs
//
//  LLM Support Chat UI - Replaces admin support
//

import SwiftUI
import Combine

struct SupportChatView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var chatService = SupportChatService()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // Header
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.title2)
                        .foregroundColor(colors.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Support")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text("Ask me anything about the app")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if chatService.isProcessing {
                        ProgressView()
                            .tint(colors.primary)
                    }
                }
                .padding()
                .background(colors.surface)
                
                Divider()
            }
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: UnifiedTheme.Spacing.md) {
                        ForEach(chatService.messages) { message in
                            SupportMessageBubble(message: message, colors: colors, theme: theme)
                                .id(message.id)
                        }
                        
                        // Suggested questions
                        if chatService.messages.count == 1 {
                            SuggestedQuestionsView(colors: colors, theme: theme) { question in
                                messageText = question
                                Task {
                                    await chatService.sendMessage(question)
                                    messageText = ""
                                }
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: chatService.messages.count) { _, _ in
                    if let lastMessage = chatService.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input
            HStack(spacing: UnifiedTheme.Spacing.sm) {
                TextField("Ask a question...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(UnifiedTheme.Spacing.sm)
                    .background(colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.isEmpty ? colors.textTertiary : colors.primary)
                }
                .disabled(messageText.isEmpty || chatService.isProcessing)
            }
            .padding()
            .background(colors.background)
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    chatService.clearChat()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        Task {
            await chatService.sendMessage(text)
        }
        
        messageText = ""
    }
}

// MARK: - Message Bubble

struct SupportMessageBubble: View {
    let message: SupportChatService.SupportMessage
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack(alignment: .top, spacing: UnifiedTheme.Spacing.sm) {
            if message.role == .assistant {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(colors.primary)
                    .frame(width: 32, height: 32)
                    .background(colors.primary.opacity(0.1))
                    .clipShape(Circle())
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(theme.typography.body)
                    .foregroundColor(message.role == .user ? .white : colors.textPrimary)
                    .padding(UnifiedTheme.Spacing.md)
                    .background(message.role == .user ? colors.primary : colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .user {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundColor(colors.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
    }
}

// MARK: - Suggested Questions

struct SuggestedQuestionsView: View {
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    let onTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
            Text("Suggested questions:")
                .font(theme.typography.caption)
                .foregroundColor(colors.textSecondary)
            
            ForEach(questions, id: \.self) { question in
                Button {
                    onTap(question)
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text(question)
                            .font(theme.typography.caption)
                        Spacer()
                        Image(systemName: "arrow.right.circle")
                            .font(.caption)
                    }
                    .foregroundColor(colors.primary)
                    .padding(.horizontal, UnifiedTheme.Spacing.sm)
                    .padding(.vertical, UnifiedTheme.Spacing.xs)
                    .background(colors.primary.opacity(0.1))
                    .cornerRadius(UnifiedTheme.CornerRadius.sm)
                }
            }
        }
        .padding()
        .background(colors.surface)
        .cornerRadius(UnifiedTheme.CornerRadius.lg)
    }
    
    private let questions = [
        "How do I create a vault?",
        "What is Audio Intel?",
        "How does dual-key work?",
        "How do I upload documents?",
        "What are shared sessions?"
    ]
}

#Preview {
    NavigationStack {
        SupportChatView()
    }
}


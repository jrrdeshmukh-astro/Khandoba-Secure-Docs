//
//  IntelChatView.swift
//  Khandoba Secure Docs
//
//  Created by AI Assistant on 12/5/25.
//
//  Chat-based Intel Report interface
//

import SwiftUI
import Combine

struct IntelChatView: View {
    let vaults: [Vault]
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var vaultService: VaultService
    
    @StateObject private var chatService = IntelChatService()
    @State private var messageText = ""
    @State private var isLoadingContext = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // Header
            VStack(spacing: UnifiedTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundColor(colors.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Intel Assistant")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        Text("Ask questions about your documents")
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
            
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: UnifiedTheme.Spacing.md) {
                        if isLoadingContext {
                            LoadingContextView(colors: colors, theme: theme)
                        } else if chatService.messages.isEmpty {
                            EmptyStateView(colors: colors, theme: theme)
                        } else {
                            ForEach(chatService.messages) { message in
                                MessageBubble(message: message, colors: colors, theme: theme)
                                    .id(message.id)
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
            
            // Input area
            HStack(spacing: UnifiedTheme.Spacing.sm) {
                TextField("Ask about your documents...", text: $messageText, axis: .vertical)
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
        .navigationTitle("Intel Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        Task {
                            await loadContext()
                        }
                    } label: {
                        Label("Refresh Context", systemImage: "arrow.clockwise")
                    }
                    
                    Button(role: .destructive) {
                        chatService.clearChat()
                    } label: {
                        Label("Clear Chat", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            chatService.configure(modelContext: modelContext, vaultService: vaultService)
            if chatService.messages.isEmpty {
                Task {
                    await loadContext()
                }
            }
        }
    }
    
    private func loadContext() async {
        isLoadingContext = true
        await chatService.loadIntelContext(for: vaults)
        isLoadingContext = false
    }
    
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        
        Task {
            await chatService.sendMessage(text)
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: IntelChatService.ChatMessage
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack(alignment: .top, spacing: UnifiedTheme.Spacing.sm) {
            if message.role == .assistant {
                Image(systemName: "brain.head.profile")
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
        .padding(.horizontal, message.role == .system ? 0 : UnifiedTheme.Spacing.md)
        .opacity(message.role == .system ? 0.7 : 1.0)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(colors.primary.opacity(0.3))
            
            Text("Intel Assistant Ready")
                .font(theme.typography.title)
                .foregroundColor(colors.textPrimary)
            
            Text("Ask me anything about your documents")
                .font(theme.typography.body)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                Text("Try asking:")
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textSecondary)
                
                SuggestedQuestion(text: "Give me a summary", colors: colors, theme: theme)
                SuggestedQuestion(text: "What are the risks?", colors: colors, theme: theme)
                SuggestedQuestion(text: "Which documents are important?", colors: colors, theme: theme)
                SuggestedQuestion(text: "What should I do next?", colors: colors, theme: theme)
            }
            .padding()
            .background(colors.surface)
            .cornerRadius(UnifiedTheme.CornerRadius.lg)
        }
        .padding()
    }
}

struct SuggestedQuestion: View {
    let text: String
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundColor(colors.primary)
            
            Text(text)
                .font(theme.typography.caption)
                .foregroundColor(colors.textPrimary)
        }
    }
}

// MARK: - Loading Context View

struct LoadingContextView: View {
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            ProgressView()
                .tint(colors.primary)
                .scaleEffect(1.5)
            
            Text("Analyzing your documents...")
                .font(theme.typography.headline)
                .foregroundColor(colors.textPrimary)
            
            Text("Building intelligence context")
                .font(theme.typography.caption)
                .foregroundColor(colors.textSecondary)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        IntelChatView(vaults: [])
            .environmentObject(VaultService())
    }
}


//
//  IntelChatView.swift
//  Khandoba Secure Docs
//
//  Interactive Chat Interface for Intel Reports
//

import SwiftUI

struct IntelChatView: View {
    @ObservedObject var chatService: IntelChatService
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @State private var inputText: String = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: UnifiedTheme.Spacing.md) {
                        ForEach(chatService.messages) { message in
                            MessageBubble(message: message, colors: colors, theme: theme)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatService.messages.count) { oldValue, newValue in
                    if let last = chatService.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input
            HStack(spacing: UnifiedTheme.Spacing.sm) {
                TextField("Ask about the report...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(inputText.isEmpty ? colors.textTertiary : colors.primary)
                }
                .disabled(inputText.isEmpty || chatService.isProcessing)
            }
            .padding()
            .background(colors.surface)
        }
        .background(colors.background)
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        Task {
            await chatService.sendMessage(text)
        }
    }
}

struct MessageBubble: View {
    let message: IntelChatMessage
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(theme.typography.body)
                    .foregroundColor(message.isUser ? .white : colors.textPrimary)
                    .padding()
                    .background(message.isUser ? colors.primary : colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(colors.textTertiary)
            }
            
            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
    }
}


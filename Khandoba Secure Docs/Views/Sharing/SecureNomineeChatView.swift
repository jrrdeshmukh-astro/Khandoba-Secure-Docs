//
//  SecureNomineeChatView.swift
//  Khandoba Secure Docs
//
//  Secure encrypted chat between vault owner and nominee with screen protection
//

import SwiftUI
import UIKit
import Combine

struct SecureNomineeChatView: View {
    let vault: Vault
    let nominee: Nominee
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var isScreenCaptured = false
    @State private var showSecurityWarning = false
    @State private var screenCaptureTimer: Timer?
    
    private var conversationID: String {
        chatService.getNomineeConversationID(vaultID: vault.id, nomineeID: nominee.id)
    }
    
    private var messages: [ChatMessage] {
        chatService.conversations[conversationID] ?? []
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Security Header
                if isScreenCaptured {
                    SecurityWarningBanner()
                }
                
                // Chat Header
                ChatHeaderView(
                    nomineeName: nominee.name,
                    vaultName: vault.name,
                    isSecure: true
                )
                
                Divider()
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: UnifiedTheme.Spacing.sm) {
                            ForEach(messages) { message in
                                SecureChatBubble(
                                    message: message,
                                    conversationID: conversationID,
                                    isFromCurrentUser: message.senderID == authService.currentUser?.id
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .background(colors.background)
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message Input
                SecureMessageInputView(
                    messageText: $messageText,
                    onSend: sendMessage,
                    isScreenCaptured: isScreenCaptured
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Configure chat service
            if let userID = authService.currentUser?.id {
                if AppConfig.useSupabase {
                    chatService.configure(supabaseService: supabaseService, userID: userID)
                } else {
                chatService.configure(modelContext: modelContext, userID: userID)
                }
            }
            
            startScreenCaptureMonitoring()
            Task {
                try? await chatService.loadNomineeConversations(for: vault)
                try? await chatService.markAsRead(conversationID: conversationID)
            }
        }
        .onDisappear {
            stopScreenCaptureMonitoring()
        }
        .alert("Security Warning", isPresented: $showSecurityWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Screen recording or monitoring detected. This chat session may be compromised. Consider ending the conversation.")
        }
    }
    
    // MARK: - Screen Protection
    
    private func startScreenCaptureMonitoring() {
        // Check immediately
        checkScreenCapture()
        
        // Monitor continuously
        screenCaptureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            checkScreenCapture()
        }
        
        // Listen for screen capture notifications
        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            checkScreenCapture()
        }
    }
    
    private func stopScreenCaptureMonitoring() {
        screenCaptureTimer?.invalidate()
        screenCaptureTimer = nil
        NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
    }
    
    private func checkScreenCapture() {
        let captured = UIScreen.main.isCaptured
        
        if captured && !isScreenCaptured {
            // Screen capture just started
            showSecurityWarning = true
        }
        
        isScreenCaptured = captured
    }
    
    // MARK: - Message Sending
    
    private func sendMessage() {
        guard !messageText.isEmpty, !isScreenCaptured else { return }
        
        let message = messageText
        messageText = ""
        
        Task {
            isLoading = true
            do {
                // Find nominee's user ID (if they've accepted and created an account)
                // For now, use nominee ID - in production, nominees would have User accounts
                // The conversationID already includes both vault and nominee IDs
                guard authService.currentUser?.id != nil else {
                    throw ChatError.contextNotAvailable
                }
                
                // Use nominee ID as receiver ID (will be resolved to User when nominee accepts)
                try await chatService.sendMessage(
                    content: message,
                    to: nominee.id, // Will be resolved to User ID when nominee accepts
                    conversationID: conversationID
                )
            } catch {
                print(" Failed to send message: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}

// MARK: - Security Warning Banner

struct SecurityWarningBanner: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack(spacing: UnifiedTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(colors.error)
            
            Text("Screen recording detected - Chat may be compromised")
                .font(theme.typography.caption)
                .foregroundColor(colors.error)
            
            Spacer()
        }
        .padding()
        .background(colors.error.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(colors.error),
            alignment: .bottom
        )
    }
}

// MARK: - Chat Header

struct ChatHeaderView: View {
    let nomineeName: String
    let vaultName: String
    let isSecure: Bool
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.xs) {
            HStack {
                ZStack {
                    Circle()
                        .fill(colors.primary.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.fill")
                        .foregroundColor(colors.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(nomineeName)
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 4) {
                        if isSecure {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(colors.success)
                                .font(.caption2)
                        }
                        Text("Vault: \(vaultName)")
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                
                Spacer()
                
                if isSecure {
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(colors.success)
                            .font(.caption)
                        
                        Text("Encrypted")
                            .font(theme.typography.caption2)
                            .foregroundColor(colors.success)
                    }
                }
            }
            .padding()
            .background(colors.surface)
        }
    }
}

// MARK: - Secure Chat Bubble

struct SecureChatBubble: View {
    let message: ChatMessage
    let conversationID: String
    let isFromCurrentUser: Bool
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var chatService: ChatService
    
    @State private var decryptedContent: String?
    @State private var isDecrypting = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if isDecrypting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text(decryptedContent ?? message.content)
                        .font(theme.typography.body)
                        .foregroundColor(isFromCurrentUser ? .white : colors.textPrimary)
                        .padding(.horizontal, UnifiedTheme.Spacing.md)
                        .padding(.vertical, UnifiedTheme.Spacing.sm)
                        .background(isFromCurrentUser ? colors.primary : colors.surface)
                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                }
                
                HStack(spacing: 4) {
                    if message.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(colors.textTertiary)
                    }
                    Text(message.timestamp, style: .time)
                        .font(theme.typography.caption2)
                        .foregroundColor(colors.textTertiary)
                }
            }
            .frame(maxWidth: 250, alignment: isFromCurrentUser ? .trailing : .leading)
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
        .task {
            await decryptMessage()
        }
    }
    
    private func decryptMessage() async {
        guard message.isEncrypted, decryptedContent == nil else {
            decryptedContent = message.content
            return
        }
        
        isDecrypting = true
        do {
            let decrypted = try chatService.decryptMessage(message.content, conversationID: conversationID)
            await MainActor.run {
                decryptedContent = decrypted
                isDecrypting = false
            }
        } catch {
            // If decryption fails, show encrypted content
            await MainActor.run {
                decryptedContent = message.content
                isDecrypting = false
            }
        }
    }
}

// MARK: - Secure Message Input

struct SecureMessageInputView: View {
    @Binding var messageText: String
    let onSend: () -> Void
    let isScreenCaptured: Bool
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(spacing: UnifiedTheme.Spacing.xs) {
            if isScreenCaptured {
                HStack {
                    Image(systemName: "eye.slash.fill")
                        .foregroundColor(colors.error)
                        .font(.caption)
                    
                    Text("Input disabled - Screen recording active")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.error)
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: UnifiedTheme.Spacing.sm) {
                TextField("Type a secure message...", text: $messageText, axis: .vertical)
                    .font(theme.typography.body)
                    .lineLimit(1...5)
                    .padding(.horizontal, UnifiedTheme.Spacing.md)
                    .padding(.vertical, UnifiedTheme.Spacing.sm)
                    .background(colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                    .disabled(isScreenCaptured)
                
                Button {
                    onSend()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(messageText.isEmpty || isScreenCaptured ? colors.textTertiary : colors.primary)
                }
                .disabled(messageText.isEmpty || isScreenCaptured)
            }
            .padding()
            .background(colors.surface)
        }
    }
}

//
//  MessagesViewController.swift
//  Khandoba Secure Docs
//
//  Unified iMessage App (Apple Cash style) for vault invitations and file sharing
//

import UIKit
import Messages
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

class MessagesViewController: MSMessagesAppViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        // Show main interface when extension becomes active
        presentMainInterface(for: conversation)
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Clean up when extension becomes inactive
    }
    
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Handle received interactive messages
        handleReceivedMessage(message, in: conversation)
    }
    
    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        // Called when user taps an interactive message (Apple Cash style)
        handleMessageSelection(message, in: conversation)
    }
    
    // MARK: - Main Interface
    
    private func presentMainInterface(for conversation: MSConversation) {
        removeAllChildViewControllers()
        
        // Check if we have shared items (from Share Sheet)
        if let items = extensionContext?.inputItems as? [NSExtensionItem],
           !items.isEmpty {
            // Show file sharing interface
            presentFileSharingView(items: items, conversation: conversation)
        } else {
            // Show main menu (invitations or file sharing)
            presentMainMenuView(conversation: conversation)
        }
    }
    
    private func presentMainMenuView(conversation: MSConversation) {
        let menuView = MainMenuMessageView(
            conversation: conversation,
            onInviteNominee: { [weak self] in
                self?.presentNomineeInvitationView(for: conversation)
            },
            onShareFile: { [weak self] in
                self?.presentFileSharingView(items: [], conversation: conversation)
            }
        )
        
        let hostingController = UIHostingController(
            rootView: menuView.environment(\.unifiedTheme, UnifiedTheme())
        )
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    // MARK: - Nominee Invitation
    
    private func presentNomineeInvitationView(for conversation: MSConversation) {
        removeAllChildViewControllers()
        
        let invitationView = NomineeInvitationMessageView(
            conversation: conversation,
            onSendInvitation: { [weak self] inviteToken, vaultName, recipientName in
                self?.sendNomineeInvitation(
                    inviteToken: inviteToken,
                    vaultName: vaultName,
                    recipientName: recipientName,
                    in: conversation
                )
            },
            onCancel: { [weak self] in
                self?.presentMainInterface(for: conversation)
            }
        )
        
        let hostingController = UIHostingController(
            rootView: invitationView.environment(\.unifiedTheme, UnifiedTheme())
        )
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    private func sendNomineeInvitation(
        inviteToken: String,
        vaultName: String,
        recipientName: String,
        in conversation: MSConversation
    ) {
        // Create invitation URL
        var components = URLComponents(string: "khandoba://nominee/invite")
        components?.queryItems = [
            URLQueryItem(name: "token", value: inviteToken),
            URLQueryItem(name: "vault", value: vaultName),
            URLQueryItem(name: "status", value: "pending"),
            URLQueryItem(name: "sender", value: recipientName)
        ]
        
        guard let url = components?.url else {
            print("❌ Failed to create invitation URL")
            return
        }
        
        // Create interactive message layout (Apple Cash style)
        let layout = MSMessageTemplateLayout()
        layout.caption = "🔐 Vault Invitation"
        layout.subcaption = vaultName
        layout.trailingCaption = "Tap to Accept"
        layout.imageTitle = "Khandoba Secure Docs"
        
        // Create message
        let message = MSMessage()
        message.layout = layout
        message.url = url
        message.summaryText = "Vault Invitation: \(vaultName) - Tap to accept"
        
        // Note: MSMessage.session is read-only. Messages framework manages sessions automatically.
        // For message updates, create new messages and insert them - framework handles replacement.
        
        // Insert message
        conversation.insert(message) { error in
            if let error = error {
                print("❌ Failed to send invitation: \(error.localizedDescription)")
            } else {
                print("✅ Nominee invitation sent via iMessage")
                self.requestPresentationStyle(.compact)
            }
        }
    }
    
    // MARK: - File Sharing
    
    private func presentFileSharingView(items: [NSExtensionItem], conversation: MSConversation) {
        removeAllChildViewControllers()
        
        let fileSharingView = FileSharingMessageView(
            items: items,
            conversation: conversation,
            onShareComplete: { [weak self] in
                self?.requestPresentationStyle(.compact)
            },
            onCancel: { [weak self] in
                self?.presentMainInterface(for: conversation)
            }
        )
        
        let hostingController = UIHostingController(
            rootView: fileSharingView.environment(\.unifiedTheme, UnifiedTheme())
        )
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    // MARK: - Interactive Message Handling (Apple Cash Style)
    
    private func handleMessageSelection(_ message: MSMessage, in conversation: MSConversation) {
        guard let url = message.url,
              url.scheme == "khandoba" else {
            return
        }
        
        // Parse invitation data
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        
        let token = queryItems.first(where: { $0.name == "token" })?.value
        let vaultName = queryItems.first(where: { $0.name == "vault" })?.value ?? "Unknown Vault"
        let status = queryItems.first(where: { $0.name == "status" })?.value ?? "pending"
        let sender = queryItems.first(where: { $0.name == "sender" })?.value ?? "Vault Owner"
        
        // Show accept/decline UI (Apple Cash style)
        presentInvitationResponseView(
            message: message,
            conversation: conversation,
            token: token,
            vaultName: vaultName,
            sender: sender,
            status: status
        )
    }
    
    private func presentInvitationResponseView(
        message: MSMessage,
        conversation: MSConversation,
        token: String?,
        vaultName: String,
        sender: String,
        status: String
    ) {
        removeAllChildViewControllers()
        
        let responseView = InvitationResponseMessageView(
            message: message,
            conversation: conversation,
            token: token,
            vaultName: vaultName,
            sender: sender,
            status: status,
            onAccept: { [weak self] in
                self?.handleInvitationAcceptance(
                    message: message,
                    conversation: conversation,
                    token: token,
                    vaultName: vaultName
                )
            },
            onDecline: { [weak self] in
                self?.handleInvitationDecline(
                    message: message,
                    conversation: conversation
                )
            }
        )
        
        let hostingController = UIHostingController(
            rootView: responseView.environment(\.unifiedTheme, UnifiedTheme())
        )
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    private func handleInvitationAcceptance(
        message: MSMessage,
        conversation: MSConversation,
        token: String?,
        vaultName: String
    ) {
        // Update message to accepted state
        let updatedLayout = MSMessageTemplateLayout()
        updatedLayout.caption = "✅ Vault Access Accepted"
        updatedLayout.subcaption = vaultName
        updatedLayout.trailingCaption = "Accepted"
        
        var components = URLComponents(string: "khandoba://nominee/invite")
        components?.queryItems = [
            URLQueryItem(name: "token", value: token ?? ""),
            URLQueryItem(name: "vault", value: vaultName),
            URLQueryItem(name: "status", value: "accepted")
        ]
        
        guard let updatedURL = components?.url else { return }
        
        let updatedMessage = MSMessage()
        updatedMessage.layout = updatedLayout
        updatedMessage.url = updatedURL
        updatedMessage.summaryText = "✅ Accepted: \(vaultName)"
        
        // Note: MSMessage.session is read-only. Messages framework manages sessions automatically.
        // Inserting a new message with similar content will update the existing message bubble.
        
        conversation.insert(updatedMessage) { error in
            if let error = error {
                print("❌ Failed to update message: \(error.localizedDescription)")
            } else {
                print("✅ Invitation accepted - message updated")
                // Open main app
                if let url = URL(string: "khandoba://nominee/invite?token=\(token ?? "")&vault=\(vaultName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vaultName)") {
                    self.extensionContext?.open(url) { success in
                        if success {
                            print("✅ Opened main app")
                        }
                    }
                }
                self.requestPresentationStyle(.compact)
            }
        }
    }
    
    private func handleInvitationDecline(
        message: MSMessage,
        conversation: MSConversation
    ) {
        var vaultName = "Vault"
        if let url = message.url,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems,
           let vault = queryItems.first(where: { $0.name == "vault" })?.value {
            vaultName = vault
        }
        
        let updatedLayout = MSMessageTemplateLayout()
        updatedLayout.caption = "❌ Vault Invitation Declined"
        updatedLayout.subcaption = vaultName
        updatedLayout.trailingCaption = "Declined"
        
        var components = URLComponents(string: "khandoba://nominee/invite")
        if let originalURL = message.url,
           let originalComponents = URLComponents(url: originalURL, resolvingAgainstBaseURL: false),
           let originalQueryItems = originalComponents.queryItems {
            components?.queryItems = originalQueryItems.map { item in
                if item.name == "status" {
                    return URLQueryItem(name: "status", value: "declined")
                }
                return item
            }
            if !(components?.queryItems?.contains { $0.name == "status" } ?? false) {
                components?.queryItems?.append(URLQueryItem(name: "status", value: "declined"))
            }
        }
        
        let updatedMessage = MSMessage()
        updatedMessage.layout = updatedLayout
        if let updatedURL = components?.url {
            updatedMessage.url = updatedURL
        }
        updatedMessage.summaryText = "❌ Declined: \(vaultName)"
        
        // Note: MSMessage.session is read-only. Messages framework manages sessions automatically.
        // Inserting a new message with similar content will update the existing message bubble.
        
        conversation.insert(updatedMessage) { error in
            if let error = error {
                print("❌ Failed to update message: \(error.localizedDescription)")
            } else {
                print("✅ Invitation declined - message updated")
                self.requestPresentationStyle(.compact)
            }
        }
    }
    
    private func handleReceivedMessage(_ message: MSMessage, in conversation: MSConversation) {
        if let url = message.url,
           url.scheme == "khandoba",
           (url.host == "nominee" || url.host == "invite") {
            print("📬 Received invitation message: \(url.absoluteString)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func removeAllChildViewControllers() {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
}

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
            onTransferOwnership: { [weak self] in
                self?.presentTransferOwnershipView(for: conversation)
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
        
        // Parse message data
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        
        let token = queryItems.first(where: { $0.name == "token" })?.value
        let vaultName = queryItems.first(where: { $0.name == "vault" })?.value ?? "Unknown Vault"
        let status = queryItems.first(where: { $0.name == "status" })?.value ?? "pending"
        let sender = queryItems.first(where: { $0.name == "sender" })?.value ?? "Vault Owner"
        
        // Determine message type based on URL path
        if url.host == "transfer" || url.path.contains("transfer") {
            // Show transfer ownership response UI
            presentTransferResponseView(
                message: message,
                conversation: conversation,
                token: token,
                vaultName: vaultName,
                sender: sender,
                status: status
            )
        } else {
            // Show nominee invitation response UI (default)
            presentInvitationResponseView(
                message: message,
                conversation: conversation,
                token: token,
                vaultName: vaultName,
                sender: sender,
                status: status
            )
        }
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
        // Process acceptance in background
        Task {
            await processInvitationAcceptance(token: token, vaultName: vaultName)
        }
        
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
                // Open main app with deep link
                if let url = URL(string: "khandoba://nominee/invite?token=\(token ?? "")&vault=\(vaultName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vaultName)") {
                    self.extensionContext?.open(url) { success in
                        if success {
                            print("✅ Opened main app to process invitation")
                        } else {
                            // Store token for later processing
                            UserDefaults(suiteName: "group.com.khandoba.securedocs")?.set(token, forKey: "pending_invite_token")
                            print("📝 Stored invitation token for later processing")
                        }
                    }
                }
                self.requestPresentationStyle(.compact)
            }
        }
    }
    
    // MARK: - Process Invitation Acceptance
    
    private func processInvitationAcceptance(token: String?, vaultName: String) async {
        guard let token = token else {
            print("⚠️ No token provided for invitation acceptance")
            return
        }
        
        // Load SwiftData context
        do {
            let schema = Schema([Nominee.self, Vault.self, User.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = container.mainContext
            
            // Find nominee by token
            let nomineeDescriptor = FetchDescriptor<Nominee>(
                predicate: #Predicate { $0.inviteToken == token }
            )
            
            let nominees = try context.fetch(nomineeDescriptor)
            
            if let nominee = nominees.first {
                // Update nominee status
                nominee.status = .accepted
                nominee.acceptedAt = Date()
                
                try context.save()
                print("✅ Nominee invitation accepted and saved")
            } else {
                print("⚠️ No nominee found with token: \(token)")
            }
        } catch {
            print("❌ Failed to process invitation acceptance: \(error.localizedDescription)")
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
        guard let url = message.url,
              url.scheme == "khandoba" else {
            return
        }
        
        // Handle nominee invitations
        if url.host == "nominee" || url.host == "invite" {
            print("📬 Received nominee invitation message: \(url.absoluteString)")
            // Parse and show invitation response view if needed
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let status = queryItems.first(where: { $0.name == "status" })?.value,
               status == "pending" {
                // Show invitation response view
                let token = queryItems.first(where: { $0.name == "token" })?.value
                let vaultName = queryItems.first(where: { $0.name == "vault" })?.value ?? "Unknown Vault"
                let sender = queryItems.first(where: { $0.name == "sender" })?.value ?? "Vault Owner"
                
                presentInvitationResponseView(
                    message: message,
                    conversation: conversation,
                    token: token,
                    vaultName: vaultName,
                    sender: sender,
                    status: status
                )
            }
        }
        
        // Handle transfer ownership requests
        if url.host == "transfer" || url.path.contains("transfer") {
            print("📬 Received transfer ownership message: \(url.absoluteString)")
            // Parse and show transfer response view if needed
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let status = queryItems.first(where: { $0.name == "status" })?.value,
               status == "pending" {
                // Show transfer response view
                let token = queryItems.first(where: { $0.name == "token" })?.value
                let vaultName = queryItems.first(where: { $0.name == "vault" })?.value ?? "Unknown Vault"
                let sender = queryItems.first(where: { $0.name == "sender" })?.value ?? "Vault Owner"
                
                presentTransferResponseView(
                    message: message,
                    conversation: conversation,
                    token: token,
                    vaultName: vaultName,
                    sender: sender,
                    status: status
                )
            }
        }
    }
    
    // MARK: - Transfer Ownership
    
    private func presentTransferOwnershipView(for conversation: MSConversation) {
        removeAllChildViewControllers()
        
        let transferView = TransferOwnershipMessageView(
            conversation: conversation,
            onSendTransfer: { [weak self] transferToken, vaultName, recipientName in
                self?.sendTransferOwnershipRequest(
                    transferToken: transferToken,
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
            rootView: transferView.environment(\.unifiedTheme, UnifiedTheme())
        )
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    private func sendTransferOwnershipRequest(
        transferToken: String,
        vaultName: String,
        recipientName: String,
        in conversation: MSConversation
    ) {
        // Create transfer URL
        var components = URLComponents(string: "khandoba://transfer/ownership")
        components?.queryItems = [
            URLQueryItem(name: "token", value: transferToken),
            URLQueryItem(name: "vault", value: vaultName),
            URLQueryItem(name: "status", value: "pending"),
            URLQueryItem(name: "sender", value: recipientName)
        ]
        
        guard let url = components?.url else {
            print("❌ Failed to create transfer URL")
            return
        }
        
        // Create interactive message layout
        let layout = MSMessageTemplateLayout()
        layout.caption = "🔄 Transfer Ownership"
        layout.subcaption = vaultName
        layout.trailingCaption = "Tap to Accept"
        layout.imageTitle = "Khandoba Secure Docs"
        
        // Create message
        let message = MSMessage()
        message.layout = layout
        message.url = url
        message.summaryText = "Transfer Ownership: \(vaultName) - Tap to accept"
        
        // Insert message
        conversation.insert(message) { error in
            if let error = error {
                print("❌ Failed to send transfer request: \(error.localizedDescription)")
            } else {
                print("✅ Transfer ownership request sent via iMessage")
                self.requestPresentationStyle(.compact)
            }
        }
    }
    
    private func presentTransferResponseView(
        message: MSMessage,
        conversation: MSConversation,
        token: String?,
        vaultName: String,
        sender: String,
        status: String
    ) {
        removeAllChildViewControllers()
        
        let responseView = TransferResponseMessageView(
            message: message,
            conversation: conversation,
            token: token,
            vaultName: vaultName,
            sender: sender,
            status: status,
            onAccept: { [weak self] in
                self?.handleTransferAcceptance(
                    message: message,
                    conversation: conversation,
                    token: token,
                    vaultName: vaultName
                )
            },
            onDecline: { [weak self] in
                self?.handleTransferDecline(
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
    
    private func handleTransferAcceptance(
        message: MSMessage,
        conversation: MSConversation,
        token: String?,
        vaultName: String
    ) {
        // Process acceptance in background
        Task {
            await processTransferAcceptance(token: token, vaultName: vaultName)
        }
        
        // Update message to accepted state
        let updatedLayout = MSMessageTemplateLayout()
        updatedLayout.caption = "✅ Ownership Transfer Accepted"
        updatedLayout.subcaption = vaultName
        updatedLayout.trailingCaption = "Accepted"
        
        var components = URLComponents(string: "khandoba://transfer/ownership")
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
        
        conversation.insert(updatedMessage) { error in
            if let error = error {
                print("❌ Failed to update message: \(error.localizedDescription)")
            } else {
                print("✅ Transfer accepted - message updated")
                // Open main app with deep link
                if let url = URL(string: "khandoba://transfer/accept?token=\(token ?? "")&vault=\(vaultName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vaultName)") {
                    self.extensionContext?.open(url) { success in
                        if success {
                            print("✅ Opened main app to process transfer")
                        } else {
                            // Store token for later processing
                            UserDefaults(suiteName: "group.com.khandoba.securedocs")?.set(token, forKey: "pending_transfer_token")
                            print("📝 Stored transfer token for later processing")
                        }
                    }
                }
                self.requestPresentationStyle(.compact)
            }
        }
    }
    
    private func handleTransferDecline(
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
        updatedLayout.caption = "❌ Ownership Transfer Declined"
        updatedLayout.subcaption = vaultName
        updatedLayout.trailingCaption = "Declined"
        
        var components = URLComponents(string: "khandoba://transfer/ownership")
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
        
        conversation.insert(updatedMessage) { error in
            if let error = error {
                print("❌ Failed to update message: \(error.localizedDescription)")
            } else {
                print("✅ Transfer declined - message updated")
                self.requestPresentationStyle(.compact)
            }
        }
    }
    
    private func processTransferAcceptance(token: String?, vaultName: String) async {
        guard let token = token else {
            print("⚠️ No token provided for transfer acceptance")
            return
        }
        
        // Load SwiftData context
        do {
            let schema = Schema([VaultTransferRequest.self, Vault.self, User.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = container.mainContext
            
            // Find transfer request by token
            let transferDescriptor = FetchDescriptor<VaultTransferRequest>(
                predicate: #Predicate { $0.transferToken == token }
            )
            
            let transfers = try context.fetch(transferDescriptor)
            
            if let transfer = transfers.first {
                // Update transfer status
                transfer.status = "accepted"
                transfer.approvedAt = Date()
                
                try context.save()
                print("✅ Transfer ownership accepted and saved")
            } else {
                print("⚠️ No transfer request found with token: \(token)")
            }
        } catch {
            print("❌ Failed to process transfer acceptance: \(error.localizedDescription)")
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

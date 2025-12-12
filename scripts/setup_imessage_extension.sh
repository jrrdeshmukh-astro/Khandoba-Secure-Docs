#!/bin/bash

# Setup iMessage Extension - Steps 2 & 3
# Replaces generated files and configures target membership

set -e  # Exit on error

PROJECT_ROOT="/Users/jaideshmukh/Desktop/Khandoba Secure Docs"
PROJECT_FILE="$PROJECT_ROOT/Khandoba Secure Docs.xcodeproj/project.pbxproj"
EXTENSION_DIR="$PROJECT_ROOT/KhandobaSecureDocsMessageApp MessagesExtension"
SOURCE_DIR="$PROJECT_ROOT/KhandobaSecureDocsMessageApp"
MAIN_APP_DIR="$PROJECT_ROOT/Khandoba Secure Docs"

echo "🚀 Setting up iMessage Extension..."
echo ""

# Step 2.1: Replace MessagesViewController.swift
echo "📝 Step 2.1: Replacing MessagesViewController.swift..."

# Read the full implementation (we'll create it inline)
cat > "$EXTENSION_DIR/MessagesViewController.swift" << 'EOF'
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
        
        // Use session for message updates
        if let existingMessage = conversation.selectedMessage,
           let existingSession = existingMessage.session {
            message.session = existingSession
        } else {
            message.session = MSSession()
        }
        
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
        updatedMessage.session = message.session ?? MSSession()
        
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
        updatedMessage.session = message.session ?? MSSession()
        
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
EOF

echo "✅ MessagesViewController.swift replaced"

# Step 2.2: Copy Views folder
echo ""
echo "📁 Step 2.2: Copying Views folder..."

if [ ! -d "$EXTENSION_DIR/Views" ]; then
    mkdir -p "$EXTENSION_DIR/Views"
fi

cp "$SOURCE_DIR/Views/MainMenuMessageView.swift" "$EXTENSION_DIR/Views/"
cp "$SOURCE_DIR/Views/NomineeInvitationMessageView.swift" "$EXTENSION_DIR/Views/"
cp "$SOURCE_DIR/Views/InvitationResponseMessageView.swift" "$EXTENSION_DIR/Views/"
cp "$SOURCE_DIR/Views/FileSharingMessageView.swift" "$EXTENSION_DIR/Views/"

echo "✅ Views folder copied (4 files)"

# Step 2.3: Copy entitlements file
echo ""
echo "🔐 Step 2.3: Copying entitlements file..."

if [ -f "$SOURCE_DIR/KhandobaSecureDocsMessageApp.entitlements" ]; then
    cp "$SOURCE_DIR/KhandobaSecureDocsMessageApp.entitlements" "$EXTENSION_DIR/"
    echo "✅ Entitlements file copied"
else
    echo "⚠️  Entitlements file not found in source, creating default..."
    cat > "$EXTENSION_DIR/KhandobaSecureDocsMessageApp.entitlements" << 'ENTITLEMENTS'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.khandoba.securedocs</string>
	</array>
	<key>com.apple.developer.icloud-container-identifiers</key>
	<array>
		<string>iCloud.com.khandoba.securedocs</string>
	</array>
	<key>com.apple.developer.icloud-services</key>
	<array>
		<string>CloudKit</string>
	</array>
</dict>
</plist>
ENTITLEMENTS
    echo "✅ Default entitlements file created"
fi

echo ""
echo "📋 Step 3: Configuring target membership..."
echo "   Note: Target membership must be configured in Xcode manually"
echo "   or using the Python script (see below)"
echo ""

# List files that need target membership
echo "Files that need to be added to 'KhandobaSecureDocsMessageApp MessagesExtension' target:"
echo "  - $MAIN_APP_DIR/Theme/UnifiedTheme.swift"
echo "  - $MAIN_APP_DIR/Theme/ThemeModifiers.swift"
echo "  - $MAIN_APP_DIR/UI/Components/StandardCard.swift"
echo "  - $MAIN_APP_DIR/Models/Vault.swift"
echo "  - $MAIN_APP_DIR/Models/Nominee.swift"
echo "  - $MAIN_APP_DIR/Models/User.swift"
echo "  - $MAIN_APP_DIR/Config/AppConfig.swift"
echo ""

echo "✅ Step 2 Complete!"
echo ""
echo "⚠️  Step 3 requires manual configuration in Xcode:"
echo "   1. Open Xcode"
echo "   2. Select each file listed above"
echo "   3. File Inspector → Target Membership"
echo "   4. Check 'KhandobaSecureDocsMessageApp MessagesExtension'"
echo ""
echo "   OR run: python3 scripts/add_target_membership.py"
echo ""

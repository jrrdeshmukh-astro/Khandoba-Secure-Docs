//
//  MessageInvitationService.swift
//  Khandoba Secure Docs
//
//  Service for sending nominee invitations via iMessage extension
//

import Foundation
import Messages
import UIKit

@MainActor
final class MessageInvitationService {
    
    static let shared = MessageInvitationService()
    
    private init() {}
    
    /// Generate invitation message content for iMessage
    func generateInvitationMessage(
        inviteToken: String,
        vaultName: String,
        nomineeName: String
    ) -> String {
        let invitationURL = "khandoba://nominee/invite?token=\(inviteToken)&vault=\(vaultName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vaultName)"
        
        return """
        🔐 Vault Invitation
        
        You've been invited to access vault: \(vaultName)
        
        Tap the link below to accept:
        \(invitationURL)
        
        Sent via Khandoba Secure Docs
        """
    }
    
    /// Create MSMessage for nominee invitation
    func createInvitationMessage(
        inviteToken: String,
        vaultName: String,
        nomineeName: String
    ) -> MSMessage? {
        // Create the invitation URL
        var components = URLComponents(string: "khandoba://nominee/invite")
        components?.queryItems = [
            URLQueryItem(name: "token", value: inviteToken),
            URLQueryItem(name: "vault", value: vaultName)
        ]
        
        guard let url = components?.url else {
            print("❌ Failed to create invitation URL")
            return nil
        }
        
        // Create message layout
        let layout = MSMessageTemplateLayout()
        layout.caption = "You've been invited to access vault: \(vaultName)"
        layout.subcaption = "Tap to accept invitation"
        layout.trailingCaption = "Khandoba"
        
        // Create message
        let message = MSMessage()
        message.layout = layout
        message.url = url
        message.summaryText = "Vault Invitation: \(vaultName)"
        
        return message
    }
    
    /// Check if Messages app is available
    func canSendMessages() -> Bool {
        #if !APP_EXTENSION
        // In main app, check if SMS URL scheme is available
        guard let smsURL = URL(string: "sms:") else {
            return false
        }
        return UIApplication.shared.canOpenURL(smsURL)
        #else
        // In iMessage extension, Messages is always available
        return true
        #endif
    }
    
    /// Open Messages app with pre-filled invitation
    func openMessagesWithInvitation(
        inviteToken: String,
        vaultName: String,
        nomineeName: String,
        phoneNumber: String?
    ) {
        guard canSendMessages() else {
            print("❌ Messages app is not available")
            return
        }
        
        // Create invitation URL
        var components = URLComponents(string: "khandoba://nominee/invite")
        components?.queryItems = [
            URLQueryItem(name: "token", value: inviteToken),
            URLQueryItem(name: "vault", value: vaultName)
        ]
        
        guard components?.url != nil else {
            print("❌ Failed to create invitation URL")
            return
        }
        
        // Create message text
        let messageText = generateInvitationMessage(
            inviteToken: inviteToken,
            vaultName: vaultName,
            nomineeName: nomineeName
        )
        
        // Create SMS URL
        var smsURLString = "sms:"
        if let phoneNumber = phoneNumber {
            let cleanedNumber = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            smsURLString += cleanedNumber
        }
        smsURLString += "&body=\(messageText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? messageText)"
        
        if let smsURL = URL(string: smsURLString) {
            #if !APP_EXTENSION
            if UIApplication.shared.canOpenURL(smsURL) {
                UIApplication.shared.open(smsURL)
                print("✅ Opened Messages app with invitation")
            } else {
                print("❌ Cannot open Messages app")
            }
            #endif
        }
    }
}


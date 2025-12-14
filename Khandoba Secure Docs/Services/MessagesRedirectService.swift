//
//  MessagesRedirectService.swift
//  Khandoba Secure Docs
//
//  Service for handling Messages app redirects with vault context
//

import Foundation
import UIKit

@MainActor
final class MessagesRedirectService {
    static let shared = MessagesRedirectService()
    
    private let appGroupIdentifier = "group.com.khandoba.securedocs"
    private let pendingNominationVaultIDKey = "pendingNominationVaultID"
    
    private init() {}
    
    /// Open Messages app and store vault context for iMessage extension
    /// - Parameter vaultID: The UUID of the vault to nominate
    /// - Returns: Success status
    func openMessagesAppForNomination(vaultID: UUID) async -> Bool {
        // Store vault context in App Group UserDefaults
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ MessagesRedirectService: Failed to access App Group UserDefaults")
            print("   ⚠️ Make sure App Group '\(appGroupIdentifier)' is enabled in both main app and extension")
            return false
        }
        
        sharedDefaults.set(vaultID.uuidString, forKey: pendingNominationVaultIDKey)
        sharedDefaults.synchronize()
        
        print("📱 MessagesRedirectService: Stored vault ID \(vaultID.uuidString) for nomination")
        
        // Open Messages app
        // Use sms: URL scheme which opens Messages app
        guard let messagesURL = URL(string: "sms:") else {
            print("❌ MessagesRedirectService: Failed to create Messages URL")
            // Clear the stored vault ID if URL creation failed
            sharedDefaults.removeObject(forKey: pendingNominationVaultIDKey)
            return false
        }
        
        // Check if Messages app is available
        guard await UIApplication.shared.canOpenURL(messagesURL) else {
            print("❌ MessagesRedirectService: Messages app is not available on this device")
            // Clear the stored vault ID
            sharedDefaults.removeObject(forKey: pendingNominationVaultIDKey)
            return false
        }
        
        // Open Messages app
        let success = await UIApplication.shared.open(messagesURL)
        
        if success {
            print("✅ MessagesRedirectService: Successfully opened Messages app")
        } else {
            print("❌ MessagesRedirectService: Failed to open Messages app")
            // Clear the stored vault ID if opening failed
            sharedDefaults.removeObject(forKey: pendingNominationVaultIDKey)
        }
        
        return success
    }
    
    /// Read pending nomination vault ID from App Group UserDefaults
    /// - Returns: Vault ID if found, nil otherwise
    func readPendingNominationVaultID() -> UUID? {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return nil
        }
        
        guard let vaultIDString = sharedDefaults.string(forKey: pendingNominationVaultIDKey),
              let vaultID = UUID(uuidString: vaultIDString) else {
            return nil
        }
        
        return vaultID
    }
    
    /// Clear pending nomination vault ID
    func clearPendingNominationVaultID() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }
        
        sharedDefaults.removeObject(forKey: pendingNominationVaultIDKey)
        sharedDefaults.synchronize()
        
        print("📱 MessagesRedirectService: Cleared pending nomination vault ID")
    }
    
    /// Check if there's a pending nomination
    /// - Returns: True if a vault ID is stored
    func hasPendingNomination() -> Bool {
        return readPendingNominationVaultID() != nil
    }
}

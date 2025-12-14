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
    @available(iOSApplicationExtension, unavailable)
    func openMessagesAppForNomination(vaultID: UUID) async -> Bool {
        // This service should only be used in the main app, not in extensions
        #if APP_EXTENSION
        print("❌ MessagesRedirectService: Cannot open Messages app from extension")
        return false
        #else
        // Store vault context in App Group UserDefaults
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ MessagesRedirectService: Failed to access App Group UserDefaults")
            print("   ⚠️ Make sure App Group '\(appGroupIdentifier)' is enabled in both main app and extension")
            return false
        }
        
        let key = self.pendingNominationVaultIDKey
        sharedDefaults.set(vaultID.uuidString, forKey: key)
        sharedDefaults.synchronize()
        
        print("📱 MessagesRedirectService: Stored vault ID \(vaultID.uuidString) for nomination")
        
        // Open Messages app
        // Use sms: URL scheme which opens Messages app
        guard let messagesURL = URL(string: "sms:") else {
            print("❌ MessagesRedirectService: Failed to create Messages URL")
            // Clear the stored vault ID if URL creation failed
            sharedDefaults.removeObject(forKey: key)
            return false
        }
        
        // Check if Messages app is available and open it
        // Note: UIApplication.shared is only available in main app, not extensions
        return await Self.openURL(messagesURL, sharedDefaults: sharedDefaults, key: key)
        #endif
    }
    
    /// Open URL using UIApplication (only available in main app)
    @available(iOSApplicationExtension, unavailable)
    private static func openURL(_ url: URL, sharedDefaults: UserDefaults, key: String) async -> Bool {
        // Check if Messages app is available (synchronous call)
        guard UIApplication.shared.canOpenURL(url) else {
            print("❌ MessagesRedirectService: Messages app is not available on this device")
            // Clear the stored vault ID
            sharedDefaults.removeObject(forKey: key)
            return false
        }
        
        // Open Messages app using completion handler (convert to async)
        return await withCheckedContinuation { continuation in
            UIApplication.shared.open(url) { success in
                if success {
                    print("✅ MessagesRedirectService: Successfully opened Messages app")
                } else {
                    print("❌ MessagesRedirectService: Failed to open Messages app")
                    // Clear the stored vault ID if opening failed
                    sharedDefaults.removeObject(forKey: key)
                }
                continuation.resume(returning: success)
            }
        }
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

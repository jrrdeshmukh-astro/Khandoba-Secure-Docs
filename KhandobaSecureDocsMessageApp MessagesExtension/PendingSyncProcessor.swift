import Foundation
import SwiftData

enum PendingSyncProcessor {
    static func processAll() async {
        await processPendingInvite()
        await processPendingTransfer()
        await processPendingEmergency()
    }
    
    private static func processPendingInvite() async {
        guard let token = UserDefaults(suiteName: MessageAppConfig.appGroupIdentifier)?.string(forKey: "pending_invite_token") else { return }
        defer {
            UserDefaults(suiteName: MessageAppConfig.appGroupIdentifier)?.removeObject(forKey: "pending_invite_token")
        }
        // Reuse deep link handler
        await DeepLinkHandler.handle(url: URL(string: "khandoba://nominee/invite?token=\(token)")!)
    }
    
    private static func processPendingTransfer() async {
        guard let token = UserDefaults(suiteName: MessageAppConfig.appGroupIdentifier)?.string(forKey: "pending_transfer_token") else { return }
        defer {
            UserDefaults(suiteName: MessageAppConfig.appGroupIdentifier)?.removeObject(forKey: "pending_transfer_token")
        }
        await DeepLinkHandler.handle(url: URL(string: "khandoba://transfer/ownership?token=\(token)")!)
    }
    
    private static func processPendingEmergency() async {
        let defaults = UserDefaults(suiteName: MessageAppConfig.appGroupIdentifier)
        guard let requestIDString = defaults?.string(forKey: "pending_emergency_request_id") else { return }
        let vaultIDString = defaults?.string(forKey: "pending_emergency_vault_id")
        defer {
            defaults?.removeObject(forKey: "pending_emergency_request_id")
            defaults?.removeObject(forKey: "pending_emergency_vault_id")
        }
        // Optionally reconcile or surface a UI
        // For now, just log; your main app can present approval UI here.
        print("⚠️ Pending emergency request: \(requestIDString) vault: \(vaultIDString ?? "unknown")")
    }
}

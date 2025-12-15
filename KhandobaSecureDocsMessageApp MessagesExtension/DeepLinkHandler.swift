import Foundation
import SwiftData

enum DeepLinkHandler {
    static func handle(url: URL) async {
        guard url.scheme == "khandoba" else { return }
        
        if url.host == "nominee", url.path.contains("invite") || url.lastPathComponent == "invite" {
            await handleNomineeInvite(url: url)
        } else if url.host == "transfer" || url.path.contains("transfer") {
            await handleTransferAccept(url: url)
        } else if url.host == "share" {
            // Optional: handle custom CKShare deep links if you use them
        }
    }
    
    @MainActor
    private static func handleNomineeInvite(url: URL) async {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value else { return }
        do {
            let container = try SharedModelContainer.container()
            let context = container.mainContext
            
            let nomineeService = NomineeService()
            nomineeService.configure(modelContext: context)
            
            // Ensure we can load it (may need brief delay for sync)
            _ = try? await nomineeService.loadInvite(token: token)
            _ = try? await nomineeService.acceptInvite(token: token)
        } catch {
            // Store for later if needed
            UserDefaults(suiteName: MessageAppConfig.appGroupIdentifier)?.set(token, forKey: "pending_invite_token")
        }
    }
    
    @MainActor
    private static func handleTransferAccept(url: URL) async {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value else { return }
        do {
            let container = try SharedModelContainer.container()
            let context = container.mainContext
            
            // Find transfer request by token and mark accepted
            let descriptor = FetchDescriptor<VaultTransferRequest>(
                predicate: #Predicate<VaultTransferRequest> { $0.transferToken == token }
            )
            if let transfer = try? context.fetch(descriptor).first {
                transfer.status = "accepted"
                transfer.approvedAt = Date()
                try? context.save()
            } else {
                // Not yet synced; store for later
                UserDefaults(suiteName: MessageAppConfig.appGroupIdentifier)?.set(token, forKey: "pending_transfer_token")
            }
        } catch {
            UserDefaults(suiteName: MessageAppConfig.appGroupIdentifier)?.set(token, forKey: "pending_transfer_token")
        }
    }
}

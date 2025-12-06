//
//  NomineeService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData
import MessageUI
import Combine
import CloudKit

@MainActor
final class NomineeService: ObservableObject {
    @Published var nominees: [Nominee] = []
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    private var cloudKitAPI: CloudKitAPIService?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.cloudKitAPI = CloudKitAPIService()
    }
    
    func loadNominees(for vault: Vault, includeInactive: Bool = false) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let modelContext = modelContext else {
            print(" NomineeService: ModelContext not available")
            return
        }
        
        print(" Loading nominees for vault: \(vault.name) (ID: \(vault.id))")
        
        // Filter nominees by vault and optionally exclude inactive ones
        let vaultID = vault.id
        let descriptor: FetchDescriptor<Nominee>
        
        if includeInactive {
            descriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { nominee in
                nominee.vault?.id == vaultID
            },
            sortBy: [SortDescriptor(\.invitedAt, order: .reverse)]
        )
        } else {
            descriptor = FetchDescriptor<Nominee>(
                predicate: #Predicate { nominee in
                    nominee.vault?.id == vaultID && nominee.status != "inactive"
                },
                sortBy: [SortDescriptor(\.invitedAt, order: .reverse)]
            )
        }
        
        let fetchedNominees = try modelContext.fetch(descriptor)
        
        print(" Found \(fetchedNominees.count) nominee(s) for vault '\(vault.name)'")
        for nominee in fetchedNominees {
            print("   - \(nominee.name) (Status: \(nominee.status), Token: \(nominee.inviteToken))")
        }
        
        await MainActor.run {
            nominees = fetchedNominees
        }
    }
    
    func inviteNominee(
        name: String,
        phoneNumber: String?,
        email: String?,
        to vault: Vault,
        invitedByUserID: UUID
    ) async throws -> Nominee {
        guard let modelContext = modelContext else {
            throw NomineeError.contextNotAvailable
        }
        
        let nominee = Nominee(
            name: name,
            phoneNumber: phoneNumber,
            email: email
        )
        
        // Set bidirectional relationship
        nominee.vault = vault
        nominee.invitedByUserID = invitedByUserID
        
        // Add nominee to vault's nomineeList to maintain relationship
        if vault.nomineeList == nil {
            vault.nomineeList = []
        }
        vault.nomineeList?.append(nominee)
        
        modelContext.insert(nominee)
        try modelContext.save()
        
        print(" Nominee created: \(nominee.name)")
        print("   Token: \(nominee.inviteToken)")
        print("   Vault: \(vault.name) (ID: \(vault.id))")
        print("   Status: \(nominee.status)")
        print("   Vault relationship: \(nominee.vault?.name ?? "nil")")
        print("   📤 CloudKit sync: Nominee record will sync automatically")
        
        // Verify the relationship was set correctly
        if nominee.vault?.id == vault.id {
            print("    Vault relationship verified")
        } else {
            print("    WARNING: Vault relationship may not be set correctly")
        }
        
        // Send push notification to nominee (if they have the app installed)
        // Note: In production, this would be sent via your backend server
        if let phoneNumber = nominee.phoneNumber {
            // TODO: Send push notification via backend API
            // The backend would look up the device token for this phone number
            // and send a push notification with the invitation token
            print("   📱 Push notification will be sent to: \(phoneNumber)")
        }
        
        // Send invitation (placeholder - would use MessageUI in production)
        await sendInvitation(to: nominee)
        
        // Reload nominees to refresh the list
        print("🔄 Reloading nominees list...")
        try await loadNominees(for: vault)
        
        // Force a refresh on the main thread
        await MainActor.run {
            print(" Nominees list updated: \(nominees.count) nominee(s)")
        }
        
        return nominee
    }
    
    func removeNominee(_ nominee: Nominee, permanently: Bool = false) async throws {
        guard let modelContext = modelContext else { return }
        
        let vault = nominee.vault
        
        if permanently {
            // Permanently delete the nominee
            // Remove from vault's nomineeList first
            if let vault = vault {
                vault.nomineeList?.removeAll { $0.id == nominee.id }
            }
            
            modelContext.delete(nominee)
            try modelContext.save()
            
            print(" Nominee permanently deleted: \(nominee.name)")
        } else {
            // Soft delete - mark as inactive
        nominee.status = "inactive"
            
            // Optionally remove from vault's nomineeList (but keep in database)
            // This is a design choice - keeping it allows viewing inactive nominees
        try modelContext.save()
            
            print(" Nominee marked as inactive: \(nominee.name)")
        }
        
        // Reload the list
        if let vault = vault {
            try await loadNominees(for: vault)
        }
    }
    
    func loadInvite(token: String) async throws -> Nominee? {
        guard let modelContext = modelContext else {
            throw NomineeError.contextNotAvailable
        }
        
        print(" Loading invitation with token: \(token)")
        print("    Checking local database and CloudKit sync...")
        
        // First, try local SwiftData (CloudKit syncs automatically)
        let descriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.inviteToken == token }
        )
        
        var nominees = try modelContext.fetch(descriptor)
        
        // If not found locally, verify with CloudKit API (for server-side validation)
        if nominees.isEmpty, let cloudKitAPI = cloudKitAPI {
            print("   🔄 Not found locally, verifying with CloudKit API...")
            do {
                let exists = try await cloudKitAPI.verifyNomineeToken(token)
                if exists {
                    print("    Token verified in CloudKit, waiting for SwiftData sync...")
                    // Wait a moment for SwiftData to sync
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    nominees = try modelContext.fetch(descriptor)
                }
            } catch {
                print("    CloudKit API verification failed: \(error.localizedDescription)")
                // Continue with local-only search
            }
        }
        
        if let nominee = nominees.first {
            print(" Invitation found: \(nominee.name)")
            print("   Vault: \(nominee.vault?.name ?? "Unknown")")
            print("   Status: \(nominee.status)")
            return nominee
        } else {
            print(" Invitation not found with token: \(token)")
            print("    If this is a new invitation, wait a few seconds for CloudKit sync")
            print("    Make sure both devices are signed into the same iCloud account")
            throw NomineeError.invalidToken
        }
    }
    
    func acceptInvite(token: String) async throws -> Nominee? {
        guard let modelContext = modelContext else {
            throw NomineeError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.inviteToken == token }
        )
        
        guard let nominee = try modelContext.fetch(descriptor).first else {
            throw NomineeError.invalidToken
        }
        
        nominee.status = "accepted"
        nominee.acceptedAt = Date()
        try modelContext.save()
        
        print(" Invitation accepted: \(nominee.name)")
        print("   Vault: \(nominee.vault?.name ?? "Unknown")")
        print("   📤 CloudKit sync: Status update will sync to owner's device")
        
        // Send push notification to vault owner
        // Note: In production, this would be sent via your backend server
        if let vault = nominee.vault, let owner = vault.owner {
            // TODO: Send push notification to owner via backend API
            print("   📱 Push notification will be sent to vault owner: \(owner.fullName)")
        }
        
        return nominee
    }
    
    private func sendInvitation(to nominee: Nominee) async {
        // Generate invitation details with deep link
        let deepLink = "khandoba://invite?token=\(nominee.inviteToken)"
        let invitationMessage = """
        You've been invited to co-manage a vault in Khandoba Secure Docs!
        
        Vault: \(nominee.vault?.name ?? "Unknown")
        Invited by: Vault Owner
        
        Tap to accept: \(deepLink)
        
        Or download Khandoba Secure Docs from the App Store and use this token:
        \(nominee.inviteToken)
        """
        
        // Note: UnifiedShareView uses MessageComposeView to actually send the message
        // This method is kept for backwards compatibility but the message
        // should be sent via UnifiedShareView's MessageComposeView
        
        // Copy to clipboard as fallback
        UIPasteboard.general.string = invitationMessage
        
        print(" Invitation generated for: \(nominee.name)")
        print("   Deep link: \(deepLink)")
        print("   Message copied to clipboard for sharing")
    }
}

enum NomineeError: LocalizedError {
    case contextNotAvailable
    case invalidToken
    case sendFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Nominee service not available"
        case .invalidToken:
            return "Invalid invitation token"
        case .sendFailed:
            return "Failed to send invitation"
        }
    }
}

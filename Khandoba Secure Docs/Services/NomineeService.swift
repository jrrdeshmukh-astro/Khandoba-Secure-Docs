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
    @Published var activeNominees: [Nominee] = [] // Currently active in vault sessions
    
    private var modelContext: ModelContext?
    private var cloudKitSharing: CloudKitSharingService?
    private var currentUserID: UUID?
    private let container: CKContainer
    
    nonisolated init() {
        self.container = CKContainer(identifier: AppConfig.cloudKitContainer)
    }
    
    func configure(modelContext: ModelContext, currentUserID: UUID? = nil) {
        self.modelContext = modelContext
        self.currentUserID = currentUserID
        self.cloudKitSharing = CloudKitSharingService()
        cloudKitSharing?.configure(modelContext: modelContext)
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
                    nominee.vault?.id == vaultID && nominee.statusRaw != NomineeStatus.inactive.rawValue && nominee.statusRaw != NomineeStatus.revoked.rawValue
                },
                sortBy: [SortDescriptor(\.invitedAt, order: .reverse)]
            )
        }
        
        var fetchedNominees = try modelContext.fetch(descriptor)
        
        // Sync CloudKit share participants to Nominee records (ENABLED - removes technical debt)
        if let sharingService = cloudKitSharing {
            do {
                let participants = try await sharingService.getShareParticipants(for: vault)
                
                // Sync CloudKit participants with Nominee records
                fetchedNominees = try await syncCloudKitParticipants(
                    participants: participants,
                    existingNominees: fetchedNominees,
                    vault: vault,
                    modelContext: modelContext
                )
            } catch {
                print("   ⚠️ Failed to sync CloudKit participants: \(error.localizedDescription)")
                // Continue with existing nominees even if CloudKit sync fails
            }
        }
        
        // Update active status based on current sessions (Bank Vault Model)
        await updateActiveStatus(for: fetchedNominees, vault: vault)
        
        print(" Found \(fetchedNominees.count) nominee(s) for vault '\(vault.name)'")
        for nominee in fetchedNominees {
            print("   - \(nominee.name) (Status: \(nominee.status.displayName), Active: \(nominee.isCurrentlyActive))")
        }
        
        await MainActor.run {
            nominees = fetchedNominees
            activeNominees = fetchedNominees.filter { $0.isCurrentlyActive }
        }
    }
    
    // MARK: - CloudKit Participant Sync (ENABLED - removes technical debt)
    
    private func syncCloudKitParticipants(
        participants: [CKShare.Participant],
        existingNominees: [Nominee],
        vault: Vault,
        modelContext: ModelContext
    ) async throws -> [Nominee] {
        var updatedNominees = existingNominees
        let currentUserID = self.currentUserID
        
        for participant in participants {
            // Skip owner
            if participant.role == .owner {
                continue
            }
            
            let identity = participant.userIdentity
            let participantName = identity.nameComponents?.formatted() ?? 
                                 identity.lookupInfo?.emailAddress ?? 
                                 "Shared User"
            let participantEmail = identity.lookupInfo?.emailAddress
            let participantID = identity.lookupInfo?.userRecordID?.recordName
            
            // Find or create nominee
            let existingNominee = updatedNominees.first { nominee in
                if let email = nominee.email, let participantEmail = participantEmail {
                    return email == participantEmail
                }
                if let nomineeParticipantID = nominee.cloudKitParticipantID,
                   let participantID = participantID {
                    return nomineeParticipantID == participantID
                }
                return nominee.name == participantName
            }
            
            if let existing = existingNominee {
                // Update existing nominee
                existing.cloudKitParticipantID = participantID
                existing.cloudKitShareRecordID = participant.share?.recordID.recordName
                
                // Update status based on CloudKit acceptance
                if participant.acceptanceStatus == .accepted {
                    if existing.status == .pending {
                        existing.status = .accepted
                        existing.acceptedAt = Date()
                    }
                }
                
                print("   ✅ Updated nominee from CloudKit: \(existing.name) (Status: \(existing.status.displayName))")
            } else {
                // Create new nominee from CloudKit participant
                let newNominee = Nominee(
                    name: participantName,
                    email: participantEmail,
                    status: participant.acceptanceStatus == .accepted ? .accepted : .pending
                )
                newNominee.vault = vault
                newNominee.invitedAt = Date()
                newNominee.cloudKitParticipantID = participantID
                newNominee.cloudKitShareRecordID = participant.share?.recordID.recordName
                
                if participant.acceptanceStatus == .accepted {
                    newNominee.acceptedAt = Date()
                }
                
                if vault.nomineeList == nil {
                    vault.nomineeList = []
                }
                vault.nomineeList?.append(newNominee)
                
                modelContext.insert(newNominee)
                updatedNominees.append(newNominee)
                
                print("   ✅ Created nominee from CloudKit participant: \(participantName)")
            }
        }
        
        try modelContext.save()
        return updatedNominees
    }
    
    // MARK: - Update Active Status (Concurrent Access - Bank Vault Model)
    
    private func updateActiveStatus(for nominees: [Nominee], vault: Vault) async {
        // Check which nominees have active sessions in this vault
        // In the Bank Vault Model: When owner opens vault, all accepted nominees get concurrent access
        guard let sessions = vault.sessions else { return }
        let now = Date()
        let activeSessions = sessions.filter { session in
            session.isActive && session.expiresAt > now
        }
        
        // Update nominee active status
        for nominee in nominees {
            // A nominee is active if:
            // 1. They have accepted the invitation
            // 2. The vault has an active session (owner opened it)
            // 3. They're a CloudKit participant with accepted status
            let isActive = (nominee.status == .accepted || nominee.status == .active) &&
                          !activeSessions.isEmpty
            
            await MainActor.run {
                nominee.isCurrentlyActive = isActive
                if isActive, let session = activeSessions.first {
                    nominee.currentSessionID = session.id
                    nominee.lastActiveAt = Date()
                    if nominee.status == .accepted {
                        nominee.status = .active
                    }
                } else if !isActive && nominee.status == .active {
                    nominee.status = .accepted
                }
            }
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
        
        // Create nominee record
        let nominee = Nominee(
            name: name,
            phoneNumber: phoneNumber,
            email: email,
            status: .pending
        )
        nominee.vault = vault
        nominee.invitedByUserID = invitedByUserID
        
        if vault.nomineeList == nil {
            vault.nomineeList = []
        }
        vault.nomineeList?.append(nominee)
        
        modelContext.insert(nominee)
        try modelContext.save()
        
        print("✅ Nominee created: \(nominee.name)")
        print("   Vault: \(vault.name) (ID: \(vault.id))")
        print("   Status: \(nominee.status.displayName)")
        
        // Create CloudKit share (primary method - no token fallback)
        if let sharingService = cloudKitSharing {
            do {
                let share = try await sharingService.getOrCreateShare(for: vault)
                if let share = share {
                    nominee.cloudKitShareRecordID = share.recordID.recordName
                    try modelContext.save()
                    print("   🔗 CloudKit share created/retrieved: \(share.recordID.recordName)")
                } else {
                    print("   ⚠️ CloudKit share not available - UICloudSharingController will handle it")
                }
            } catch {
                print("   ⚠️ CloudKit share creation failed: \(error.localizedDescription)")
                throw NomineeError.shareCreationFailed
            }
        }
        
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
            // Remove from CloudKit share first
            if let sharingService = cloudKitSharing,
               let vault = nominee.vault,
               let participantID = nominee.cloudKitParticipantID {
                do {
                    try await sharingService.removeParticipant(
                        participantID: participantID,
                        from: vault
                    )
                } catch {
                    print("⚠️ Failed to remove from CloudKit share: \(error.localizedDescription)")
                    // Continue with local removal
                }
            }
            
            // Soft delete - mark as revoked
            nominee.status = .revoked
            nominee.vault?.nomineeList?.removeAll { $0.id == nominee.id }
            
            try modelContext.save()
            
            print("✅ Nominee revoked: \(nominee.name)")
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
        
        nominee.status = .accepted
        nominee.acceptedAt = Date()
        try modelContext.save()
        
        print("✅ Invitation accepted: \(nominee.name)")
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
    
    private func sendInvitation(to nominee: Nominee, shareURL: URL?) async {
        // Generate invitation details with CloudKit share URL (preferred) or token fallback
        let primaryLink: String
        let fallbackMessage: String
        
        if let shareURL = shareURL {
            // Use CloudKit share URL (works across different iCloud accounts)
            primaryLink = shareURL.absoluteString
            fallbackMessage = """
            
            Or use this token if the link doesn't work:
            \(nominee.inviteToken)
            """
        } else {
            // Fallback to token-based deep link
            primaryLink = "khandoba://invite?token=\(nominee.inviteToken)"
            fallbackMessage = """
            
            Or download Khandoba Secure Docs from the App Store and use this token:
            \(nominee.inviteToken)
            """
        }
        
        let invitationMessage = """
        You've been invited to co-manage a vault in Khandoba Secure Docs!
        
        Vault: \(nominee.vault?.name ?? "Unknown")
        Invited by: Vault Owner
        
        Tap to accept: \(primaryLink)
        \(fallbackMessage)
        """
        
        // Note: UnifiedShareView uses MessageComposeView to actually send the message
        // This method is kept for backwards compatibility but the message
        // should be sent via UnifiedShareView's MessageComposeView
        
        // Copy to clipboard as fallback
        UIPasteboard.general.string = invitationMessage
        
        print(" Invitation generated for: \(nominee.name)")
        if let shareURL = shareURL {
            print("   CloudKit share URL: \(shareURL.absoluteString)")
        } else {
            print("   Deep link (token-based): \(primaryLink)")
        }
        print("   Message copied to clipboard for sharing")
    }
}

enum NomineeError: LocalizedError {
    case contextNotAvailable
    case invalidToken
    case sendFailed
    case shareCreationFailed
    case participantNotFound
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Nominee service not available"
        case .invalidToken:
            return "Invalid invitation token"
        case .sendFailed:
            return "Failed to send invitation"
        case .shareCreationFailed:
            return "Failed to create CloudKit share"
        case .participantNotFound:
            return "Participant not found in CloudKit share"
        }
    }
}

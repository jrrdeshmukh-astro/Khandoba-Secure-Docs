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
        // Both main app and extension use the same CloudKit container
        // Container ID: "iCloud.com.khandoba.securedocs"
        let containerID = "iCloud.com.khandoba.securedocs"
        self.container = CKContainer(identifier: containerID)
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
                    nominee.vault?.id == vaultID && nominee.statusRaw != "inactive" && nominee.statusRaw != "revoked"
                },
                sortBy: [SortDescriptor(\.invitedAt, order: .reverse)]
            )
        }
        
        var fetchedNominees = try modelContext.fetch(descriptor)
        
        // Sync CloudKit share participants to Nominee records (ENABLED - removes technical debt)
        if let sharingService = cloudKitSharing {
            do {
                // Get share and participants together
                let (share, participants) = try await sharingService.getShareAndParticipants(for: vault)
                
                // Sync CloudKit participants with Nominee records
                fetchedNominees = try await syncCloudKitParticipants(
                    participants: participants,
                    shareRecordID: share?.recordID.recordName,
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
        shareRecordID: String?,
        existingNominees: [Nominee],
        vault: Vault,
        modelContext: ModelContext
    ) async throws -> [Nominee] {
        var updatedNominees = existingNominees
        
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
            
            // Find or create nominee - improved matching logic
            let existingNominee = updatedNominees.first { nominee in
                // Priority 1: Match by CloudKit participant ID (most reliable)
                if let nomineeParticipantID = nominee.cloudKitParticipantID,
                   let participantID = participantID {
                    return nomineeParticipantID == participantID
                }
                // Priority 2: Match by email (if both have emails)
                if let email = nominee.email, let participantEmail = participantEmail, !email.isEmpty, !participantEmail.isEmpty {
                    return email.lowercased() == participantEmail.lowercased()
                }
                // Priority 3: Match by name (least reliable, but fallback)
                return nominee.name == participantName && nominee.vault?.id == vault.id
            }
            
            if let existing = existingNominee {
                // Update existing nominee with latest CloudKit data
                existing.cloudKitParticipantID = participantID
                existing.cloudKitShareRecordID = shareRecordID
                
                // Update email if missing
                if existing.email == nil || existing.email?.isEmpty == true, let email = participantEmail {
                    existing.email = email
                }
                
                // Update name if it's just a placeholder
                if existing.name == "Nominee" || existing.name.isEmpty {
                    existing.name = participantName
                }
                
                // Update status based on CloudKit acceptance
                if participant.acceptanceStatus == .accepted {
                    if existing.status == .pending {
                        existing.status = .accepted
                        existing.acceptedAt = Date()
                    }
                } else if participant.acceptanceStatus == .pending {
                    // Keep pending status if not yet accepted
                    if existing.status != .pending {
                        existing.status = .pending
                    }
                }
                
                print("   ✅ Updated nominee from CloudKit: \(existing.name) (Status: \(existing.status.displayName), ParticipantID: \(participantID ?? "none"))")
            } else {
                // Create new nominee from CloudKit participant
                // Validation: Check if nominee with same email/name already exists (avoid duplicates)
                let duplicateCheck = existingNominees.first { nominee in
                    if let email = nominee.email, let participantEmail = participantEmail {
                        return email.lowercased() == participantEmail.lowercased()
                    }
                    return nominee.name == participantName && nominee.vault?.id == vault.id
                }
                
                if duplicateCheck != nil {
                    print("   ⚠️ Skipping duplicate nominee: \(participantName) (already exists)")
                    continue
                }
                
                let newNominee = Nominee(
                    name: participantName,
                    email: participantEmail,
                    status: participant.acceptanceStatus == .accepted ? .accepted : .pending
                )
                newNominee.vault = vault
                newNominee.invitedAt = Date()
                newNominee.cloudKitParticipantID = participantID
                newNominee.cloudKitShareRecordID = shareRecordID
                
                if participant.acceptanceStatus == .accepted {
                    newNominee.acceptedAt = Date()
                }
                
                if vault.nomineeList == nil {
                    vault.nomineeList = []
                }
                vault.nomineeList?.append(newNominee)
                
                modelContext.insert(newNominee)
                updatedNominees.append(newNominee)
                
                print("   ✅ Created nominee from CloudKit participant: \(participantName) (Status: \(newNominee.status.displayName))")
            }
        }
        
        // Remove nominees that are no longer in CloudKit share (if they were CloudKit-based)
        // But keep local nominees that were created manually
        let cloudKitParticipantIDs = Set(participants.compactMap { $0.userIdentity.lookupInfo?.userRecordID?.recordName })
        let nomineesToRemove = updatedNominees.filter { nominee in
            // Only remove if:
            // 1. Has CloudKit participant ID
            // 2. Not in current CloudKit participants
            // 3. Not manually created (has inviteToken but no CloudKit ID means manual)
            if let participantID = nominee.cloudKitParticipantID {
                return !cloudKitParticipantIDs.contains(participantID)
            }
            return false // Keep nominees without CloudKit IDs (manual nominees)
        }
        
        for nominee in nomineesToRemove {
            print("   🗑️ Removing nominee no longer in CloudKit share: \(nominee.name)")
            nominee.status = .revoked
            vault.nomineeList?.removeAll { $0.id == nominee.id }
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
                // Ensure vault is saved and synced before attempting to share
                try modelContext.save()
                print("   💾 Vault saved before CloudKit share creation")
                
                let share = try await sharingService.getOrCreateShare(for: vault)
                if let share = share {
                    nominee.cloudKitShareRecordID = share.recordID.recordName
                    try modelContext.save()
                    print("   ✅ CloudKit share created/retrieved: \(share.recordID.recordName)")
                    print("   📋 Share Record ID: \(share.recordID.recordName)")
                    // Note: CKShare doesn't directly expose rootRecordID
                    // The root record is accessed via the share's rootRecord property
                    // For logging purposes, we can note that the share references a root record
                    print("   📋 Share references root record (vault)")
                } else {
                    print("   ⚠️ CloudKit share not available yet")
                    print("   ℹ️ This usually means the vault hasn't synced to CloudKit yet")
                    print("   ℹ️ The nominee invitation will work once CloudKit sync completes")
                    print("   ℹ️ You can retry the invitation in a few seconds")
                    // Don't throw error - allow nominee to be created locally
                    // CloudKit sync will happen in background and share can be created later
                }
            } catch {
                print("   ⚠️ CloudKit share creation failed: \(error.localizedDescription)")
                print("   ℹ️ Error details: \(error)")
                // Don't throw - allow nominee to be created locally
                // The share can be created later when CloudKit sync completes
                print("   ℹ️ Nominee created locally - CloudKit share will be created when sync completes")
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
        guard let modelContext = modelContext else {
            throw NomineeError.contextNotAvailable
        }
        
        let vault = nominee.vault
        
        // Always remove from CloudKit share first (before local deletion)
        if let sharingService = cloudKitSharing,
           let vault = vault,
           let participantID = nominee.cloudKitParticipantID {
            do {
                print("🔗 Removing nominee from CloudKit share: \(nominee.name)")
                try await sharingService.removeParticipant(
                    participantID: participantID,
                    from: vault
                )
                print("   ✅ CloudKit participant removed successfully")
            } catch {
                print("⚠️ Failed to remove from CloudKit share: \(error.localizedDescription)")
                // Continue with local removal even if CloudKit fails
                // This ensures local state is consistent
            }
        } else if nominee.cloudKitParticipantID == nil {
            print("   ℹ️ Nominee has no CloudKit participant ID - skipping CloudKit removal")
        }
        
        if permanently {
            // Permanently delete the nominee
            // Remove from vault's nomineeList first
            if let vault = vault {
                vault.nomineeList?.removeAll { $0.id == nominee.id }
            }
            
            modelContext.delete(nominee)
            try modelContext.save()
            
            print("✅ Nominee permanently deleted: \(nominee.name)")
        } else {
            // Soft delete - mark as revoked
            nominee.status = .revoked
            nominee.vault?.nomineeList?.removeAll { $0.id == nominee.id }
            
            // Clear CloudKit references
            nominee.cloudKitParticipantID = nil
            nominee.cloudKitShareRecordID = nil
            
            try modelContext.save()
            
            print("✅ Nominee revoked: \(nominee.name)")
        }
        
        // Reload the list to reflect changes
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
        
        // If not found locally, wait for CloudKit sync (SwiftData syncs automatically)
        if nominees.isEmpty {
            print("   🔄 Not found locally, waiting for CloudKit sync...")
            // Wait a moment for SwiftData to sync from CloudKit
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    nominees = try modelContext.fetch(descriptor)
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
        
        // Send local notification to vault owner when nominee accepts
        // CloudKit will also sync the status change, but local notification provides immediate awareness
        if let vault = nominee.vault, let owner = vault.owner {
            // Send local notification to owner (if they're the current user on this device)
            // For cross-device notifications, CloudKit sync will handle it
            let pushService = PushNotificationService.shared
            pushService.sendNomineeAcceptedNotification(
                nomineeName: nominee.name,
                vaultName: vault.name
            )
            print("   📱 Notification sent to vault owner: \(owner.fullName)")
            print("   📬 CloudKit sync will notify owner on other devices automatically")
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

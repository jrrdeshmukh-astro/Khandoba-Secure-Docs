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
    private var supabaseService: SupabaseService?
    private var cloudKitSharing: CloudKitSharingService?
    private var currentUserID: UUID?
    private var antiVaultService: AntiVaultService?
    private var vaultService: VaultService?
    private let container: CKContainer
    
    nonisolated init() {
        // Both main app and extension use the same CloudKit container
        // Container ID: "iCloud.com.khandoba.securedocs"
        let containerID = "iCloud.com.khandoba.securedocs"
        self.container = CKContainer(identifier: containerID)
    }
    
    // SwiftData/CloudKit mode
    func configure(modelContext: ModelContext, currentUserID: UUID? = nil, antiVaultService: AntiVaultService? = nil, vaultService: VaultService? = nil) {
        self.modelContext = modelContext
        self.supabaseService = nil
        self.currentUserID = currentUserID
        self.antiVaultService = antiVaultService
        self.vaultService = vaultService
        self.cloudKitSharing = CloudKitSharingService()
        cloudKitSharing?.configure(modelContext: modelContext)
    }
    
    // Supabase mode
    func configure(supabaseService: SupabaseService, currentUserID: UUID? = nil, antiVaultService: AntiVaultService? = nil, vaultService: VaultService? = nil) {
        self.supabaseService = supabaseService
        self.modelContext = nil
        self.currentUserID = currentUserID
        self.antiVaultService = antiVaultService
        self.vaultService = vaultService
        self.cloudKitSharing = nil
    }
    
    func loadNominees(for vault: Vault, includeInactive: Bool = false) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await loadNomineesFromSupabase(
                vault: vault,
                includeInactive: includeInactive,
                supabaseService: supabaseService
            )
            return
        }
        
        // SwiftData/CloudKit mode
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
    
    // MARK: - Supabase Implementation
    
    /// Load nominees from Supabase
    private func loadNomineesFromSupabase(
        vault: Vault,
        includeInactive: Bool,
        supabaseService: SupabaseService
    ) async throws {
        print(" Loading nominees from Supabase for vault: \(vault.name) (ID: \(vault.id))")
        
        // RLS automatically filters nominees user has access to
        var supabaseNominees: [SupabaseNominee] = try await supabaseService.fetchAll(
            "nominees",
            filters: ["vault_id": vault.id.uuidString]
        )
        
        // Filter by status if needed
        if !includeInactive {
            supabaseNominees = supabaseNominees.filter { nominee in
                nominee.status != "inactive" && nominee.status != "revoked"
            }
        }
        
        // Sort by invited_at
        supabaseNominees.sort { $0.invitedAt > $1.invitedAt }
        
        // Convert to Nominee models for compatibility
        let convertedNominees = supabaseNominees.map { supabaseNominee in
            let nominee = Nominee(
                name: supabaseNominee.userID.uuidString, // Will need to fetch user name
                email: nil,
                status: NomineeStatus(rawValue: supabaseNominee.status) ?? .pending,
                invitedAt: supabaseNominee.invitedAt
            )
            nominee.id = supabaseNominee.id
            nominee.email = nil // Would need to fetch from users table
            nominee.invitedByUserID = supabaseNominee.invitedByUserID
            nominee.acceptedAt = supabaseNominee.acceptedAt
            nominee.statusRaw = supabaseNominee.status
            nominee.selectedDocumentIDs = supabaseNominee.selectedDocumentIDs
            nominee.sessionExpiresAt = supabaseNominee.sessionExpiresAt
            nominee.isSubsetAccess = supabaseNominee.isSubsetAccess
            
            // Fetch user name from Supabase
            Task {
                do {
                    let user: SupabaseUser = try await supabaseService.fetch(
                        "users",
                        id: supabaseNominee.userID
                    )
                    await MainActor.run {
                        nominee.name = user.fullName
                        nominee.email = user.email
                    }
                } catch {
                    print("⚠️ Failed to fetch user for nominee: \(error)")
                }
            }
            
            return nominee
        }
        
        // Update active status
        await updateActiveStatus(for: convertedNominees, vault: vault)
        
        await MainActor.run {
            nominees = convertedNominees
            activeNominees = convertedNominees.filter { $0.isCurrentlyActive }
        }
        
        print(" Found \(convertedNominees.count) nominee(s) for vault '\(vault.name)'")
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
        invitedByUserID: UUID,
        selectedDocumentIDs: [UUID]? = nil,
        sessionExpiresAt: Date? = nil,
        isSubsetAccess: Bool = false
    ) async throws -> Nominee {
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            return try await inviteNomineeToSupabase(
                name: name,
                phoneNumber: phoneNumber,
                email: email,
                vault: vault,
                invitedByUserID: invitedByUserID,
                selectedDocumentIDs: selectedDocumentIDs,
                sessionExpiresAt: sessionExpiresAt,
                isSubsetAccess: isSubsetAccess,
                supabaseService: supabaseService
            )
        }
        
        // SwiftData/CloudKit mode
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
        nominee.selectedDocumentIDs = selectedDocumentIDs
        nominee.sessionExpiresAt = sessionExpiresAt
        nominee.isSubsetAccess = isSubsetAccess
        
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
        
        // Trigger anti-vault monitoring if enabled
        if let antiVaultService = antiVaultService {
            do {
                try await antiVaultService.monitorSessionNomination(
                    vaultID: vault.id,
                    nomineeID: nominee.id,
                    selectedDocumentIDs: selectedDocumentIDs
                )
                print("✅ Anti-vault monitoring triggered for vault: \(vault.name)")
            } catch {
                print("⚠️ Failed to trigger anti-vault monitoring: \(error.localizedDescription)")
                // Don't fail the nomination if anti-vault monitoring fails
            }
        }
        
        // Force a refresh on the main thread
        await MainActor.run {
            print(" Nominees list updated: \(nominees.count) nominee(s)")
        }
        
        return nominee
    }
    
    /// Invite nominee via Supabase
    private func inviteNomineeToSupabase(
        name: String,
        phoneNumber: String?,
        email: String?,
        vault: Vault,
        invitedByUserID: UUID,
        selectedDocumentIDs: [UUID]? = nil,
        sessionExpiresAt: Date? = nil,
        isSubsetAccess: Bool = false,
        supabaseService: SupabaseService
    ) async throws -> Nominee {
        // First, find or create user by email
        var userID: UUID
        
        if let email = email {
            // Try to find existing user by email
            let users: [SupabaseUser] = try await supabaseService.fetchAll(
                "users",
                filters: ["email": email]
            )
            
            if let existingUser = users.first {
                userID = existingUser.id
            } else {
                // User doesn't exist - would need to create or invite
                // For now, we'll create a placeholder
                // In production, you'd send an invitation email/SMS
                throw NomineeError.sendFailed
            }
        } else {
            // Need email to invite
            throw NomineeError.sendFailed
        }
        
        // Check if nominee already exists
        let existing: [SupabaseNominee] = try await supabaseService.fetchAll(
            "nominees",
            filters: ["vault_id": vault.id.uuidString, "user_id": userID.uuidString]
        )
        
        if let existingNominee = existing.first {
            // Nominee already exists
            let nominee = Nominee(
                name: name,
                phoneNumber: phoneNumber,
                email: email,
                status: NomineeStatus(rawValue: existingNominee.status) ?? .pending
            )
            nominee.id = existingNominee.id
            return nominee
        }
        
        // Create new nominee with subset access support
        let supabaseNominee = SupabaseNominee(
            vaultID: vault.id,
            userID: userID,
            invitedByUserID: invitedByUserID,
            status: "pending",
            accessLevel: "read",
            selectedDocumentIDs: selectedDocumentIDs,
            sessionExpiresAt: sessionExpiresAt,
            isSubsetAccess: isSubsetAccess
        )
        
        let created: SupabaseNominee = try await supabaseService.insert(
            "nominees",
            values: supabaseNominee
        )
        
        // Convert to Nominee model
        let nominee = Nominee(
            name: name,
            phoneNumber: phoneNumber,
            email: email,
            status: .pending
        )
        nominee.id = created.id
        nominee.invitedAt = created.invitedAt
        nominee.selectedDocumentIDs = created.selectedDocumentIDs
        nominee.sessionExpiresAt = created.sessionExpiresAt
        nominee.isSubsetAccess = created.isSubsetAccess
        
        // Reload nominees
        try await loadNominees(for: vault)
        
        // Trigger anti-vault monitoring if enabled
        if let antiVaultService = antiVaultService {
            do {
                try await antiVaultService.monitorSessionNomination(
                    vaultID: vault.id,
                    nomineeID: nominee.id,
                    selectedDocumentIDs: selectedDocumentIDs
                )
                print("✅ Anti-vault monitoring triggered for vault: \(vault.name)")
            } catch {
                print("⚠️ Failed to trigger anti-vault monitoring: \(error.localizedDescription)")
                // Don't fail the nomination if anti-vault monitoring fails
            }
        }
        
        return nominee
    }
    
    func removeNominee(_ nominee: Nominee, permanently: Bool = false) async throws {
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            if permanently {
                try await supabaseService.delete("nominees", id: nominee.id)
            } else {
                // Update status to revoked
                let supabaseNominee: SupabaseNominee = try await supabaseService.fetch(
                    "nominees",
                    id: nominee.id
                )
                var updated = supabaseNominee
                updated.status = "revoked"
                updated.revokedAt = Date()
                
                let _: SupabaseNominee = try await supabaseService.update(
                    "nominees",
                    id: nominee.id,
                    values: updated
                )
            }
            
            // Reload nominees
            if let vault = nominee.vault {
                try await loadNominees(for: vault)
            }
            return
        }
        
        // SwiftData/CloudKit mode
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
    
    /// Accept a nominee invitation by nominee ID (for Supabase mode)
    func acceptNominee(nomineeID: UUID) async throws -> Nominee? {
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService, let currentUserID = currentUserID {
            // Fetch nominee from Supabase
            let supabaseNominee: SupabaseNominee = try await supabaseService.fetch("nominees", id: nomineeID)
            
            // Verify this nominee is for the current user
            guard supabaseNominee.userID == currentUserID else {
                throw NomineeError.invalidToken
            }
            
            // Update nominee status to accepted
            var updated = supabaseNominee
            updated.status = "accepted"
            updated.acceptedAt = Date()
            
            let _: SupabaseNominee = try await supabaseService.update(
                "nominees",
                id: nomineeID,
                values: updated
            )
            
            // Convert to Nominee model
            let nominee = Nominee(
                name: "", // Will be fetched from user
                email: nil,
                status: .accepted,
                invitedAt: supabaseNominee.invitedAt
            )
            nominee.id = supabaseNominee.id
            nominee.acceptedAt = Date()
            nominee.selectedDocumentIDs = supabaseNominee.selectedDocumentIDs
            nominee.sessionExpiresAt = supabaseNominee.sessionExpiresAt
            nominee.isSubsetAccess = supabaseNominee.isSubsetAccess
            
            // Fetch vault and user info
            let vault: SupabaseVault = try await supabaseService.fetch("vaults", id: supabaseNominee.vaultID)
            let user: SupabaseUser = try await supabaseService.fetch("users", id: supabaseNominee.userID)
            let owner: SupabaseUser = try await supabaseService.fetch("users", id: vault.ownerID)
            
            // Create Vault model for nominee
            let vaultModel = Vault(
                name: vault.name,
                vaultDescription: vault.vaultDescription,
                keyType: vault.keyType
            )
            vaultModel.id = vault.id
            nominee.vault = vaultModel
            
            nominee.name = user.fullName
            nominee.email = user.email
            
            print("✅ Nominee accepted in Supabase: \(nominee.name)")
            print("   Vault: \(vault.name)")
            
            // Check if this is a transfer ownership request
            // Transfer ownership: If nominee was invited by vault owner and this is the only nominee
            if supabaseNominee.invitedByUserID == vault.ownerID {
                // Check if this is the only nominee for this vault
                let allNominees: [SupabaseNominee] = try await supabaseService.fetchAll(
                    "nominees",
                    filters: ["vault_id": vault.id.uuidString]
                )
                let pendingNominees = allNominees.filter { $0.status == "pending" || $0.status == "accepted" }
                
                // If this is the only nominee and they're accepting, it's likely a transfer
                if pendingNominees.count == 1 && pendingNominees.first?.id == nomineeID {
                    print("🔄 Transfer ownership detected - transferring vault to new owner")
                    // Transfer ownership to the accepting user
                    if let vaultService = vaultService {
                        try await vaultService.transferOwnership(vault: vaultModel, to: currentUserID)
                        print("✅ Vault ownership transferred in Supabase: \(vault.name) → User ID: \(currentUserID)")
                    } else {
                        print("⚠️ VaultService not available - ownership transfer skipped")
                    }
                }
            }
            
            return nominee
        }
        
        throw NomineeError.contextNotAvailable
    }
    
    func acceptInvite(token: String) async throws -> Nominee? {
        // Supabase mode - token-based invites not used, use direct database access
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            // In Supabase, nominees are accepted by updating status
            // Token-based invites would need a separate invitations table
            // For now, return nil (would need to implement invitation system)
            throw NomineeError.invalidToken
        }
        
        // SwiftData/CloudKit mode
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
        
        // Check if this is a transfer ownership request
        // Transfer ownership: If nominee is the only nominee and vault owner invited them, transfer ownership
        if let vault = nominee.vault,
           let owner = vault.owner,
           let currentUserID = currentUserID,
           nominee.invitedByUserID == owner.id {
            // Check if this is a transfer (only one nominee, and nominee is accepting)
            let allNominees = vault.nomineeList ?? []
            let pendingNominees = allNominees.filter { $0.status == .pending || $0.status == .accepted }
            
            // If this is the only nominee and they're accepting, it's likely a transfer
            if pendingNominees.count == 1 && pendingNominees.first?.id == nominee.id {
                print("🔄 Transfer ownership detected - transferring vault to new owner")
                // Transfer ownership to the accepting user
                if let vaultService = vaultService {
                    try await vaultService.transferOwnership(vault: vault, to: currentUserID)
                    print("✅ Vault ownership transferred: \(vault.name) → User ID: \(currentUserID)")
                } else {
                    // Fallback: Update vault owner directly
                    let userDescriptor = FetchDescriptor<User>(
                        predicate: #Predicate { $0.id == currentUserID }
                    )
                    if let newOwner = try modelContext.fetch(userDescriptor).first {
                        vault.owner = newOwner
                        if newOwner.ownedVaults == nil {
                            newOwner.ownedVaults = []
                        }
                        if !(newOwner.ownedVaults?.contains(where: { $0.id == vault.id }) ?? false) {
                            newOwner.ownedVaults?.append(vault)
                        }
                        owner.ownedVaults?.removeAll { $0.id == vault.id }
                        try modelContext.save()
                        print("✅ Vault ownership transferred: \(vault.name) → \(newOwner.fullName)")
                    }
                }
            }
        }
        
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
    case vaultNotFound
    case userNotAuthenticated
    
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
        case .vaultNotFound:
            return "Vault not found"
        case .userNotAuthenticated:
            return "User not authenticated"
        }
    }
}

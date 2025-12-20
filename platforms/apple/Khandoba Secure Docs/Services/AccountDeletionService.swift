//
//  AccountDeletionService.swift
//  Khandoba Secure Docs
//
//  Handles account deletion in compliance with App Store requirements
//

import Foundation
import SwiftData
import Combine
import CloudKit

@MainActor
final class AccountDeletionService: ObservableObject {
    @Published var isDeleting = false
    @Published var deletionError: AccountDeletionError?
    
    private var modelContext: ModelContext?
    private var supabaseService: SupabaseService?
    private var cloudKitSharing: CloudKitSharingService?
    
    init() {
        self.cloudKitSharing = CloudKitSharingService()
    }
    
    // SwiftData/CloudKit mode
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.supabaseService = nil
        cloudKitSharing?.configure(modelContext: modelContext)
    }
    
    // Supabase mode
    func configure(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
        self.modelContext = nil
    }
    
    /// Delete user account and all associated data
    /// This complies with App Store Guideline 5.1.1(v) - Account Deletion
    func deleteAccount(user: User) async throws {
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await deleteAccountFromSupabase(user: user, supabaseService: supabaseService)
            return
        }
        
        guard let modelContext = modelContext else {
            throw AccountDeletionError.contextNotAvailable
        }
        
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            // 1. Delete all user-owned vaults and their contents
            // OPTION 1 COMPLIANCE: Complete deletion - all access logs deleted with vaults via cascade
            // SwiftData cascade delete will automatically delete:
            // - Access logs (VaultAccessLog) via @Relationship(deleteRule: .cascade)
            // - Documents (Document)
            // - Sessions (VaultSession)
            // - Dual key requests (DualKeyRequest)
            // - Emergency requests (EmergencyAccessRequest)
            // - Transfer requests (VaultTransferRequest)
            if let vaults = user.ownedVaults {
                print("🗑️ Deleting \(vaults.count) vault(s) owned by user")
                print("   → Access logs will be deleted via cascade delete (Option 1: Complete Deletion)")
                for vault in vaults {
                    // Verify access logs exist before deletion (for testing/debugging)
                    let logCount = vault.accessLogs?.count ?? 0
                    if logCount > 0 {
                        print("   → Vault '\(vault.name)' has \(logCount) access log(s) - will be deleted")
                    }
                    
                    // Delete all documents in vault
                    if let documents = vault.documents {
                        for document in documents {
                            modelContext.delete(document)
                        }
                    }
                    
                    // Delete vault - cascade delete will remove all access logs automatically
                    modelContext.delete(vault)
                }
            }
            
            // 2. Delete user roles
            if let roles = user.roles {
                for role in roles {
                    modelContext.delete(role)
                }
            }
            
            // 3. Delete chat messages sent by user
            if let messages = user.sentMessages {
                for message in messages {
                    modelContext.delete(message)
                }
            }
            
            // 4. Delete vault sessions (nullify relationship, but clean up orphaned sessions)
            if let sessions = user.vaultSessions {
                for session in sessions {
                    modelContext.delete(session)
                }
            }
            
            // 5. Delete dual key requests
            if let requests = user.dualKeyRequests {
                for request in requests {
                    modelContext.delete(request)
                }
            }
            
            // 6. Terminate nominee access to shared vaults
            // This removes the user from vaults they were given access to as a nominee
            try await terminateNomineeAccess(for: user, modelContext: modelContext)
            
            // 7. Delete the user account itself
            modelContext.delete(user)
            
            // 8. Save all deletions
            try modelContext.save()
            
            // 9. Force CloudKit sync to ensure deletions propagate
            // Wait a moment for SwiftData to queue CloudKit deletions
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Force another save to ensure CloudKit sync is triggered
            try modelContext.save()
            
            print("✅ Account deletion completed successfully")
            print("   → CloudKit sync initiated - deletions will propagate to iCloud")
            
        } catch {
            print("❌ Error deleting account: \(error.localizedDescription)")
            throw AccountDeletionError.deletionFailed(error.localizedDescription)
        }
    }
    
    /// Terminate nominee access to shared vaults
    /// Removes the user from all vaults they were given access to as a nominee
    private func terminateNomineeAccess(for user: User, modelContext: ModelContext) async throws {
        guard let userEmail = user.email else {
            print("   ℹ️ User has no email - skipping nominee access termination")
            return
        }
        
        print("🔒 Terminating nominee access for user: \(user.fullName) (\(userEmail))")
        
        // Find all Nominee records that match this user's email
        let nomineeDescriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { nominee in
                nominee.email == userEmail
            }
        )
        
        let nominees = try modelContext.fetch(nomineeDescriptor)
        
        if nominees.isEmpty {
            print("   ℹ️ No nominee records found for this user")
            return
        }
        
        print("   Found \(nominees.count) nominee record(s) to remove")
        
        // Group nominees by vault to handle CloudKit share removal efficiently
        var vaultsToUpdate: Set<UUID> = []
        
        for nominee in nominees {
            if let vault = nominee.vault {
                vaultsToUpdate.insert(vault.id)
                
                // IMPORTANT: Preserve access logs and map data for vault owner
                // Access logs remain with the vault owner for audit trail and security
                // We update logs to mark user as deleted but keep all historical data
                if let accessLogs = vault.accessLogs {
                    for log in accessLogs {
                        // If this log entry is from the user being deleted, mark it but preserve it
                        if log.userID == user.id {
                            // Update the user name to indicate account was deleted
                            // Keep all other data (timestamp, location, access type, etc.)
                            log.userName = (log.userName ?? "User") + " (Account Deleted)"
                            print("   📋 Preserved access log entry: \(log.accessType) at \(log.timestamp)")
                        }
                    }
                }
                
                // Close any active vault sessions for this vault where user is the session owner
                if let sessions = vault.sessions {
                    for session in sessions {
                        // Check if this session belongs to the user being deleted
                        if let sessionUser = session.user, sessionUser.id == user.id {
                            print("   🔒 Closing vault session for: \(vault.name)")
                            modelContext.delete(session)
                        }
                    }
                }
                
                // Remove from CloudKit share if applicable
                if let participantID = nominee.cloudKitParticipantID,
                   let sharingService = cloudKitSharing {
                    do {
                        try await sharingService.removeParticipant(
                            participantID: participantID,
                            from: vault
                        )
                        print("   ✅ Removed from CloudKit share: \(vault.name)")
                    } catch {
                        // Log but don't fail - CloudKit removal is best effort
                        print("   ⚠️ Failed to remove from CloudKit share for \(vault.name): \(error.localizedDescription)")
                    }
                }
            }
            
            // Delete the nominee record (this removes them from the vault's nominee list)
            // Note: Access logs remain with the vault owner
            print("   🗑️ Deleting nominee record: \(nominee.name)")
            modelContext.delete(nominee)
        }
        
        print("   ✅ Terminated nominee access to \(vaultsToUpdate.count) vault(s)")
    }
    
    // MARK: - Supabase Account Deletion
    
    /// Delete account from Supabase
    private func deleteAccountFromSupabase(user: User, supabaseService: SupabaseService) async throws {
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            let userID = user.id
            print("🗑️ Deleting account from Supabase: \(user.fullName) (\(userID))")
            
            // 1. Delete all user-owned vaults and their contents
            // RLS policies will ensure proper access control
            let ownedVaults: [SupabaseVault] = try await supabaseService.fetchAll(
                "vaults",
                filters: ["owner_id": userID]
            )
            
            print("🗑️ Deleting \(ownedVaults.count) vault(s) owned by user")
            
            for vault in ownedVaults {
                // Delete all documents in vault
                let documents: [SupabaseDocument] = try await supabaseService.fetchAll(
                    "documents",
                    filters: ["vault_id": vault.id]
                )
                
                print("   → Deleting \(documents.count) document(s) from vault '\(vault.name)'")
                for document in documents {
                    // Delete document file from storage if exists
                    if let storagePath = document.storagePath {
                        do {
                            try await supabaseService.deleteFile(bucket: "documents", path: storagePath)
                            print("   ✅ Deleted document file: \(storagePath)")
                        } catch {
                            print("   ⚠️ Failed to delete document file: \(error.localizedDescription)")
                            // Continue with record deletion even if file deletion fails
                        }
                    }
                    
                    // Delete document record
                    try await supabaseService.delete("documents", id: document.id)
                    print("   ✅ Deleted document record: \(document.name)")
                }
                
                // Delete access logs (cascade delete handled by database or manual deletion)
                let accessLogs: [SupabaseVaultAccessLog] = try await supabaseService.fetchAll(
                    "vault_access_logs",
                    filters: ["vault_id": vault.id]
                )
                
                print("   → Deleting \(accessLogs.count) access log(s)")
                for log in accessLogs {
                    try await supabaseService.delete("vault_access_logs", id: log.id)
                }
                
                // Delete vault sessions
                let sessions: [SupabaseVaultSession] = try await supabaseService.fetchAll(
                    "vault_sessions",
                    filters: ["vault_id": vault.id]
                )
                
                print("   → Deleting \(sessions.count) session(s)")
                for session in sessions {
                    try await supabaseService.delete("vault_sessions", id: session.id)
                }
                
                // Delete dual key requests
                let dualKeyRequests: [SupabaseDualKeyRequest] = try await supabaseService.fetchAll(
                    "dual_key_requests",
                    filters: ["vault_id": vault.id]
                )
                
                print("   → Deleting \(dualKeyRequests.count) dual key request(s)")
                for request in dualKeyRequests {
                    try await supabaseService.delete("dual_key_requests", id: request.id)
                }
                
                // Delete vault
                try await supabaseService.delete("vaults", id: vault.id)
                print("   ✅ Deleted vault: \(vault.name)")
            }
            
            // 2. Terminate nominee access to shared vaults
            try await terminateNomineeAccessFromSupabase(user: user, supabaseService: supabaseService)
            
            // 3. Delete chat messages sent by user
            let chatMessages: [SupabaseChatMessage] = try await supabaseService.fetchAll(
                "chat_messages",
                filters: ["sender_id": userID]
            )
            
            print("🗑️ Deleting \(chatMessages.count) chat message(s)")
            for message in chatMessages {
                try await supabaseService.delete("chat_messages", id: message.id)
            }
            
            // 4. Delete user roles
            let userRoles: [SupabaseUserRole] = try await supabaseService.fetchAll(
                "user_roles",
                filters: ["user_id": userID]
            )
            
            print("🗑️ Deleting \(userRoles.count) user role(s)")
            for role in userRoles {
                try await supabaseService.delete("user_roles", id: role.id)
            }
            
            // 5. Delete emergency access requests
            let emergencyRequests: [SupabaseEmergencyAccessRequest] = try await supabaseService.fetchAll(
                "emergency_access_requests",
                filters: ["requester_id": userID]
            )
            
            print("🗑️ Deleting \(emergencyRequests.count) emergency access request(s)")
            for request in emergencyRequests {
                try await supabaseService.delete("emergency_access_requests", id: request.id)
            }
            
            // 6. Delete vault transfer requests
            let transferRequests: [SupabaseVaultTransferRequest] = try await supabaseService.fetchAll(
                "vault_transfer_requests",
                filters: ["from_user_id": userID]
            )
            
            print("🗑️ Deleting \(transferRequests.count) transfer request(s)")
            for request in transferRequests {
                try await supabaseService.delete("vault_transfer_requests", id: request.id)
            }
            
            // 7. Delete the user account itself
            try await supabaseService.delete("users", id: userID)
            
            // 8. Sign out from Supabase auth
            try await supabaseService.signOut()
            
            print("✅ Account deletion completed successfully in Supabase")
            print("   → All user data has been permanently deleted")
            
        } catch {
            print("❌ Error deleting account from Supabase: \(error.localizedDescription)")
            throw AccountDeletionError.deletionFailed(error.localizedDescription)
        }
    }
    
    /// Terminate nominee access from Supabase
    private func terminateNomineeAccessFromSupabase(user: User, supabaseService: SupabaseService) async throws {
        let userID = user.id
        print("🔒 Terminating nominee access for user: \(user.fullName) (\(userID))")
        
        // Find all Nominee records that match this user's ID
        let nominees: [SupabaseNominee] = try await supabaseService.fetchAll(
            "nominees",
            filters: ["user_id": userID]
        )
        
        if nominees.isEmpty {
            print("   ℹ️ No nominee records found for this user")
            return
        }
        
        print("   Found \(nominees.count) nominee record(s) to remove")
        
        var vaultsToUpdate: Set<UUID> = []
        
        for nominee in nominees {
            vaultsToUpdate.insert(nominee.vaultID)
            
            // Update access logs to mark user as deleted but preserve them
            let accessLogs: [SupabaseVaultAccessLog] = try await supabaseService.fetchAll(
                "vault_access_logs",
                filters: ["vault_id": nominee.vaultID, "user_id": user.id]
            )
            
            for log in accessLogs {
                var updatedLog = log
                updatedLog.userName = (log.userName ?? "User") + " (Account Deleted)"
                try await supabaseService.update("vault_access_logs", id: log.id, values: updatedLog)
                print("   📋 Preserved access log entry: \(log.accessType) at \(log.timestamp)")
            }
            
            // Close active vault sessions
            let sessions: [SupabaseVaultSession] = try await supabaseService.fetchAll(
                "vault_sessions",
                filters: ["vault_id": nominee.vaultID, "user_id": user.id, "is_active": true]
            )
            
            for session in sessions {
                var updatedSession = session
                updatedSession.isActive = false
                try await supabaseService.update("vault_sessions", id: session.id, values: updatedSession)
                print("   🔒 Closed vault session for vault: \(nominee.vaultID)")
            }
            
            // Delete the nominee record
            try await supabaseService.delete("nominees", id: nominee.id)
            print("   🗑️ Deleted nominee record: \(nominee.id)")
        }
        
        print("   ✅ Terminated nominee access to \(vaultsToUpdate.count) vault(s)")
    }
}

enum AccountDeletionError: LocalizedError {
    case contextNotAvailable
    case deletionFailed(String)
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Unable to access data. Please try again."
        case .deletionFailed(let message):
            return "Account deletion failed: \(message)"
        case .userNotFound:
            return "User account not found."
        }
    }
}

//
//  AccountDeletionService.swift
//  Khandoba Secure Docs
//
//  Handles account deletion in compliance with App Store requirements
//

import Foundation
import SwiftData
import Combine

@MainActor
final class AccountDeletionService: ObservableObject {
    @Published var isDeleting = false
    @Published var deletionError: AccountDeletionError?
    
    private var modelContext: ModelContext?
    
    init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Delete user account and all associated data
    /// This complies with App Store Guideline 5.1.1(v) - Account Deletion
    func deleteAccount(user: User) async throws {
        guard let modelContext = modelContext else {
            throw AccountDeletionError.contextNotAvailable
        }
        
        isDeleting = true
        defer { isDeleting = false }
        
        do {
            // 1. Delete all user-owned vaults and their contents
            // (SwiftData cascade delete will handle documents, sessions, etc.)
            if let vaults = user.ownedVaults {
                print("🗑️ Deleting \(vaults.count) vault(s) owned by user")
                for vault in vaults {
                    // Delete all documents in vault
                    if let documents = vault.documents {
                        for document in documents {
                            modelContext.delete(document)
                        }
                    }
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
            
            // 6. Delete the user account itself
            modelContext.delete(user)
            
            // 7. Save all deletions
            try modelContext.save()
            
            print("✅ Account deletion completed successfully")
            
        } catch {
            print("❌ Error deleting account: \(error.localizedDescription)")
            throw AccountDeletionError.deletionFailed(error.localizedDescription)
        }
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

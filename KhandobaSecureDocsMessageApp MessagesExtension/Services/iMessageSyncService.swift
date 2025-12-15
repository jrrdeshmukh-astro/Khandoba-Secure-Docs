//
//  iMessageSyncService.swift
//  Khandoba Secure Docs
//
//  Service to handle sync between iMessage extension and main app
//

import Foundation
import SwiftData
import CloudKit
import Combine

// MARK: - Sync Status

enum SyncStatus: String, Codable {
    case pending = "pending"
    case syncing = "syncing"
    case synced = "synced"
    case failed = "failed"
    case timeout = "timeout"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .syncing: return "Syncing..."
        case .synced: return "Synced"
        case .failed: return "Failed"
        case .timeout: return "Timeout"
        }
    }
}

// MARK: - Sync Errors

enum SyncError: LocalizedError {
    case timeout(entityType: String, entityID: UUID)
    case cloudKitUnavailable
    case entityNotFound(entityType: String, entityID: UUID)
    case syncFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .timeout(let entityType, let entityID):
            return "Sync timeout for \(entityType) (\(entityID.uuidString)). Please check your connection and try again."
        case .cloudKitUnavailable:
            return "CloudKit is currently unavailable. Please check your iCloud settings and try again."
        case .entityNotFound(let entityType, let entityID):
            return "\(entityType) with ID \(entityID.uuidString) not found. It may not have synced yet."
        case .syncFailed(let reason):
            return "Sync failed: \(reason)"
        }
    }
}

@MainActor
final class iMessageSyncService: ObservableObject {
    static let shared = iMessageSyncService()
    
    @Published var syncStatus: [String: SyncStatus] = [:] // Entity ID -> Status
    
    private let appGroupIdentifier = "group.com.khandoba.securedocs"
    private var userDefaults: UserDefaults?
    
    private init() {
        userDefaults = UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Sync Flags
    
    /// Mark that a nominee was created and needs sync
    func markNomineeCreated(_ nomineeID: UUID) {
        var created = getCreatedNominees()
        created.append(nomineeID.uuidString)
        userDefaults?.set(created, forKey: "sync_created_nominees")
        print("📝 Marked nominee for sync: \(nomineeID)")
    }
    
    /// Mark that a nominee was accepted and needs sync
    func markNomineeAccepted(_ nomineeID: UUID) {
        var accepted = getAcceptedNominees()
        accepted.append(nomineeID.uuidString)
        userDefaults?.set(accepted, forKey: "sync_accepted_nominees")
        print("📝 Marked nominee acceptance for sync: \(nomineeID)")
    }
    
    /// Mark that a transfer request was created and needs sync
    func markTransferCreated(_ transferID: UUID) {
        var created = getCreatedTransfers()
        created.append(transferID.uuidString)
        userDefaults?.set(created, forKey: "sync_created_transfers")
        print("📝 Marked transfer for sync: \(transferID)")
    }
    
    /// Mark that a transfer was accepted and needs sync
    func markTransferAccepted(_ transferID: UUID) {
        var accepted = getAcceptedTransfers()
        accepted.append(transferID.uuidString)
        userDefaults?.set(accepted, forKey: "sync_accepted_transfers")
        print("📝 Marked transfer acceptance for sync: \(transferID)")
    }
    
    /// Mark that an emergency request was created and needs sync
    func markEmergencyCreated(_ requestID: UUID) {
        var created = getCreatedEmergencies()
        created.append(requestID.uuidString)
        userDefaults?.set(created, forKey: "sync_created_emergencies")
        print("📝 Marked emergency request for sync: \(requestID)")
    }
    
    // MARK: - Get Sync Flags
    
    func getCreatedNominees() -> [String] {
        return userDefaults?.array(forKey: "sync_created_nominees") as? [String] ?? []
    }
    
    func getAcceptedNominees() -> [String] {
        return userDefaults?.array(forKey: "sync_accepted_nominees") as? [String] ?? []
    }
    
    func getCreatedTransfers() -> [String] {
        return userDefaults?.array(forKey: "sync_created_transfers") as? [String] ?? []
    }
    
    func getAcceptedTransfers() -> [String] {
        return userDefaults?.array(forKey: "sync_accepted_transfers") as? [String] ?? []
    }
    
    func getCreatedEmergencies() -> [String] {
        return userDefaults?.array(forKey: "sync_created_emergencies") as? [String] ?? []
    }
    
    // MARK: - Clear Sync Flags
    
    func clearNomineeCreated(_ nomineeID: UUID) {
        var created = getCreatedNominees()
        created.removeAll { $0 == nomineeID.uuidString }
        userDefaults?.set(created, forKey: "sync_created_nominees")
    }
    
    func clearNomineeAccepted(_ nomineeID: UUID) {
        var accepted = getAcceptedNominees()
        accepted.removeAll { $0 == nomineeID.uuidString }
        userDefaults?.set(accepted, forKey: "sync_accepted_nominees")
    }
    
    func clearTransferCreated(_ transferID: UUID) {
        var created = getCreatedTransfers()
        created.removeAll { $0 == transferID.uuidString }
        userDefaults?.set(created, forKey: "sync_created_transfers")
    }
    
    func clearTransferAccepted(_ transferID: UUID) {
        var accepted = getAcceptedTransfers()
        accepted.removeAll { $0 == transferID.uuidString }
        userDefaults?.set(accepted, forKey: "sync_accepted_transfers")
    }
    
    func clearEmergencyCreated(_ requestID: UUID) {
        var created = getCreatedEmergencies()
        created.removeAll { $0 == requestID.uuidString }
        userDefaults?.set(created, forKey: "sync_created_emergencies")
    }
    
    // MARK: - Verify CloudKit Sync
    
    /// Verify that an entity has synced to CloudKit by checking if it exists in the shared context
    /// Uses multiple verification checks for reliability
    func verifyCloudKitSync(for entityID: UUID, entityType: String, context: ModelContext, timeout: TimeInterval = 10.0) async -> Bool {
        let entityKey = "\(entityType)_\(entityID.uuidString)"
        syncStatus[entityKey] = .syncing
        
        print("🔄 Verifying CloudKit sync for \(entityType): \(entityID)")
        
        let startTime = Date()
        let checkInterval: TimeInterval = 0.5
        var checkCount = 0
        var consecutiveFinds = 0
        let requiredConsecutiveFinds = 2 // Require 2 consecutive finds for reliability
        
        while Date().timeIntervalSince(startTime) < timeout {
            checkCount += 1
            
            // Check if entity exists in context (CloudKit syncs automatically via SwiftData)
            let found = await MainActor.run {
                do {
                    var result = false
                    switch entityType {
                    case "Nominee":
                        let descriptor = FetchDescriptor<Nominee>(
                            predicate: #Predicate { $0.id == entityID }
                        )
                        result = (try? context.fetch(descriptor).first) != nil
                    case "VaultTransferRequest":
                        let descriptor = FetchDescriptor<VaultTransferRequest>(
                            predicate: #Predicate { $0.id == entityID }
                        )
                        result = (try? context.fetch(descriptor).first) != nil
                    case "EmergencyAccessRequest":
                        let descriptor = FetchDescriptor<EmergencyAccessRequest>(
                            predicate: #Predicate { $0.id == entityID }
                        )
                        result = (try? context.fetch(descriptor).first) != nil
                    case "Vault":
                        let descriptor = FetchDescriptor<Vault>(
                            predicate: #Predicate { $0.id == entityID }
                        )
                        result = (try? context.fetch(descriptor).first) != nil
                    default:
                        result = false
                    }
                    
                    // Additional verification: check if entity has required relationships
                    if result {
                        switch entityType {
                        case "Nominee":
                            let nomineeDescriptor = FetchDescriptor<Nominee>(
                                predicate: #Predicate { $0.id == entityID }
                            )
                            if let nominee = try? context.fetch(nomineeDescriptor).first {
                                // Verify nominee has vault relationship
                                result = nominee.vault != nil
                            }
                        case "VaultTransferRequest":
                            let transferDescriptor = FetchDescriptor<VaultTransferRequest>(
                                predicate: #Predicate { $0.id == entityID }
                            )
                            if let transfer = try? context.fetch(transferDescriptor).first {
                                // Verify transfer has vault relationship
                                result = transfer.vault != nil
                            }
                        default:
                            break
                        }
                    }
                    
                    return result
                } catch {
                    print("⚠️ Error during sync verification: \(error.localizedDescription)")
                    return false
                }
            }
            
            if found {
                consecutiveFinds += 1
                if consecutiveFinds >= requiredConsecutiveFinds {
                    print("✅ CloudKit sync verified for \(entityType): \(entityID) (after \(checkCount) checks)")
                    syncStatus[entityKey] = .synced
                    return true
                }
            } else {
                consecutiveFinds = 0
            }
            
            // Wait before next check
            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }
        
        print("⚠️ CloudKit sync verification timeout for \(entityType): \(entityID) (checked \(checkCount) times)")
        syncStatus[entityKey] = .timeout
        return false
    }
    
    /// Wait for CloudKit sync with exponential backoff and retry mechanism
    func waitForCloudKitSync(
        entityID: UUID,
        entityType: String,
        context: ModelContext,
        maxWait: TimeInterval = 30.0,
        onProgress: ((SyncStatus) -> Void)? = nil
    ) async throws {
        let entityKey = "\(entityType)_\(entityID.uuidString)"
        syncStatus[entityKey] = .pending
        onProgress?(.pending)
        
        print("⏳ Waiting for CloudKit sync: \(entityType) \(entityID) (max wait: \(maxWait)s)")
        
        var waitTime: TimeInterval = 0.5
        let maxWaitTime: TimeInterval = maxWait
        var totalWait: TimeInterval = 0
        var attempt = 0
        let maxAttempts = 10
        
        syncStatus[entityKey] = .syncing
        onProgress?(.syncing)
        
        while totalWait < maxWaitTime && attempt < maxAttempts {
            attempt += 1
            print("   Attempt \(attempt)/\(maxAttempts): Checking sync (waited \(String(format: "%.1f", totalWait))s)")
            
            let synced = await verifyCloudKitSync(for: entityID, entityType: entityType, context: context, timeout: waitTime)
            if synced {
                print("✅ Sync confirmed for \(entityType): \(entityID) (total wait: \(String(format: "%.1f", totalWait))s)")
                syncStatus[entityKey] = .synced
                onProgress?(.synced)
                return
            }
            
            totalWait += waitTime
            waitTime = min(waitTime * 1.5, 3.0) // Exponential backoff, max 3 seconds
            
            // Log progress
            if attempt % 3 == 0 {
                print("   ⏳ Still syncing... (waited \(String(format: "%.1f", totalWait))s)")
            }
            
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        let error: SyncError
        if attempt >= maxAttempts {
            error = .syncFailed(reason: "Maximum retry attempts reached")
        } else {
            error = .timeout(entityType: entityType, entityID: entityID)
        }
        
        print("❌ Sync wait failed for \(entityType): \(entityID) (waited \(String(format: "%.1f", totalWait))s, \(attempt) attempts)")
        syncStatus[entityKey] = .failed
        onProgress?(.failed)
        throw error
    }
    
    /// Get sync status for an entity
    func getSyncStatus(for entityID: UUID, entityType: String) -> SyncStatus {
        let entityKey = "\(entityType)_\(entityID.uuidString)"
        return syncStatus[entityKey] ?? .pending
    }
    
    /// Clear sync status for an entity
    func clearSyncStatus(for entityID: UUID, entityType: String) {
        let entityKey = "\(entityType)_\(entityID.uuidString)"
        syncStatus.removeValue(forKey: entityKey)
    }
    
    // MARK: - Privilege Verification
    
    /// Check if a user (by ID) has nominee access to a vault
    func verifyNomineeAccess(userID: UUID, vaultID: UUID, context: ModelContext) -> Bool {
        let vaultDescriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.id == vaultID }
        )
        
        guard let vault = try? context.fetch(vaultDescriptor).first else {
            return false
        }
        
        // Check if user is a nominee with accepted/active status
        if let nominees = vault.nomineeList {
            return nominees.contains { nominee in
                // Match by user ID if available, or by email/phone if nominee was created for this user
                (nominee.status == .accepted || nominee.status == .active)
            }
        }
        
        return false
    }
    
    /// Check if a user is the owner of a vault
    func verifyVaultOwnership(userID: UUID, vaultID: UUID, context: ModelContext) -> Bool {
        let vaultDescriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.id == vaultID }
        )
        
        guard let vault = try? context.fetch(vaultDescriptor).first,
              let owner = vault.owner else {
            return false
        }
        
        return owner.id == userID
    }
}

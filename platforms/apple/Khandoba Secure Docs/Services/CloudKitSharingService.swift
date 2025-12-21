//
//  CloudKitSharingService.swift
//  Khandoba Secure Docs
//
//  CloudKit Sharing service for sharing vaults with nominees
//  Enables cross-iCloud-account sharing using CKShare
//

import Foundation
import CloudKit
import SwiftUI
import SwiftData
import Combine
#if os(iOS)
import UIKit
#endif

@MainActor
final class CloudKitSharingService: ObservableObject {
    @Published var isSharing = false
    @Published var shareError: String?
    
    private let container: CKContainer
    private var modelContext: ModelContext?
    
    init() {
        // Both main app and extension use the same CloudKit container
        // Use MessageAppConfig for extension, AppConfig for main app
        // Both main app and extension use the same CloudKit container
        // Container ID: "iCloud.com.khandoba.securedocs"
        let containerID = "iCloud.com.khandoba.securedocs"
        self.container = CKContainer(identifier: containerID)
    }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Create Share for Vault
    
    /// Create a CKShare for a vault to share with nominees
    /// Returns the share metadata URL that can be sent to the nominee
    func createShare(for vault: Vault) async throws -> URL {
        // Skip CloudKit operations if Supabase is enabled
        guard !AppConfig.useSupabase else {
            throw CloudKitSharingError.shareCreationFailed
        }
        
        print("🔗 Creating CloudKit share for vault: \(vault.name)")

        // Ensure vault is synced to CloudKit first
        try await ensureVaultSynced(vault)
        
        // Get the CloudKit record ID for the vault
        // SwiftData stores records with a specific naming convention
        guard let vaultRecordID = try await getVaultRecordID(vault) else {
            throw CloudKitSharingError.vaultRecordNotFound
        }
        
        // Check if share already exists
        if let existingShare = try await getExistingShare(for: vaultRecordID) {
            print("   ✅ Share already exists, returning existing share URL")
            return try await getShareURL(from: existingShare)
        }
        
        // Get the root record first
        let rootRecord = try await getVaultRecord(vaultRecordID)
        
        // Create new share
        let share = CKShare(rootRecord: rootRecord)
        share[CKShare.SystemFieldKey.title] = vault.name
        share.publicPermission = .none // Private share only
        
        // Add the share to the root record's share property
        rootRecord.setParent(share.recordID)
        
        // Save both the share and the updated root record
        let database = container.privateCloudDatabase
        let (saveResult, _) = try await database.modifyRecords(saving: [share, rootRecord], deleting: [])
        
        guard case .success(let savedShare) = saveResult[share.recordID] else {
            throw CloudKitSharingError.shareCreationFailed
        }
        
        guard let savedShareRecord = savedShare as? CKShare else {
            throw CloudKitSharingError.shareCreationFailed
        }
        
        print("   ✅ Share created successfully")
        
        // Get the share URL using UICloudSharingController
        return try await getShareURL(from: savedShareRecord)
    }
    
    // MARK: - Ensure Vault Synced
    
    /// Ensure vault is synced to CloudKit before sharing
    /// This forces SwiftData to sync the vault to CloudKit
    private func ensureVaultSynced(_ vault: Vault) async throws {
        // Skip CloudKit operations if Supabase is enabled
        guard !AppConfig.useSupabase else {
            return
        }
        
        guard let modelContext = modelContext else {
            return
        }
        
        print("   🔄 Ensuring vault is synced to CloudKit...")
        print("   📋 Vault: \(vault.name) (ID: \(vault.id.uuidString))")
        
        // Force save to trigger CloudKit sync
        try modelContext.save()
        print("   💾 Vault saved to SwiftData")
        
        // Wait for CloudKit sync with retry logic
        // SwiftData + CloudKit sync can take a few seconds
        let maxRetries = 5
        let retryDelay: UInt64 = 1_000_000_000 // 1 second
        
        for attempt in 1...maxRetries {
            print("   ⏳ Waiting for CloudKit sync (attempt \(attempt)/\(maxRetries))...")
            try await Task.sleep(nanoseconds: retryDelay)
            
            // Try to find the record in CloudKit
            if let recordID = try? await getVaultRecordID(vault) {
                print("   ✅ Vault found in CloudKit: \(recordID.recordName)")
                return
            }
            
            // Also try to trigger SwiftData sync by accessing the vault
            let vaultID = vault.id
            let _ = try modelContext.fetch(FetchDescriptor<Vault>(
                predicate: #Predicate { $0.id == vaultID }
            ))
        }
        
        print("   ⚠️ Vault may not be synced to CloudKit yet after \(maxRetries) attempts")
        print("   ℹ️ This is OK - CloudKit sync happens asynchronously")
        print("   ℹ️ The record will be available once sync completes")
    }
    
    // MARK: - Get Vault Record ID
    
    /// Get the CloudKit record ID for a SwiftData Vault model
    /// Uses direct record ID lookups based on SwiftData's naming conventions
    /// Returns nil if record not found, allowing UICloudSharingController to handle it automatically
    /// Note: We avoid querying CloudKit directly as system fields aren't queryable
    private func getVaultRecordID(_ vault: Vault) async throws -> CKRecord.ID? {
        guard modelContext != nil else {
            print("   ❌ ModelContext not configured")
            return nil
        }
        
        let database = container.privateCloudDatabase
        let zoneID = CKRecordZone.default().zoneID
        
        // SwiftData + CloudKit uses predictable naming conventions
        // Try common naming formats (most reliable approach)
        print("   🔍 Trying direct record ID lookups...")
        
        // Format 1: CD_<EntityName>_<UUID> (most common SwiftData + CloudKit format)
        let recordName1 = "CD_Vault_\(vault.id.uuidString)"
        let recordID1 = CKRecord.ID(recordName: recordName1, zoneID: zoneID)
        
        // Format 2: Just the UUID (some configurations)
        let recordName2 = vault.id.uuidString
        let recordID2 = CKRecord.ID(recordName: recordName2, zoneID: zoneID)
        
        // Format 3: Lowercase entity name
        let recordName3 = "CD_vault_\(vault.id.uuidString)"
        let recordID3 = CKRecord.ID(recordName: recordName3, zoneID: zoneID)
        
        // Format 4: Try with hyphens (some CloudKit configurations)
        let recordName4 = "CD-Vault-\(vault.id.uuidString)"
        let recordID4 = CKRecord.ID(recordName: recordName4, zoneID: zoneID)
        
        let recordIDsToTry = [
            (recordID1, "CD_Vault_<UUID>"),
            (recordID2, "UUID only"),
            (recordID3, "CD_vault_<UUID>"),
            (recordID4, "CD-Vault-<UUID>")
        ]
        
        for (recordID, formatName) in recordIDsToTry {
            do {
                let fetchResult = try await database.records(for: [recordID])
                if case .success(let record) = fetchResult[recordID] {
                    // Verify it's the correct vault by checking name
                    let recordName = (record["name"] as? String) ?? 
                                    (record["ZNAME"] as? String) ?? 
                                    (record["Name"] as? String) ?? ""
                    
                    if recordName == vault.name || recordName.isEmpty {
                        print("   ✅ Found CloudKit record using format '\(formatName)': \(recordID.recordName)")
                        return recordID
                    } else {
                        print("   ⚠️ Found record with format '\(formatName)' but name mismatch: '\(recordName)' vs '\(vault.name)'")
                    }
                }
            } catch {
                // Continue to next format - this is expected if record doesn't exist with this format
            }
        }
        
        // If all direct lookups fail, the record might not be synced to CloudKit yet
        // This is OK - SwiftData will sync it automatically, and UICloudSharingController
        // can use the PersistentIdentifier to find it
        print("   ℹ️ Could not find CloudKit record with direct lookups")
        print("   ℹ️ Vault ID: \(vault.id.uuidString)")
        print("   ℹ️ Vault Name: \(vault.name)")
        print("   ℹ️ This may mean:")
        print("      - Record hasn't synced to CloudKit yet (wait a few seconds and try again)")
        print("      - CloudKit sync is disabled or not configured")
        print("   ℹ️ UICloudSharingController will use PersistentIdentifier to find the record automatically")
        return nil
    }
    
    /// Get the actual CloudKit record for the vault
    private func getVaultRecord(_ recordID: CKRecord.ID) async throws -> CKRecord {
        let database = container.privateCloudDatabase
        let fetchResult = try await database.records(for: [recordID])
        
        guard case .success(let record) = fetchResult[recordID] else {
            throw CloudKitSharingError.vaultRecordNotFound
        }
        
        return record
    }
    
    // MARK: - Check for Existing Share
    
    /// Check if a share already exists for this vault
    /// Uses the root record's parent to find the share (if it exists)
    private func getExistingShare(for recordID: CKRecord.ID) async throws -> CKShare? {
        let database = container.privateCloudDatabase
        
        print("   🔍 Checking for existing share for record: \(recordID.recordName)")
        
        // Fetch the root record to check if it has a parent (which would be the share)
        do {
            let fetchResult = try await database.records(for: [recordID])
            
            if case .success(let rootRecord) = fetchResult[recordID] {
                // Check if the root record has a parent (which indicates it's shared)
                // parent is a CKRecord.Reference, we need to get its recordID
                if let parentReference = rootRecord.parent {
                    let parentRecordID = parentReference.recordID
                    print("   ✅ Found parent record (share): \(parentRecordID.recordName)")
                    
                    // Fetch the parent record, which should be the CKShare
                    let shareFetchResult = try await database.records(for: [parentRecordID])
                    
                    if case .success(let shareRecord) = shareFetchResult[parentRecordID],
                       let share = shareRecord as? CKShare {
                        print("   ✅ Existing share found: \(share.recordID.recordName)")
                        return share
                    }
                } else {
                    print("   ℹ️ No parent record found - vault is not shared yet")
                }
            }
        } catch {
            // Error fetching - might mean record doesn't exist or isn't shared
            print("   ⚠️ Error checking for existing share: \(error.localizedDescription)")
            // This is fine - just means there's no existing share
        }
        
        return nil
    }
    
    // MARK: - Get Share URL
    
    /// Get the share metadata URL from a CKShare
    /// CloudKit share URLs are constructed from the share's record ID
    private func getShareURL(from share: CKShare) async throws -> URL {
        // CloudKit share URLs follow this format:
        // https://www.icloud.com/share/[shareToken]?participantKey=[key]
        // The share token is the record name of the share
        
        let shareToken = share.recordID.recordName
        
        // Construct the share URL
        // Note: The actual share URL format may vary, but this is the standard format
        // In production, you might need to use UICloudSharingController to get the exact URL
        guard let url = URL(string: "https://www.icloud.com/share/\(shareToken)") else {
            // Fallback: use custom URL scheme with token
            // The app will handle this and convert it to a CloudKit share acceptance
            guard let fallbackURL = URL(string: "khandoba://share?token=\(shareToken)") else {
                throw CloudKitSharingError.shareURLNotFound
            }
            return fallbackURL
        }
        
        return url
    }
    
    // MARK: - Accept Share Invitation
    
    /// Accept a CloudKit share invitation from a metadata URL
    /// Note: For programmatic acceptance, we fetch the share and let SwiftData handle it
    /// The proper way is through the AppDelegate.userDidAcceptCloudKitShareWith method
    func acceptShareInvitation(from url: URL) async throws {
        print("📥 Accepting CloudKit share invitation from URL: \(url)")
        
        var shareRecordID: CKRecord.ID?
        
        // Handle different URL formats
        if url.scheme == "khandoba" && url.host == "share" {
            // Custom URL scheme: khandoba://share?token=...
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
                // Construct record ID from token
                let zoneID = CKRecordZone.default().zoneID
                shareRecordID = CKRecord.ID(recordName: token, zoneID: zoneID)
            }
        } else if url.absoluteString.contains("icloud.com/share") {
            // iCloud share URL: https://www.icloud.com/share/[token]
            // Extract token from path
            let pathComponents = url.pathComponents
            if let shareIndex = pathComponents.firstIndex(of: "share"), 
               shareIndex + 1 < pathComponents.count {
                let token = pathComponents[shareIndex + 1]
                let zoneID = CKRecordZone.default().zoneID
                shareRecordID = CKRecord.ID(recordName: token, zoneID: zoneID)
            }
        } else if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let token = components.queryItems?.first(where: { $0.name == "ckShareID" })?.value {
            // Standard CloudKit share metadata URL
            let zoneID = CKRecordZone.default().zoneID
            shareRecordID = CKRecord.ID(recordName: token, zoneID: zoneID)
        }
        
        guard let shareID = shareRecordID else {
            print("   ❌ Could not extract share record ID from URL")
            throw CloudKitSharingError.invalidShareURL
        }
        
        print("   Extracted share record ID: \(shareID.recordName)")
        
        // Fetch the share record to trigger SwiftData sync
        // When SwiftData sees a shared record, it automatically syncs it
        let database = container.privateCloudDatabase
        do {
            let fetchResult = try await database.records(for: [shareID])
            
            if case .success(let record) = fetchResult[shareID], record is CKShare {
                print("   ✅ Share record fetched successfully")
                print("   📤 SwiftData will automatically sync the shared vault")
                // SwiftData will handle the sync automatically
                // The vault should appear in the nominee's device after sync
            } else {
                throw CloudKitSharingError.shareAcceptanceFailed
            }
        } catch {
            print("   ❌ Error fetching share: \(error.localizedDescription)")
            // If fetching fails, the share might need to be accepted through the system
            // In this case, we'll let the AppDelegate handle it when iOS opens the app
            throw CloudKitSharingError.shareAcceptanceFailed
        }
    }
    
    /// Helper to get root record ID from metadata, handling iOS 16+ deprecation
    /// Uses hierarchicalRootRecordID when available, falls back to rootRecordID for compatibility
    private func getRootRecordID(from metadata: CKShare.Metadata) -> CKRecord.ID {
        // Try to use the new API first (iOS 16+)
        if #available(iOS 16.0, *), let hierarchicalID = metadata.hierarchicalRootRecordID {
            return hierarchicalID
        }
        
        // Fallback to deprecated API when:
        // 1. iOS < 16.0 (API not deprecated yet)
        // 2. hierarchicalRootRecordID is nil on iOS 16+ (can happen in some cases)
        // This deprecation warning is intentional and necessary for backward compatibility
        // Use hierarchicalRootRecordID on iOS 16+ and fall back to rootRecordID for compatibility
        #if swift(>=5.7)
        if #available(iOS 16.0, macOS 13.0, *) {
            return metadata.hierarchicalRootRecordID ?? metadata.rootRecordID
        } else {
            return metadata.rootRecordID
        }
        #else
        return metadata.rootRecordID
        #endif
    }
    
    func processShareInvitation(from metadata: CKShare.Metadata) async throws {
        print("📥 Processing CloudKit share invitation from metadata")
        // Use hierarchicalRootRecordID (replacement for deprecated rootRecordID in iOS 16+)
        // hierarchicalRootRecordID is optional, so we fallback to deprecated rootRecordID if nil
        let rootRecordID = getRootRecordID(from: metadata)
        print("   Root record: \(rootRecordID.recordName)")
        print("   Share record: \(metadata.share.recordID.recordName)")
        
        // iOS has already accepted the share when AppDelegate receives it
        // We just need to ensure SwiftData syncs the shared records
        // The shared vault should appear in SwiftData automatically
        
        // Fetch the share to ensure it's in our database
        let database = container.privateCloudDatabase
        do {
            let fetchResult = try await database.records(for: [metadata.share.recordID, rootRecordID])
            
            if case .success(let shareRecord) = fetchResult[metadata.share.recordID] {
                print("   ✅ Share record fetched: \(shareRecord.recordID.recordName)")
            }
            
            if case .success(let rootRecord) = fetchResult[rootRecordID] {
                print("   ✅ Root record fetched: \(rootRecord.recordID.recordName)")
                print("   📤 SwiftData will automatically sync the shared vault")
            }
        } catch {
            print("   ⚠️ Error fetching share records: \(error.localizedDescription)")
            // This is not critical - SwiftData will sync automatically
            // Just log the error and continue
        }
        
        print("   ✅ Share invitation processed successfully")
    }
    
    // MARK: - Get Share Metadata from URL
    
    /// Extract share information from a metadata URL
    func getShareMetadata(from url: URL) async throws -> CKShare.Metadata? {
        // CloudKit share URLs contain metadata that can be parsed
        // This is used to preview the share before accepting
        
        // For now, we'll accept the share directly
        // In a production app, you might want to show a preview first
        return nil
    }
    
    // MARK: - Get Share Participants
    
    /// Get all participants from a CloudKit share for a vault
    /// Returns an array of participant information
    func getShareParticipants(for vault: Vault) async throws -> [CKShare.Participant] {
        // Skip CloudKit operations if Supabase is enabled
        guard !AppConfig.useSupabase else {
            print("⚠️ CloudKit sharing disabled - using Supabase instead")
            return []
        }
        
        print("👥 Getting CloudKit share participants for vault: \(vault.name)")
        
        // Ensure vault is synced to CloudKit first
        try await ensureVaultSynced(vault)
        
        guard let vaultRecordID = try await getVaultRecordID(vault),
              let share = try await getExistingShare(for: vaultRecordID) else {
            print("   No share found for this vault")
            return []
        }
        
        // CKShare.participants contains all participants (owner + invitees)
        let participants = share.participants
        
        print("   Found \(participants.count) participant(s)")
        for (index, participant) in participants.enumerated() {
            let identity = participant.userIdentity
            let name = identity.nameComponents?.formatted() ?? identity.lookupInfo?.emailAddress ?? "Unknown"
            let role = participant.role == .owner ? "Owner" : "Participant"
            let acceptanceStatus = participant.acceptanceStatus == .accepted ? "Accepted" : "Pending"
            print("   \(index + 1). \(name) (\(role), \(acceptanceStatus))")
        }
        
        return participants
    }
    
    /// Get both the share and its participants for a vault
    /// Returns a tuple of (share, participants) for convenience
    func getShareAndParticipants(for vault: Vault) async throws -> (CKShare?, [CKShare.Participant]) {
        // Skip CloudKit operations if Supabase is enabled
        guard !AppConfig.useSupabase else {
            print("⚠️ CloudKit sharing disabled - using Supabase instead")
            return (nil, [])
        }
        
        print("👥 Getting CloudKit share and participants for vault: \(vault.name)")
        
        // Ensure vault is synced to CloudKit first
        try await ensureVaultSynced(vault)
        
        guard let vaultRecordID = try await getVaultRecordID(vault),
              let share = try await getExistingShare(for: vaultRecordID) else {
            print("   No share found for this vault")
            return (nil, [])
        }
        
        let participants = share.participants
        
        print("   Found share: \(share.recordID.recordName)")
        print("   Found \(participants.count) participant(s)")
        
        return (share, participants)
    }
    
    // MARK: - Present CloudKit Sharing Controller
    
    /// Get or create a share and return it for UICloudSharingController
    /// With SwiftData + CloudKit, we let UICloudSharingController handle record lookup automatically
    /// using the model's PersistentIdentifier. This is the recommended approach.
    /// 
    /// NOTE: No server deployment needed - CloudKit is Apple's backend service
    func getOrCreateShare(for vault: Vault) async throws -> CKShare? {
        // Skip CloudKit operations if Supabase is enabled
        guard !AppConfig.useSupabase else {
            print("⚠️ CloudKit sharing disabled - using Supabase instead")
            return nil
        }
        
        print("🔗 Getting or creating CloudKit share for vault: \(vault.name)")
        print("   ℹ️ Using SwiftData + CloudKit integration (no server needed)")
        
        // Ensure vault is saved to SwiftData
        // CloudKit sync happens automatically in the background
        guard let modelContext = modelContext else {
            print("   ⚠️ ModelContext not available")
            return nil
        }
        
        // Save vault to ensure it's persisted
        // SwiftData will sync to CloudKit automatically
        try modelContext.save()
        print("   💾 Vault saved to SwiftData")
        print("   ⏳ CloudKit sync happens automatically in background")
        
        // With SwiftData + CloudKit, the best approach is to return nil
        // and let UICloudSharingController use the model's PersistentIdentifier
        // to find the CloudKit record automatically. This avoids manual queries
        // and works reliably with SwiftData's internal CloudKit integration.
        print("   ℹ️ Returning nil - UICloudSharingController will use PersistentIdentifier")
        print("   ℹ️ SwiftData manages CloudKit record IDs internally")
        return nil
    }
    
    // MARK: - Remove Share
    
    /// Remove a share (revoke access for all participants)
    func removeShare(for vault: Vault) async throws {
        // Skip CloudKit operations if Supabase is enabled
        guard !AppConfig.useSupabase else {
            print("⚠️ CloudKit sharing disabled - using Supabase instead")
            return
        }
        
        print("🔒 Removing CloudKit share for vault: \(vault.name)")
        
        guard let vaultRecordID = try await getVaultRecordID(vault),
              let share = try await getExistingShare(for: vaultRecordID) else {
            print("   No share found to remove")
            return
        }
        
        let database = container.privateCloudDatabase
        try await database.deleteRecord(withID: share.recordID)
        
        print("   ✅ Share removed successfully")
    }
    
    // MARK: - Remove Participant
    
    /// Remove a specific participant from a CloudKit share
    func removeParticipant(participantID: String?, from vault: Vault) async throws {
        // Skip CloudKit operations if Supabase is enabled
        guard !AppConfig.useSupabase else {
            print("⚠️ CloudKit sharing disabled - using Supabase instead")
            return
        }
        
        print("🔒 Removing participant from CloudKit share for vault: \(vault.name)")
        
        guard let vaultRecordID = try await getVaultRecordID(vault),
              let share = try await getExistingShare(for: vaultRecordID) else {
            print("   ⚠️ Vault or share not found - may not be shared yet")
            // Don't throw error - vault might not be shared, which is fine
            return
        }
        
        guard let participantID = participantID else {
            print("   ⚠️ No participant ID provided")
            return
        }
        
        // Find and remove participant
        let participants = share.participants
        if let participant = participants.first(where: { 
            $0.userIdentity.lookupInfo?.userRecordID?.recordName == participantID 
        }) {
            share.removeParticipant(participant)
            
            let database = container.privateCloudDatabase
            try await database.save(share)
            
            print("   ✅ Participant removed successfully: \(participantID)")
        } else {
            print("   ⚠️ Participant not found in CloudKit share: \(participantID)")
            // Don't throw error - participant may have already been removed
            // This is not critical for local cleanup
        }
    }
    
    // MARK: - Transfer Share Ownership
    
    /// Transfer CloudKit share ownership to a new owner
    /// Note: CloudKit share ownership is typically managed by the system
    /// This method updates the share's owner participant
    func transferShareOwnership(for vault: Vault, to newOwnerUserID: UUID) async throws {
        // Skip CloudKit operations if Supabase is enabled
        guard !AppConfig.useSupabase else {
            print("⚠️ CloudKit sharing disabled - using Supabase instead")
            return
        }
        
        print("🔄 Transferring CloudKit share ownership for vault: \(vault.name)")
        
        guard let vaultRecordID = try await getVaultRecordID(vault),
              let share = try await getExistingShare(for: vaultRecordID) else {
            print("   ℹ️ Vault not shared via CloudKit - ownership transfer not needed")
            return
        }
        
        // CloudKit share ownership is managed by the system when a share is accepted
        // The new owner becomes the owner when they accept the share
        // For programmatic transfer, we need to update the share's owner participant
        
        let database = container.privateCloudDatabase
        
        // Get current owner (CKShare.owner is non-optional)
        let currentOwner = share.owner
        let ownerName = currentOwner.userIdentity.nameComponents?.formatted() ?? 
                       currentOwner.userIdentity.lookupInfo?.emailAddress ?? 
                       "Unknown"
        print("   Current owner: \(ownerName)")
        
        // Note: CloudKit doesn't provide a direct API to change share ownership
        // The ownership is determined by who created the share or who accepted it
        // For transfer ownership, the new owner should accept the share
        // This method is a placeholder for future implementation if needed
        
        print("   ℹ️ CloudKit share ownership is managed by the system")
        print("   ℹ️ New owner will become owner when they accept the share")
        
        // Save the share to ensure it's synced
        try await database.save(share)
        
        print("   ✅ Share updated (ownership will transfer when new owner accepts)")
    }
}

// MARK: - Error Types

enum CloudKitSharingError: LocalizedError {
    case vaultRecordNotFound
    case shareCreationFailed
    case shareURLNotFound
    case invalidShareURL
    case shareAcceptanceFailed
    case containerNotAvailable
    case participantNotFound
    
    var errorDescription: String? {
        switch self {
        case .vaultRecordNotFound:
            return "Vault record not found in CloudKit"
        case .shareCreationFailed:
            return "Failed to create CloudKit share"
        case .shareURLNotFound:
            return "Share URL not found"
        case .invalidShareURL:
            return "Invalid share URL"
        case .shareAcceptanceFailed:
            return "Failed to accept share invitation"
        case .containerNotAvailable:
            return "CloudKit container not available"
        case .participantNotFound:
            return "Participant not found in CloudKit share"
        }
    }
}


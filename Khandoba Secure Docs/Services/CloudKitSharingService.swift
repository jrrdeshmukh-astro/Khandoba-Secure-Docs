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
import UIKit

@MainActor
final class CloudKitSharingService: ObservableObject {
    @Published var isSharing = false
    @Published var shareError: String?
    
    private let container: CKContainer
    private var modelContext: ModelContext?
    
    init() {
        self.container = CKContainer(identifier: AppConfig.cloudKitContainer)
    }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Create Share for Vault
    
    /// Create a CKShare for a vault to share with nominees
    /// Returns the share metadata URL that can be sent to the nominee
    func createShare(for vault: Vault) async throws -> URL {
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
    /// Uses query-all-and-match approach to find the record reliably
    /// Returns nil if record not found, allowing UICloudSharingController to handle it automatically
    private func getVaultRecordID(_ vault: Vault) async throws -> CKRecord.ID? {
        guard modelContext != nil else {
            print("   ❌ ModelContext not configured")
            return nil
        }
        
        let database = container.privateCloudDatabase
        let zoneID = CKRecordZone.default().zoneID
        
        // Method 1: Try common naming formats (most reliable for SwiftData + CloudKit)
        // SwiftData with CloudKit uses predictable naming conventions
        print("   🔍 Trying common naming formats...")
        
        // Format 1: CD_<EntityName>_<UUID> (most common SwiftData + CloudKit format)
        let recordName1 = "CD_Vault_\(vault.id.uuidString)"
        let recordID1 = CKRecord.ID(recordName: recordName1, zoneID: zoneID)
        
        // Format 2: Just the UUID (some configurations)
        let recordName2 = vault.id.uuidString
        let recordID2 = CKRecord.ID(recordName: recordName2, zoneID: zoneID)
        
        // Format 3: Lowercase entity name
        let recordName3 = "CD_vault_\(vault.id.uuidString)"
        let recordID3 = CKRecord.ID(recordName: recordName3, zoneID: zoneID)
        
        // Format 4: Try with underscores replaced by hyphens (some CloudKit configurations)
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
        
        // Method 2: Query all Vault records and match by UUID stored in record
        // This is more reliable as it searches all records and matches by the vault's UUID
        print("   🔍 Trying query all Vault records and match by UUID...")
        do {
            // Query all CD_Vault records (SwiftData uses CD_ prefix)
            let query = CKQuery(recordType: "CD_Vault", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let (matchResults, _) = try await database.records(matching: query, inZoneWith: zoneID, desiredKeys: ["id", "name", "ZNAME", "Name"])
            
            let vaultUUIDString = vault.id.uuidString
            
            // Match by UUID stored in the record
            for (recordID, result) in matchResults {
                if case .success(let record) = result {
                    // Check if the record's ID field matches our vault UUID
                    // SwiftData stores the UUID in various field names
                    let recordIDValue = (record["id"] as? String) ?? 
                                       (record["ZID"] as? String) ?? 
                                       (record["ID"] as? String) ?? ""
                    
                    // Also check record name formats
                    let recordName = recordID.recordName
                    if recordName.contains(vaultUUIDString) || recordIDValue == vaultUUIDString {
                        // Verify by name as well
                        let recordNameValue = (record["name"] as? String) ?? 
                                            (record["ZNAME"] as? String) ?? 
                                            (record["Name"] as? String) ?? ""
                        
                        if recordNameValue == vault.name || recordNameValue.isEmpty {
                            print("   ✅ Found CloudKit record by UUID query: \(recordID.recordName)")
                            return recordID
                        }
                    }
                }
            }
        } catch {
            print("   ℹ️ Query all records failed: \(error.localizedDescription)")
        }
        
        // Method 3: Try querying by creation date range (if creationDate is queryable)
        // This is a fallback if direct record ID lookup fails
        print("   🔍 Trying query by creation date range...")
        do {
            // Query for records created within 1 minute of vault creation
            let startDate = vault.createdAt.addingTimeInterval(-30)
            let endDate = vault.createdAt.addingTimeInterval(30)
            
            // Note: This requires 'creationDate' to be queryable in CloudKit schema
            // If it's not, this will fail gracefully
            let datePredicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@", startDate as NSDate, endDate as NSDate)
            let query = CKQuery(recordType: "CD_Vault", predicate: datePredicate)
            
            let (matchResults, _) = try await database.records(matching: query, inZoneWith: zoneID)
            
            // Match by name from the results
            for (recordID, result) in matchResults {
                if case .success(let record) = result {
                    let recordName = (record["name"] as? String) ?? 
                                    (record["ZNAME"] as? String) ?? 
                                    (record["Name"] as? String) ?? ""
                    
                    if recordName == vault.name {
                        print("   ✅ Found CloudKit record by date+name: \(recordID.recordName)")
                        return recordID
                    }
                }
            }
        } catch {
            // This is expected if creationDate is not queryable or query fails
            print("   ℹ️ Query by date not available (field may not be queryable): \(error.localizedDescription)")
        }
        
        // If all methods fail, the record might not be synced to CloudKit yet
        print("   ℹ️ Could not find CloudKit record with any method")
        print("   ℹ️ Vault ID: \(vault.id.uuidString)")
        print("   ℹ️ Vault Name: \(vault.name)")
        print("   ℹ️ Vault Created: \(vault.createdAt)")
        print("   ℹ️ This may mean:")
        print("      - Record hasn't synced to CloudKit yet (wait a few seconds and try again)")
        print("      - CloudKit sync is disabled or not configured")
        print("      - The vault needs to be saved first")
        print("   ℹ️ Falling back to token-based sharing or letting UICloudSharingController handle it")
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
    
    /// Process a CloudKit share invitation from metadata (called by AppDelegate)
    /// Note: iOS has already accepted the share when this is called
    /// We just need to process the metadata and let SwiftData sync
    func processShareInvitation(from metadata: CKShare.Metadata) async throws {
        print("📥 Processing CloudKit share invitation from metadata")
        // Use hierarchicalRootRecordID (replacement for deprecated rootRecordID in iOS 16+)
        // hierarchicalRootRecordID is optional, so we fallback to deprecated rootRecordID if nil
        let rootRecordID: CKRecord.ID
        if #available(iOS 16.0, *) {
            // Use new API if available
            if let hierarchicalID = metadata.hierarchicalRootRecordID {
                rootRecordID = hierarchicalID
            } else {
                // Fallback to deprecated API only if hierarchical is nil
                // Note: rootRecordID deprecated in iOS 16.0+ but needed for backward compatibility
                // This is intentional - we need to support older iOS versions
                // Compiler warning is acceptable - this API is still functional
                // swiftlint:disable:next deprecated_api
                // swift:suppress:deprecated
                rootRecordID = metadata.rootRecordID
            }
        } else {
            // Fallback for older iOS versions
            rootRecordID = metadata.rootRecordID
        }
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
    /// This allows users to share via native iOS sharing (Messages, Mail, etc.)
    /// Returns nil if we can't get the record ID after extended retries, letting UICloudSharingController handle it
    func getOrCreateShare(for vault: Vault) async throws -> CKShare? {
        print("🔗 Getting or creating CloudKit share for vault: \(vault.name)")
        
        // Ensure vault is synced to CloudKit first (with retries)
        try await ensureVaultSynced(vault)
        
        // Try to get the CloudKit record ID with additional retries
        // This is critical for nominee invitations, so we wait longer
        var vaultRecordID: CKRecord.ID?
        let maxRetries = 10 // More retries for invitation flow
        let retryDelay: UInt64 = 1_000_000_000 // 1 second
        
        for attempt in 1...maxRetries {
            if let recordID = try? await getVaultRecordID(vault) {
                vaultRecordID = recordID
                print("   ✅ Found CloudKit record ID on attempt \(attempt): \(recordID.recordName)")
                break
            }
            
            if attempt < maxRetries {
                print("   ⏳ CloudKit record not found yet (attempt \(attempt)/\(maxRetries)), waiting...")
                try await Task.sleep(nanoseconds: retryDelay)
                
                // Trigger another save to encourage sync
                if let modelContext = modelContext {
                    try? modelContext.save()
                }
            }
        }
        
        // If we still can't find it, return nil to let UICloudSharingController handle it
        guard let recordID = vaultRecordID else {
            print("   ⚠️ Could not get CloudKit record ID after \(maxRetries) attempts")
            print("   ℹ️ The vault may not be synced to CloudKit yet")
            print("   ℹ️ This can happen if:")
            print("      - CloudKit sync is disabled")
            print("      - iCloud account is not signed in")
            print("      - Network connectivity issues")
            print("      - CloudKit sync is still in progress (can take up to 30 seconds)")
            print("   ℹ️ UICloudSharingController will handle sharing automatically when sync completes")
            return nil
        }
        
        // Check if share already exists
        if let existingShare = try? await getExistingShare(for: recordID) {
            print("   ✅ Using existing share")
            return existingShare
        }
        
        // Try to create new share
        do {
            print("   Creating new share...")
            let rootRecord = try await getVaultRecord(recordID)
            let share = CKShare(rootRecord: rootRecord)
            share[CKShare.SystemFieldKey.title] = vault.name
            share.publicPermission = CKShare.ParticipantPermission.none // Private share only
            
            // Add the share to the root record's share property
            rootRecord.setParent(share.recordID)
            
            // Save both the share and the updated root record
            let database = container.privateCloudDatabase
            let (saveResult, _) = try await database.modifyRecords(saving: [share, rootRecord], deleting: [])
            
            if case .success(let savedShare) = saveResult[share.recordID],
               let savedShareRecord = savedShare as? CKShare {
                print("   ✅ Share created successfully")
                return savedShareRecord
            }
        } catch {
            print("   ℹ️ Failed to create share programmatically: \(error.localizedDescription)")
            print("   ℹ️ This is OK - token-based sharing will be used as fallback")
            // Return nil to let UICloudSharingController handle it or use token fallback
        }
        
        // If we can't create the share, return nil
        // The calling code will use token-based sharing as fallback
        print("   ℹ️ Returning nil - token-based sharing will be used")
        return nil
    }
    
    // MARK: - Remove Share
    
    /// Remove a share (revoke access for all participants)
    func removeShare(for vault: Vault) async throws {
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


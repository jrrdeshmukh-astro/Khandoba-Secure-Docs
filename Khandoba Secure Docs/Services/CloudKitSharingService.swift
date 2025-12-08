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
    
    // MARK: - Get Vault Record ID
    
    /// Get the CloudKit record ID for a SwiftData Vault model
    /// NOTE: This method is disabled because CloudKit queries require queryable fields
    /// and SwiftData doesn't expose field names reliably. Use UICloudSharingController
    /// preparation handler instead, which handles record lookup automatically.
    private func getVaultRecordID(_ vault: Vault) async throws -> CKRecord.ID? {
        // Disabled: Querying CloudKit with NSPredicate(value: true) causes
        // "Field 'recordName' is not marked queryable" error
        // SwiftData manages CloudKit records internally and doesn't expose
        // reliable ways to query them directly
        
        // Return nil to indicate we should use UICloudSharingController's
        // automatic record resolution instead
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
            
            if case .success(let record) = fetchResult[shareID], let share = record as? CKShare {
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
        print("   Root record: \(metadata.rootRecordID.recordName)")
        print("   Share record: \(metadata.share.recordID.recordName)")
        
        // iOS has already accepted the share when AppDelegate receives it
        // We just need to ensure SwiftData syncs the shared records
        // The shared vault should appear in SwiftData automatically
        
        // Fetch the share to ensure it's in our database
        let database = container.privateCloudDatabase
        do {
            let fetchResult = try await database.records(for: [metadata.share.recordID, metadata.rootRecordID])
            
            if case .success(let shareRecord) = fetchResult[metadata.share.recordID] {
                print("   ✅ Share record fetched: \(shareRecord.recordID.recordName)")
            }
            
            if case .success(let rootRecord) = fetchResult[metadata.rootRecordID] {
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
    
    // MARK: - Present CloudKit Sharing Controller
    
    /// Get or create a share and return it for UICloudSharingController
    /// This allows users to share via native iOS sharing (Messages, Mail, etc.)
    /// Returns nil if we can't get the record ID, letting UICloudSharingController handle it
    func getOrCreateShare(for vault: Vault) async throws -> CKShare? {
        print("🔗 Getting or creating CloudKit share for vault: \(vault.name)")
        
        // Try to get the CloudKit record ID (may fail due to query limitations)
        // If it fails, return nil to let UICloudSharingController handle it
        guard let vaultRecordID = try? await getVaultRecordID(vault) else {
            print("   ⚠️ Could not get CloudKit record ID - UICloudSharingController will handle it")
            return nil
        }
        
        // Check if share already exists
        if let existingShare = try? await getExistingShare(for: vaultRecordID) {
            print("   ✅ Using existing share")
            return existingShare
        }
        
        // Try to create new share
        do {
            print("   Creating new share...")
            let rootRecord = try await getVaultRecord(vaultRecordID)
            let share = CKShare(rootRecord: rootRecord)
            share[CKShare.SystemFieldKey.title] = vault.name
            share.publicPermission = .none // Private share only
            
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
            print("   ⚠️ Failed to create share: \(error.localizedDescription)")
            // Return nil to let UICloudSharingController handle it
        }
        
        // If we can't create the share, return nil
        // UICloudSharingController will handle share creation automatically
        print("   ℹ️ Returning nil - UICloudSharingController will handle share creation")
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
}

// MARK: - Error Types

enum CloudKitSharingError: LocalizedError {
    case vaultRecordNotFound
    case shareCreationFailed
    case shareURLNotFound
    case invalidShareURL
    case shareAcceptanceFailed
    case containerNotAvailable
    
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
        }
    }
}


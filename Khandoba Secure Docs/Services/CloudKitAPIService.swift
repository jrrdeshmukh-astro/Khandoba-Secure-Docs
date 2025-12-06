//
//  CloudKitAPIService.swift
//  Khandoba Secure Docs
//
//  CloudKit Framework integration for direct CloudKit operations
//  Provides sync monitoring, token verification, and health checks
//  Note: Uses CloudKit framework (automatic iCloud auth), not REST API
//

import Foundation
import CloudKit
import CryptoKit

@MainActor
final class CloudKitAPIService: ObservableObject {
    @Published var syncStatus: SyncStatus = .unknown
    @Published var lastSyncTime: Date?
    @Published var syncError: String?
    
    enum SyncStatus {
        case unknown
        case syncing
        case synced
        case error(String)
    }
    
    // CloudKit Configuration
    private let containerIdentifier = AppConfig.cloudKitContainer
    private let keyID = AppConfig.cloudKitKeyID
    private let teamID: String
    private let environment: CKEnvironment
    
    private var container: CKContainer?
    
    init() {
        // Get team ID from AppConfig
        self.teamID = AppConfig.cloudKitTeamID
        
        // Use development for TestFlight, production for App Store
        #if DEBUG
        self.environment = .development
        #else
        self.environment = .production
        #endif
        
        self.container = CKContainer(identifier: containerIdentifier)
    }
    
    // MARK: - CloudKit Sync Status
    
    /// Check CloudKit sync status for nominee invitations
    func checkSyncStatus() async {
        syncStatus = .syncing
        
        do {
            guard let container = container else {
                throw CloudKitAPIError.containerNotAvailable
            }
            
            let database = container.privateCloudDatabase
            
            // Query for recent nominee records to verify sync
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: "Nominee", predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "invitedAt", ascending: false)]
            
            let (matchResults, _) = try await database.records(matching: query, inZoneWith: nil, desiredKeys: ["inviteToken", "status", "invitedAt"], resultsLimit: 10)
            
            var recordCount = 0
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    recordCount += 1
                    print("📋 Found nominee record: \(record.recordID.recordName)")
                case .failure(let error):
                    print("⚠️ Error fetching record: \(error.localizedDescription)")
                }
            }
            
            await MainActor.run {
                syncStatus = .synced
                lastSyncTime = Date()
                syncError = nil
            }
            
            print("✅ CloudKit sync check complete: \(recordCount) nominee records found")
            
        } catch {
            await MainActor.run {
                syncStatus = .error(error.localizedDescription)
                syncError = error.localizedDescription
            }
            print("❌ CloudKit sync check failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Nominee Invitation Operations
    
    /// Verify nominee invitation token exists in CloudKit
    func verifyNomineeToken(_ token: String) async throws -> Bool {
        guard let container = container else {
            throw CloudKitAPIError.containerNotAvailable
        }
        
        let database = container.privateCloudDatabase
        
        // Query for nominee with matching token
        let predicate = NSPredicate(format: "inviteToken == %@", token)
        let query = CKQuery(recordType: "Nominee", predicate: predicate)
        
        do {
            let (matchResults, _) = try await database.records(matching: query, inZoneWith: nil, desiredKeys: ["inviteToken", "status"], resultsLimit: 1)
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let tokenValue = record["inviteToken"] as? String, tokenValue == token {
                        print("✅ Nominee token verified in CloudKit: \(token)")
                        return true
                    }
                case .failure(let error):
                    print("⚠️ Error verifying token: \(error.localizedDescription)")
                    throw error
                }
            }
            
            print("❌ Nominee token not found in CloudKit: \(token)")
            return false
            
        } catch {
            print("❌ CloudKit query failed: \(error.localizedDescription)")
            throw CloudKitAPIError.queryFailed(error.localizedDescription)
        }
    }
    
    /// Get nominee record from CloudKit by token
    func getNomineeByToken(_ token: String) async throws -> [String: Any]? {
        guard let container = container else {
            throw CloudKitAPIError.containerNotAvailable
        }
        
        let database = container.privateCloudDatabase
        
        let predicate = NSPredicate(format: "inviteToken == %@", token)
        let query = CKQuery(recordType: "Nominee", predicate: predicate)
        
        let (matchResults, _) = try await database.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1)
        
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                var nomineeData: [String: Any] = [:]
                nomineeData["id"] = record.recordID.recordName
                nomineeData["inviteToken"] = record["inviteToken"] as? String
                nomineeData["status"] = record["status"] as? String
                nomineeData["name"] = record["name"] as? String
                nomineeData["invitedAt"] = record["invitedAt"] as? Date
                return nomineeData
            case .failure(let error):
                throw error
            }
        }
        
        return nil
    }
    
    // MARK: - Sync Monitoring
    
    /// Monitor CloudKit sync health
    func monitorSyncHealth() async -> SyncHealthReport {
        var report = SyncHealthReport()
        
        do {
            guard let container = container else {
                report.status = .error("Container not available")
                return report
            }
            
            let accountStatus = try await container.accountStatus()
            report.accountStatus = accountStatus
            
            switch accountStatus {
            case .available:
                report.status = .healthy
                // Check recent sync activity
                await checkSyncStatus()
            case .noAccount:
                report.status = .error("No iCloud account")
            case .restricted:
                report.status = .error("iCloud account restricted")
            case .couldNotDetermine:
                report.status = .error("Could not determine account status")
            case .temporarilyUnavailable:
                report.status = .error("iCloud temporarily unavailable")
            @unknown default:
                report.status = .error("Unknown account status")
            }
            
        } catch {
            report.status = .error(error.localizedDescription)
        }
        
        return report
    }
    
    // MARK: - Helper Methods
    
    private func extractTeamID(from bundleID: String) -> String? {
        // Team ID is typically in the bundle identifier or can be extracted
        // For now, return nil and require manual configuration
        return nil
    }
    
    // MARK: - CloudKit Database Access
    
    /// Get CloudKit database for direct operations
    func getPrivateDatabase() -> CKDatabase? {
        return container?.privateCloudDatabase
    }
    
    func getPublicDatabase() -> CKDatabase? {
        return container?.publicCloudDatabase
    }
}

// MARK: - Error Types

enum CloudKitAPIError: LocalizedError {
    case containerNotAvailable
    case queryFailed(String)
    case recordNotFound
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .containerNotAvailable:
            return "CloudKit container not available"
        case .queryFailed(let message):
            return "CloudKit query failed: \(message)"
        case .recordNotFound:
            return "Record not found in CloudKit"
        case .syncFailed(let message):
            return "CloudKit sync failed: \(message)"
        }
    }
}

// MARK: - Sync Health Report

struct SyncHealthReport {
    var status: HealthStatus = .unknown
    var accountStatus: CKAccountStatus?
    var lastSyncTime: Date?
    var recordCount: Int = 0
    var errorMessage: String?
    
    enum HealthStatus {
        case unknown
        case healthy
        case warning
        case error(String)
    }
}

// MARK: - CloudKit Environment Extension

extension CKEnvironment {
    var displayName: String {
        switch self {
        case .development:
            return "Development"
        case .production:
            return "Production"
        @unknown default:
            return "Unknown"
        }
    }
}

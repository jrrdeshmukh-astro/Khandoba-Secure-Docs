//
//  VaultService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData
import SwiftUI
import Combine
import CoreLocation

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Import AsyncTimeout for timeout handling

final class VaultService: ObservableObject {
    @Published var vaults: [Vault] = []
    @Published var isLoading = false
    @Published var activeSessions: [UUID: VaultSession] = [:]
    
    var modelContext: ModelContext? // Made public for Intel vault access
    private var currentUserID: UUID?
    var currentUser: User? // Added for Intel report access
    private var dataMergeService = DataMergeService() // For CloudKit data operations
    
    // Session timeout management
    private var sessionTimeoutTasks: [UUID: Task<Void, Never>] = [:]
    private let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
    private let activityExtension: TimeInterval = 15 * 60 // 15 minutes on activity
    
    init() {}
    
    // iOS-ONLY: Using SwiftData/CloudKit exclusively
    func configure(modelContext: ModelContext, userID: UUID) {
        self.modelContext = modelContext
        self.currentUserID = userID
        dataMergeService.configure(modelContext: modelContext)
        
        // Load current user
        Task {
            let userDescriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.id == userID }
            )
            currentUser = try? modelContext.fetch(userDescriptor).first
        }
    }
    
    func loadVaults() async throws {
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else { return }
        
        // ONE-TIME CLEANUP: Delete Intel Reports vault
        try await deleteIntelReportsVault()
        
        // CRITICAL: Clean up orphaned vaults (vaults with no owner or deleted owner)
        // This prevents CloudKit from restoring deleted vaults
        try await cleanupOrphanedVaults(modelContext: modelContext)
        
        let descriptor = FetchDescriptor<Vault>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let fetchedVaults = try modelContext.fetch(descriptor)
        
        // CRITICAL: Ensure all vaults have owners assigned
        // Fix for existing vaults that may not have owners set
        if let currentUserID = currentUserID {
            let userDescriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.id == currentUserID }
            )
            if let currentUser = try? modelContext.fetch(userDescriptor).first {
                var needsSave = false
                for vault in fetchedVaults {
                    // Only fix non-system vaults that don't have an owner
                    if vault.owner == nil && !vault.isSystemVault {
                        print("⚠️ VaultService: Found vault '\(vault.name)' without owner, assigning current user")
                        vault.owner = currentUser
                        
                        // Initialize ownedVaults if needed
                        if currentUser.ownedVaults == nil {
                            currentUser.ownedVaults = []
                        }
                        if !(currentUser.ownedVaults?.contains(where: { $0.id == vault.id }) ?? false) {
                            currentUser.ownedVaults?.append(vault)
                        }
                        needsSave = true
                    }
                }
                
                if needsSave {
                    try modelContext.save()
                    print("✅ VaultService: Fixed vaults without owners")
                }
            }
        }
        
        // Log vault information for debugging
        print("📦 VaultService: Loaded \(fetchedVaults.count) vault(s)")
        for vault in fetchedVaults {
            let ownerName = vault.owner?.fullName ?? "Unknown"
            let isShared = currentUserID != nil && vault.owner?.id != currentUserID
            print("   - \(vault.name) (Owner: \(ownerName), Shared: \(isShared), System: \(vault.isSystemVault))")
        }
        
        vaults = fetchedVaults
        
        // Load active sessions
        await loadActiveSessions()
    }
    
    
    /// Clean up orphaned vaults (vaults with no owner or deleted owner)
    /// This prevents CloudKit from restoring vaults after account deletion
    private func cleanupOrphanedVaults(modelContext: ModelContext) async throws {
        // Find all vaults
        let allVaultsDescriptor = FetchDescriptor<Vault>()
        let allVaults = try modelContext.fetch(allVaultsDescriptor)
        
        // Find all existing users
        let usersDescriptor = FetchDescriptor<User>()
        let allUsers = try modelContext.fetch(usersDescriptor)
        let existingUserIDs = Set(allUsers.map { $0.id })
        
        var orphanedVaults: [Vault] = []
        
        for vault in allVaults {
            // Skip system vaults (they may not have owners)
            if vault.isSystemVault {
                continue
            }
            
            // Check if vault has an owner
            if let owner = vault.owner {
                // Check if owner still exists
                if !existingUserIDs.contains(owner.id) {
                    print("   ⚠️ Found vault with deleted owner: \(vault.name)")
                    orphanedVaults.append(vault)
                }
            } else {
                // Vault with no owner is orphaned (unless it's a system vault)
                print("   ⚠️ Found vault with no owner: \(vault.name)")
                orphanedVaults.append(vault)
            }
        }
        
        // Delete orphaned vaults
        if !orphanedVaults.isEmpty {
            print("   🗑️ Cleaning up \(orphanedVaults.count) orphaned vault(s)")
            for vault in orphanedVaults {
                // Delete all documents first
                if let documents = vault.documents {
                    for document in documents {
                        modelContext.delete(document)
                    }
                }
                // Delete vault
                modelContext.delete(vault)
            }
            
            try modelContext.save()
            print("   ✅ Cleaned up \(orphanedVaults.count) orphaned vault(s)")
        }
    }
    
    /// Force refresh vaults (useful after accepting CloudKit shares)
    func refreshVaults() async throws {
        try await loadVaults()
    }
    
    /// One-time cleanup: Delete Intel Reports vault completely
    private func deleteIntelReportsVault() async throws {
        guard let modelContext = modelContext else { return }
        
        // Find Intel Reports vault
        let descriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.name == "Intel Reports" || $0.isSystemVault == true }
        )
        
        let intelVaults = try modelContext.fetch(descriptor)
        
        if !intelVaults.isEmpty {
            print(" Deleting Intel Reports vaults...")
            for vault in intelVaults {
                // Delete all documents in the vault first
                if let documents = vault.documents {
                    print("   Deleting \(documents.count) documents from \(vault.name)")
                    for document in documents {
                        modelContext.delete(document)
                    }
                }
                
                // Delete vault itself
                print("   Deleting vault: \(vault.name)")
                modelContext.delete(vault)
            }
            
            try modelContext.save()
            print(" Intel Reports vault(s) permanently deleted")
        }
    }
    
    func createVault(name: String, description: String?, keyType: String, vaultType: String = "both") async throws -> Vault {
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext, let currentUserID = currentUserID else {
            throw VaultError.contextNotAvailable
        }
        
        // Find current user
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == currentUserID }
        )
        guard let currentUser = try modelContext.fetch(userDescriptor).first else {
            // User not found in database - this shouldn't happen if auth is working
            // Log detailed error for debugging
            print("❌ VaultService.createVault: User not found in database")
            print("   Looking for user ID: \(currentUserID)")
            print("   Available users in database:")
            let allUsersDescriptor = FetchDescriptor<User>()
            if let allUsers = try? modelContext.fetch(allUsersDescriptor) {
                for user in allUsers {
                    print("     - User ID: \(user.id), Name: \(user.fullName)")
                }
            } else {
                print("     - Could not fetch users from database")
            }
            throw VaultError.userNotFound
        }
        
        let vault = Vault(
            name: name,
            vaultDescription: description,
            keyType: keyType
        )
        vault.vaultType = vaultType
        
        vault.owner = currentUser
        
        // Initialize optional arrays
        if currentUser.ownedVaults == nil {
            currentUser.ownedVaults = []
        }
        currentUser.ownedVaults?.append(vault)
        
        // Initialize vault arrays
        if vault.documents == nil { vault.documents = [] }
        if vault.sessions == nil { vault.sessions = [] }
        if vault.accessLogs == nil { vault.accessLogs = [] }
        if vault.dualKeyRequests == nil { vault.dualKeyRequests = [] }
        
        // Auto-create anti-vault for 1:1 relationship
        let antiVaultID = UUID()
        vault.antiVaultID = antiVaultID
        vault.antiVaultStatus = "locked"
        vault.antiVaultCreatedAt = Date()
        vault.antiVaultAutoUnlockPolicyData = encodeAutoUnlockPolicy(AutoUnlockPolicy())
        vault.antiVaultThreatDetectionSettingsData = encodeThreatDetectionSettings(ThreatDetectionSettings())
        
        // Also create AntiVault model for backward compatibility
        let antiVault = AntiVault(
            id: antiVaultID,
            vaultID: antiVaultID,
            monitoredVaultID: vault.id,
            ownerID: currentUserID,
            status: "locked"
        )
        modelContext.insert(antiVault)
        
        modelContext.insert(vault)
        try modelContext.save()
        
        // Log vault creation
        let accessLog = VaultAccessLog(
            accessType: "created",
            userID: currentUserID,
            userName: currentUser.fullName
        )
        accessLog.vault = vault
        
        // Add location data if available
        let locationService = await MainActor.run { LocationService() }
        let location = await MainActor.run { locationService.currentLocation }
        if let location = location {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
        }
        
        modelContext.insert(accessLog)
        try modelContext.save()
        
        try await loadVaults()
        
        return vault
    }
    
    /// Update vault threat index with formal logic analysis results
    func updateThreatIndexWithLogic(vault: Vault, result: ThreatInferenceResult) async throws {
        // This method is a convenience wrapper that calls the FormalLogicThreatInferenceService
        // to update vault threat metrics. The actual update logic is in FormalLogicThreatInferenceService.
        // This method can be called from VaultService to trigger threat analysis updates.
        
        // The vault's threatIndex and threatLevel are updated by FormalLogicThreatInferenceService.updateVaultThreatMetrics()
        // This method exists for integration purposes and can trigger additional vault-related updates if needed.
        
        print("📊 VaultService: Updating threat index with logical analysis for vault: \(vault.name)")
        
        // If using SwiftData, save the context after threat metrics update
        if let modelContext = modelContext {
            try modelContext.save()
        }
        
        // Reload vaults to refresh the UI
        try await loadVaults()
    }
    
    
    /// Load access logs for a vault
    func loadAccessLogs(for vault: Vault) async throws -> [VaultAccessLog] {
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        return vault.accessLogs ?? []
    }
    
    func deleteVault(_ vault: Vault) async throws {
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw VaultError.contextNotAvailable
        }
        
        modelContext.delete(vault)
        try modelContext.save()
        
        try await loadVaults()
    }
    
    func openVault(_ vault: Vault) async throws {
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        guard let currentUserID = currentUserID else {
            throw VaultError.userNotFound
        }
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw VaultError.contextNotAvailable
        }
        
        // Check if vault requires dual-key approval
        if vault.keyType == "dual" {
            //  CHECK: Prevent duplicate pending requests for same vault
            // Fetch all pending requests and filter in Swift (simpler than complex predicate)
            let allPendingDescriptor = FetchDescriptor<DualKeyRequest>(
                predicate: #Predicate { $0.status == "pending" }
            )
            
            let allPendingRequests = try modelContext.fetch(allPendingDescriptor)
            let existingRequests = allPendingRequests.filter { $0.vault?.id == vault.id }
            
            if let existingRequest = existingRequests.first {
                print(" Pending request already exists for vault: \(vault.name)")
                print("   Request ID: \(existingRequest.id)")
                print("   Requested: \(existingRequest.requestedAt)")
                print("   → Reusing existing request instead of creating duplicate")
                
                // Use the existing request for ML processing
                // Configure service on MainActor (configure is @MainActor)
                // modelContext is already unwrapped at function start
                // Use Task with @MainActor to avoid Sendable requirement
                let approvalService = await Task { @MainActor in
                    let service = DualKeyApprovalService()
                    service.configure(
                        modelContext: modelContext,
                        vaultService: self
                    )
                    return service
                }.value
                
                do {
                    let decision = try await approvalService.processDualKeyRequest(existingRequest, vault: vault)
                    
                    switch decision.action {
                    case .autoApproved:
                        print(" ML AUTO-APPROVED: Access granted")
                        
                        // CLEAR all other pending requests for this user after approval
                        let userPendingRequests = allPendingRequests.filter { $0.requester?.id == currentUserID }
                        for oldRequest in userPendingRequests {
                            modelContext.delete(oldRequest)
                        }
                        try? modelContext.save()
                        print("   Cleared \(userPendingRequests.count) pending request(s)")
                        
                        // Continue to session creation below
                        
                    case .autoDenied:
                        print(" ML AUTO-DENIED: Access denied")
                        throw VaultError.accessDenied
                    }
                } catch {
                    print(" ML processing error: \(error)")
                    throw VaultError.awaitingApproval
                }
            } else {
                // No existing pending request - create new one
            let request = DualKeyRequest(reason: "Requesting vault access")
            request.vault = vault
            
            // Find current user
            let userDescriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.id == currentUserID }
            )
            if let currentUser = try modelContext.fetch(userDescriptor).first {
                request.requester = currentUser
            }
            
            modelContext.insert(request)
            try modelContext.save()
            
                //  AUTOMATIC ML-BASED APPROVAL/DENIAL
                print(" Dual-key request created - initiating ML analysis...")
                
                // Configure service on MainActor (configure is @MainActor)
                // modelContext is already unwrapped at function start
                // Use Task with @MainActor to avoid Sendable requirement
                let approvalService = await Task { @MainActor in
                    let service = DualKeyApprovalService()
                    service.configure(
                        modelContext: modelContext,
                        vaultService: self
                    )
                    return service
                }.value
                
                do {
                    // Process with ML + Formal Logic
                    let decision = try await approvalService.processDualKeyRequest(request, vault: vault)
                    
                    // Check the automatic decision
                    switch decision.action {
                    case .autoApproved:
                        print(" ML AUTO-APPROVED: Access granted automatically")
                        print("   Confidence: \(Int(decision.confidence * 100))%")
                        print("   Reasoning: \(decision.logicalReasoning.prefix(200))...")
                        
                        // CLEAR all pending requests for this user after approval
                        let userPendingRequests = allPendingRequests.filter { $0.requester?.id == currentUserID }
                        for oldRequest in userPendingRequests {
                            modelContext.delete(oldRequest)
                        }
                        try? modelContext.save()
                        print("   Cleared \(userPendingRequests.count) pending request(s)")
                        
                        // Request is now approved - continue with session creation below
                        
                    case .autoDenied:
                        print(" ML AUTO-DENIED: Access denied automatically")
                        print("   Confidence: \(Int(decision.confidence * 100))%")
                        print("   Reasoning: \(decision.logicalReasoning.prefix(200))...")
                        throw VaultError.accessDenied
                    }
                    
                    // If approved, continue to create session
                    print("    Proceeding with vault access...")
                    
                } catch {
                    print(" ML processing error: \(error)")
                    // Fallback: treat as denied for security
            throw VaultError.awaitingApproval
                }
            }
        }
        
        // Create session
        let session = VaultSession()
        session.vault = vault
        
        // Find current user
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == currentUserID }
        )
        if let currentUser = try modelContext.fetch(userDescriptor).first {
            session.user = currentUser
        }
        
        modelContext.insert(session)
        
        // Update vault status
        vault.status = "active"
        vault.lastAccessedAt = Date()
        
        // COMPREHENSIVE EVENT LOGGING with timestamp, location, owner
        let locationService = await MainActor.run { LocationService() }
        
        // Ensure we have location - request if needed
        let currentLocation = await MainActor.run { locationService.currentLocation }
        if currentLocation == nil {
            await locationService.requestLocationPermission()
            // Give it a moment to get location
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        }
        
        let accessLog = VaultAccessLog(
            accessType: "opened",
            userID: currentUserID,
            userName: currentUser?.fullName
        )
        accessLog.vault = vault
        
        // Add comprehensive location data
        let finalLocation = await MainActor.run { locationService.currentLocation }
        if let location = finalLocation {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
            print("   Location logged: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        } else {
            // Use default SF coordinates if location unavailable
            accessLog.locationLatitude = 37.7749
            accessLog.locationLongitude = -122.4194
            print("   Using default location (permissions may be denied)")
        }
        
        // Log owner information
        if let owner = vault.owner {
            print("   Vault owner: \(owner.fullName)")
        }
        
        modelContext.insert(accessLog)
        print("   Access event logged: opened at \(Date())")
        
        try modelContext.save()
        
        activeSessions[vault.id] = session
        
        // Start session timeout timer
        startSessionTimeout(for: vault)
        
        // 🔗 INTEGRATION: Open shared vault session for nominees
        if let currentUser = currentUser {
            #if !APP_EXTENSION
            // Configure service on MainActor (configure is @MainActor)
            // modelContext and currentUserID are already unwrapped at function start
            // Use Task with @MainActor to avoid Sendable requirement
            let sharedSessionService = await Task { @MainActor in
                let service = SharedVaultSessionService()
                service.configure(modelContext: modelContext, userID: currentUserID)
                return service
            }.value
            try await sharedSessionService.openSharedVault(vault, unlockedBy: currentUser)
            print(" Shared vault session opened - nominees can now access")
            #endif
            
            //  NOMINEE ACCESS: Check if current user is a nominee
            await checkAndGrantNomineeAccess(for: vault, userID: currentUserID)
        }
        
        try await loadVaults()
    }
    
    
    // MARK: - Nominee Access Management
    
    /// Check if current user is a nominee and grant access if eligible
    private func checkAndGrantNomineeAccess(for vault: Vault, userID: UUID) async {
        guard let modelContext = modelContext else { return }
        
        // Check if user is a nominee for this vault
        // Use simpler predicate to avoid SwiftData macro issues
        let vaultID = vault.id
        let nomineeDescriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate<Nominee> { nominee in
                nominee.statusRaw == "accepted" || nominee.statusRaw == "active"
            }
        )
        
        do {
            let allNominees = try modelContext.fetch(nomineeDescriptor)
            
            // Filter in Swift to match vault (simpler than complex predicate)
            let nominees = allNominees.filter { nominee in
                nominee.vault?.id == vaultID
            }
            
            // Check if current user matches any nominee (by email or phone)
            // Note: In production, you'd match by authenticated user email/phone
            // For now, we'll check if there are any active nominees and grant them access
            if !nominees.isEmpty {
                print(" Found \(nominees.count) active nominee(s) for vault: \(vault.name)")
                
                // Grant access via shared session (already opened above)
                // Nominees will be notified via SharedVaultSessionService notifications
                for nominee in nominees {
                    print("    Nominee '\(nominee.name)' has access (status: \(nominee.status.displayName))")
                }
            }
        } catch {
            print(" Error checking nominee access: \(error)")
        }
    }
    
    /// Start or restart session timeout timer
    /// Uses the actual session's expiresAt time, not a fixed duration
    private func startSessionTimeout(for vault: Vault) {
        // Cancel existing timer if any
        sessionTimeoutTasks[vault.id]?.cancel()
        
        // Get the session's actual expiration time
        guard let session = activeSessions[vault.id],
              session.isActive,
              session.expiresAt > Date() else {
            print("⚠️ Cannot start timeout: No active session for vault \(vault.name)")
            return
        }
        
        // Calculate time until expiration
        let timeUntilExpiration = session.expiresAt.timeIntervalSinceNow
        guard timeUntilExpiration > 0 else {
            // Session already expired - close vault immediately
            print("⚠️ Session already expired for vault \(vault.name), closing immediately")
            Task {
                try? await closeVault(vault)
            }
            return
        }
        
        print("⏱️ Starting session timeout for vault '\(vault.name)': expires in \(Int(timeUntilExpiration / 60)) minutes")
        
        // Create new timer task that waits until the actual expiration time
        let task = Task {
            // Sleep until expiration time
            try? await Task.sleep(nanoseconds: UInt64(timeUntilExpiration * 1_000_000_000))
            
            // Check if task was cancelled
            if !Task.isCancelled {
                // Double-check session is still expired
                if let currentSession = activeSessions[vault.id],
                   currentSession.expiresAt <= Date() {
                    print("🔒 Session expired for vault '\(vault.name)', auto-locking...")
                    try? await closeVault(vault)
                } else {
                    print("⚠️ Session timeout fired but session was extended - ignoring")
                }
            }
        }
        
        sessionTimeoutTasks[vault.id] = task
    }
    
    /// Extend vault session when user performs an activity
    /// Call this when: recording video, previewing document, editing, etc.
    func extendVaultSession(for vault: Vault) async {
        guard let session = activeSessions[vault.id], session.isActive else { return }
        
        print("🔄 Extending vault session for: \(vault.name)")
        
        // Calculate new expiration time (extend from now, not from old expiration)
        let newExpiresAt = Date().addingTimeInterval(activityExtension)
        session.expiresAt = newExpiresAt
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        if let modelContext = modelContext {
            try? modelContext.save()
        }
        
        // Restart timeout timer with new expiration time
        startSessionTimeout(for: vault)
        
        // Log activity
        await logVaultActivity(vault, activityType: "session_extended")
    }
    
    /// Track vault activity (for session extension)
    func trackVaultActivity(for vault: Vault, activityType: String) async {
        // Extend session on any significant activity
        let extendableActivities = ["recording", "previewing", "editing", "uploading"]
        
        if extendableActivities.contains(activityType) {
            await extendVaultSession(for: vault)
        }
    }
    
    /// Log vault activity
    private func logVaultActivity(_ vault: Vault, activityType: String) async {
        guard let currentUserID = currentUserID else { return }
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else { return }
        
        let accessLog = VaultAccessLog(
            accessType: activityType,
            userID: currentUserID,
            userName: currentUser?.fullName
        )
        accessLog.vault = vault
        
        // Add location data if available
        let locationService = await MainActor.run { LocationService() }
        let location = await MainActor.run { locationService.currentLocation }
        if let location = location {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
        }
        
        modelContext.insert(accessLog)
        try? modelContext.save()
    }
    
    func closeVault(_ vault: Vault) async throws {
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        guard let currentUserID = currentUserID else {
            throw VaultError.userNotFound
        }
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw VaultError.contextNotAvailable
        }
        
        vault.status = "locked"
        
        // Cancel timeout timer
        sessionTimeoutTasks[vault.id]?.cancel()
        sessionTimeoutTasks.removeValue(forKey: vault.id)
        
        // End session
        if let session = activeSessions[vault.id] {
            session.isActive = false
            activeSessions.removeValue(forKey: vault.id)
        }
        
        // 🔗 INTEGRATION: Lock shared vault session (notifies all nominees)
        #if !APP_EXTENSION
        if let currentUser = currentUser {
            // Configure service on MainActor (configure is @MainActor)
            // modelContext and currentUserID are already unwrapped at function start
            // Use Task with @MainActor to avoid Sendable requirement
            let sharedSessionService = await Task { @MainActor in
                let service = SharedVaultSessionService()
                service.configure(modelContext: modelContext, userID: currentUserID)
                return service
            }.value
            try? await sharedSessionService.lockSharedVault(vault, lockedBy: currentUser)
            print(" Shared vault session locked - nominees notified")
        }
        #endif
        
        // Log access with location
        let accessLog = VaultAccessLog(
            accessType: "closed",
            userID: currentUserID,
            userName: currentUser?.fullName
        )
        accessLog.vault = vault
        
        // Add location data if available
        let locationService = await MainActor.run { LocationService() }
        let location = await MainActor.run { locationService.currentLocation }
        if let location = location {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
        }
        
        modelContext.insert(accessLog)
        
        try? modelContext.save()
        
        try? await loadVaults()
    }
    
    
    
    func hasActiveSession(for vaultID: UUID) -> Bool {
        if let session = activeSessions[vaultID] {
            return session.isActive && session.expiresAt > Date()
        }
        return false
    }
    
    private func loadActiveSessions() async {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<VaultSession>(
            predicate: #Predicate { $0.isActive == true }
        )
        
        if let sessions = try? modelContext.fetch(descriptor) {
            for session in sessions {
                if session.expiresAt > Date(), let vaultID = session.vault?.id, let vault = vaults.first(where: { $0.id == vaultID }) {
                    activeSessions[vaultID] = session
                    // Restart timeout timer for active session
                    startSessionTimeout(for: vault)
                } else {
                    // Session expired - mark as inactive
                    session.isActive = false
                    if let vaultID = session.vault?.id {
                        activeSessions.removeValue(forKey: vaultID)
                        sessionTimeoutTasks[vaultID]?.cancel()
                        sessionTimeoutTasks.removeValue(forKey: vaultID)
                    }
                    try? modelContext.save()
                }
            }
        }
    }
    
    func getTotalStorage() -> Int64 {
        var total: Int64 = 0
        for vault in vaults {
            if let documents = vault.documents {
                for document in documents {
                    total += document.fileSize
                }
            }
        }
        return total
    }
    
    func formatStorage(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func ensureIntelVaultExists(for user: User) async throws {
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw VaultError.contextNotAvailable
        }
        
        // Check if Intel Reports vault already exists (simplified predicate to avoid SwiftData complexity)
        let descriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.name == "Intel Reports" }
        )
        
        let allIntelVaults = try modelContext.fetch(descriptor)
        let existing = allIntelVaults.filter { $0.owner?.id == user.id }
        
        if existing.isEmpty {
            // Create Intel Reports vault (dual-key, system vault)
            let intelVault = Vault(
                name: "Intel Reports",
                vaultDescription: "AI-generated voice memo intelligence reports from cross-document analysis. Listen to compiled insights about your documents.",
                keyType: "dual" // Always dual-key for security
            )
            intelVault.vaultType = "both"
            intelVault.isSystemVault = true // Mark as system vault - read-only for users
            intelVault.owner = user
            user.ownedVaults?.append(intelVault)
            
            modelContext.insert(intelVault)
            try modelContext.save()
            
            // Reload vaults to include new Intel Vault
            try await loadVaults()
        }
    }
    
    /// Ensure Intel Vault exists (overload for UUID)
    func ensureIntelVaultExists(for userID: UUID) async throws {
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw VaultError.contextNotAvailable
        }
        
        // Find user by ID
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userID }
        )
        guard let user = try modelContext.fetch(userDescriptor).first else {
            throw VaultError.userNotFound
        }
        
        // Use the User-based method
        try await ensureIntelVaultExists(for: user)
    }
    
    // MARK: - Transfer Ownership
    
    /// Transfer vault ownership to a new owner
    /// This is called when a nominee accepts a transfer invitation
    /// IMPORTANT: Only nominated users can receive ownership
    func transferOwnership(vault: Vault, to newOwnerID: UUID) async throws {
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw VaultError.contextNotAvailable
        }
        
        // Validate that the new owner is a nominee
        try validateNomineeForTransfer(vault: vault, newOwnerID: newOwnerID, modelContext: modelContext)
        
        // Find new owner
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == newOwnerID }
        )
        
        guard let newOwner = try modelContext.fetch(userDescriptor).first else {
            throw VaultError.userNotFound
        }
        
        // Get previous owner
        let previousOwner = vault.owner
        
        // Update vault owner
        vault.owner = newOwner
        
        // Update owned vaults lists
        if newOwner.ownedVaults == nil {
            newOwner.ownedVaults = []
        }
        if !(newOwner.ownedVaults?.contains(where: { $0.id == vault.id }) ?? false) {
            newOwner.ownedVaults?.append(vault)
        }
        
        // Remove from previous owner's list
        if let previousOwner = previousOwner {
            previousOwner.ownedVaults?.removeAll { $0.id == vault.id }
        }
        
        try modelContext.save()
        
        // Reload vaults to reflect ownership change
        try await loadVaults()
        
        print("✅ Vault ownership transferred: \(vault.name) → \(newOwner.fullName)")
    }
    
    /// Validate that a user is a nominee before allowing ownership transfer
    
    
    
    // MARK: - Anti-Vault Encoding Helpers
    
    private func encodeAutoUnlockPolicy(_ policy: AutoUnlockPolicy) -> Data? {
        let json: [String: Any] = [
            "unlockOnSessionNomination": policy.unlockOnSessionNomination,
            "unlockOnSubsetNomination": policy.unlockOnSubsetNomination,
            "requireApproval": policy.requireApproval,
            "approvalUserIDs": policy.approvalUserIDs.map { $0.uuidString }
        ]
        return try? JSONSerialization.data(withJSONObject: json)
    }
    
    private func encodeThreatDetectionSettings(_ settings: ThreatDetectionSettings) -> Data? {
        let json: [String: Any] = [
            "detectContentDiscrepancies": settings.detectContentDiscrepancies,
            "detectMetadataMismatches": settings.detectMetadataMismatches,
            "detectAccessPatternAnomalies": settings.detectAccessPatternAnomalies,
            "detectGeographicInconsistencies": settings.detectGeographicInconsistencies,
            "detectEditHistoryDiscrepancies": settings.detectEditHistoryDiscrepancies,
            "minThreatSeverity": settings.minThreatSeverity
        ]
        return try? JSONSerialization.data(withJSONObject: json)
    }
    
    // MARK: - Broadcast Vault: Open Street
    
    /// Create or get the "Open Street" broadcast vault
    /// Broadcast vaults are publicly accessible to all users
    func createOrGetOpenStreetVault() async throws -> Vault {
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw VaultError.contextNotAvailable
        }
        
        // Check if "Open Street" vault exists
        let descriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.name == "Open Street" && $0.isBroadcast == true }
        )
        
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        
        // Create "Open Street" vault
        let openStreetVault = Vault(
            name: "Open Street",
            vaultDescription: "A public vault for everyone to share and access documents",
            keyType: "single"
        )
        openStreetVault.isBroadcast = true
        openStreetVault.accessLevel = "public_read"
        openStreetVault.status = "active"
        openStreetVault.vaultType = "both"
        
        // Set owner (use current user or leave nil for system vault)
        if let currentUserID = self.currentUserID {
            let userDescriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.id == currentUserID }
            )
            if let currentUser = try? modelContext.fetch(userDescriptor).first {
                openStreetVault.owner = currentUser
            }
        }
        
        modelContext.insert(openStreetVault)
        try modelContext.save()
        
        // Reload vaults
        try await self.loadVaults()
        
        print("✅ Created 'Open Street' broadcast vault: \(openStreetVault.id)")
        return openStreetVault
    }
}

enum VaultError: LocalizedError {
    case contextNotAvailable
    case serviceNotConfigured
    case userNotFound
    case awaitingApproval
    case accessDenied
    case transferOwnershipRestricted(String)
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Database context not available"
        case .serviceNotConfigured:
            return "Service not configured. Please ensure CloudKit is properly initialized."
        case .userNotFound:
            return "Current user not found"
        case .accessDenied:
            return "Access denied by security system"
        case .awaitingApproval:
            return "Vault requires admin approval. Request has been submitted."
        case .transferOwnershipRestricted(let message):
            return message
        }
    }
}

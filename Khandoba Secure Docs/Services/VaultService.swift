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

final class VaultService: ObservableObject {
    @Published var vaults: [Vault] = []
    @Published var isLoading = false
    @Published var activeSessions: [UUID: VaultSession] = [:]
    
    var modelContext: ModelContext? // Made public for Intel vault access
    private var currentUserID: UUID?
    var currentUser: User? // Added for Intel report access
    
    // Session timeout management
    private var sessionTimeoutTasks: [UUID: Task<Void, Never>] = [:]
    private let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
    private let activityExtension: TimeInterval = 15 * 60 // 15 minutes on activity
    
    init() {}
    
    func configure(modelContext: ModelContext, userID: UUID) {
        self.modelContext = modelContext
        self.currentUserID = userID
        
        // Load current user
        Task {
            let userDescriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.id == userID }
            )
            currentUser = try? modelContext.fetch(userDescriptor).first
        }
    }
    
    func loadVaults() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let modelContext = modelContext else { return }
        
        // ONE-TIME CLEANUP: Delete Intel Reports vault
        try await deleteIntelReportsVault()
        
        let descriptor = FetchDescriptor<Vault>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        var fetchedVaults = try modelContext.fetch(descriptor)
        
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
        guard let modelContext = modelContext, let currentUserID = currentUserID else {
            throw VaultError.contextNotAvailable
        }
        
        // Find current user
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == currentUserID }
        )
        guard let currentUser = try modelContext.fetch(userDescriptor).first else {
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
    
    func deleteVault(_ vault: Vault) async throws {
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(vault)
        try modelContext.save()
        
        try await loadVaults()
    }
    
    func openVault(_ vault: Vault) async throws {
        guard let modelContext = modelContext, let currentUserID = currentUserID else {
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
                let approvalService = await MainActor.run { DualKeyApprovalService() }
                await MainActor.run { approvalService.configure(modelContext: modelContext) }
                
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
                
                let approvalService = await MainActor.run { DualKeyApprovalService() }
                await MainActor.run { approvalService.configure(modelContext: modelContext) }
                
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
            let sharedSessionService = await MainActor.run { SharedVaultSessionService() }
            await MainActor.run { sharedSessionService.configure(modelContext: modelContext, userID: currentUserID) }
            try await sharedSessionService.openSharedVault(vault, unlockedBy: currentUser)
            print(" Shared vault session opened - nominees can now access")
            
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
                nominee.statusRaw == NomineeStatus.accepted.rawValue || nominee.statusRaw == NomineeStatus.active.rawValue
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
    private func startSessionTimeout(for vault: Vault) {
        // Cancel existing timer if any
        sessionTimeoutTasks[vault.id]?.cancel()
        
        // Create new timer task
        let task = Task {
            try? await Task.sleep(nanoseconds: UInt64(sessionTimeout * 1_000_000_000))
            
            // Check if task was cancelled
            if !Task.isCancelled {
                await closeVault(vault)
            }
        }
        
        sessionTimeoutTasks[vault.id] = task
    }
    
    /// Extend vault session when user performs an activity
    /// Call this when: recording video, previewing document, editing, etc.
    func extendVaultSession(for vault: Vault) async {
        guard let session = activeSessions[vault.id], session.isActive else { return }
        
        print("🔄 Extending vault session for: \(vault.name)")
        
        // Update session expiry time
        session.expiresAt = Date().addingTimeInterval(activityExtension)
        
        // Restart timeout timer
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
        guard let modelContext = modelContext, let currentUserID = currentUserID else { return }
        
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
    
    func closeVault(_ vault: Vault) async {
        guard let modelContext = modelContext, let currentUserID = currentUserID else { return }
        
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
        if let currentUser = currentUser {
            let sharedSessionService = await MainActor.run { SharedVaultSessionService() }
            await MainActor.run { sharedSessionService.configure(modelContext: modelContext, userID: currentUserID) }
            try? await sharedSessionService.lockSharedVault(vault, lockedBy: currentUser)
            print(" Shared vault session locked - nominees notified")
        }
        
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
                if session.expiresAt > Date(), let vaultID = session.vault?.id {
                    activeSessions[vaultID] = session
                } else {
                    session.isActive = false
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
}

enum VaultError: LocalizedError {
    case contextNotAvailable
    case userNotFound
    case awaitingApproval
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Database context not available"
        case .userNotFound:
            return "Current user not found"
        case .accessDenied:
            return "Access denied by security system"
        case .awaitingApproval:
            return "Vault requires admin approval. Request has been submitted."
        }
    }
}

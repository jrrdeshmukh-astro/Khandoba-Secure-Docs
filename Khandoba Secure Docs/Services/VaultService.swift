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
    private var supabaseService: SupabaseService?
    private var currentUserID: UUID?
    var currentUser: User? // Added for Intel report access
    
    // Session timeout management
    private var sessionTimeoutTasks: [UUID: Task<Void, Never>] = [:]
    private let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
    private let activityExtension: TimeInterval = 15 * 60 // 15 minutes on activity
    
    init() {}
    
    // SwiftData/CloudKit mode
    func configure(modelContext: ModelContext, userID: UUID) {
        self.modelContext = modelContext
        self.supabaseService = nil
        self.currentUserID = userID
        
        // Load current user
        Task {
            let userDescriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.id == userID }
            )
            currentUser = try? modelContext.fetch(userDescriptor).first
        }
    }
    
    // Supabase mode
    func configure(supabaseService: SupabaseService, userID: UUID) {
        self.supabaseService = supabaseService
        self.modelContext = nil
        self.currentUserID = userID
        
        // Load current user from Supabase
        Task {
            do {
                let supabaseUser: SupabaseUser = try await supabaseService.fetch(
                    "users",
                    id: userID
                )
                // Convert to User model for compatibility
                await MainActor.run {
                    // Note: We'll need to create a User from SupabaseUser
                    // For now, we'll store the SupabaseUser data
                }
            } catch {
                print("⚠️ Failed to load user from Supabase: \(error)")
            }
        }
    }
    
    func loadVaults() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService, let userID = currentUserID {
            try await loadVaultsFromSupabase(supabaseService: supabaseService, userID: userID)
            return
        }
        
        // SwiftData/CloudKit mode
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
    
    /// Load vaults from Supabase
    private func loadVaultsFromSupabase(supabaseService: SupabaseService, userID: UUID) async throws {
        // RLS automatically filters vaults user has access to
        let supabaseVaults: [SupabaseVault] = try await supabaseService.fetchAll("vaults", filters: nil)
        
        // Convert to Vault models for compatibility
        await MainActor.run {
            self.vaults = supabaseVaults.map { supabaseVault in
                let vault = Vault(
                    name: supabaseVault.name,
                    vaultDescription: supabaseVault.vaultDescription,
                    keyType: supabaseVault.keyType
                )
                vault.id = supabaseVault.id
                vault.createdAt = supabaseVault.createdAt
                vault.lastAccessedAt = supabaseVault.lastAccessedAt
                vault.status = supabaseVault.status
                vault.vaultType = supabaseVault.vaultType
                vault.isSystemVault = supabaseVault.isSystemVault
                vault.encryptionKeyData = supabaseVault.encryptionKeyData
                vault.isEncrypted = supabaseVault.isEncrypted
                vault.isZeroKnowledge = supabaseVault.isZeroKnowledge
                vault.relationshipOfficerID = supabaseVault.relationshipOfficerID
                return vault
            }
        }
        
        // Load active sessions
        await loadActiveSessionsFromSupabase(supabaseService: supabaseService, userID: userID)
    }
    
    /// Load active sessions from Supabase
    private func loadActiveSessionsFromSupabase(supabaseService: SupabaseService, userID: UUID) async {
        do {
            let sessions: [SupabaseVaultSession] = try await supabaseService.fetchAll(
                "vault_sessions",
                filters: ["user_id": userID, "is_active": true]
            )
            
            await MainActor.run {
                for session in sessions {
                    if session.expiresAt > Date() {
                        let vaultSession = VaultSession(
                            startedAt: session.startedAt,
                            expiresAt: session.expiresAt,
                            isActive: session.isActive,
                            wasExtended: session.wasExtended
                        )
                        vaultSession.id = session.id
                        
                        // Find vault by ID
                        if let vault = vaults.first(where: { $0.id == session.vaultID }) {
                            vaultSession.vault = vault
                            activeSessions[session.vaultID] = vaultSession
                        }
                    }
                }
            }
        } catch {
            print("⚠️ Failed to load sessions from Supabase: \(error)")
        }
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
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService, let currentUserID = currentUserID {
            return try await createVaultInSupabase(
                name: name,
                description: description,
                keyType: keyType,
                vaultType: vaultType,
                supabaseService: supabaseService,
                userID: currentUserID
            )
        }
        
        // SwiftData/CloudKit mode
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
    
    /// Create vault in Supabase
    private func createVaultInSupabase(
        name: String,
        description: String?,
        keyType: String,
        vaultType: String,
        supabaseService: SupabaseService,
        userID: UUID
    ) async throws -> Vault {
        let supabaseVault = SupabaseVault(
            name: name,
            vaultDescription: description,
            ownerID: userID,
            status: "locked",
            keyType: keyType,
            vaultType: vaultType,
            isSystemVault: false,
            isEncrypted: true,
            isZeroKnowledge: true
        )
        
        let created: SupabaseVault = try await supabaseService.insert(
            "vaults",
            values: supabaseVault
        )
        
        // Create access log
        var accessLog = SupabaseVaultAccessLog(
            vaultID: created.id,
            accessType: "created",
            userID: userID
        )
        
        // Add location if available
        let locationService = await MainActor.run { LocationService() }
        let location = await MainActor.run { locationService.currentLocation }
        if let location = location {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
        }
        
        let _: SupabaseVaultAccessLog = try await supabaseService.insert(
            "vault_access_logs",
            values: accessLog
        )
        
        // Convert to Vault model for compatibility
        let vault = Vault(
            name: created.name,
            vaultDescription: created.vaultDescription,
            keyType: created.keyType
        )
        vault.id = created.id
        vault.createdAt = created.createdAt
        vault.status = created.status
        vault.vaultType = created.vaultType
        vault.isSystemVault = created.isSystemVault
        vault.encryptionKeyData = created.encryptionKeyData
        vault.isEncrypted = created.isEncrypted
        vault.isZeroKnowledge = created.isZeroKnowledge
        
        try await loadVaults()
        
        return vault
    }
    
    /// Archive a vault
    func archiveVault(_ vault: Vault) async throws {
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await archiveVaultInSupabase(vault: vault, supabaseService: supabaseService)
            return
        }
        
        // SwiftData/CloudKit mode
        guard let modelContext = modelContext else {
            throw VaultError.contextNotAvailable
        }
        
        vault.status = "archived"
        vault.lastAccessedAt = Date()
        
        // Close any active sessions
        if let session = activeSessions[vault.id] {
            session.isActive = false
            activeSessions.removeValue(forKey: vault.id)
        }
        
        try modelContext.save()
        
        // Reload vaults to update UI
        try await loadVaults()
        
        print("✅ Vault archived: \(vault.name)")
    }
    
    /// Unarchive a vault
    func unarchiveVault(_ vault: Vault) async throws {
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await unarchiveVaultInSupabase(vault: vault, supabaseService: supabaseService)
            return
        }
        
        // SwiftData/CloudKit mode
        guard let modelContext = modelContext else {
            throw VaultError.contextNotAvailable
        }
        
        vault.status = "locked" // Unarchive sets to locked, not active
        vault.lastAccessedAt = Date()
        
        try modelContext.save()
        
        // Reload vaults to update UI
        try await loadVaults()
        
        print("✅ Vault unarchived: \(vault.name)")
    }
    
    /// Archive vault in Supabase
    private func archiveVaultInSupabase(vault: Vault, supabaseService: SupabaseService) async throws {
        let update: [String: Any] = [
            "status": "archived",
            "last_accessed_at": ISO8601DateFormatter().string(from: Date()),
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let _: SupabaseVault = try await supabaseService.update(
            "vaults",
            id: vault.id,
            values: update
        )
        
        // Close any active sessions
        if let session = activeSessions[vault.id] {
            session.isActive = false
            activeSessions.removeValue(forKey: vault.id)
        }
        
        // Update local vault status
        vault.status = "archived"
        vault.lastAccessedAt = Date()
        
        // Reload vaults to update UI
        try await loadVaults()
        
        print("✅ Vault archived in Supabase: \(vault.name)")
    }
    
    /// Unarchive vault in Supabase
    private func unarchiveVaultInSupabase(vault: Vault, supabaseService: SupabaseService) async throws {
        let update: [String: Any] = [
            "status": "locked",
            "last_accessed_at": ISO8601DateFormatter().string(from: Date()),
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let _: SupabaseVault = try await supabaseService.update(
            "vaults",
            id: vault.id,
            values: update
        )
        
        // Update local vault status
        vault.status = "locked"
        vault.lastAccessedAt = Date()
        
        // Reload vaults to update UI
        try await loadVaults()
        
        print("✅ Vault unarchived in Supabase: \(vault.name)")
    }
    
    /// Load access logs for a vault (works in both Supabase and SwiftData modes)
    func loadAccessLogs(for vault: Vault) async throws -> [VaultAccessLog] {
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            return try await loadAccessLogsFromSupabase(for: vault, supabaseService: supabaseService)
        }
        
        // SwiftData/CloudKit mode - use relationship
        return vault.accessLogs ?? []
    }
    
    /// Load access logs from Supabase for a vault
    private func loadAccessLogsFromSupabase(for vault: Vault, supabaseService: SupabaseService) async throws -> [VaultAccessLog] {
        // Fetch access logs for this vault
        let supabaseLogs: [SupabaseVaultAccessLog] = try await supabaseService.fetchAll(
            "vault_access_logs",
            filters: ["vault_id": vault.id.uuidString],
            orderBy: "timestamp",
            ascending: false
        )
        
        // Convert to VaultAccessLog models
        return supabaseLogs.map { supabaseLog in
            let log = VaultAccessLog(
                timestamp: supabaseLog.timestamp,
                accessType: supabaseLog.accessType,
                userID: supabaseLog.userID,
                userName: supabaseLog.userName,
                deviceInfo: supabaseLog.deviceInfo
            )
            log.id = supabaseLog.id
            log.locationLatitude = supabaseLog.locationLatitude
            log.locationLongitude = supabaseLog.locationLongitude
            log.ipAddress = supabaseLog.ipAddress
            log.documentID = supabaseLog.documentID
            log.documentName = supabaseLog.documentName
            log.vault = vault
            return log
        }
    }
    
    func deleteVault(_ vault: Vault) async throws {
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await supabaseService.delete("vaults", id: vault.id)
            try await loadVaults()
            return
        }
        
        // SwiftData/CloudKit mode
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(vault)
        try modelContext.save()
        
        try await loadVaults()
    }
    
    func openVault(_ vault: Vault) async throws {
        guard let currentUserID = currentUserID else {
            throw VaultError.userNotFound
        }
        
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await openVaultInSupabase(vault: vault, supabaseService: supabaseService, userID: currentUserID)
            return
        }
        
        // SwiftData/CloudKit mode
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
                        supabaseService: supabaseService,
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
                        supabaseService: supabaseService,
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
    
    /// Open vault in Supabase mode
    private func openVaultInSupabase(
        vault: Vault,
        supabaseService: SupabaseService,
        userID: UUID
    ) async throws {
        print("🔓 Opening vault in Supabase mode: \(vault.name)")
        
        // TODO: Add dual-key approval support for Supabase mode
        // For now, skip dual-key check and proceed directly
        
        // Get location for access log
        let locationService = await MainActor.run { LocationService() }
        let currentLocation = await MainActor.run { locationService.currentLocation }
        if currentLocation == nil {
            await locationService.requestLocationPermission()
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        }
        let finalLocation = await MainActor.run { locationService.currentLocation }
        
        // Get device info
        let deviceInfo = UIDevice.current.model + " " + (UIDevice.current.systemVersion)
        
        // Get user name
        var userName: String? = nil
        do {
            let supabaseUser: SupabaseUser = try await supabaseService.fetch("users", id: userID)
            userName = supabaseUser.fullName
        } catch {
            print("⚠️ Failed to fetch user name: \(error)")
        }
        
        // Create vault session in Supabase
        let expiresAt = Date().addingTimeInterval(sessionTimeout)
        let supabaseSession = SupabaseVaultSession(
            vaultID: vault.id,
            userID: userID,
            startedAt: Date(),
            expiresAt: expiresAt,
            isActive: true,
            wasExtended: false
        )
        
        print("📝 Creating vault session in Supabase...")
        let createdSession: SupabaseVaultSession
        do {
            createdSession = try await supabaseService.insert(
                "vault_sessions",
                values: supabaseSession
            )
            print("✅ Vault session created (ID: \(createdSession.id))")
        } catch {
            print("❌ Failed to create vault session: \(error.localizedDescription)")
            throw error
        }
        
        // Create local VaultSession for compatibility
        let vaultSession = VaultSession(
            startedAt: createdSession.startedAt,
            expiresAt: createdSession.expiresAt,
            isActive: createdSession.isActive,
            wasExtended: createdSession.wasExtended
        )
        vaultSession.id = createdSession.id
        vaultSession.vault = vault
        
        // Update vault status
        vault.status = "active"
        vault.lastAccessedAt = Date()
        
        // Create access log in Supabase
        var accessLog = SupabaseVaultAccessLog(
            vaultID: vault.id,
            timestamp: Date(),
            accessType: "opened",
            userID: userID,
            userName: userName,
            deviceInfo: deviceInfo
        )
        
        // Add location data
        if let location = finalLocation {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
            print("   Location logged: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        } else {
            // Use default coordinates if location unavailable
            accessLog.locationLatitude = 37.7749
            accessLog.locationLongitude = -122.4194
            print("   Using default location (permissions may be denied)")
        }
        
        print("📝 Creating access log in Supabase...")
        do {
            let _: SupabaseVaultAccessLog = try await supabaseService.insert(
                "vault_access_logs",
                values: accessLog
            )
            print("✅ Access log created")
        } catch {
            print("⚠️ Failed to create access log: \(error.localizedDescription)")
            // Continue anyway - session is more important
        }
        
        // Update vault in Supabase (fetch first to get ownerID)
        do {
            // Fetch existing vault to get ownerID (it's a let constant)
            let existingVault: SupabaseVault = try await supabaseService.fetch("vaults", id: vault.id)
            
            // Create updated vault with mutable fields
            var updatedVault = SupabaseVault(
                id: existingVault.id,
                name: existingVault.name,
                vaultDescription: existingVault.vaultDescription,
                ownerID: existingVault.ownerID, // Use existing ownerID
                createdAt: existingVault.createdAt,
                lastAccessedAt: Date(),
                status: "active",
                keyType: existingVault.keyType,
                vaultType: existingVault.vaultType,
                isSystemVault: existingVault.isSystemVault,
                encryptionKeyData: existingVault.encryptionKeyData,
                isEncrypted: existingVault.isEncrypted,
                isZeroKnowledge: existingVault.isZeroKnowledge,
                relationshipOfficerID: existingVault.relationshipOfficerID,
                updatedAt: Date()
            )
            
            let _: SupabaseVault = try await supabaseService.update(
                "vaults",
                id: vault.id,
                values: updatedVault
            )
            print("✅ Vault status updated")
        } catch {
            print("⚠️ Failed to update vault status: \(error.localizedDescription)")
            // Continue anyway - session is more important
        }
        
        // Store session locally
        await MainActor.run {
            activeSessions[vault.id] = vaultSession
        }
        
        // Start session timeout timer
        startSessionTimeout(for: vault)
        
        print("✅ Vault opened successfully")
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
    
    func closeVault(_ vault: Vault) async throws {
        guard let currentUserID = currentUserID else {
            throw VaultError.userNotFound
        }
        
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await closeVaultInSupabase(vault: vault, supabaseService: supabaseService, userID: currentUserID)
            return
        }
        
        // SwiftData/CloudKit mode
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
    
    /// Close/lock vault in Supabase mode
    private func closeVaultInSupabase(
        vault: Vault,
        supabaseService: SupabaseService,
        userID: UUID
    ) async throws {
        print("🔒 Locking vault in Supabase mode: \(vault.name)")
        
        // Get location and device info
        let locationService = await MainActor.run { LocationService() }
        let location = await MainActor.run { locationService.currentLocation }
        let deviceInfo = UIDevice.current.model
        
        // Update vault status to "locked" in Supabase
        let existingVault: SupabaseVault = try await supabaseService.fetch("vaults", id: vault.id)
        var updatedVault = SupabaseVault(
            id: existingVault.id,
            name: existingVault.name,
            vaultDescription: existingVault.vaultDescription,
            ownerID: existingVault.ownerID,
            createdAt: existingVault.createdAt,
            lastAccessedAt: existingVault.lastAccessedAt,
            status: "locked",
            keyType: existingVault.keyType,
            vaultType: existingVault.vaultType,
            isSystemVault: existingVault.isSystemVault,
            encryptionKeyData: existingVault.encryptionKeyData,
            isEncrypted: existingVault.isEncrypted,
            isZeroKnowledge: existingVault.isZeroKnowledge,
            relationshipOfficerID: existingVault.relationshipOfficerID,
            updatedAt: Date()
        )
        try await supabaseService.update("vaults", id: vault.id, values: updatedVault)
        
        // End all active sessions for this vault
        let activeSessions: [SupabaseVaultSession] = try await supabaseService.fetchAll(
            "vault_sessions",
            filters: ["vault_id": vault.id.uuidString, "is_active": true]
        )
        
        for session in activeSessions {
            // Create updated session with same ID and all required fields
            let updatedSession = SupabaseVaultSession(
                id: session.id,
                vaultID: session.vaultID,
                userID: session.userID,
                startedAt: session.startedAt,
                expiresAt: session.expiresAt,
                isActive: false,
                wasExtended: session.wasExtended,
                createdAt: session.createdAt,
                updatedAt: Date()
            )
            try await supabaseService.update("vault_sessions", id: session.id, values: updatedSession)
        }
        
        // Create access log
        var accessLog = SupabaseVaultAccessLog(
            vaultID: vault.id,
            timestamp: Date(),
            accessType: "closed",
            userID: userID,
            userName: currentUser?.fullName ?? "User",
            deviceInfo: deviceInfo
        )
        
        if let location = location {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
        }
        
        try await supabaseService.insert("vault_access_logs", values: accessLog)
        
        // Update local state
        await MainActor.run {
            vault.status = "locked"
            activeSessions.removeValue(forKey: vault.id)
            sessionTimeoutTasks[vault.id]?.cancel()
            sessionTimeoutTasks.removeValue(forKey: vault.id)
        }
        
        print("✅ Vault locked successfully")
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
        // Supabase mode - use user ID directly
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await ensureIntelVaultExistsInSupabase(userID: user.id, supabaseService: supabaseService)
            return
        }
        
        // SwiftData/CloudKit mode
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
    
    /// Ensure Intel Vault exists in Supabase (overload for UUID)
    func ensureIntelVaultExists(for userID: UUID) async throws {
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await ensureIntelVaultExistsInSupabase(userID: userID, supabaseService: supabaseService)
            return
        }
        throw VaultError.contextNotAvailable
    }
    
    /// Ensure Intel Vault exists in Supabase
    private func ensureIntelVaultExistsInSupabase(userID: UUID, supabaseService: SupabaseService) async throws {
        // Check if Intel Reports vault already exists
        let allVaults: [SupabaseVault] = try await supabaseService.fetchAll("vaults", filters: nil)
        let existing = allVaults.first { $0.name == "Intel Reports" && $0.ownerID == userID }
        
        if existing == nil {
            // Create Intel Reports vault (dual-key, system vault)
            let intelVault = SupabaseVault(
                name: "Intel Reports",
                vaultDescription: "AI-generated voice memo intelligence reports from cross-document analysis. Listen to compiled insights about your documents.",
                ownerID: userID,
                status: "locked",
                keyType: "dual", // Always dual-key for security
                vaultType: "both",
                isSystemVault: true, // Mark as system vault - read-only for users
                isEncrypted: true,
                isZeroKnowledge: true
            )
            
            let _: SupabaseVault = try await supabaseService.insert(
                "vaults",
                values: intelVault
            )
            
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

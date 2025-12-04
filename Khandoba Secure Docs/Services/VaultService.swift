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
        
        let descriptor = FetchDescriptor<Vault>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        vaults = try modelContext.fetch(descriptor)
        
        // Load active sessions
        await loadActiveSessions()
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
        let locationService = LocationService()
        if let location = locationService.currentLocation {
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
            // Create dual-key request
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
            
            throw VaultError.awaitingApproval
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
        
        // Log access with location
        let accessLog = VaultAccessLog(
            accessType: "opened",
            userID: currentUserID,
            userName: currentUser?.fullName
        )
        accessLog.vault = vault
        
        // Add location data if available
        let locationService = LocationService()
        if let location = locationService.currentLocation {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
        }
        
        modelContext.insert(accessLog)
        
        try modelContext.save()
        
        activeSessions[vault.id] = session
        
        // Start session timeout timer
        startSessionTimeout(for: vault)
        
        try await loadVaults()
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
        let locationService = LocationService()
        if let location = locationService.currentLocation {
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
        
        // Log access with location
        let accessLog = VaultAccessLog(
            accessType: "closed",
            userID: currentUserID,
            userName: nil
        )
        accessLog.vault = vault
        
        // Add location data if available
        let locationService = LocationService()
        if let location = locationService.currentLocation {
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
        
        // Check if Intel Vault already exists (simplified predicate to avoid SwiftData complexity)
        let descriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.name == "Intel Vault" }
        )
        
        let allIntelVaults = try modelContext.fetch(descriptor)
        let existing = allIntelVaults.filter { $0.owner?.id == user.id }
        
        if existing.isEmpty {
            // Create Intel Vault (dual-key, system vault)
            let intelVault = Vault(
                name: "Intel Vault",
                vaultDescription: "AI-generated intelligence reports from cross-document analysis. This vault stores compiled insights from your documents.",
                keyType: "dual" // Always dual-key for security
            )
            intelVault.vaultType = "both"
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
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Database context not available"
        case .userNotFound:
            return "Current user not found"
        case .awaitingApproval:
            return "Vault requires admin approval. Request has been submitted."
        }
    }
}

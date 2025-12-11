//
//  SharedVaultSessionService.swift
//  Khandoba Secure Docs
//
//  Shared vault sessions - One session per vault for all users
//  Like a physical bank vault: open for everyone or locked for everyone
//

import Foundation
import SwiftData
import Combine
import UserNotifications

@MainActor
final class SharedVaultSessionService: ObservableObject {
    @Published var sharedSessions: [UUID: SharedVaultSession] = [:]
    @Published var sessionNotifications: [SessionNotification] = []
    
    private var modelContext: ModelContext?
    private var currentUserID: UUID?
    
    // Real-time session monitoring
    private var sessionCheckTimer: Timer?
    
    nonisolated init() {}
    
    @MainActor
    func configure(modelContext: ModelContext, userID: UUID) {
        self.modelContext = modelContext
        self.currentUserID = userID
        
        // Start monitoring for session changes
        startSessionMonitoring()
    }
    
    // MARK: - Shared Session Management
    
    /// Open vault - creates shared session for ALL users
    func openSharedVault(_ vault: Vault, unlockedBy user: User) async throws {
        guard modelContext != nil else {
            throw SessionError.contextNotAvailable
        }
        
        print("🔓 Opening shared vault: \(vault.name)")
        
        // Check if vault already has active session
        if let existingSession = sharedSessions[vault.id] {
            print("    Vault already open (shared session active)")
            // Notify user that vault is already open
            await notifySessionAlreadyActive(vault: vault, openedBy: existingSession.unlockedBy)
            return
        }
        
        // Create new shared session
        let session = SharedVaultSession(
            vaultID: vault.id,
            vaultName: vault.name,
            unlockedBy: user.id,
            unlockedByName: user.fullName,
            unlockedAt: Date(),
            expiresAt: Date().addingTimeInterval(30 * 60) // 30 minutes
        )
        
        sharedSessions[vault.id] = session
        
        print(" Shared session created for: \(vault.name)")
        print("   Unlocked by: \(user.fullName)")
        print("   Expires: \(session.expiresAt.formatted(date: .omitted, time: .shortened))")
        
        // Notify ALL vault members
        await notifyVaultOpened(vault: vault, by: user)
        
        // Start auto-lock timer
        startAutoLockTimer(for: vault, session: session)
    }
    
    /// Lock vault - closes session for ALL users
    func lockSharedVault(_ vault: Vault, lockedBy user: User) async throws {
        print(" Locking shared vault: \(vault.name)")
        
        guard let session = sharedSessions[vault.id] else {
            print("    Vault already locked")
            return
        }
        
        // Remove session
        sharedSessions.removeValue(forKey: vault.id)
        
        print(" Shared session closed for: \(vault.name)")
        print("   Locked by: \(user.fullName)")
        
        // Notify ALL vault members
        await notifyVaultLocked(vault: vault, by: user, duration: session.duration)
    }
    
    /// Check if vault is currently open (shared session exists)
    func isVaultOpen(_ vault: Vault) -> Bool {
        guard let session = sharedSessions[vault.id] else {
            return false
        }
        
        // Check if session expired
        if session.expiresAt < Date() {
            print("⏰ Session expired for: \(vault.name)")
            Task {
                try? await autoLockVault(vault)
            }
            return false
        }
        
        return true
    }
    
    /// Get session info for vault
    func getSessionInfo(_ vault: Vault) -> SharedVaultSession? {
        return sharedSessions[vault.id]
    }
    
    /// Extend session when activity detected
    func extendSession(for vault: Vault, activity: String) {
        guard var session = sharedSessions[vault.id] else { return }
        
        // Extend by 15 minutes
        session.expiresAt = Date().addingTimeInterval(15 * 60)
        session.lastActivity = activity
        session.lastActivityAt = Date()
        
        sharedSessions[vault.id] = session
        
        print("    Session extended for \(vault.name)")
        print("   Activity: \(activity)")
        print("   New expiry: \(session.expiresAt.formatted(date: .omitted, time: .shortened))")
    }
    
    // MARK: - Privileged Lock Control
    
    /// Check if user has privilege to manually lock vault
    func canLockVault(_ vault: Vault, user: User) -> Bool {
        // Only vault owner can lock (admin role removed)
        return vault.owner?.id == user.id
    }
    
    // MARK: - Auto-Lock Timer
    
    private func startAutoLockTimer(for vault: Vault, session: SharedVaultSession) {
        // Will be auto-locked when session expires
        // Timer checks every minute
    }
    
    private func autoLockVault(_ vault: Vault) async throws {
        guard modelContext != nil else { return }
        
        print("⏰ Auto-locking vault (session expired): \(vault.name)")
        
        sharedSessions.removeValue(forKey: vault.id)
        
        // Notify all members about auto-lock
        await notifyVaultAutoLocked(vault: vault)
    }
    
    // MARK: - Session Monitoring
    
    private func startSessionMonitoring() {
        // Check for session changes every 5 seconds
        sessionCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkSessionExpiry()
            }
        }
    }
    
    private func checkSessionExpiry() async {
        let now = Date()
        var expiredVaults: [UUID] = []
        
        for (vaultID, session) in sharedSessions {
            if session.expiresAt < now {
                expiredVaults.append(vaultID)
            }
        }
        
        // Auto-lock expired vaults
        for vaultID in expiredVaults {
            sharedSessions.removeValue(forKey: vaultID)
            print("⏰ Auto-locked vault (expired)")
        }
    }
    
    // MARK: - Notifications
    
    private func notifyVaultOpened(vault: Vault, by user: User) async {
        let notification = SessionNotification(
            type: .vaultOpened,
            vaultID: vault.id,
            vaultName: vault.name,
            userName: user.fullName,
            message: "\(user.fullName) opened \(vault.name)",
            timestamp: Date()
        )
        
        sessionNotifications.insert(notification, at: 0)
        
        // Send local notification
        await sendLocalNotification(
            title: "Vault Opened",
            body: "\(user.fullName) opened \(vault.name)",
            vaultID: vault.id
        )
        
        print("📢 Notification sent: Vault opened by \(user.fullName)")
    }
    
    private func notifyVaultLocked(vault: Vault, by user: User, duration: TimeInterval) async {
        let notification = SessionNotification(
            type: .vaultLocked,
            vaultID: vault.id,
            vaultName: vault.name,
            userName: user.fullName,
            message: "\(user.fullName) locked \(vault.name) (open for \(formatDuration(duration)))",
            timestamp: Date()
        )
        
        sessionNotifications.insert(notification, at: 0)
        
        // Send local notification
        await sendLocalNotification(
            title: "Vault Locked",
            body: "\(user.fullName) locked \(vault.name)",
            vaultID: vault.id
        )
        
        print("📢 Notification sent: Vault locked by \(user.fullName)")
    }
    
    private func notifyVaultAutoLocked(vault: Vault) async {
        let notification = SessionNotification(
            type: .vaultAutoLocked,
            vaultID: vault.id,
            vaultName: vault.name,
            userName: "System",
            message: "\(vault.name) auto-locked (session expired)",
            timestamp: Date()
        )
        
        sessionNotifications.insert(notification, at: 0)
        
        // Send local notification
        await sendLocalNotification(
            title: "Vault Auto-Locked",
            body: "\(vault.name) was automatically locked",
            vaultID: vault.id
        )
        
        print("📢 Notification sent: Vault auto-locked")
    }
    
    private func notifySessionAlreadyActive(vault: Vault, openedBy userID: UUID) async {
        // Inform user that vault is already open
        let notification = SessionNotification(
            type: .sessionActive,
            vaultID: vault.id,
            vaultName: vault.name,
            userName: "Unknown",
            message: "\(vault.name) is already open",
            timestamp: Date()
        )
        
        sessionNotifications.insert(notification, at: 0)
    }
    
    private func sendLocalNotification(title: String, body: String, vaultID: UUID) async {
        // Use PushNotificationService for consistent notification handling
        PushNotificationService.shared.sendVaultAccessNotification(
            vaultName: title,
            openedBy: body
        )
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
    }
    
    deinit {
        sessionCheckTimer?.invalidate()
    }
}

// MARK: - Data Models

struct SharedVaultSession: Identifiable {
    let id = UUID()
    let vaultID: UUID
    let vaultName: String
    let unlockedBy: UUID
    let unlockedByName: String
    let unlockedAt: Date
    var expiresAt: Date
    var lastActivity: String?
    var lastActivityAt: Date?
    
    var duration: TimeInterval {
        Date().timeIntervalSince(unlockedAt)
    }
    
    var isExpired: Bool {
        expiresAt < Date()
    }
    
    var remainingTime: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }
}

struct SessionNotification: Identifiable {
    let id = UUID()
    let type: NotificationType
    let vaultID: UUID
    let vaultName: String
    let userName: String
    let message: String
    let timestamp: Date
    
    enum NotificationType {
        case vaultOpened
        case vaultLocked
        case vaultAutoLocked
        case sessionActive
        case sessionExtended
    }
}

// MARK: - Errors

enum SessionError: LocalizedError {
    case contextNotAvailable
    case sessionExpired
    case noPermission
    case vaultAlreadyOpen
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Database context not available"
        case .sessionExpired:
            return "Vault session has expired"
        case .noPermission:
            return "You don't have permission to lock this vault"
        case .vaultAlreadyOpen:
            return "Vault is already open"
        }
    }
}


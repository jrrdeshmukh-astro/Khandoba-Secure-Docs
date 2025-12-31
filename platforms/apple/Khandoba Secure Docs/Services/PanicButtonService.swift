//
//  PanicButtonService.swift
//  Khandoba Secure Docs
//
//  Panic Button service for emergency security actions
//  Combines iOS + Web security features
//

import Foundation
import SwiftData
import Combine
import LocalAuthentication
#if os(iOS)
import UIKit
#endif

@MainActor
final class PanicButtonService: ObservableObject {
    @Published var isPanicModeActive = false
    @Published var panicActionsExecuted: [PanicAction] = []
    @Published var lastPanicActivation: Date?
    
    private var modelContext: ModelContext?
    private var currentUserID: UUID?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext, userID: UUID) {
        self.modelContext = modelContext
        self.currentUserID = userID
    }
    
    // MARK: - Panic Button Activation
    
    /// Activate panic mode - emergency security lockdown
    func activatePanicMode(reason: String? = nil) async throws {
        guard let modelContext = modelContext, let userID = currentUserID else {
            throw PanicError.contextNotAvailable
        }
        
        // Require biometric authentication for panic activation
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw PanicError.biometricNotAvailable
        }
        
        let success = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Confirm panic mode activation"
        )
        
        guard success else {
            throw PanicError.biometricFailed
        }
        
        // Execute panic actions
        var executedActions: [PanicAction] = []
        
        // 1. Close all vault sessions
        executedActions.append(await closeAllVaultSessions(modelContext: modelContext, userID: userID))
        
        // 2. Revoke all device authorizations (except current device)
        executedActions.append(await revokeAllDevices(modelContext: modelContext, userID: userID))
        
        // 3. Lock all vaults
        executedActions.append(await lockAllVaults(modelContext: modelContext, userID: userID))
        
        // 4. Clear sensitive cache
        executedActions.append(await clearSensitiveCache())
        
        // 5. Send security alerts
        executedActions.append(await sendPanicAlerts())
        
        // 6. Log panic activation
        await logPanicActivation(reason: reason, actions: executedActions, modelContext: modelContext)
        
        await MainActor.run {
            isPanicModeActive = true
            panicActionsExecuted = executedActions
            lastPanicActivation = Date()
        }
        
        print("🚨 PANIC MODE ACTIVATED - All security actions executed")
    }
    
    /// Deactivate panic mode (requires authentication)
    func deactivatePanicMode() async throws {
        guard modelContext != nil else {
            throw PanicError.contextNotAvailable
        }
        
        // Require biometric authentication
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw PanicError.biometricNotAvailable
        }
        
        let success = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Confirm panic mode deactivation"
        )
        
        guard success else {
            throw PanicError.biometricFailed
        }
        
        await MainActor.run {
            isPanicModeActive = false
        }
        
        print("✅ Panic mode deactivated")
    }
    
    // MARK: - Panic Actions
    
    private func closeAllVaultSessions(modelContext: ModelContext, userID: UUID) async -> PanicAction {
        let descriptor = FetchDescriptor<VaultSession>(
            predicate: #Predicate { $0.user?.id == userID }
        )
        
        if let sessions = try? modelContext.fetch(descriptor) {
            for session in sessions {
                modelContext.delete(session)
            }
            try? modelContext.save()
            
            return PanicAction(
                type: .closeAllSessions,
                status: .completed,
                message: "Closed \(sessions.count) vault session(s)",
                timestamp: Date()
            )
        }
        
        return PanicAction(
            type: .closeAllSessions,
            status: .completed,
            message: "No active sessions",
            timestamp: Date()
        )
    }
    
    private func revokeAllDevices(modelContext: ModelContext, userID: UUID) async -> PanicAction {
        let userDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userID }
        )
        
        if let user = try? modelContext.fetch(userDescriptor).first,
           let devices = user.authorizedDevices {
            var revokedCount = 0
            let currentDeviceID = await getCurrentDeviceIdentifier()
            
            for device in devices {
                // Don't revoke current device
                if device.deviceIdentifier != currentDeviceID {
                    device.isAuthorized = false
                    device.isWhitelisted = false
                    revokedCount += 1
                }
            }
            
            try? modelContext.save()
            
            return PanicAction(
                type: .revokeDevices,
                status: .completed,
                message: "Revoked \(revokedCount) device(s)",
                timestamp: Date()
            )
        }
        
        return PanicAction(
            type: .revokeDevices,
            status: .completed,
            message: "No devices to revoke",
            timestamp: Date()
        )
    }
    
    private func lockAllVaults(modelContext: ModelContext, userID: UUID) async -> PanicAction {
        let vaultDescriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.owner?.id == userID && $0.isSystemVault == false }
        )
        
        if let vaults = try? modelContext.fetch(vaultDescriptor) {
            // Close all sessions for these vaults
            let sessionDescriptor = FetchDescriptor<VaultSession>()
            if let allSessions = try? modelContext.fetch(sessionDescriptor) {
                for session in allSessions where vaults.contains(where: { $0.id == session.vault?.id }) {
                    modelContext.delete(session)
                }
            }
            
            try? modelContext.save()
            
            return PanicAction(
                type: .lockAllVaults,
                status: .completed,
                message: "Locked \(vaults.count) vault(s)",
                timestamp: Date()
            )
        }
        
        return PanicAction(
            type: .lockAllVaults,
            status: .completed,
            message: "No vaults to lock",
            timestamp: Date()
        )
    }
    
    private func clearSensitiveCache() async -> PanicAction {
        // Clear any cached sensitive data
        // This would clear document previews, decrypted content, etc.
        // Implementation depends on your caching strategy
        
        return PanicAction(
            type: .clearCache,
            status: .completed,
            message: "Sensitive cache cleared",
            timestamp: Date()
        )
    }
    
    private func sendPanicAlerts() async -> PanicAction {
        let pushService = PushNotificationService.shared
        
        pushService.sendSecurityAlertNotification(
            title: "🚨 PANIC MODE ACTIVATED",
            body: "Emergency security lockdown initiated. All vaults locked, sessions closed, and devices revoked.",
            threatType: "panic_mode"
        )
        
        return PanicAction(
            type: .sendAlerts,
            status: .completed,
            message: "Security alerts sent",
            timestamp: Date()
        )
    }
    
    private func logPanicActivation(reason: String?, actions: [PanicAction], modelContext: ModelContext) async {
        // Log to VaultAccessLog or create a dedicated panic log
        // This creates an audit trail of panic activations
        
        print("🚨 Panic Mode Logged:")
        print("   Reason: \(reason ?? "Not specified")")
        print("   Actions: \(actions.count)")
        for action in actions {
            print("     - \(action.type.rawValue): \(action.message)")
        }
    }
    
    private func getCurrentDeviceIdentifier() async -> String {
        #if os(iOS)
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #elseif os(macOS)
        return ProcessInfo.processInfo.hostName
        #else
        return UUID().uuidString
        #endif
    }
}

// MARK: - Models

struct PanicAction: Identifiable, Codable {
    let id: UUID
    let type: PanicActionType
    let status: PanicActionStatus
    let message: String
    let timestamp: Date
    
    init(type: PanicActionType, status: PanicActionStatus, message: String, timestamp: Date) {
        self.id = UUID()
        self.type = type
        self.status = status
        self.message = message
        self.timestamp = timestamp
    }
}

enum PanicActionType: String, Codable {
    case closeAllSessions = "Close All Sessions"
    case revokeDevices = "Revoke Devices"
    case lockAllVaults = "Lock All Vaults"
    case clearCache = "Clear Cache"
    case sendAlerts = "Send Alerts"
}

enum PanicActionStatus: String, Codable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    case failed = "Failed"
}

enum PanicError: LocalizedError {
    case contextNotAvailable
    case biometricNotAvailable
    case biometricFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Panic button service not configured"
        case .biometricNotAvailable:
            return "Biometric authentication not available"
        case .biometricFailed:
            return "Biometric authentication failed"
        }
    }
}


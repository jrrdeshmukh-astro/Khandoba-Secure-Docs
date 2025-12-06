//
//  PushNotificationService.swift
//  Khandoba Secure Docs
//
//  Push notification service for nominee invitations, vault access, and security alerts
//

import Foundation
import UserNotifications
import UIKit
import Combine

@MainActor
final class PushNotificationService: NSObject, ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?
    @Published var isRegistered = false
    
    static let shared = PushNotificationService()
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Registration
    
    /// Request push notification permissions
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        
        await MainActor.run {
            authorizationStatus = granted ? .authorized : .denied
        }
        
        if granted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            print("✅ Push notification authorization granted")
        } else {
            print("❌ Push notification authorization denied")
        }
        
        return granted
    }
    
    /// Register device token with APNs
    func registerDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        isRegistered = true
        
        print("✅ Device token registered: \(tokenString)")
        
        // TODO: Send token to your backend server for push notification delivery
        // sendTokenToServer(tokenString)
    }
    
    /// Handle registration failure
    func registrationFailed(error: Error) {
        isRegistered = false
        print("❌ Push notification registration failed: \(error.localizedDescription)")
    }
    
    // MARK: - Notification Handling
    
    /// Handle incoming remote notification
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        print("📬 Received remote notification")
        
        guard let aps = userInfo["aps"] as? [String: Any] else {
            return .noData
        }
        
        // Handle different notification types
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "nominee_invitation":
                await handleNomineeInvitationNotification(userInfo)
            case "vault_opened":
                await handleVaultOpenedNotification(userInfo)
            case "vault_locked":
                await handleVaultLockedNotification(userInfo)
            case "nominee_accepted":
                await handleNomineeAcceptedNotification(userInfo)
            case "security_alert":
                await handleSecurityAlertNotification(userInfo)
            default:
                print("⚠️ Unknown notification type: \(notificationType)")
            }
        }
        
        return .newData
    }
    
    // MARK: - Notification Types
    
    private func handleNomineeInvitationNotification(_ userInfo: [AnyHashable: Any]) async {
        print("📧 Nominee invitation notification")
        if let token = userInfo["inviteToken"] as? String {
            print("   Token: \(token)")
            // Post notification for UI to handle
            NotificationCenter.default.post(
                name: .nomineeInvitationReceived,
                object: nil,
                userInfo: ["token": token]
            )
        }
    }
    
    private func handleVaultOpenedNotification(_ userInfo: [AnyHashable: Any]) async {
        print("🔓 Vault opened notification")
        if let vaultID = userInfo["vaultID"] as? String {
            print("   Vault ID: \(vaultID)")
            NotificationCenter.default.post(
                name: .vaultOpenedByNominee,
                object: nil,
                userInfo: ["vaultID": vaultID]
            )
        }
    }
    
    private func handleVaultLockedNotification(_ userInfo: [AnyHashable: Any]) async {
        print("🔒 Vault locked notification")
        if let vaultID = userInfo["vaultID"] as? String {
            print("   Vault ID: \(vaultID)")
            NotificationCenter.default.post(
                name: .vaultLockedByOwner,
                object: nil,
                userInfo: ["vaultID": vaultID]
            )
        }
    }
    
    private func handleNomineeAcceptedNotification(_ userInfo: [AnyHashable: Any]) async {
        print("✅ Nominee accepted notification")
        if let nomineeID = userInfo["nomineeID"] as? String {
            print("   Nominee ID: \(nomineeID)")
            NotificationCenter.default.post(
                name: .nomineeAcceptedInvitation,
                object: nil,
                userInfo: ["nomineeID": nomineeID]
            )
        }
    }
    
    private func handleSecurityAlertNotification(_ userInfo: [AnyHashable: Any]) async {
        print("🚨 Security alert notification")
        if let alertType = userInfo["alertType"] as? String {
            print("   Alert Type: \(alertType)")
            NotificationCenter.default.post(
                name: .securityAlertReceived,
                object: nil,
                userInfo: userInfo
            )
        }
    }
    
    // MARK: - Local Notifications
    
    /// Send local notification for nominee invitation
    func sendNomineeInvitationNotification(token: String, vaultName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Vault Invitation"
        content.body = "You've been invited to access vault: \(vaultName)"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "nominee_invitation",
            "inviteToken": token,
            "vaultName": vaultName
        ]
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error.localizedDescription)")
            } else {
                print("✅ Nominee invitation notification sent")
            }
        }
    }
    
    /// Send local notification for vault access
    func sendVaultAccessNotification(vaultName: String, openedBy: String) {
        let content = UNMutableNotificationContent()
        content.title = "Vault Opened"
        content.body = "\(openedBy) opened vault: \(vaultName)"
        content.sound = .default
        content.userInfo = [
            "type": "vault_opened",
            "vaultName": vaultName,
            "openedBy": openedBy
        ]
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Send security alert notification
    func sendSecurityAlertNotification(title: String, body: String, threatType: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "security_alert",
            "threatType": threatType
        ]
        
        // Request critical alert permission for high-priority threats
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send security alert: \(error.localizedDescription)")
            } else {
                print("✅ Security alert sent: \(title)")
            }
        }
    }
    
    // MARK: - Status
    
    private func checkAuthorizationStatus() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            await MainActor.run {
                authorizationStatus = settings.authorizationStatus
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        Task { @MainActor in
            await handleRemoteNotification(userInfo)
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let nomineeInvitationReceived = Notification.Name("nomineeInvitationReceived")
    static let vaultOpenedByNominee = Notification.Name("vaultOpenedByNominee")
    static let vaultLockedByOwner = Notification.Name("vaultLockedByOwner")
    static let nomineeAcceptedInvitation = Notification.Name("nomineeAcceptedInvitation")
    static let securityAlertReceived = Notification.Name("securityAlertReceived")
}

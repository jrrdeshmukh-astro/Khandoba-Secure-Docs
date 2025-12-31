//
//  PushNotificationService.swift
//  Khandoba Secure Docs
//
//  Push notification service for nominee invitations, vault access, and security alerts
//

import Foundation
import UserNotifications
import Combine

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Platform-agnostic background fetch result
enum BackgroundFetchResult {
    case newData
    case noData
    case failed
}

#if os(iOS) || os(tvOS)
extension BackgroundFetchResult {
    var uiBackgroundFetchResult: UIBackgroundFetchResult {
        switch self {
        case .newData: return .newData
        case .noData: return .noData
        case .failed: return .failed
        }
    }
}
#endif

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
            #if APP_EXTENSION
            // In extension, skip registration
            print(" Push notification registration skipped in extension")
            #else
            // Register for remote notifications only in main app
            registerForRemoteNotificationsMainApp()
            #endif
            print(" Push notification authorization granted")
        } else {
            print(" Push notification authorization denied")
        }
        
        return granted
    }
    
    /// Register device token with APNs
    func registerDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        isRegistered = true
        
        print(" Device token registered: \(tokenString)")
        
        // Store device token locally for CloudKit-based push notifications
        // Since the app uses CloudKit for sync, device tokens are managed by Apple's push service
        // CloudKit subscriptions will automatically use this token for remote notifications
        storeDeviceTokenLocally(tokenString)
    }
    
    /// Store device token locally for CloudKit push notifications
    /// CloudKit will automatically use this token when processing subscription notifications
    private func storeDeviceTokenLocally(_ token: String) {
        let defaults = UserDefaults(suiteName: AppConfig.appGroupIdentifier)
        defaults?.set(token, forKey: "devicePushToken")
        defaults?.set(Date(), forKey: "deviceTokenRegisteredAt")
        
        print(" Device token stored locally for CloudKit push notifications")
        print("   CloudKit subscriptions will use this token automatically")
        
        // Note: CloudKit handles push notification delivery automatically when:
        // 1. CloudKit subscriptions are created (via SwiftData sync)
        // 2. Records change in the CloudKit database
        // 3. Apple's push service delivers notifications to registered devices
        // No custom backend server is required for CloudKit-based apps
    }
    
    /// Handle registration failure
    func registrationFailed(error: Error) {
        isRegistered = false
        print(" Push notification registration failed: \(error.localizedDescription)")
    }
    
    // MARK: - Notification Handling
    
    /// Handle incoming remote notification
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async -> BackgroundFetchResult {
        print("📬 Received remote notification")
        
        guard userInfo["aps"] as? [String: Any] != nil else {
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
                print(" Unknown notification type: \(notificationType)")
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
        print(" Vault locked notification")
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
        print(" Nominee accepted notification")
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
        print(" Security alert notification")
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
                print(" Failed to send notification: \(error.localizedDescription)")
            } else {
                print(" Nominee invitation notification sent")
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
    
    /// Send notification when nominee accepts invitation
    func sendNomineeAcceptedNotification(nomineeName: String, vaultName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Nominee Accepted"
        content.body = "\(nomineeName) accepted access to vault: \(vaultName)"
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "type": "nominee_accepted",
            "nomineeName": nomineeName,
            "vaultName": vaultName
        ]
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(" Failed to send nominee accepted notification: \(error.localizedDescription)")
            } else {
                print(" Nominee accepted notification sent: \(nomineeName) → \(vaultName)")
            }
        }
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
                print(" Failed to send security alert: \(error.localizedDescription)")
            } else {
                print(" Security alert sent: \(title)")
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
    
    // MARK: - Helper Methods (Conditionally Compiled)
    
    #if !APP_EXTENSION
    /// Register for remote notifications (main app only)
    @MainActor
    private func registerForRemoteNotificationsMainApp() {
        #if os(iOS) || os(tvOS)
        UIApplication.shared.registerForRemoteNotifications()
        #elseif os(macOS)
        NSApplication.shared.registerForRemoteNotifications(matching: [.alert, .sound, .badge])
        #endif
    }
    #else
    /// Register for remote notifications (dummy for extension)
    @MainActor
    private func registerForRemoteNotificationsMainApp() {
        // Not available in extension
    }
    #endif
}

// MARK: - Notification Names

extension Notification.Name {
    static let nomineeInvitationReceived = Notification.Name("nomineeInvitationReceived")
    static let vaultOpenedByNominee = Notification.Name("vaultOpenedByNominee")
    static let vaultLockedByOwner = Notification.Name("vaultLockedByOwner")
    static let nomineeAcceptedInvitation = Notification.Name("nomineeAcceptedInvitation")
    static let securityAlertReceived = Notification.Name("securityAlertReceived")
}

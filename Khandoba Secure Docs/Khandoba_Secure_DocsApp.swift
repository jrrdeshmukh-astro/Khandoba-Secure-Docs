//
//  Khandoba_Secure_DocsApp.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData
import Combine
import UserNotifications
import CloudKit

@main
struct Khandoba_Secure_DocsApp: App {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var pushNotificationService = PushNotificationService.shared
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            UserRole.self,
            Vault.self,
            VaultSession.self,
            VaultAccessLog.self,
            DualKeyRequest.self,
            Document.self,
            DocumentVersion.self,
            ChatMessage.self,
            Nominee.self,
            VaultTransferRequest.self,
            EmergencyAccessRequest.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic  // Enable CloudKit sync for nominee invitations and cross-device sync
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print(" ModelContainer created successfully with CloudKit sync enabled")
            print("   CloudKit Container: \(AppConfig.cloudKitContainer)")
            return container
        } catch {
            // Log error and provide fallback
            print(" ModelContainer creation failed: \(error.localizedDescription)")
            print(" Falling back to local-only storage (CloudKit sync disabled)")
            // Try local-only fallback (no CloudKit)
            do {
                let localConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )
                let container = try ModelContainer(for: schema, configurations: [localConfig])
                print(" Fallback: Using local-only storage")
                return container
            } catch {
                print(" Even local container failed: \(error.localizedDescription)")
                // Last resort: in-memory container
                do {
                    let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    let container = try ModelContainer(for: schema, configurations: [memoryConfig])
                    print(" Last resort: Using in-memory storage (data will be lost on app close)")
                    return container
                } catch {
                    print(" All container creation attempts failed")
                    // Absolute last resort: minimal container
                    let minimalSchema = Schema([User.self, UserRole.self])
                    return try! ModelContainer(for: minimalSchema, configurations: [ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)])
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(pushNotificationService)
                .environment(\.unifiedTheme, UnifiedTheme())
                .onAppear {
                    authService.configure(modelContext: sharedModelContainer.mainContext)
                    setupPushNotifications()
                }
                .preferredColorScheme(.dark) // Force dark theme
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func setupPushNotifications() {
        Task {
            do {
                let granted = try await pushNotificationService.requestAuthorization()
                if granted {
                    print(" Push notifications enabled")
                }
            } catch {
                print(" Push notification setup failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - AppDelegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = PushNotificationService.shared
        return true
    }
    
    // Handle device token registration
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationService.shared.registerDeviceToken(deviceToken)
        }
    }
    
    // Handle registration failure
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            PushNotificationService.shared.registrationFailed(error: error)
        }
    }
    
    // Handle remote notification when app is in background
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            let result = await PushNotificationService.shared.handleRemoteNotification(userInfo)
            completionHandler(result)
        }
    }
    
    // MARK: - CloudKit Share Invitation Handling
    
    /// Handle CloudKit share invitations when app is opened from a share URL
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        print("📥 CloudKit share invitation received")
        print("   Share record: \(cloudKitShareMetadata.share.recordID.recordName)")
        print("   Root record: \(cloudKitShareMetadata.rootRecordID.recordName)")
        
        // Post notification to handle share acceptance
        NotificationCenter.default.post(
            name: .cloudKitShareInvitationReceived,
            object: nil,
            userInfo: ["metadata": cloudKitShareMetadata]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cloudKitShareInvitationReceived = Notification.Name("cloudKitShareInvitationReceived")
}

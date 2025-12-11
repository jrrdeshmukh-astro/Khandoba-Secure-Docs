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
import UIKit

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
        // Use App Group for shared storage with extensions
        let appGroupIdentifier = "group.com.khandoba.securedocs"
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier),
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
                let appGroupIdentifier = "group.com.khandoba.securedocs"
                
                let localConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    groupContainer: .identifier(appGroupIdentifier),
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
        
        // Force dark mode for system alerts and modals
        // This ensures the "Sign in to Apple Account" modal matches the app's dark theme
        configureDarkModeAppearance()
        
        return true
    }
    
    private func configureDarkModeAppearance() {
        if #available(iOS 13.0, *) {
            // Set window appearance to dark for all windows
            // Skip in app extensions where UIApplication.shared is unavailable
            // Use compile-time check to completely exclude UIApplication.shared in extensions
            #if !APP_EXTENSION
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = .dark
                }
            }
            #endif
            
            // Configure UITextField appearance in alerts for dark mode
            let textFieldAppearance = UITextField.appearance(whenContainedInInstancesOf: [UIAlertController.self])
            textFieldAppearance.overrideUserInterfaceStyle = .dark
            
            // Configure UIButton appearance in alerts for dark mode
            let buttonAppearance = UIButton.appearance(whenContainedInInstancesOf: [UIAlertController.self])
            buttonAppearance.overrideUserInterfaceStyle = .dark
            
            // Also set for any future windows
            NotificationCenter.default.addObserver(
                forName: UIWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { notification in
                if let window = notification.object as? UIWindow {
                    window.overrideUserInterfaceStyle = .dark
                }
            }
            
            print("✅ Dark mode enforced for system alerts, modals, and all windows")
        }
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
    
    /// Helper to get root record name from CloudKit share metadata
    /// Note: rootRecordID is deprecated in iOS 16.0+, but still functional
    /// Using it for compatibility - no replacement API available yet
    private func getRootRecordName(from metadata: CKShare.Metadata) -> String {
        // Suppress deprecation warning - API is still functional
        // This deprecation warning is expected and can be safely ignored
        #if swift(>=5.9)
        // Access deprecated API - still functional, no replacement available
        return metadata.rootRecordID.recordName
        #else
        return metadata.rootRecordID.recordName
        #endif
    }
    
    /// Handle CloudKit share invitations when app is opened from a share URL
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        print("📥 CloudKit share invitation received")
        print("   Share record: \(cloudKitShareMetadata.share.recordID.recordName)")
        // Access via helper to minimize deprecation warning scope
        let rootRecordName = getRootRecordName(from: cloudKitShareMetadata)
        print("   Root record: \(rootRecordName)")
        
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
    static let navigateToVault = Notification.Name("navigateToVault")
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}

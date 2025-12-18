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
    @StateObject private var supabaseService = SupabaseService()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // SwiftData ModelContainer - only used when useSupabase = false
    var sharedModelContainer: ModelContainer? {
        // Skip SwiftData initialization if using Supabase
        guard !AppConfig.useSupabase else { return nil }
        
        return {
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
            VaultAccessRequest.self,
            EmergencyAccessRequest.self
        ])
        // Use App Group for shared storage with extensions
        let appGroupIdentifier = "group.com.khandoba.securedocs"
        
        // Explicitly specify CloudKit container for sync
        let cloudKitContainer = AppConfig.cloudKitContainer
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier),
            cloudKitDatabase: .private(cloudKitContainer)  // Explicitly use private CloudKit database with container identifier
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ModelContainer created successfully with CloudKit sync enabled")
            print("   CloudKit Container: \(cloudKitContainer)")
            print("   App Group: \(appGroupIdentifier)")
            
            // Verify CloudKit is actually enabled
            if let config = container.configurations.first {
                let cloudKitDB = config.cloudKitDatabase
                print("   ✅ CloudKit Database: \(cloudKitDB)")
            }
            
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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(pushNotificationService)
                .environmentObject(supabaseService)
                .environment(\.unifiedTheme, UnifiedTheme())
                .onAppear {
                    // Initialize Supabase if enabled
                    if AppConfig.useSupabase {
                        Task {
                            do {
                                try await supabaseService.configure()
                                print("✅ Supabase initialized successfully")
                                
                                // Configure authentication service AFTER Supabase is initialized
                                await MainActor.run {
                                    authService.configure(supabaseService: supabaseService)
                                }
                            } catch {
                                print("⚠️ Supabase initialization failed: \(error.localizedDescription)")
                                print("   Falling back to SwiftData/CloudKit")
                            }
                        }
                    } else {
                        // SwiftData/CloudKit mode
                        if let modelContext = sharedModelContainer?.mainContext {
                            authService.configure(modelContext: modelContext)
                        }
                    }
                    
                    setupPushNotifications()
                    
                    // Only verify CloudKit if not using Supabase
                    if !AppConfig.useSupabase {
                    verifyCloudKitSetup()
                    }
        }
        .preferredColorScheme(.dark) // Force dark theme
        }
        .modelContainer(sharedModelContainer ?? createMinimalModelContainer())
    }
    
    // Create a minimal ModelContainer for Supabase mode (when SwiftData is not used)
    private func createMinimalModelContainer() -> ModelContainer {
        let schema = Schema([User.self, UserRole.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
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
    
    // MARK: - CloudKit Verification
    
    private func verifyCloudKitSetup() {
        Task {
            let containerIdentifier = AppConfig.cloudKitContainer
            let container = CKContainer(identifier: containerIdentifier)
            
            // Check account status
            do {
                let accountStatus = try await container.accountStatus()
                switch accountStatus {
                case .available:
                    print("✅ iCloud account is available - CloudKit sync should work")
                case .noAccount:
                    print("⚠️ No iCloud account signed in - CloudKit sync will not work")
                    print("   User needs to sign in to iCloud in Settings")
                case .restricted:
                    print("⚠️ iCloud account is restricted - CloudKit sync may be limited")
                case .couldNotDetermine:
                    print("⚠️ Could not determine iCloud account status")
                case .temporarilyUnavailable:
                    print("⚠️ iCloud account is temporarily unavailable")
                @unknown default:
                    print("⚠️ Unknown iCloud account status")
                }
                
                // Try to fetch user record to verify container is accessible
                if accountStatus == .available {
                    do {
                        let _ = try await container.userRecordID()
                        print("✅ CloudKit container is accessible and configured correctly")
                    } catch {
                        print("⚠️ Could not access CloudKit user record: \(error.localizedDescription)")
                        print("   This might indicate a configuration issue")
                    }
                }
            } catch {
                print("❌ Error checking CloudKit account status: \(error.localizedDescription)")
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
        
        // Setup memory pressure monitoring
        setupMemoryPressureMonitoring()
        
        return true
    }
    
    private func setupMemoryPressureMonitoring() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: .main)
        source.setEventHandler {
            let event = source.mask
            if event.contains(.warning) {
                Task { @MainActor in
                    DataOptimizationService.cleanupCacheIfNeeded(maxSize: 5_000_000) // More aggressive cleanup
                }
            } else if event.contains(.critical) {
                Task { @MainActor in
                    DataOptimizationService.handleMemoryPressure()
                }
            }
        }
        source.resume()
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
    
    /// Helper to get root record ID from metadata (handles iOS 16+ deprecation)
    private func getRootRecordID(from metadata: CKShare.Metadata) -> CKRecord.ID {
        if #available(iOS 16.0, *) {
            if let hierarchicalID = metadata.hierarchicalRootRecordID {
                return hierarchicalID
            }
        }
        // Fallback to deprecated rootRecordID for iOS < 16 or when hierarchical is nil
        return metadata.rootRecordID
    }
    
    /// Helper to get root record name from CloudKit share metadata
    private func getRootRecordName(from metadata: CKShare.Metadata) -> String {
        return getRootRecordID(from: metadata).recordName
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
// Note: Notification names moved to Config/NotificationNames.swift for sharing with extensions

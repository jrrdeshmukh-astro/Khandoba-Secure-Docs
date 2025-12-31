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

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@main
struct Khandoba_Secure_DocsApp: App {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var pushNotificationService = PushNotificationService.shared
    @StateObject private var migrationService = DataMigrationService()
    @StateObject private var deviceManagementService = DeviceManagementService()
    @StateObject private var complianceDetectionService = ComplianceDetectionService()
    
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(tvOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    // SwiftData ModelContainer with CloudKit sync
    // iOS-ONLY: Using CloudKit + SwiftData for seamless iCloud integration
    // Use lazy static to ensure single instance (prevents multiple CloudKit handler registrations)
    private static var _sharedModelContainer: ModelContainer?
    
    var sharedModelContainer: ModelContainer {
        if let existing = Self._sharedModelContainer {
            return existing
        }
        let container = Self.createModelContainer()
        Self._sharedModelContainer = container
        return container
    }
    
    private static func createModelContainer() -> ModelContainer {
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
            EmergencyAccessRequest.self,
            EmergencyAccessPass.self,
            Device.self
        ])
        // Use App Group for shared storage with extensions
        let appGroupIdentifier = "group.com.khandoba.securedocs"
        
        // Ensure Application Support directory exists in App Group
        // This prevents CoreData errors when creating the store file
        // Wrap in do-catch to handle any potential errors gracefully
        do {
            if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
                let appSupportURL = appGroupURL.appendingPathComponent("Library/Application Support", isDirectory: true)
                try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            // Log but don't crash - ModelContainer will handle directory creation if needed
            print("⚠️ Could not pre-create Application Support directory: \(error.localizedDescription)")
            print("   ModelContainer will attempt to create it automatically")
        }
        
        // Explicitly specify CloudKit container for sync
        // Try CloudKit first, fallback to local storage if it fails (e.g., no iCloud account)
        let cloudKitContainer = AppConfig.cloudKitContainer
        
        // Try CloudKit first
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier),
            cloudKitDatabase: .private(cloudKitContainer)
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
            // CloudKit setup failed (likely no iCloud account in simulator)
            // Fallback to local-only storage
            print("⚠️ CloudKit setup failed: \(error.localizedDescription)")
            print("   Falling back to local-only storage (CloudKit sync disabled)")
            
            // Fallback to local-only storage (no CloudKit)
            do {
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier(appGroupIdentifier),
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: [localConfig])
            print("✅ Using local-only storage (CloudKit not available)")
            return container
        } catch {
            print("⚠️ Local container failed: \(error.localizedDescription)")
            // Last resort: in-memory container
            do {
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: schema, configurations: [memoryConfig])
                print("⚠️ Using in-memory storage (data will be lost on app close)")
                return container
            } catch {
                print("❌ All container creation attempts failed: \(error.localizedDescription)")
                // Absolute last resort: minimal in-memory container
                let minimalSchema = Schema([User.self, UserRole.self])
                do {
                    let minimalConfig = ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)
                    return try ModelContainer(for: minimalSchema, configurations: [minimalConfig])
                } catch {
                    // If even this fails, we have a serious problem
                    print("❌ CRITICAL: Even minimal container failed: \(error.localizedDescription)")
                    // Create the most basic possible container
                    let basicSchema = Schema([User.self])
                    do {
                        return try ModelContainer(for: basicSchema, configurations: [ModelConfiguration(schema: basicSchema, isStoredInMemoryOnly: true)])
                    } catch {
                        // Absolute last resort
                        print("❌ FATAL: Even absolute minimal container failed: \(error.localizedDescription)")
                        // This should never fail, but if it does, we'll use the most basic possible container
                        let minimalSchema = Schema([User.self])
                        return try! ModelContainer(for: minimalSchema, configurations: [ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)])
                    }
                }
            }
        }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(pushNotificationService)
                .environmentObject(deviceManagementService)
                .environmentObject(complianceDetectionService)
                .environment(\.unifiedTheme, UnifiedTheme())
                .onAppear {
                    // iOS-ONLY: Using SwiftData/CloudKit exclusively
                    // Access modelContext - container is guaranteed to be initialized
                    let modelContext = sharedModelContainer.mainContext
                    authService.configure(modelContext: modelContext)
                    complianceDetectionService.configure(modelContext: modelContext)
                    
                    // Configure device management when user is authenticated
                    if let userID = authService.currentUser?.id {
                        deviceManagementService.configure(modelContext: modelContext, userID: userID)
                    }
                    
                    setupPushNotifications()
                    verifyCloudKitSetup()
                    
                    #if os(macOS)
                    configureMacOSMenuBar()
                    #endif
                }
                .preferredColorScheme(.dark) // Force dark theme
                .modelContainer(sharedModelContainer)
        }
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

// MARK: - AppDelegate
// Platform-specific app delegates are in:
// - App/AppDelegate_iOS.swift
// - App/AppDelegate_macOS.swift  
// - App/AppDelegate_tvOS.swift

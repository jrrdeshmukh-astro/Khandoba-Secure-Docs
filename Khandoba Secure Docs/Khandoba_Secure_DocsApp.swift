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
    @StateObject private var supabaseService = SupabaseService()
    @StateObject private var migrationService = DataMigrationService()
    
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(tvOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
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
                                
                                // Check and perform migration if needed (users upgrading from 1.0.0)
                                if let modelContext = sharedModelContainer?.mainContext {
                                    // Create DataMergeService for migration
                                    let dataMergeService = DataMergeService()
                                    await MainActor.run {
                                        dataMergeService.configure(supabaseService: supabaseService, modelContext: modelContext)
                                        migrationService.configure(
                                            modelContext: modelContext,
                                            supabaseService: supabaseService,
                                            dataMergeService: dataMergeService
                                        )
                                    }
                                    
                                    if migrationService.needsMigration() {
                                        print("🔄 Migration needed - user upgrading from version 1.0.0")
                                        do {
                                            try await migrationService.migrateFromCloudKitToSupabase()
                                            print("✅ Migration completed successfully")
                                        } catch {
                                            print("⚠️ Migration failed: \(error.localizedDescription)")
                                            // Continue anyway - user can retry later
                                        }
                                    } else {
                                        print("ℹ️ No migration needed - user already on version 1.0.1")
                                    }
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
                    
                    #if os(macOS)
                    configureMacOSMenuBar()
                    #endif
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

// MARK: - AppDelegate
// Platform-specific app delegates are in:
// - App/AppDelegate_iOS.swift
// - App/AppDelegate_macOS.swift  
// - App/AppDelegate_tvOS.swift

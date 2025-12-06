//
//  Khandoba_Secure_DocsApp.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData
import Combine

@main
struct Khandoba_Secure_DocsApp: App {
    @StateObject private var authService = AuthenticationService()
    
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
            print("✅ ModelContainer created successfully with CloudKit sync enabled")
            print("   CloudKit Container: \(AppConfig.cloudKitContainer)")
            return container
        } catch {
            // Log error and provide fallback
            print("❌ ModelContainer creation failed: \(error.localizedDescription)")
            print("⚠️ Falling back to local-only storage (CloudKit sync disabled)")
            // Try local-only fallback (no CloudKit)
            do {
                let localConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )
                let container = try ModelContainer(for: schema, configurations: [localConfig])
                print("✅ Fallback: Using local-only storage")
                return container
            } catch {
                print("❌ Even local container failed: \(error.localizedDescription)")
                // Last resort: in-memory container
                do {
                    let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    let container = try ModelContainer(for: schema, configurations: [memoryConfig])
                    print("⚠️ Last resort: Using in-memory storage (data will be lost on app close)")
                    return container
                } catch {
                    print("❌ All container creation attempts failed")
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
                .environment(\.unifiedTheme, UnifiedTheme())
                .onAppear {
                    authService.configure(modelContext: sharedModelContainer.mainContext)
                }
                .preferredColorScheme(.dark) // Force dark theme
        }
        .modelContainer(sharedModelContainer)
    }
}

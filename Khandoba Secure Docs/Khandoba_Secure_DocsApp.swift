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
            cloudKitDatabase: .none  // Disable CloudKit for v1.0, add in v1.1
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Log error and provide fallback
            print("❌ ModelContainer creation failed: \(error.localizedDescription)")
            // Try in-memory fallback
            do {
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [memoryConfig])
            } catch {
                print("❌ Even in-memory container failed: \(error.localizedDescription)")
                // Last resort: minimal container
                let minimalSchema = Schema([User.self, UserRole.self])
                return try! ModelContainer(for: minimalSchema, configurations: [ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)])
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

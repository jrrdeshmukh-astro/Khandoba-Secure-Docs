//
//  ClientMainView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct ClientMainView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var vaultService = VaultService()
    @StateObject private var documentService = DocumentService()
    @StateObject private var chatService = ChatService()
    @StateObject private var shareExtensionService = ShareExtensionService()
    
    @State private var selectedTab = 0
    @AppStorage("hasCompletedClientOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        TabView(selection: $selectedTab) {
            // Dashboard
            ClientDashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Vaults
            VaultListView()
                .tabItem {
                    Label("Vaults", systemImage: "lock.shield.fill")
                }
                .tag(1)
            
            // Documents
            DocumentSearchView()
                .tabItem {
                    Label("Documents", systemImage: "doc.fill")
                }
                .tag(2)
            
            // Triage
            TriageView()
                .tabItem {
                    Label("Triage", systemImage: "cross.case.fill")
                }
                .tag(3)
            
            // Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(4)
        }
        .tint(colors.primary)
        .onAppear {
            configureServices()
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .environmentObject(vaultService)
        .environmentObject(documentService)
        .environmentObject(chatService)
        .fullScreenCover(isPresented: $showOnboarding) {
            ClientOnboardingView()
        }
    }
    
    private func configureServices() {
        guard let userID = authService.currentUser?.id else { return }
        
        vaultService.configure(modelContext: modelContext, userID: userID)
        documentService.configure(modelContext: modelContext, userID: userID)
        chatService.configure(modelContext: modelContext, userID: userID)
        shareExtensionService.configure(modelContext: modelContext, userID: userID)
        
        // Sync vaults to share extension and process pending uploads
        Task {
            await syncVaultsToExtension()
            await shareExtensionService.processPendingUploads()
        }
    }
    
    private func syncVaultsToExtension() async {
        do {
            try await vaultService.loadVaults()
            // Filter out system vaults
            let userVaults = vaultService.vaults.filter { !$0.isSystemVault }
            shareExtensionService.syncVaultsToExtension(vaults: userVaults)
        } catch {
            print(" Failed to sync vaults to extension: \(error.localizedDescription)")
        }
    }
}


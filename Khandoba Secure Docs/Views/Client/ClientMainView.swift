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
    @EnvironmentObject var supabaseService: SupabaseService
    
    @StateObject private var vaultService = VaultService()
    @StateObject private var documentService = DocumentService()
    @StateObject private var chatService = ChatService()
    @StateObject private var contentFilterService = ContentFilterService()
    @StateObject private var subscriptionService = SubscriptionService()
    
    #if os(tvOS)
    @StateObject private var focusCoordinator = FocusEngineCoordinator()
    #endif
    
    @State private var selectedTab = 0
    @AppStorage("hasCompletedClientOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var navigateToVaultID: UUID?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        #if os(tvOS)
        // Apple TV: Use sidebar navigation instead of TabView
        NavigationSplitView {
            sidebarView(colors: colors)
        } detail: {
            detailView(colors: colors)
        }
        .environmentObject(focusCoordinator)
        #else
        // iOS/macOS: Use TabView
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
        #endif
        .onAppear {
            configureServices()
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToVault)) { notification in
            if let vaultID = notification.userInfo?["vaultID"] as? UUID {
                // Switch to vaults tab and navigate to the vault
                selectedTab = 1 // Vaults tab
                navigateToVaultID = vaultID
            }
        }
        .onChange(of: navigateToVaultID) { oldValue, newValue in
            if newValue != nil {
                // Post notification to VaultListView to navigate
                NotificationCenter.default.post(
                    name: .navigateToVault,
                    object: nil,
                    userInfo: ["vaultID": newValue!]
                )
                navigateToVaultID = nil
            }
        }
        .environmentObject(vaultService)
        .environmentObject(documentService)
        .environmentObject(chatService)
        .fullScreenCover(isPresented: $showOnboarding) {
            ClientOnboardingView()
        }
    }
    
    #if os(tvOS)
    @ViewBuilder
    private func sidebarView(colors: UnifiedTheme.ColorSet) -> some View {
        List {
            NavigationLink(value: 0) {
                Label("Home", systemImage: "house.fill")
                    .font(.title2)
            }
            NavigationLink(value: 1) {
                Label("Vaults", systemImage: "lock.shield.fill")
                    .font(.title2)
            }
            NavigationLink(value: 2) {
                Label("Documents", systemImage: "doc.fill")
                    .font(.title2)
            }
            NavigationLink(value: 3) {
                Label("Triage", systemImage: "cross.case.fill")
                    .font(.title2)
            }
            NavigationLink(value: 4) {
                Label("Profile", systemImage: "person.circle.fill")
                    .font(.title2)
            }
        }
        .navigationTitle("Khandoba")
    }
    
    @ViewBuilder
    private func detailView(colors: UnifiedTheme.ColorSet) -> some View {
        Group {
            switch selectedTab {
            case 0:
                ClientDashboardView()
            case 1:
                VaultListView()
            case 2:
                DocumentSearchView()
            case 3:
                TriageView()
            case 4:
                ProfileView()
            default:
                ClientDashboardView()
            }
        }
        .environmentObject(vaultService)
        .environmentObject(documentService)
        .environmentObject(chatService)
    }
    #endif
    
    private func configureServices() {
        guard let userID = authService.currentUser?.id else { return }
        
        // Configure services based on backend mode
        if AppConfig.useSupabase {
            // Supabase mode
            vaultService.configure(supabaseService: supabaseService, userID: userID)
            documentService.configure(supabaseService: supabaseService, userID: userID, contentFilterService: contentFilterService, subscriptionService: subscriptionService)
            chatService.configure(supabaseService: supabaseService, userID: userID)
        } else {
            // SwiftData/CloudKit mode
            subscriptionService.configure(modelContext: modelContext)
            vaultService.configure(modelContext: modelContext, userID: userID)
            documentService.configure(modelContext: modelContext, userID: userID, contentFilterService: contentFilterService, subscriptionService: subscriptionService)
            chatService.configure(modelContext: modelContext, userID: userID)
        }
        
        // Load subscription status
        Task {
            await subscriptionService.loadProducts()
            await subscriptionService.updatePurchasedProducts()
        }
    }
}


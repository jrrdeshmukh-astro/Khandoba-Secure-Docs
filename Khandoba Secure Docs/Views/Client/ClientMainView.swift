//
//  ClientMainView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct ClientMainView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var vaultService = VaultService()
    @StateObject private var documentService = DocumentService()
    @StateObject private var chatService = ChatService()
    @StateObject private var contentFilterService = ContentFilterService()
    @StateObject private var subscriptionService = SubscriptionService()
    
    #if os(tvOS)
    @State private var selectedSidebarItem: Int? = 0
    #endif
    
    @State private var selectedTab = 0
    @AppStorage("hasCompletedClientOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var navigateToVaultID: UUID?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Group {
            #if os(tvOS)
            // Apple TV: Use sidebar navigation instead of TabView
            NavigationSplitView {
                sidebarView(colors: colors)
            } detail: {
                detailView(colors: colors)
            }
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
        }
        .onAppear {
            configureServices()
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToVault)) { notification in
            if let vaultID = notification.userInfo?["vaultID"] as? UUID {
                #if !os(tvOS)
                // Switch to vaults tab and navigate to the vault (iOS/macOS only)
                selectedTab = 1 // Vaults tab
                #endif
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
        #if os(iOS) || os(tvOS)
        .fullScreenCover(isPresented: $showOnboarding) {
            Text("Welcome to Khandoba Secure Docs")
                .onAppear {
                    hasCompletedOnboarding = true
                    showOnboarding = false
                }
        }
        #else
        .sheet(isPresented: $showOnboarding) {
            Text("Welcome to Khandoba Secure Docs")
                .onAppear {
                    hasCompletedOnboarding = true
                    showOnboarding = false
                }
        }
        #endif
    }
    
    #if os(tvOS)
    @ViewBuilder
    private func sidebarView(colors: UnifiedTheme.Colors) -> some View {
        List(selection: $selectedSidebarItem) {
            NavigationLink(value: 0) {
                Label("Home", systemImage: "house.fill")
                    .font(.title2)
                    .padding(.vertical, 8)
            }
            NavigationLink(value: 1) {
                Label("Vaults", systemImage: "lock.shield.fill")
                    .font(.title2)
                    .padding(.vertical, 8)
            }
            NavigationLink(value: 2) {
                Label("Documents", systemImage: "doc.fill")
                    .font(.title2)
                    .padding(.vertical, 8)
            }
            NavigationLink(value: 3) {
                Label("Triage", systemImage: "cross.case.fill")
                    .font(.title2)
                    .padding(.vertical, 8)
            }
            NavigationLink(value: 4) {
                Label("Profile", systemImage: "person.circle.fill")
                    .font(.title2)
                    .padding(.vertical, 8)
            }
        }
        .navigationTitle("Khandoba")
        .listStyle(.sidebar)
        .onChange(of: selectedSidebarItem) { oldValue, newValue in
            if let newValue = newValue {
                selectedTab = newValue
            }
        }
    }
    
    @ViewBuilder
    private func detailView(colors: UnifiedTheme.Colors) -> some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    #endif
    
    private func configureServices() {
        guard let userID = authService.currentUser?.id else { return }
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        subscriptionService.configure(modelContext: modelContext)
        vaultService.configure(modelContext: modelContext, userID: userID)
        documentService.configure(modelContext: modelContext, userID: userID, contentFilterService: contentFilterService, subscriptionService: subscriptionService)
        chatService.configure(modelContext: modelContext, userID: userID)
        
        // Load subscription status
        Task {
            await subscriptionService.loadProducts()
            await subscriptionService.updatePurchasedProducts()
        }
    }
}


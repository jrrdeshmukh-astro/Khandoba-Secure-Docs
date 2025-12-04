//
//  AdminMainView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct AdminMainView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("hasCompletedAdminOnboarding") private var hasCompletedOnboarding = false
    
    @State private var showOnboarding = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        TabView {
            AdminDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
            
            AdminApprovalsView()
                .tabItem {
                    Label("Approvals", systemImage: "checkmark.shield.fill")
                }
            
            AdminChatInboxView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
            
            AdminVaultListView()
                .tabItem {
                    Label("Vaults", systemImage: "lock.shield.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
        }
        .tint(colors.primary)
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            AdminOnboardingView()
        }
    }
}

struct AdminDashboardView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.lg) {
                        Text("Admin Dashboard")
                            .font(theme.typography.title)
                            .foregroundColor(colors.textPrimary)
                            .padding()
                        
                        Text("Admin features coming soon...")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Admin Console")
        }
    }
}


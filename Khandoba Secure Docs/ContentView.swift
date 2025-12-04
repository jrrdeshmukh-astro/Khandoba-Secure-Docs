//
//  ContentView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        Group {
            if authService.isLoading {
                LoadingView("Initializing...")
            } else if !authService.isAuthenticated {
                WelcomeView()
            } else if needsAccountSetup {
                AccountSetupView()
            } else if needsSubscription {
                SubscriptionRequiredView()
            } else if authService.currentRole == nil {
                RoleSelectionView()
            } else {
                // Main App - Role based navigation
                if authService.currentRole == .client {
                    ClientMainView()
                } else {
                    AdminMainView()
                }
            }
        }
    }
    
    /// Check if user needs to complete account setup
    /// Shows AccountSetupView if name is missing or default
    private var needsAccountSetup: Bool {
        guard let user = authService.currentUser else { return false }
        
        // Check if name is missing, empty, or still default "User"
        let name = user.fullName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty || name == "User"
    }
    
    /// Check if user needs to purchase subscription
    /// Premium subscription is REQUIRED to use the app
    private var needsSubscription: Bool {
        guard let user = authService.currentUser else { return false }
        
        // Check if user has active premium subscription
        if !user.isPremiumSubscriber {
            return true
        }
        
        // Check if subscription has expired
        if let expiryDate = user.subscriptionExpiryDate {
            return expiryDate < Date()
        }
        
        return true // No subscription data = needs subscription
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
        .environmentObject(AuthenticationService())
}

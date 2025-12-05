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
    
    // Use @AppStorage to observe permissions changes
    @AppStorage("permissions_setup_complete") private var permissionsComplete = false
    
    var body: some View {
        Group {
            if authService.isLoading {
                LoadingView("Initializing...")
            } else if !authService.isAuthenticated {
                WelcomeView()
            } else if needsPermissionsSetup {
                // PERMISSIONS FIRST - right after signin
                PermissionsSetupView()
            } else if needsSubscription {
                // Then subscription
                SubscriptionRequiredView()
            } else if needsAccountSetup {
                // Then profile setup
                AccountSetupView()
            } else {
                // Main App - Single role, autopilot mode
                ClientMainView()
            }
        }
    }
    
    /// Check if user needs permissions setup
    /// Shows PermissionsSetupView after first signin
    private var needsPermissionsSetup: Bool {
        guard authService.isAuthenticated else { return false }
        
        // Use @AppStorage property to observe changes
        return !permissionsComplete
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
            return true  // Not a premium subscriber → needs subscription ✅
        }
        
        // Check if subscription has expired
        if let expiryDate = user.subscriptionExpiryDate {
            return expiryDate < Date()  // Expired → needs subscription ✅
        }
        
        // Has premium status but no expiry date = valid subscription
        // (perpetual, lifetime, or subscription without expiry tracking)
        return false  // Has active premium → doesn't need subscription ✅
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
        .environmentObject(AuthenticationService())
}

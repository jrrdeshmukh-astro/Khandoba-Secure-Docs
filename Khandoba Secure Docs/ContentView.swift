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
    
    // Deep link handling for nominee invitations and transfer requests
    @State private var pendingInviteToken: String?
    @State private var pendingTransferToken: String?
    @State private var showInvitationView = false
    @State private var showTransferView = false
    
    // Push notification handling
    @EnvironmentObject var pushNotificationService: PushNotificationService
    
    var body: some View {
        Group {
            if authService.isLoading {
                LoadingView("Initializing...")
            } else if !authService.isAuthenticated {
                WelcomeView()
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
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
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .sheet(isPresented: $showInvitationView) {
                        if let token = pendingInviteToken {
                            AcceptNomineeInvitationView(inviteToken: token)
                        }
                    }
                    .sheet(isPresented: $showTransferView) {
                        if let token = pendingTransferToken {
                            AcceptTransferView(transferToken: token)
                        }
                    }
            }
        }
        .onAppear {
            // Check for pending invitation token from previous launch
            if let token = UserDefaults.standard.string(forKey: "pending_invite_token") {
                pendingInviteToken = token
                UserDefaults.standard.removeObject(forKey: "pending_invite_token")
                if authService.isAuthenticated && !needsPermissionsSetup && !needsSubscription && !needsAccountSetup {
                    showInvitationView = true
                }
            }
            
            // Check for pending transfer token from previous launch
            if let token = UserDefaults.standard.string(forKey: "pending_transfer_token") {
                pendingTransferToken = token
                UserDefaults.standard.removeObject(forKey: "pending_transfer_token")
                if authService.isAuthenticated && !needsPermissionsSetup && !needsSubscription && !needsAccountSetup {
                    showTransferView = true
                }
            }
            
            // Listen for push notification events
            setupNotificationObservers()
        }
        .onReceive(NotificationCenter.default.publisher(for: .nomineeInvitationReceived)) { notification in
            if let token = notification.userInfo?["token"] as? String {
                handleNomineeInvitationToken(token)
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle nominee invitation and transfer deep links
        if url.scheme == "khandoba" {
            if url.host == "nominee" && url.path == "/invite" {
                // New format: khandoba://nominee/invite?token=UUID&vault=Name
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
                    handleNomineeInvitationToken(token)
                }
            } else if url.host == "invite" {
                // Legacy format: khandoba://invite?token=UUID (for backward compatibility)
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
                    handleNomineeInvitationToken(token)
                }
            } else if url.host == "transfer" {
                // Transfer format: khandoba://transfer?token=UUID
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
                    handleTransferToken(token)
                }
            }
        }
    }
    
    private func handleNomineeInvitationToken(_ token: String) {
        pendingInviteToken = token
        
        // If user is authenticated and setup is complete, show invitation view
        if authService.isAuthenticated && !needsPermissionsSetup && !needsSubscription && !needsAccountSetup {
            showInvitationView = true
        } else {
            // Store token for later (after authentication/setup)
            UserDefaults.standard.set(token, forKey: "pending_invite_token")
        }
    }
    
    private func handleTransferToken(_ token: String) {
        pendingTransferToken = token
        
        // If user is authenticated and setup is complete, show transfer view
        if authService.isAuthenticated && !needsPermissionsSetup && !needsSubscription && !needsAccountSetup {
            showTransferView = true
        } else {
            // Store token for later (after authentication/setup)
            UserDefaults.standard.set(token, forKey: "pending_transfer_token")
        }
    }
    
    private func setupNotificationObservers() {
        // Observer setup is handled by .onReceive modifier
        // This method can be used for additional setup if needed
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
            return true  // Not a premium subscriber → needs subscription 
        }
        
        // Check if subscription has expired
        if let expiryDate = user.subscriptionExpiryDate {
            return expiryDate < Date()  // Expired → needs subscription 
        }
        
        // Has premium status but no expiry date = valid subscription
        // (perpetual, lifetime, or subscription without expiry tracking)
        return false  // Has active premium → doesn't need subscription 
    }
}

#Preview {
    ContentView()
        .modelContainer(for: User.self, inMemory: true)
        .environmentObject(AuthenticationService())
}

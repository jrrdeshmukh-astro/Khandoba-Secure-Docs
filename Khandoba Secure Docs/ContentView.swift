//
//  ContentView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData
import CloudKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    // Use @AppStorage to observe permissions changes
    @AppStorage("permissions_setup_complete") private var permissionsComplete = false
    
    // Deep link handling for nominee invitations and transfer requests
    @State private var pendingInviteToken: String?
    @State private var pendingTransferToken: String?
    @State private var pendingShareURL: URL?
    @State private var showInvitationView = false
    @State private var showTransferView = false
    @State private var showCloudKitShareSuccess = false
    @State private var cloudKitShareRootRecordID: String?
    
    // CloudKit sharing service
    @StateObject private var cloudKitSharing = CloudKitSharingService()
    
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
                        } else {
                            // Fallback view if token is missing
                            VStack {
                                Text("Invalid Invitation")
                                    .font(.title)
                                Text("The invitation link is invalid or expired.")
                                    .foregroundColor(.secondary)
                                Button("Close") {
                                    showInvitationView = false
                                }
                                .padding()
                            }
                            .padding()
                        }
                    }
                    .sheet(isPresented: $showCloudKitShareSuccess) {
                        CloudKitShareSuccessView(rootRecordID: cloudKitShareRootRecordID)
                    }
                    .sheet(isPresented: $showTransferView) {
                        if let token = pendingTransferToken {
                            AcceptTransferView(transferToken: token)
                        } else {
                            // Fallback view if token is missing
                            VStack {
                                Text("Invalid Transfer Request")
                                    .font(.title)
                                Text("The transfer link is invalid or expired.")
                                    .foregroundColor(.secondary)
                                Button("Close") {
                                    showTransferView = false
                                }
                                .padding()
                            }
                            .padding()
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
            
            // Check for pending CloudKit share URL from previous launch
            if let urlData = UserDefaults.standard.data(forKey: "pending_share_url"),
               let urlString = String(data: urlData, encoding: .utf8),
               let url = URL(string: urlString) {
                pendingShareURL = url
                UserDefaults.standard.removeObject(forKey: "pending_share_url")
                if authService.isAuthenticated && !needsPermissionsSetup && !needsSubscription && !needsAccountSetup {
                    acceptCloudKitShare(url: url)
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
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitShareInvitationReceived)) { notification in
            if let metadata = notification.userInfo?["metadata"] as? CKShare.Metadata {
                handleCloudKitShareInvitation(metadata)
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep link received: \(url)")
        
        // Handle CloudKit share URLs (iCloud.com/share or khandoba://share)
        if url.absoluteString.contains("icloud.com/share") || (url.scheme == "khandoba" && url.host == "share") {
            print("   ✅ CloudKit share URL detected")
            handleCloudKitShareURL(url)
            return
        }
        
        // Handle nominee invitation and transfer deep links
        if url.scheme == "khandoba" {
            print("   Scheme: khandoba")
            print("   Host: \(url.host ?? "nil")")
            print("   Path: \(url.path)")
            
            if url.host == "nominee" && url.path == "/invite" {
                // New format: khandoba://nominee/invite?token=UUID&vault=Name
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
                    print("   ✅ Found nominee invite token: \(token)")
                    handleNomineeInvitationToken(token)
                } else {
                    print("   ❌ Failed to extract token from nominee invite URL")
                }
            } else if url.host == "invite" {
                // Legacy format: khandoba://invite?token=UUID (for backward compatibility)
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
                    print("   ✅ Found legacy invite token: \(token)")
                    handleNomineeInvitationToken(token)
                } else {
                    print("   ❌ Failed to extract token from invite URL")
                }
            } else if url.host == "transfer" {
                // Transfer format: khandoba://transfer?token=UUID
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
                    print("   ✅ Found transfer token: \(token)")
                    handleTransferToken(token)
                } else {
                    print("   ❌ Failed to extract token from transfer URL")
                }
            } else {
                print("   ⚠️ Unknown deep link host: \(url.host ?? "nil")")
            }
        } else {
            print("   ⚠️ Unknown URL scheme: \(url.scheme ?? "nil")")
        }
    }
    
    private func handleCloudKitShareURL(_ url: URL) {
        print("📥 Handling CloudKit share URL: \(url)")
        pendingShareURL = url
        
        // If user is authenticated and setup is complete, accept share immediately
        if authService.isAuthenticated && !needsPermissionsSetup && !needsSubscription && !needsAccountSetup {
            print("   ✅ User ready, accepting share")
            acceptCloudKitShare(url: url)
        } else {
            print("   ⏳ User not ready, storing share URL for later")
            // Store share URL for later
            if let urlString = url.absoluteString.data(using: .utf8) {
                UserDefaults.standard.set(urlString, forKey: "pending_share_url")
            }
        }
    }
    
    private func handleCloudKitShareInvitation(_ metadata: CKShare.Metadata) {
        print("📥 Handling CloudKit share invitation from metadata")
        
        // Accept the share using the metadata-based method (preferred)
        acceptCloudKitShare(metadata: metadata)
    }
    
    private func acceptCloudKitShare(url: URL) {
        Task {
            do {
                try await cloudKitSharing.acceptShareInvitation(from: url)
                print("   ✅ CloudKit share accepted successfully")
                
                // Extract root record ID from URL if possible
                var rootRecordID: String?
                if url.absoluteString.contains("icloud.com/share") {
                    // Try to extract from URL path
                    let pathComponents = url.pathComponents
                    if let shareIndex = pathComponents.firstIndex(of: "share"), 
                       shareIndex + 1 < pathComponents.count {
                        // The share token is in the path, but we need the root record ID
                        // For now, we'll show success without the specific vault name
                    }
                }
                
                // After accepting share, wait a moment for SwiftData to sync
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    // Show success view for CloudKit share
                    cloudKitShareRootRecordID = rootRecordID
                    showCloudKitShareSuccess = true
                }
            } catch {
                print("   ❌ Error accepting CloudKit share: \(error.localizedDescription)")
                // Fallback: try to extract token and use token-based flow
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let token = components.queryItems?.first(where: { $0.name == "token" })?.value {
                    handleNomineeInvitationToken(token)
                } else {
                    // Show success view anyway - SwiftData might still sync
                    await MainActor.run {
                        showCloudKitShareSuccess = true
                    }
                }
            }
        }
    }
    
    private func acceptCloudKitShare(metadata: CKShare.Metadata) {
        Task {
            do {
                // Process the share (iOS has already accepted it)
                try await cloudKitSharing.processShareInvitation(from: metadata)
                print("   ✅ CloudKit share processed successfully from metadata")
                
                // After processing share, wait a moment for SwiftData to sync
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    // Show success view for CloudKit share (different from token-based invitation)
                    cloudKitShareRootRecordID = metadata.rootRecordID.recordName
                    showCloudKitShareSuccess = true
                }
            } catch {
                print("   ❌ Error processing CloudKit share from metadata: \(error.localizedDescription)")
                // Even if processing fails, SwiftData might still sync
                // Show success view anyway
                await MainActor.run {
                    cloudKitShareRootRecordID = metadata.rootRecordID.recordName
                    showCloudKitShareSuccess = true
                }
            }
        }
    }
    
    private func handleNomineeInvitationToken(_ token: String) {
        print("📧 Handling nominee invitation token: \(token)")
        pendingInviteToken = token
        
        // If user is authenticated and setup is complete, show invitation view
        if authService.isAuthenticated && !needsPermissionsSetup && !needsSubscription && !needsAccountSetup {
            print("   ✅ User ready, showing invitation view")
            showInvitationView = true
        } else {
            print("   ⏳ User not ready, storing token for later")
            print("      Authenticated: \(authService.isAuthenticated)")
            print("      Needs permissions: \(needsPermissionsSetup)")
            print("      Needs subscription: \(needsSubscription)")
            print("      Needs account setup: \(needsAccountSetup)")
            // Store token for later (after authentication/setup)
            UserDefaults.standard.set(token, forKey: "pending_invite_token")
        }
    }
    
    private func handleTransferToken(_ token: String) {
        print("🔄 Handling transfer token: \(token)")
        pendingTransferToken = token
        
        // If user is authenticated and setup is complete, show transfer view
        if authService.isAuthenticated && !needsPermissionsSetup && !needsSubscription && !needsAccountSetup {
            print("   ✅ User ready, showing transfer view")
            showTransferView = true
        } else {
            print("   ⏳ User not ready, storing token for later")
            print("      Authenticated: \(authService.isAuthenticated)")
            print("      Needs permissions: \(needsPermissionsSetup)")
            print("      Needs subscription: \(needsSubscription)")
            print("      Needs account setup: \(needsAccountSetup)")
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

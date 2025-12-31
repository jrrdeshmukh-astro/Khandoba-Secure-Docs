//
//  PermissionsSetupView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import SwiftUI
import CoreLocation

struct PermissionsSetupView: View {
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthenticationService
    @AppStorage("permissions_setup_complete") private var permissionsComplete = false
    
    @StateObject private var locationService = LocationService()
    @StateObject private var pushNotificationService = PushNotificationService.shared
    @State private var isRequesting = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: UnifiedTheme.Spacing.xxl) {
                    Spacer()
                        .frame(height: UnifiedTheme.Spacing.xxl)
                    
                    // Header
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 80))
                            .foregroundColor(colors.primary)
                        
                        Text("Enable Notifications")
                            .font(theme.typography.largeTitle)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.bold)
                        
                        Text("Get alerts for vault access and invitations")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Why we need it
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text("Why we need notifications:")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        PermissionReason(
                            icon: "person.badge.plus",
                            title: "Nominee Invitations",
                            description: "Get notified when someone invites you to a vault",
                            colors: colors
                        )
                        
                        PermissionReason(
                            icon: "lock.shield.fill",
                            title: "Vault Access Alerts",
                            description: "Know when vaults are opened or locked",
                            colors: colors
                        )
                        
                        PermissionReason(
                            icon: "exclamationmark.shield.fill",
                            title: "Security Alerts",
                            description: "Immediate alerts for suspicious activity",
                            colors: colors
                        )
                        
                        PermissionReason(
                            icon: "checkmark.circle.fill",
                            title: "Status Updates",
                            description: "Get notified when nominees accept invitations",
                            colors: colors
                        )
                    }
                    .padding(UnifiedTheme.Spacing.lg)
                    .background(colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.xl)
                    .padding(.horizontal)
                    
                    // Privacy note
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(colors.success)
                            Text("Your Privacy")
                                .font(theme.typography.subheadline)
                                .foregroundColor(colors.textPrimary)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Notifications are sent only for important events. You can manage notification preferences in Settings.")
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    }
                    
                    Spacer()
                    
                    // Enable button
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        Button {
                            requestPermissions()
                        } label: {
                            HStack {
                                if isRequesting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Enable Notifications")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isRequesting)
                        
                        Button("Skip for Now") {
                            skipPermissions()
                        }
                        .font(theme.typography.body)
                        .foregroundColor(colors.textSecondary)
                    }
                    .padding(.horizontal, UnifiedTheme.Spacing.xl)
                    .padding(.bottom, UnifiedTheme.Spacing.xl)
                }
            }
        }
    }
    
    private func requestPermissions() {
        isRequesting = true
        
        Task {
            // Request push notification permission
            do {
                let granted = try await pushNotificationService.requestAuthorization()
                if granted {
                    print(" Push notification permission granted")
                } else {
                    print(" Push notification permission denied")
                }
            } catch {
                print(" Push notification request failed: \(error.localizedDescription)")
            }
            
            // Request location permission
            await locationService.requestLocationPermission()
            
            // Start tracking immediately
            locationService.startTracking()
            
            // Wait a moment to get first location
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isRequesting = false
                // Mark complete - this will trigger ContentView to move forward
                permissionsComplete = true
                print(" Permissions setup complete")
            }
        }
    }
    
    private func skipPermissions() {
        // Mark as complete even if skipped
        permissionsComplete = true
        print("Permissions skipped - using default locations")
    }
}

struct PermissionReason: View {
    let icon: String
    let title: String
    let description: String
    let colors: UnifiedTheme.Colors
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    
    var body: some View {
        HStack(alignment: .top, spacing: UnifiedTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(colors.primary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(theme.typography.caption)
                    .foregroundColor(colors.textSecondary)
            }
        }
    }
}

#Preview {
    PermissionsSetupView()
        .environmentObject(AuthenticationService())
}


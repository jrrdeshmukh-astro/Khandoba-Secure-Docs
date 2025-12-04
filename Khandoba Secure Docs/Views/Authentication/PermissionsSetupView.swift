//
//  PermissionsSetupView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import SwiftUI
import CoreLocation

struct PermissionsSetupView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthenticationService
    @AppStorage("permissions_setup_complete") private var permissionsComplete = false
    
    @StateObject private var locationService = LocationService()
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
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(colors.primary)
                        
                        Text("Location Access")
                            .font(theme.typography.largeTitle)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.bold)
                        
                        Text("Required for security features")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    // Why we need it
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                        Text("Why we need location access:")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        PermissionReason(
                            icon: "shield.checkered",
                            title: "Security Monitoring",
                            description: "Detect access from unusual locations",
                            colors: colors
                        )
                        
                        PermissionReason(
                            icon: "map.fill",
                            title: "Access Map",
                            description: "Visualize where you access your vaults",
                            colors: colors
                        )
                        
                        PermissionReason(
                            icon: "exclamationmark.triangle.fill",
                            title: "Threat Detection",
                            description: "Alert you to suspicious location changes",
                            colors: colors
                        )
                        
                        PermissionReason(
                            icon: "chart.xyaxis.line",
                            title: "ML Risk Analysis",
                            description: "Analyze geographic patterns for security",
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
                        
                        Text("Location data is encrypted and stored only on your device. We never share your location with third parties.")
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
                                    Text("Enable Location Access")
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
                print("Location permission granted - tracking started")
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
    
    @Environment(\.unifiedTheme) var theme
    
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


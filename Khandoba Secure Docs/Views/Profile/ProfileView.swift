//
//  ProfileView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let roleColor = colors.clientColor
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                List {
                    Color.clear
                        .frame(height: 0)
                        .listRowBackground(Color.clear)
                    // Profile Section
                    Section {
                        HStack(spacing: UnifiedTheme.Spacing.md) {
                            // Avatar
                            if let imageData = authService.currentUser?.profilePictureData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(roleColor, lineWidth: 2)
                                    )
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(roleColor.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                    
                                    // Show person/face icon
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(roleColor)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(authService.currentUser?.fullName ?? "User")
                                    .font(theme.typography.title2)
                                    .foregroundColor(colors.textPrimary)
                                    .fontWeight(.bold)
                                
                                if let email = authService.currentUser?.email {
                                    Text(email)
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textSecondary)
                                }
                                
                                // User badge (single role system)
                                HStack(spacing: 4) {
                                    Image(systemName: "person.circle.fill")
                                    Text("User")
                                }
                                .font(.caption)
                                .foregroundColor(roleColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(roleColor.opacity(0.2))
                                .cornerRadius(UnifiedTheme.CornerRadius.sm)
                            }
                        }
                        .padding(.vertical, UnifiedTheme.Spacing.sm)
                    }
                    
                    // Role switching removed - single role system (autopilot mode)
                    
                    // Settings Section
                    Section("Settings") {
                        NavigationLink {
                            ManualInviteTokenView()
                        } label: {
                            HStack(spacing: UnifiedTheme.Spacing.md) {
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(colors.primary)
                                    .frame(width: 24)
                                Text("Accept Invitation")
                                    .foregroundColor(colors.textPrimary)
                            }
                        }
                        .listRowBackground(colors.surface)
                        
                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            HStack(spacing: UnifiedTheme.Spacing.md) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(colors.primary)
                                    .frame(width: 24)
                                Text("Notifications")
                                    .foregroundColor(colors.textPrimary)
                            }
                        }
                        .listRowBackground(colors.surface)
                        
                        NavigationLink {
                            PrivacyPolicyView()
                        } label: {
                            HStack(spacing: UnifiedTheme.Spacing.md) {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundColor(colors.primary)
                                    .frame(width: 24)
                                Text("Privacy Policy")
                                    .foregroundColor(colors.textPrimary)
                            }
                        }
                        .listRowBackground(colors.surface)
                        
                        NavigationLink {
                            TermsOfServiceView()
                        } label: {
                            HStack(spacing: UnifiedTheme.Spacing.md) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(colors.primary)
                                    .frame(width: 24)
                                Text("Terms of Service")
                                    .foregroundColor(colors.textPrimary)
                            }
                        }
                        .listRowBackground(colors.surface)
                        
                        NavigationLink {
                            SupportChatView()
                        } label: {
                            HStack(spacing: UnifiedTheme.Spacing.md) {
                                Image(systemName: "sparkles.rectangle.stack.fill")
                                    .foregroundColor(colors.primary)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AI Support")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Text("Chat with AI assistant")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                                Text("Help & Support")
                                    .foregroundColor(colors.textPrimary)
                            }
                        }
                        .listRowBackground(colors.surface)
                    }
                    
                    // About Section
                    Section("About") {
                        HStack {
                            Text("Version")
                                .foregroundColor(colors.textPrimary)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(colors.textSecondary)
                        }
                        .listRowBackground(colors.surface)
                    }
                    
                    // Sign Out Section
                    Section {
                        Button {
                            showSignOutConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                    .foregroundColor(colors.error)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .listRowBackground(colors.surface)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(colors.background)
                .tint(colors.primary) // Override iOS default tint
            }
            .navigationTitle("Profile")
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private var initials: String {
        guard let fullName = authService.currentUser?.fullName else { return "?" }
        let components = fullName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else if let first = components.first {
            return String(first.prefix(2))
        }
        return "?"
    }
    
    // Role functions removed - single role system
    
    private func getInitials() -> String {
        guard let name = authService.currentUser?.fullName, !name.isEmpty else {
            return "U"
        }
        
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1).uppercased()
            let last = components[1].prefix(1).uppercased()
            return first + last
        } else if let first = components.first {
            return String(first.prefix(2).uppercased())
        }
        return "U"
    }
    
    private func getRoleColor(for role: Role?, colors: UnifiedTheme.Colors) -> Color {
        // Single role - everyone uses client color
        return colors.clientColor
    }
}


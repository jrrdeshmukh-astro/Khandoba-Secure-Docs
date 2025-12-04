//
//  UserManagementView.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import SwiftUI
import SwiftData

struct UserManagementView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @Query private var users: [User]
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                List {
                    ForEach(users) { user in
                        NavigationLink {
                            UserDetailView(user: user)
                        } label: {
                            UserManagementRow(user: user)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(colors.background)
            }
            .navigationTitle("User Management")
        }
    }
}

struct UserManagementRow: View {
    let user: User
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        HStack(spacing: UnifiedTheme.Spacing.md) {
            if let imageData = user.profilePictureData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(colors.primary.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(String(user.fullName.prefix(1)))
                        .foregroundColor(colors.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(theme.typography.subheadline)
                    .foregroundColor(colors.textPrimary)
                
                HStack(spacing: 4) {
                    ForEach((user.roles ?? []).filter { $0.isActive }, id: \.id) { role in
                        Text(role.role.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(colors.primary.opacity(0.2))
                            .foregroundColor(colors.primary)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct UserDetailView: View {
    let user: User
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var showAddRole = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        ScrollView {
            VStack(spacing: UnifiedTheme.Spacing.lg) {
                // Profile
                VStack(spacing: UnifiedTheme.Spacing.md) {
                    if let imageData = user.profilePictureData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    }
                    
                    Text(user.fullName)
                        .font(theme.typography.title2)
                        .foregroundColor(colors.textPrimary)
                        .fontWeight(.bold)
                    
                    if let email = user.email {
                        Text(email)
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                .padding()
                
                // Roles
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        HStack {
                            Text("Assigned Roles")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Spacer()
                            
                            Button {
                                showAddRole = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(colors.primary)
                            }
                        }
                        
                        ForEach((user.roles ?? []).filter { $0.isActive }) { role in
                            HStack {
                                Image(systemName: role.role.iconName)
                                    .foregroundColor(colors.primary)
                                
                                Text(role.role.displayName)
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textPrimary)
                                
                                Spacer()
                                
                                Text("Since \(role.assignedAt, style: .date)")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Account Info
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Account Information")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        MetadataRow(label: "User ID", value: user.id.uuidString)
                        Divider()
                        MetadataRow(label: "Created", value: user.createdAt.formatted(date: .abbreviated, time: .shortened))
                        Divider()
                        MetadataRow(label: "Last Active", value: user.lastActiveAt.formatted(date: .abbreviated, time: .shortened))
                        Divider()
                        MetadataRow(label: "Status", value: user.isActive ? "Active" : "Inactive")
                    }
                }
                .padding(.horizontal)
                
                // Vaults
                StandardCard {
                    VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                        Text("Owned Vaults")
                            .font(theme.typography.headline)
                            .foregroundColor(colors.textPrimary)
                        
                        if (user.ownedVaults ?? []).isEmpty {
                            Text("No vaults created")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                        } else {
                            ForEach(user.ownedVaults ?? []) { vault in
                                HStack {
                                    Group {
                                        if vault.keyType == "dual" {
                                            HStack(spacing: -2) {
                                                Image(systemName: "key.fill")
                                                    .font(.caption)
                                                Image(systemName: "key.fill")
                                                    .font(.caption)
                                                    .rotationEffect(.degrees(15))
                                            }
                                        } else {
                                            Image(systemName: "lock.fill")
                                        }
                                    }
                                    .foregroundColor(colors.primary)
                                    
                                    Text(vault.name)
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text("\(vault.documents?.count ?? 0) docs")
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(colors.background)
        .navigationTitle("User Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

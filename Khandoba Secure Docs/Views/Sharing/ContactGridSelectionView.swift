//
//  ContactGridSelectionView.swift
//  Khandoba Secure Docs
//
//  Game Center-style contact selection with user detection
//  Shows which contacts are already app users and which can be invited
//

import SwiftUI
import Contacts
import SwiftData

struct ContactGridSelectionView: View {
    let onContactSelected: (CNContact, Bool) -> Void // Contact + isExistingUser
    let onDismiss: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var contactStore = ContactStore()
    @StateObject private var discoveryService = ContactDiscoveryService()
    
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var isDiscovering = false
    @State private var permissionStatus: CNAuthorizationStatus = .notDetermined
    @State private var selectedContacts: Set<String> = [] // Contact identifiers
    
    private var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contactStore.contacts
        } else {
            return contactStore.contacts.filter { contact in
                let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces).lowercased()
                let searchLower = searchText.lowercased()
                
                if fullName.contains(searchLower) {
                    return true
                }
                
                for phone in contact.phoneNumbers {
                    if phone.value.stringValue.contains(searchText) {
                        return true
                    }
                }
                
                for email in contact.emailAddresses {
                    if let emailString = email.value as String?,
                       emailString.lowercased().contains(searchLower) {
                        return true
                    }
                }
                
                return false
            }
        }
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                if permissionStatus == .denied {
                    PermissionDeniedView(colors: colors, theme: theme)
                } else if isLoading || isDiscovering {
                    LoadingView("Loading contacts...")
                } else if filteredContacts.isEmpty {
                    EmptyContactsView(searchText: searchText, colors: colors, theme: theme)
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: UnifiedTheme.Spacing.md),
                                GridItem(.flexible(), spacing: UnifiedTheme.Spacing.md)
                            ],
                            spacing: UnifiedTheme.Spacing.md
                        ) {
                            ForEach(filteredContacts, id: \.identifier) { contact in
                                ContactGridCard(
                                    contact: contact,
                                    isExistingUser: discoveryService.isContactRegistered(contact),
                                    isSelected: selectedContacts.contains(contact.identifier),
                                    colors: colors,
                                    theme: theme,
                                    onInvite: {
                                        onContactSelected(contact, discoveryService.isContactRegistered(contact))
                                    },
                                    onToggleSelection: {
                                        if selectedContacts.contains(contact.identifier) {
                                            selectedContacts.remove(contact.identifier)
                                        } else {
                                            selectedContacts.insert(contact.identifier)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(UnifiedTheme.Spacing.md)
                    }
                }
            }
            .navigationTitle("Select Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search contacts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(colors.textTertiary)
                    }
                }
            }
        }
        .task {
            await loadContacts()
        }
    }
    
    private func loadContacts() async {
        isLoading = true
        permissionStatus = CNContactStore.authorizationStatus(for: .contacts)
        
        if permissionStatus == .authorized {
            await contactStore.fetchContacts()
            
            // Discover which contacts are registered users
            isDiscovering = true
            discoveryService.configure(modelContext: modelContext)
            await discoveryService.discoverRegisteredContacts()
            isDiscovering = false
        } else if permissionStatus == .notDetermined {
            let store = CNContactStore()
            do {
                let granted = try await store.requestAccess(for: .contacts)
                await MainActor.run {
                    permissionStatus = granted ? .authorized : .denied
                    if granted {
                        Task {
                            await contactStore.fetchContacts()
                            
                            // Discover which contacts are registered users
                            isDiscovering = true
                            discoveryService.configure(modelContext: modelContext)
                            await discoveryService.discoverRegisteredContacts()
                            isDiscovering = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    permissionStatus = .denied
                }
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}

// MARK: - Contact Grid Card

struct ContactGridCard: View {
    let contact: CNContact
    let isExistingUser: Bool
    let isSelected: Bool
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    let onInvite: () -> Void
    let onToggleSelection: () -> Void
    
    private var fullName: String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }
    
    var body: some View {
        VStack(spacing: UnifiedTheme.Spacing.sm) {
            // Avatar with user indicator
            ZStack(alignment: .bottomTrailing) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colors.primary.opacity(0.3),
                                    colors.primary.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    if let imageData = contact.thumbnailImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        // Initials
                        if !fullName.isEmpty {
                            Text(String(fullName.prefix(1)).uppercased())
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                                .foregroundColor(colors.primary)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(colors.primary)
                        }
                    }
                }
                
                // Green message icon badge for existing users
                if isExistingUser {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "message.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 4, y: 4)
                }
            }
            
            // Name
            Text(fullName.isEmpty ? "Unknown" : fullName)
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textPrimary)
                .fontWeight(.medium)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            
            // Source label
            Text("From Contacts")
                .font(theme.typography.caption2)
                .foregroundColor(colors.textTertiary)
            
            // Invite Button
            Button(action: onInvite) {
                Text(isExistingUser ? "Invite" : "Invite")
                    .font(theme.typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, UnifiedTheme.Spacing.xs)
                    .background(
                        isExistingUser 
                            ? Color.green 
                            : colors.primary
                    )
                    .cornerRadius(UnifiedTheme.CornerRadius.sm)
            }
        }
        .padding(UnifiedTheme.Spacing.sm)
        .background(colors.surface)
        .cornerRadius(UnifiedTheme.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: UnifiedTheme.CornerRadius.md)
                .stroke(
                    isSelected ? colors.primary : Color.clear,
                    lineWidth: 2
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Permission Denied View

struct PermissionDeniedView: View {
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        VStack(spacing: UnifiedTheme.Spacing.lg) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 64))
                .foregroundColor(colors.error)
            
            Text("Contacts Access Denied")
                .font(theme.typography.title2)
                .foregroundColor(colors.textPrimary)
            
            Text("Please enable contacts access in Settings to select contacts")
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            } label: {
                Text("Open Settings")
                    .font(theme.typography.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, UnifiedTheme.Spacing.lg)
                    .padding(.vertical, UnifiedTheme.Spacing.md)
                    .background(colors.primary)
                    .cornerRadius(UnifiedTheme.CornerRadius.md)
            }
        }
        .padding()
    }
}

// MARK: - Empty Contacts View

struct EmptyContactsView: View {
    let searchText: String
    let colors: UnifiedTheme.Colors
    let theme: UnifiedTheme
    
    var body: some View {
        VStack(spacing: UnifiedTheme.Spacing.md) {
            Image(systemName: searchText.isEmpty ? "person.3" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(colors.textTertiary)
            
            Text(searchText.isEmpty ? "No Contacts" : "No Results")
                .font(theme.typography.headline)
                .foregroundColor(colors.textPrimary)
            
            Text(searchText.isEmpty ? "You don't have any contacts yet" : "Try a different search term")
                .font(theme.typography.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContactGridSelectionView(
        onContactSelected: { contact, isUser in
            print("Selected: \(contact.givenName), isUser: \(isUser)")
        },
        onDismiss: {}
    )
    .environment(\.unifiedTheme, UnifiedTheme())
}

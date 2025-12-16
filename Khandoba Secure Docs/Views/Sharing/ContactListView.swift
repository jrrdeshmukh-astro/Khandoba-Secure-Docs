//
//  ContactListView.swift
//  Khandoba Secure Docs
//
//  Custom contact list with search functionality
//

import SwiftUI
import Contacts
import Combine

struct ContactListView: View {
    let onContactSelected: (CNContact) -> Void
    let onDismiss: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var contactStore = ContactStore()
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var permissionStatus: CNAuthorizationStatus = .notDetermined
    
    private var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return contactStore.contacts
        } else {
            return contactStore.contacts.filter { contact in
                let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces).lowercased()
                let searchLower = searchText.lowercased()
                
                // Search by name
                if fullName.contains(searchLower) {
                    return true
                }
                
                // Search by phone number
                for phone in contact.phoneNumbers {
                    if phone.value.stringValue.contains(searchText) {
                        return true
                    }
                }
                
                // Search by email
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
                    // Permission denied state
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
                } else if isLoading {
                    // Loading state
                    VStack(spacing: UnifiedTheme.Spacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading contacts...")
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                } else if filteredContacts.isEmpty {
                    // Empty state
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
                } else {
                    // Contact list
                    List {
                        ForEach(filteredContacts, id: \.identifier) { contact in
                            ContactListRow(contact: contact) {
                                onContactSelected(contact)
                            }
                            .listRowBackground(colors.surface)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: UnifiedTheme.Spacing.xs,
                                leading: UnifiedTheme.Spacing.md,
                                bottom: UnifiedTheme.Spacing.xs,
                                trailing: UnifiedTheme.Spacing.md
                            ))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Select Contact")
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
        } else if permissionStatus == .notDetermined {
            let store = CNContactStore()
            do {
                let granted = try await store.requestAccess(for: .contacts)
                await MainActor.run {
                    permissionStatus = granted ? .authorized : .denied
                    if granted {
                        Task {
                            await contactStore.fetchContacts()
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

// MARK: - Contact Store

@MainActor
class ContactStore: ObservableObject {
    @Published var contacts: [CNContact] = []
    
    func fetchContacts() async {
        let store = CNContactStore()
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactImageDataKey,
            CNContactThumbnailImageDataKey
        ] as [CNKeyDescriptor]
        
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        request.sortOrder = .givenName
        
        var fetchedContacts: [CNContact] = []
        
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                // Only include contacts with phone or email
                if !contact.phoneNumbers.isEmpty || !contact.emailAddresses.isEmpty {
                    fetchedContacts.append(contact)
                }
                return true
            }
            
            // Sort by full name
            fetchedContacts.sort { contact1, contact2 in
                let name1 = "\(contact1.givenName) \(contact1.familyName)".trimmingCharacters(in: .whitespaces)
                let name2 = "\(contact2.givenName) \(contact2.familyName)".trimmingCharacters(in: .whitespaces)
                return name1 < name2
            }
            
            contacts = fetchedContacts
        } catch {
            print("⚠️ Error fetching contacts: \(error.localizedDescription)")
            contacts = []
        }
    }
}

// MARK: - Contact List Row

struct ContactListRow: View {
    let contact: CNContact
    let onTap: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        
        Button(action: onTap) {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colors.primary.opacity(0.25),
                                    colors.primary.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    if let imageData = contact.thumbnailImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        // Initials or icon
                        if !fullName.isEmpty {
                            Text(String(fullName.prefix(1)).uppercased())
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(colors.primary)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(colors.primary)
                        }
                    }
                }
                
                // Contact Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(fullName.isEmpty ? "Unknown" : fullName)
                        .font(theme.typography.subheadline)
                        .foregroundColor(colors.textPrimary)
                        .fontWeight(.medium)
                    
                    if let phone = contact.phoneNumbers.first?.value.stringValue {
                        Text(phone)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    } else if let email = contact.emailAddresses.first?.value as String? {
                        Text(email)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(colors.textTertiary)
            }
            .padding(.vertical, UnifiedTheme.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

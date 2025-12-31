//
//  GameCenterStyleNomineeView.swift
//  Khandoba Secure Docs
//
//  Game Center-style nominee selection interface with friends/family list
//

import SwiftUI
import SwiftData
import Contacts

struct GameCenterStyleNomineeView: View {
    let vault: Vault
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var vaultService: VaultService
    
    @StateObject private var nomineeService = NomineeService()
    @StateObject private var contactDiscovery = ContactDiscoveryService()
    
    @State private var nominees: [Nominee] = []
    @State private var contacts: [CNContact] = []
    @State private var searchText = ""
    @State private var selectedCategory: NomineeCategory = .all
    @State private var isLoading = false
    @State private var showContactPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum NomineeCategory: String, CaseIterable {
        case all = "All"
        case friends = "Friends"
        case family = "Family"
        case accepted = "Accepted"
        case pending = "Pending"
        
        var icon: String {
            switch self {
            case .all: return "person.2.fill"
            case .friends: return "person.2.fill"
            case .family: return "house.fill"
            case .accepted: return "checkmark.circle.fill"
            case .pending: return "clock.fill"
            }
        }
    }
    
    var filteredNominees: [Nominee] {
        var filtered = nominees
        
        // Filter by category
        switch selectedCategory {
        case .all:
            break
        case .friends, .family:
            // For now, all nominees are shown (can be enhanced with tagging)
            break
        case .accepted:
            filtered = filtered.filter { $0.status == .accepted || $0.status == .active }
        case .pending:
            filtered = filtered.filter { $0.status == .pending }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { nominee in
                nominee.name.localizedCaseInsensitiveContains(searchText) ||
                nominee.email?.localizedCaseInsensitiveContains(searchText) == true ||
                nominee.phoneNumber?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return filtered
    }
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(colors.textSecondary)
                        
                        TextField("Search nominees...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding()
                    .background(colors.surface)
                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Category Picker (Game Center style)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: UnifiedTheme.Spacing.sm) {
                            ForEach(NomineeCategory.allCases, id: \.self) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: category.icon)
                                        Text(category.rawValue)
                                    }
                                    .font(theme.typography.subheadline)
                                    .padding(.horizontal, UnifiedTheme.Spacing.md)
                                    .padding(.vertical, UnifiedTheme.Spacing.sm)
                                    .background(selectedCategory == category ? colors.primary : colors.surface)
                                    .foregroundColor(selectedCategory == category ? .white : colors.textPrimary)
                                    .cornerRadius(UnifiedTheme.CornerRadius.lg)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, UnifiedTheme.Spacing.sm)
                    }
                    
                    // Nominee List
                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if filteredNominees.isEmpty {
                        Spacer()
                        VStack(spacing: UnifiedTheme.Spacing.md) {
                            Image(systemName: "person.2.slash.fill")
                                .font(.system(size: 50))
                                .foregroundColor(colors.textSecondary)
                            
                            Text(selectedCategory == .all ? "No Nominees" : "No \(selectedCategory.rawValue) Nominees")
                                .font(theme.typography.headline)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("Invite people to access this vault")
                                .font(theme.typography.caption)
                                .foregroundColor(colors.textSecondary)
                            
                            Button {
                                showContactPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Invite Nominee")
                                }
                                .padding()
                                .background(colors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(UnifiedTheme.CornerRadius.lg)
                            }
                            .padding(.top)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: UnifiedTheme.Spacing.sm) {
                                ForEach(filteredNominees) { nominee in
                                    GameCenterNomineeRow(
                                        nominee: nominee,
                                        vault: vault,
                                        contactDiscovery: contactDiscovery
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Nominees")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showContactPicker = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(colors.primary)
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button {
                        showContactPicker = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(colors.primary)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView(
                    vault: vault,
                    onContactsSelected: { contacts in
                        // Handle contact selection
                        showContactPicker = false
                    },
                    onDismiss: {
                        showContactPicker = false
                    },
                    contactDiscovery: contactDiscovery
                )
            }
            .task {
                await loadNominees()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func loadNominees() async {
        isLoading = true
        defer { isLoading = false }
        
        // Configure services - iOS-ONLY: Using SwiftData/CloudKit exclusively
        if let userID = authService.currentUser?.id {
            nomineeService.configure(modelContext: modelContext, currentUserID: userID, vaultService: vaultService)
        } else {
            nomineeService.configure(modelContext: modelContext, vaultService: vaultService)
        }
        
        do {
            try await nomineeService.loadNominees(for: vault)
            await MainActor.run {
                nominees = nomineeService.nominees
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct GameCenterNomineeRow: View {
    let nominee: Nominee
    let vault: Vault
    let contactDiscovery: ContactDiscoveryService?
    
    @SwiftUI.Environment(\.unifiedTheme) var theme
    @SwiftUI.Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vaultService: VaultService
    @SwiftUI.Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var showTransferOwnership = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        let isRegistered = contactDiscovery?.isContactRegistered(createContactFromNominee()) ?? false
        
        StandardCard {
            HStack(spacing: UnifiedTheme.Spacing.md) {
                // Profile Picture/Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if let email = nominee.email, !email.isEmpty {
                        Text(String(email.prefix(1).uppercased()))
                            .font(theme.typography.headline)
                            .foregroundColor(statusColor)
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(statusColor)
                    }
                }
                
                // Nominee Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(nominee.name)
                            .font(theme.typography.subheadline)
                            .foregroundColor(colors.textPrimary)
                            .fontWeight(.semibold)
                        
                        if isRegistered {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(colors.success)
                                .font(.caption)
                        }
                    }
                    
                    if let email = nominee.email, !email.isEmpty {
                        Text(email)
                            .font(theme.typography.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        
                        Text(nominee.status.displayName)
                            .font(theme.typography.caption2)
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: UnifiedTheme.Spacing.sm) {
                    // Transfer Ownership (only for accepted nominees)
                    if nominee.status == .accepted || nominee.status == .active {
                        Button {
                            showTransferOwnership = true
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(colors.warning)
                                .font(.title3)
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showTransferOwnership) {
            VaultTransferView(vault: vault, preselectedNominee: nominee)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var statusColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch nominee.status {
        case .pending: return colors.warning
        case .accepted, .active: return colors.success
        case .inactive, .revoked: return colors.textTertiary
        }
    }
    
    private func createContactFromNominee() -> CNContact {
        let contact = CNMutableContact()
        contact.givenName = nominee.name
        if let email = nominee.email {
            contact.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: email as NSString)]
        }
        if let phone = nominee.phoneNumber {
            contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phone))]
        }
        return contact
    }
}

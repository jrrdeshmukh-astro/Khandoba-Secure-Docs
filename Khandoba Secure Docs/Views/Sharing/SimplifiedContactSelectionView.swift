//
//  SimplifiedContactSelectionView.swift
//  Khandoba Secure Docs
//
//  Simplified contact selection view - directly shows contact picker without vault card
//

import SwiftUI
import Contacts
import SwiftData

struct SimplifiedContactSelectionView: View {
    let vault: Vault
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var supabaseService: SupabaseService
    @EnvironmentObject var vaultService: VaultService
    
    @StateObject private var nomineeService = NomineeService()
    @State private var showContactPicker = false
    @State private var selectedContacts: [CNContact] = []
    @State private var showNomineeInvitation = false
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: UnifiedTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: UnifiedTheme.Spacing.sm) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(colors.primary)
                        
                        Text("Invite to Vault")
                            .font(theme.typography.title)
                            .foregroundColor(colors.textPrimary)
                        
                        Text("Select contacts to invite to \(vault.name)")
                            .font(theme.typography.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, UnifiedTheme.Spacing.xl)
                    
                    // Select Contact Button
                    Button {
                        showContactPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Select Contact")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(UnifiedTheme.CornerRadius.lg)
                    }
                    .disabled(isProcessing)
                    .padding(.horizontal)
                    
                    // Selected Contacts
                    if !selectedContacts.isEmpty {
                        ScrollView {
                            VStack(spacing: UnifiedTheme.Spacing.sm) {
                                ForEach(Array(selectedContacts.enumerated()), id: \.offset) { index, contact in
                                    StandardCard {
                                        HStack {
                                            Image(systemName: "person.circle.fill")
                                                .foregroundColor(colors.primary)
                                                .font(.system(size: 30))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("\(contact.givenName) \(contact.familyName)")
                                                    .font(theme.typography.body)
                                                    .foregroundColor(colors.textPrimary)
                                                
                                                if let phone = contact.phoneNumbers.first?.value.stringValue {
                                                    Text(phone)
                                                        .font(theme.typography.caption)
                                                        .foregroundColor(colors.textSecondary)
                                                }
                                                
                                                if let email = contact.emailAddresses.first?.value as String? {
                                                    Text(email)
                                                        .font(theme.typography.caption)
                                                        .foregroundColor(colors.textSecondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Button {
                                                selectedContacts.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(colors.textTertiary)
                                            }
                                        }
                                        .padding()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Send Invitation Button
                        Button {
                            showNomineeInvitation = true
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Send Invitation")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        .disabled(isProcessing)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Invite to Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView(
                    vault: vault,
                    onContactsSelected: { contacts in
                        for contact in contacts {
                            if !selectedContacts.contains(where: { $0.identifier == contact.identifier }) {
                                selectedContacts.append(contact)
                            }
                        }
                        showContactPicker = false
                    },
                    onDismiss: {
                        showContactPicker = false
                    }
                )
            }
            .sheet(isPresented: $showNomineeInvitation) {
                NomineeInvitationView(vault: vault)
            }
            .onAppear {
                // Configure nominee service
                if AppConfig.useSupabase {
                    if let userID = authService.currentUser?.id {
                        nomineeService.configure(supabaseService: supabaseService, currentUserID: userID, vaultService: vaultService)
                    } else {
                        nomineeService.configure(supabaseService: supabaseService, vaultService: vaultService)
                    }
                } else {
                    nomineeService.configure(modelContext: modelContext, vaultService: vaultService)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

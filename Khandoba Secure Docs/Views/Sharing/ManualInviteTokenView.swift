//
//  ManualInviteTokenView.swift
//  Khandoba Secure Docs
//
//  Manual token entry for TestFlight testing
//

import SwiftUI
import SwiftData

struct ManualInviteTokenView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authService: AuthenticationService
    
    @StateObject private var nomineeService = NomineeService()
    @State private var tokenInput = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showInvitationView = false
    @State private var loadedNominee: Nominee?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: UnifiedTheme.Spacing.xl) {
                        // Header
                        VStack(spacing: UnifiedTheme.Spacing.sm) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 50))
                                .foregroundColor(colors.primary)
                            
                            Text("Accept Invitation")
                                .font(theme.typography.title)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("Enter the invitation token you received")
                                .font(theme.typography.body)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, UnifiedTheme.Spacing.xl)
                        
                        // Info Card
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.sm) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(colors.info)
                                    Text("How to Use")
                                        .font(theme.typography.subheadline)
                                        .foregroundColor(colors.textPrimary)
                                        .fontWeight(.semibold)
                                }
                                
                                Text("If you received an invitation via iMessage, copy the token from the message and paste it here. This is useful for TestFlight testing when deep links may not work.")
                                    .font(theme.typography.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Token Input
                        StandardCard {
                            VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                                Text("Invitation Token")
                                    .font(theme.typography.subheadline)
                                    .foregroundColor(colors.textPrimary)
                                    .fontWeight(.semibold)
                                
                                TextField("Paste token here", text: $tokenInput)
                                    .font(theme.typography.body)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .padding(UnifiedTheme.Spacing.md)
                                    .background(colors.surface)
                                    .cornerRadius(UnifiedTheme.CornerRadius.md)
                                
                                if !tokenInput.isEmpty {
                                    Button {
                                        tokenInput = ""
                                    } label: {
                                        HStack {
                                            Image(systemName: "xmark.circle.fill")
                                            Text("Clear")
                                        }
                                        .font(theme.typography.caption)
                                        .foregroundColor(colors.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Submit Button
                        Button {
                            loadInvitation()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Load Invitation")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(tokenInput.isEmpty ? colors.surface : colors.primary)
                            .foregroundColor(tokenInput.isEmpty ? colors.textTertiary : .white)
                            .cornerRadius(UnifiedTheme.CornerRadius.lg)
                        }
                        .disabled(tokenInput.isEmpty || isLoading)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Accept Invitation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showInvitationView) {
                if let nominee = loadedNominee {
                    AcceptNomineeInvitationView(inviteToken: nominee.inviteToken)
                }
            }
            .onAppear {
                nomineeService.configure(modelContext: modelContext)
            }
        }
    }
    
    private func loadInvitation() {
        guard !tokenInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        isLoading = true
        Task {
            do {
                let token = tokenInput.trimmingCharacters(in: .whitespaces)
                // Load the invitation without accepting it yet
                let nominee = try await nomineeService.loadInvite(token: token)
                
                await MainActor.run {
                    loadedNominee = nominee
                    isLoading = false
                    showInvitationView = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Invalid or expired invitation token. Please check the token and try again."
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

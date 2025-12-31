//
//  KYCVerificationView.swift
//  Khandoba Secure Docs
//
//  KYC verification admin view
//

import SwiftUI

struct KYCVerificationView: View {
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @StateObject private var kycService = KYCVerificationService.shared
    
    @State private var selectedVerification: IDVerification?
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                List {
                    ForEach(kycService.pendingVerifications, id: \.id) { verification in
                        VerificationRow(verification: verification) {
                            selectedVerification = verification
                        }
                    }
                }
                .navigationTitle("KYC Verification")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .sheet(item: $selectedVerification) { verification in
            VerificationDetailView(verification: verification)
        }
        .onAppear {
            kycService.configure(modelContext: modelContext)
        }
    }
}

private struct VerificationRow: View {
    let verification: IDVerification
    let onTap: () -> Void
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("User ID: \(verification.userID.uuidString.prefix(8))")
                        .font(theme.typography.headline)
                    
                    Text("Submitted: \(DateFormatter.localizedString(from: verification.submittedAt, dateStyle: .medium, timeStyle: .short))")
                        .font(theme.typography.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                Text(verification.status)
                    .font(theme.typography.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(UnifiedTheme.CornerRadius.sm)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var statusColor: Color {
        let colors = theme.colors(for: colorScheme)
        switch verification.statusEnum {
        case .pending:
            return colors.warning
        case .approved:
            return colors.success
        case .rejected:
            return colors.error
        case .expired:
            return colors.textTertiary
        case .none:
            return colors.textTertiary
        }
    }
}

private struct VerificationDetailView: View {
    let verification: IDVerification
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var kycService = KYCVerificationService.shared
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var reviewNotes: String = ""
    @State private var showApproveConfirmation = false
    @State private var showRejectConfirmation = false
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.lg) {
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Verification Details")
                                .font(theme.typography.headline)
                            
                            if let name = verification.fullName {
                                KYCDetailRow(label: "Full Name", value: name)
                            }
                            
                            if let dob = verification.dateOfBirth {
                                KYCDetailRow(label: "Date of Birth", value: DateFormatter.localizedString(from: dob, dateStyle: .long, timeStyle: .none))
                            }
                            
                            if let address = verification.address {
                                KYCDetailRow(label: "Address", value: address)
                            }
                        }
                        .padding()
                    }
                    
                    StandardCard {
                        VStack(alignment: .leading, spacing: UnifiedTheme.Spacing.md) {
                            Text("Review Notes")
                                .font(theme.typography.headline)
                            
                            TextField("Enter review notes", text: $reviewNotes, axis: .vertical)
                                .lineLimit(5...10)
                        }
                        .padding()
                    }
                    
                    // Action Buttons
                    HStack(spacing: UnifiedTheme.Spacing.md) {
                        Button {
                            showRejectConfirmation = true
                        } label: {
                            Text("Reject")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(colors.error)
                        
                        Button {
                            showApproveConfirmation = true
                        } label: {
                            Text("Approve")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("KYC Review")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Approve Verification", isPresented: $showApproveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Approve") {
                    approveVerification()
                }
            } message: {
                Text("Are you sure you want to approve this KYC verification?")
            }
            .alert("Reject Verification", isPresented: $showRejectConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reject") {
                    rejectVerification()
                }
            } message: {
                Text("Are you sure you want to reject this KYC verification?")
            }
        }
    }
    
    private func approveVerification() {
        guard let reviewerID = authService.currentUser?.id else { return }
        try? kycService.reviewVerification(
            verification,
            approved: true,
            reviewerID: reviewerID,
            notes: reviewNotes.isEmpty ? nil : reviewNotes
        )
        dismiss()
    }
    
    private func rejectVerification() {
        guard let reviewerID = authService.currentUser?.id else { return }
        try? kycService.reviewVerification(
            verification,
            approved: false,
            reviewerID: reviewerID,
            notes: reviewNotes.isEmpty ? nil : reviewNotes
        )
        dismiss()
    }
}

private struct KYCDetailRow: View {
    let label: String
    let value: String
    
    @Environment(\.unifiedTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = theme.colors(for: colorScheme)
        
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(colors.textSecondary)
            Text(value)
                .font(theme.typography.body)
                .foregroundColor(colors.textPrimary)
        }
    }
}


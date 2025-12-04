//
//  NomineeService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData
import MessageUI
import Combine

@MainActor
final class NomineeService: ObservableObject {
    @Published var nominees: [Nominee] = []
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadNominees(for vault: Vault) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let modelContext = modelContext else { return }
        
        // Get nominees for this vault
        // In a full implementation, we'd filter by vault
        let descriptor = FetchDescriptor<Nominee>()
        nominees = try modelContext.fetch(descriptor)
    }
    
    func inviteNominee(
        name: String,
        phoneNumber: String?,
        email: String?,
        to vault: Vault,
        invitedByUserID: UUID
    ) async throws -> Nominee {
        guard let modelContext = modelContext else {
            throw NomineeError.contextNotAvailable
        }
        
        let nominee = Nominee(
            name: name,
            phoneNumber: phoneNumber,
            email: email
        )
        
        nominee.vault = vault
        nominee.invitedByUserID = invitedByUserID
        
        modelContext.insert(nominee)
        try modelContext.save()
        
        // Send invitation (placeholder - would use MessageUI in production)
        await sendInvitation(to: nominee)
        
        try await loadNominees(for: vault)
        
        return nominee
    }
    
    func removeNominee(_ nominee: Nominee) async throws {
        guard let modelContext = modelContext else { return }
        
        nominee.status = "inactive"
        try modelContext.save()
        
        if let vault = nominee.vault {
            try await loadNominees(for: vault)
        }
    }
    
    func acceptInvite(token: String) async throws -> Nominee? {
        guard let modelContext = modelContext else {
            throw NomineeError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.inviteToken == token }
        )
        
        guard let nominee = try modelContext.fetch(descriptor).first else {
            throw NomineeError.invalidToken
        }
        
        nominee.status = "accepted"
        nominee.acceptedAt = Date()
        try modelContext.save()
        
        return nominee
    }
    
    private func sendInvitation(to nominee: Nominee) async {
        // Generate invitation details
        let invitationMessage = """
        You've been invited to co-manage a vault in Khandoba Secure Docs!
        
        Vault: \(nominee.vault?.name ?? "Unknown")
        Invited by: Vault Owner
        Role: Dual-key approval required
        
        Download Khandoba Secure Docs from the App Store to accept.
        """
        
        // In a production app with MessageUI:
        // - Use MFMessageComposeViewController to send SMS/iMessage
        // - Include deep link to app
        // - Track delivery status
        
        // For now, copy to clipboard for manual sharing
        UIPasteboard.general.string = invitationMessage
        
        print("✅ Invitation generated for: \(nominee.name)")
        print("   Message copied to clipboard for sharing")
    }
}

enum NomineeError: LocalizedError {
    case contextNotAvailable
    case invalidToken
    case sendFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Nominee service not available"
        case .invalidToken:
            return "Invalid invitation token"
        case .sendFailed:
            return "Failed to send invitation"
        }
    }
}

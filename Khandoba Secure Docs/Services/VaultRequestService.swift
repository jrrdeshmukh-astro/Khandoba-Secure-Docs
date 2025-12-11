//
//  VaultRequestService.swift
//  Khandoba Secure Docs
//
//  Zelle-like vault sharing service for requesting and sending vault access
//  Vault stays with owner (like bank account), just access is shared
//

import Foundation
import SwiftData
import Combine
import CloudKit

@MainActor
final class VaultRequestService: ObservableObject {
    @Published var pendingRequests: [VaultAccessRequest] = []
    @Published var sentRequests: [VaultAccessRequest] = []
    @Published var receivedRequests: [VaultAccessRequest] = []
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    private var cloudKitSharing: CloudKitSharingService?
    private var nomineeService: NomineeService?
    private var currentUserID: UUID?
    
    nonisolated init() {}
    
    func configure(
        modelContext: ModelContext,
        currentUserID: UUID?,
        cloudKitSharing: CloudKitSharingService? = nil,
        nomineeService: NomineeService? = nil
    ) {
        self.modelContext = modelContext
        self.currentUserID = currentUserID
        self.cloudKitSharing = cloudKitSharing
        self.nomineeService = nomineeService
    }
    
    // MARK: - Request Vault Access (Like "Request Money" in Zelle)
    
    /// Request access to a vault from another user
    /// Similar to Zelle's "Request Money" feature
    func requestVaultAccess(
        vault: Vault,
        from ownerEmail: String?,
        from ownerPhone: String?,
        message: String? = nil
    ) async throws -> VaultAccessRequest {
        guard let modelContext = modelContext,
              let currentUserID = currentUserID else {
            throw VaultRequestError.contextNotAvailable
        }
        
        guard let owner = vault.owner else {
            throw VaultRequestError.vaultHasNoOwner
        }
        
        // Check if user is already a nominee
        if let nominees = vault.nomineeList,
           nominees.contains(where: { $0.email?.lowercased() == ownerEmail?.lowercased() || $0.phoneNumber == ownerPhone }) {
            throw VaultRequestError.alreadyHasAccess
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Create request
        let request = VaultAccessRequest(
            requestType: "request",
            message: message,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) // Expires in 7 days
        )
        
        request.vault = vault
        request.vaultID = vault.id
        request.vaultName = vault.name
        
        // Set requester (current user)
        request.requesterUserID = currentUserID
        if let currentUser = try? await getCurrentUser() {
            request.requesterName = currentUser.fullName
            request.requesterEmail = currentUser.email
            request.requesterPhone = currentUser.phoneNumber
        }
        
        // Set recipient (vault owner)
        request.recipientUserID = owner.id
        request.recipientName = owner.fullName
        request.recipientEmail = ownerEmail ?? owner.email
        request.recipientPhone = ownerPhone ?? owner.phoneNumber
        
        modelContext.insert(request)
        try modelContext.save()
        
        print("✅ Vault access request created: \(vault.name)")
        print("   Requester: \(request.requesterName ?? "Unknown")")
        print("   Owner: \(owner.fullName)")
        
        // Load requests to update UI
        try await loadRequests()
        
        return request
    }
    
    // MARK: - Send Vault Access (Like "Send Money" in Zelle)
    
    /// Send vault access to another user
    /// Similar to Zelle's "Send Money" feature
    func sendVaultAccess(
        vault: Vault,
        to recipientEmail: String?,
        to recipientPhone: String?,
        to recipientName: String?,
        message: String? = nil
    ) async throws -> VaultAccessRequest {
        guard let modelContext = modelContext,
              let currentUserID = currentUserID else {
            throw VaultRequestError.contextNotAvailable
        }
        
        // Verify current user owns the vault
        guard vault.owner?.id == currentUserID else {
            throw VaultRequestError.notVaultOwner
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Create send request
        let request = VaultAccessRequest(
            requestType: "send",
            message: message,
            expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) // Expires in 7 days
        )
        
        request.vault = vault
        request.vaultID = vault.id
        request.vaultName = vault.name
        
        // Set sender (current user - vault owner)
        request.requesterUserID = currentUserID
        if let currentUser = try? await getCurrentUser() {
            request.requesterName = currentUser.fullName
            request.requesterEmail = currentUser.email
            request.requesterPhone = currentUser.phoneNumber
        }
        
        // Set recipient
        request.recipientName = recipientName
        request.recipientEmail = recipientEmail
        request.recipientPhone = recipientPhone
        
        modelContext.insert(request)
        try modelContext.save()
        
        print("✅ Vault access send request created: \(vault.name)")
        print("   Sender: \(request.requesterName ?? "Unknown")")
        print("   Recipient: \(recipientName ?? recipientEmail ?? recipientPhone ?? "Unknown")")
        
        // Automatically create CloudKit share and nominee
        // This is like Zelle automatically sending the money
        try await processSendRequest(request)
        
        // Load requests to update UI
        try await loadRequests()
        
        return request
    }
    
    // MARK: - Process Send Request (Auto-accept)
    
    /// Process a send request by automatically creating CloudKit share
    /// Similar to how Zelle automatically sends money when you "Send"
    private func processSendRequest(_ request: VaultAccessRequest) async throws {
        guard let vault = request.vault,
              let cloudKitSharing = cloudKitSharing,
              let nomineeService = nomineeService else {
            return
        }
        
        // Create nominee and CloudKit share automatically
        // This is the "send" action - access is granted immediately
        do {
            let nominee = try await nomineeService.inviteNominee(
                name: request.recipientName ?? "Shared User",
                phoneNumber: request.recipientPhone,
                email: request.recipientEmail,
                to: vault,
                invitedByUserID: request.requesterUserID ?? UUID()
            )
            
            // Update request with CloudKit share info
            request.cloudKitShareRecordID = nominee.cloudKitShareRecordID
            request.status = "accepted"
            request.respondedAt = Date()
            
            try modelContext?.save()
            
            print("   ✅ Vault access automatically granted via CloudKit share")
        } catch {
            print("   ⚠️ Failed to create CloudKit share: \(error.localizedDescription)")
            // Request remains pending, can be retried
        }
    }
    
    // MARK: - Accept Request
    
    /// Accept a vault access request
    /// Similar to accepting a money request in Zelle
    func acceptRequest(_ request: VaultAccessRequest) async throws {
        guard let modelContext = modelContext,
              let vault = request.vault,
              let cloudKitSharing = cloudKitSharing,
              let nomineeService = nomineeService else {
            throw VaultRequestError.contextNotAvailable
        }
        
        guard request.status == "pending" else {
            throw VaultRequestError.requestNotPending
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Create nominee and CloudKit share
        let nominee = try await nomineeService.inviteNominee(
            name: request.requesterName ?? "Shared User",
            phoneNumber: request.requesterPhone,
            email: request.requesterEmail,
            to: vault,
            invitedByUserID: request.requesterUserID ?? UUID()
        )
        
        // Update request
        request.status = "accepted"
        request.respondedAt = Date()
        request.cloudKitShareRecordID = nominee.cloudKitShareRecordID
        
        try modelContext.save()
        
        print("✅ Vault access request accepted: \(vault.name)")
        
        // Load requests to update UI
        try await loadRequests()
    }
    
    // MARK: - Decline Request
    
    /// Decline a vault access request
    func declineRequest(_ request: VaultAccessRequest, reason: String? = nil) async throws {
        guard let modelContext = modelContext else {
            throw VaultRequestError.contextNotAvailable
        }
        
        guard request.status == "pending" else {
            throw VaultRequestError.requestNotPending
        }
        
        request.status = "declined"
        request.respondedAt = Date()
        request.responseMessage = reason
        
        try modelContext.save()
        
        print("❌ Vault access request declined: \(request.vaultName ?? "Unknown")")
        
        // Load requests to update UI
        try await loadRequests()
    }
    
    // MARK: - Load Requests
    
    /// Load all vault access requests
    func loadRequests() async throws {
        guard let modelContext = modelContext,
              let currentUserID = currentUserID else {
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let descriptor = FetchDescriptor<VaultAccessRequest>(
            sortBy: [SortDescriptor(\.requestedAt, order: .reverse)]
        )
        
        let allRequests = try modelContext.fetch(descriptor)
        
        // Get current user for email/phone matching
        let currentUser = try? await getCurrentUser()
        
        // Filter by current user
        let sent = allRequests.filter { $0.requesterUserID == currentUserID }
        let received = allRequests.filter { 
            $0.recipientUserID == currentUserID || 
            (currentUser?.email != nil && $0.recipientEmail?.lowercased() == currentUser?.email?.lowercased()) ||
            (currentUser?.phoneNumber != nil && $0.recipientPhone == currentUser?.phoneNumber)
        }
        let pending = allRequests.filter { $0.status == "pending" }
        
        await MainActor.run {
            self.sentRequests = sent
            self.receivedRequests = received
            self.pendingRequests = pending
        }
        
        print("📋 Loaded \(allRequests.count) vault access request(s)")
        print("   Sent: \(sent.count), Received: \(received.count), Pending: \(pending.count)")
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUser() async throws -> User? {
        guard let modelContext = modelContext,
              let currentUserID = currentUserID else {
            return nil
        }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == currentUserID }
        )
        
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Errors

enum VaultRequestError: LocalizedError {
    case contextNotAvailable
    case vaultHasNoOwner
    case notVaultOwner
    case alreadyHasAccess
    case requestNotPending
    case invalidRequest
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Model context not available"
        case .vaultHasNoOwner:
            return "Vault has no owner"
        case .notVaultOwner:
            return "You are not the owner of this vault"
        case .alreadyHasAccess:
            return "User already has access to this vault"
        case .requestNotPending:
            return "Request is not pending"
        case .invalidRequest:
            return "Invalid request"
        }
    }
}

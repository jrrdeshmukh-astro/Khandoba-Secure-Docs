//
//  VaultOpenRequestService.swift
//  Khandoba Secure Docs
//
//  Vault open request service
//

import Foundation
import SwiftData
import Combine

@MainActor
final class VaultOpenRequestService: ObservableObject {
    static let shared = VaultOpenRequestService()
    
    @Published var pendingRequests: [VaultAccessRequest] = []
    @Published var isProcessing = false
    
    private var modelContext: ModelContext?
    private var vaultService: VaultService?
    
    private init() {}
    
    func configure(modelContext: ModelContext, vaultService: VaultService) {
        self.modelContext = modelContext
        self.vaultService = vaultService
        loadPendingRequests()
    }
    
    // MARK: - Request Management
    
    private func loadPendingRequests() {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<VaultAccessRequest>(
                predicate: #Predicate { $0.status == "pending" },
                sortBy: [SortDescriptor(\.requestedAt)]
            )
            pendingRequests = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading pending requests: \(error)")
        }
    }
    
    /// Request to open locked vault
    func requestVaultAccess(
        vaultID: UUID,
        requesterID: UUID,
        message: String?
    ) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        let request = VaultAccessRequest(
            requestType: "request",
            message: message
        )
        request.vaultID = vaultID
        request.requesterUserID = requesterID
        request.expiresAt = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days
        
        modelContext.insert(request)
        try modelContext.save()
        loadPendingRequests()
    }
    
    /// Approve vault access request
    func approveRequest(_ request: VaultAccessRequest, approverID: UUID) async throws {
        guard let modelContext = modelContext,
              let vaultService = vaultService,
              let vaultID = request.vaultID else {
            throw DocumentError.contextNotAvailable
        }
        
        // Get vault
        let vaultDescriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.id == vaultID }
        )
        guard let vault = try modelContext.fetch(vaultDescriptor).first else {
            throw DocumentError.contextNotAvailable
        }
        
        // Unlock vault temporarily (would integrate with VaultService)
        request.status = "accepted"
        request.respondedAt = Date()
        
        try modelContext.save()
        loadPendingRequests()
    }
    
    /// Decline vault access request
    func declineRequest(_ request: VaultAccessRequest, approverID: UUID, reason: String?) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        request.status = "declined"
        request.respondedAt = Date()
        request.responseMessage = reason
        
        try modelContext.save()
        loadPendingRequests()
    }
}


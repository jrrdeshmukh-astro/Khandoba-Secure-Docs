//
//  EmergencyAccessService.swift
//  Khandoba Secure Docs
//
//  Emergency access management service
//

import Foundation
import SwiftData
import Combine

@MainActor
final class EmergencyAccessService: ObservableObject {
    static let shared = EmergencyAccessService()
    
    @Published var pendingRequests: [EmergencyAccessRequest] = []
    @Published var activeGrants: [EmergencyAccessRequest] = []
    @Published var isProcessing = false
    
    private var modelContext: ModelContext?
    private var vaultService: VaultService?
    
    private init() {}
    
    func configure(modelContext: ModelContext, vaultService: VaultService) {
        self.modelContext = modelContext
        self.vaultService = vaultService
        loadRequests()
        startExpirationMonitoring()
    }
    
    // MARK: - Request Management
    
    private func loadRequests() {
        guard let modelContext = modelContext else { return }
        
        do {
            let pendingDescriptor = FetchDescriptor<EmergencyAccessRequest>(
                predicate: #Predicate { $0.status == "pending" },
                sortBy: [SortDescriptor(\.requestedAt)]
            )
            pendingRequests = try modelContext.fetch(pendingDescriptor)
            
            let activeDescriptor = FetchDescriptor<EmergencyAccessRequest>(
                predicate: #Predicate { $0.status == "approved" },
                sortBy: [SortDescriptor(\.approvedAt, order: .reverse)]
            )
            activeGrants = try modelContext.fetch(activeDescriptor)
        } catch {
            print("Error loading emergency access requests: \(error)")
        }
    }
    
    /// Request emergency access
    func requestEmergencyAccess(
        vaultID: UUID,
        requesterID: UUID,
        reason: String,
        urgency: String = "medium"
    ) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        let request = EmergencyAccessRequest(
            reason: reason,
            urgency: urgency,
            status: "pending"
        )
        request.vault = try? modelContext.fetch(FetchDescriptor<Vault>(predicate: #Predicate { $0.id == vaultID })).first
        request.requesterID = requesterID
        
        modelContext.insert(request)
        try modelContext.save()
        loadRequests()
    }
    
    /// Approve emergency access
    func approveEmergencyAccess(
        _ request: EmergencyAccessRequest,
        approverID: UUID
    ) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        request.status = "approved"
        request.approvedAt = Date()
        request.approverID = approverID
        request.expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        
        try modelContext.save()
        loadRequests()
    }
    
    /// Deny emergency access
    func denyEmergencyAccess(
        _ request: EmergencyAccessRequest,
        approverID: UUID
    ) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        request.status = "denied"
        request.approverID = approverID
        
        try modelContext.save()
        loadRequests()
    }
    
    /// Revoke emergency access
    func revokeEmergencyAccess(_ request: EmergencyAccessRequest) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        request.status = "denied"
        request.expiresAt = Date()
        
        try modelContext.save()
        loadRequests()
    }
    
    // MARK: - Expiration Monitoring
    
    private func startExpirationMonitoring() {
        Task {
            while true {
                await checkExpiredGrants()
                try? await Task.sleep(nanoseconds: 60_000_000_000) // Check every minute
            }
        }
    }
    
    private func checkExpiredGrants() async {
        guard let modelContext = modelContext else { return }
        
        let now = Date()
        for grant in activeGrants {
            if let expiresAt = grant.expiresAt, expiresAt <= now {
                do {
                    grant.status = "denied"
                    try modelContext.save()
                    loadRequests()
                } catch {
                    print("Error revoking expired grant: \(error)")
                }
            }
        }
    }
}


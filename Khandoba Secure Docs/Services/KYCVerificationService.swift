//
//  KYCVerificationService.swift
//  Khandoba Secure Docs
//
//  KYC verification service
//

import Foundation
import SwiftData
import Combine

@MainActor
final class KYCVerificationService: ObservableObject {
    static let shared = KYCVerificationService()
    
    @Published var pendingVerifications: [IDVerification] = []
    @Published var isProcessing = false
    
    private var modelContext: ModelContext?
    
    private init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadPendingVerifications()
    }
    
    // MARK: - Verification Management
    
    private func loadPendingVerifications() {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<IDVerification>(
                predicate: #Predicate { $0.status == "Pending" },
                sortBy: [SortDescriptor(\.submittedAt)]
            )
            pendingVerifications = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading pending verifications: \(error)")
        }
    }
    
    /// Submit KYC verification
    func submitVerification(
        userID: UUID,
        idDocumentID: UUID?,
        proofOfAddressID: UUID?,
        fullName: String?,
        dateOfBirth: Date?,
        address: String?
    ) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        let verification = IDVerification(userID: userID, status: .pending)
        verification.idDocumentID = idDocumentID
        verification.proofOfAddressID = proofOfAddressID
        verification.fullName = fullName
        verification.dateOfBirth = dateOfBirth
        verification.address = address
        
        modelContext.insert(verification)
        try modelContext.save()
        loadPendingVerifications()
    }
    
    /// Review and approve/reject verification
    func reviewVerification(
        _ verification: IDVerification,
        approved: Bool,
        reviewerID: UUID,
        notes: String?
    ) throws {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        verification.status = approved ? VerificationStatus.approved.rawValue : VerificationStatus.rejected.rawValue
        verification.reviewedAt = Date()
        verification.reviewerID = reviewerID
        verification.reviewNotes = notes
        verification.updatedAt = Date()
        
        try modelContext.save()
        loadPendingVerifications()
    }
    
    /// Get verification for user
    func getVerification(for userID: UUID) -> IDVerification? {
        guard let modelContext = modelContext else { return nil }
        
        do {
            let descriptor = FetchDescriptor<IDVerification>(
                predicate: #Predicate { $0.userID == userID },
                sortBy: [SortDescriptor(\.submittedAt, order: .reverse)]
            )
            return try modelContext.fetch(descriptor).first
        } catch {
            return nil
        }
    }
}


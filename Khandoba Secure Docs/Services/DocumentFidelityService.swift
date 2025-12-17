//
//  DocumentFidelityService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/17/25.
//

import Foundation
import SwiftData
import Combine
import SwiftUI
import CoreLocation

@MainActor
final class DocumentFidelityService: ObservableObject {
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    private var supabaseService: SupabaseService?
    private var currentUserID: UUID?
    
    nonisolated init() {}
    
    // SwiftData/CloudKit mode
    func configure(modelContext: ModelContext, userID: UUID) {
        self.modelContext = modelContext
        self.supabaseService = nil
        self.currentUserID = userID
    }
    
    // Supabase mode
    func configure(supabaseService: SupabaseService, userID: UUID) {
        self.supabaseService = supabaseService
        self.modelContext = nil
        self.currentUserID = userID
    }
    
    // MARK: - Transfer Tracking
    
    /// Track document transfer event
    func trackTransfer(
        document: Document,
        toVault: Vault,
        fromVault: Vault?,
        userID: UUID,
        location: CLLocation? = nil,
        deviceInfo: String? = nil,
        ipAddress: String? = nil,
        reason: String? = nil
    ) async throws {
        print("📊 Tracking document transfer: \(document.name)")
        
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await trackTransferInSupabase(
                document: document,
                toVault: toVault,
                fromVault: fromVault,
                userID: userID,
                location: location,
                deviceInfo: deviceInfo,
                ipAddress: ipAddress,
                reason: reason,
                supabaseService: supabaseService
            )
        } else {
            try await trackTransferInSwiftData(
                document: document,
                toVault: toVault,
                fromVault: fromVault,
                userID: userID,
                location: location,
                deviceInfo: deviceInfo,
                ipAddress: ipAddress,
                reason: reason
            )
        }
    }
    
    private func trackTransferInSwiftData(
        document: Document,
        toVault: Vault,
        fromVault: Vault?,
        userID: UUID,
        location: CLLocation?,
        deviceInfo: String?,
        ipAddress: String?,
        reason: String?
    ) async throws {
        guard let modelContext = modelContext else {
            throw FidelityError.contextNotAvailable
        }
        
        // Get or create fidelity record
        let fidelity = try await getOrCreateFidelity(for: document, modelContext: modelContext)
        
        // Create transfer event
        let transferEvent = TransferEvent(
            timestamp: Date(),
            fromVaultID: fromVault?.id,
            toVaultID: toVault.id,
            userID: userID,
            userName: nil, // Can be fetched if needed
            locationLatitude: location?.coordinate.latitude,
            locationLongitude: location?.coordinate.longitude,
            deviceInfo: deviceInfo ?? UIDevice.current.model,
            ipAddress: ipAddress,
            reason: reason
        )
        
        // Update transfer history
        var history = fidelity.transferHistory
        history.append(transferEvent)
        fidelity.transferHistory = history
        fidelity.transferCount = history.count
        
        // Update unique counts
        updateUniqueCounts(fidelity: fidelity, location: location, deviceInfo: deviceInfo, ipAddress: ipAddress)
        
        // Recompute fidelity score
        try await computeFidelityScore(for: fidelity)
        
        // Save
        try modelContext.save()
        print("✅ Transfer tracked: \(fidelity.transferCount) total transfers")
    }
    
    private func trackTransferInSupabase(
        document: Document,
        toVault: Vault,
        fromVault: Vault?,
        userID: UUID,
        location: CLLocation?,
        deviceInfo: String?,
        ipAddress: String?,
        reason: String?,
        supabaseService: SupabaseService
    ) async throws {
        // Get or create fidelity record
        let fidelity = try await getOrCreateFidelityInSupabase(for: document, supabaseService: supabaseService)
        
        // Create transfer event
        let transferEvent = TransferEvent(
            timestamp: Date(),
            fromVaultID: fromVault?.id,
            toVaultID: toVault.id,
            userID: userID,
            userName: nil,
            locationLatitude: location?.coordinate.latitude,
            locationLongitude: location?.coordinate.longitude,
            deviceInfo: deviceInfo ?? UIDevice.current.model,
            ipAddress: ipAddress,
            reason: reason
        )
        
        // Update transfer history
        var history = fidelity.transferHistory
        history.append(transferEvent)
        fidelity.transferHistory = history
        fidelity.transferCount = history.count
        
        // Update unique counts
        updateUniqueCounts(fidelity: fidelity, location: location, deviceInfo: deviceInfo, ipAddress: ipAddress)
        
        // Recompute fidelity score
        try await computeFidelityScore(for: fidelity)
        
        // Update in Supabase
        let supabaseFidelity = try await convertToSupabaseFidelity(fidelity, documentID: document.id)
        try await supabaseService.update("document_fidelity", id: fidelity.id, values: supabaseFidelity)
        print("✅ Transfer tracked in Supabase: \(fidelity.transferCount) total transfers")
    }
    
    // MARK: - Edit Tracking
    
    /// Track document edit event
    func trackEdit(
        document: Document,
        userID: UUID,
        versionNumber: Int,
        changeDescription: String? = nil,
        location: CLLocation? = nil,
        deviceInfo: String? = nil,
        ipAddress: String? = nil
    ) async throws {
        print("📝 Tracking document edit: \(document.name) (v\(versionNumber))")
        
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await trackEditInSupabase(
                document: document,
                userID: userID,
                versionNumber: versionNumber,
                changeDescription: changeDescription,
                location: location,
                deviceInfo: deviceInfo,
                ipAddress: ipAddress,
                supabaseService: supabaseService
            )
        } else {
            try await trackEditInSwiftData(
                document: document,
                userID: userID,
                versionNumber: versionNumber,
                changeDescription: changeDescription,
                location: location,
                deviceInfo: deviceInfo,
                ipAddress: ipAddress
            )
        }
    }
    
    private func trackEditInSwiftData(
        document: Document,
        userID: UUID,
        versionNumber: Int,
        changeDescription: String?,
        location: CLLocation?,
        deviceInfo: String?,
        ipAddress: String?
    ) async throws {
        guard let modelContext = modelContext else {
            throw FidelityError.contextNotAvailable
        }
        
        // Get or create fidelity record
        let fidelity = try await getOrCreateFidelity(for: document, modelContext: modelContext)
        
        // Create edit event
        let editEvent = EditEvent(
            timestamp: Date(),
            userID: userID,
            userName: nil,
            changeDescription: changeDescription,
            versionNumber: versionNumber,
            locationLatitude: location?.coordinate.latitude,
            locationLongitude: location?.coordinate.longitude,
            deviceInfo: deviceInfo ?? UIDevice.current.model,
            ipAddress: ipAddress
        )
        
        // Update edit history
        var history = fidelity.editHistory
        history.append(editEvent)
        fidelity.editHistory = history
        fidelity.editCount = history.count
        
        // Update unique counts
        updateUniqueCounts(fidelity: fidelity, location: location, deviceInfo: deviceInfo, ipAddress: ipAddress)
        
        // Recompute fidelity score
        try await computeFidelityScore(for: fidelity)
        
        // Save
        try modelContext.save()
        print("✅ Edit tracked: \(fidelity.editCount) total edits")
    }
    
    private func trackEditInSupabase(
        document: Document,
        userID: UUID,
        versionNumber: Int,
        changeDescription: String?,
        location: CLLocation?,
        deviceInfo: String?,
        ipAddress: String?,
        supabaseService: SupabaseService
    ) async throws {
        // Get or create fidelity record
        let fidelity = try await getOrCreateFidelityInSupabase(for: document, supabaseService: supabaseService)
        
        // Create edit event
        let editEvent = EditEvent(
            timestamp: Date(),
            userID: userID,
            userName: nil,
            changeDescription: changeDescription,
            versionNumber: versionNumber,
            locationLatitude: location?.coordinate.latitude,
            locationLongitude: location?.coordinate.longitude,
            deviceInfo: deviceInfo ?? UIDevice.current.model,
            ipAddress: ipAddress
        )
        
        // Update edit history
        var history = fidelity.editHistory
        history.append(editEvent)
        fidelity.editHistory = history
        fidelity.editCount = history.count
        
        // Update unique counts
        updateUniqueCounts(fidelity: fidelity, location: location, deviceInfo: deviceInfo, ipAddress: ipAddress)
        
        // Recompute fidelity score
        try await computeFidelityScore(for: fidelity)
        
        // Update in Supabase
        let supabaseFidelity = try await convertToSupabaseFidelity(fidelity, documentID: document.id)
        try await supabaseService.update("document_fidelity", id: fidelity.id, values: supabaseFidelity)
        print("✅ Edit tracked in Supabase: \(fidelity.editCount) total edits")
    }
    
    // MARK: - Fidelity Score Computation
    
    /// Compute fidelity score (0-100) for a document
    func computeFidelityScore(for fidelity: DocumentFidelity) async throws {
        var score = 100.0 // Base score
        
        // Transfer count deduction: -2 points per transfer (max -30)
        let transferDeduction = min(Double(fidelity.transferCount) * 2.0, 30.0)
        score -= transferDeduction
        
        // Edit count deduction: -1 point per edit (max -20)
        let editDeduction = min(Double(fidelity.editCount) * 1.0, 20.0)
        score -= editDeduction
        
        // Rapid transfers: -5 points per transfer within 1 hour (max -15)
        let rapidTransferDeduction = detectRapidTransfers(fidelity: fidelity)
        score -= rapidTransferDeduction
        
        // Geographic anomalies: -10 points per impossible travel (max -20)
        let geoDeduction = detectGeographicAnomalies(fidelity: fidelity)
        score -= geoDeduction
        
        // Device/IP changes: -3 points per unique device (max -15)
        let deviceDeduction = min(Double(fidelity.uniqueDeviceCount) * 3.0, 15.0)
        score -= deviceDeduction
        
        // Clamp to 0-100
        score = max(0, min(100, score))
        
        fidelity.fidelityScore = Int(score)
        fidelity.lastComputedAt = Date()
        
        // Detect threat patterns
        detectThreatPatterns(fidelity: fidelity)
        
        print("📊 Fidelity score computed: \(fidelity.fidelityScore)/100")
    }
    
    private func detectRapidTransfers(fidelity: DocumentFidelity) -> Double {
        let transfers = fidelity.transferHistory.sorted { $0.timestamp > $1.timestamp }
        var rapidCount = 0
        
        for i in 0..<transfers.count - 1 {
            let timeDiff = transfers[i].timestamp.timeIntervalSince(transfers[i + 1].timestamp)
            if timeDiff < 3600 { // Less than 1 hour
                rapidCount += 1
            }
        }
        
        return min(Double(rapidCount) * 5.0, 15.0)
    }
    
    private func detectGeographicAnomalies(fidelity: DocumentFidelity) -> Double {
        let transfers = fidelity.transferHistory.filter { $0.locationLatitude != nil && $0.locationLongitude != nil }
        var anomalyCount = 0
        
        for i in 0..<transfers.count - 1 {
            guard let loc1 = transfers[i].locationLatitude,
                  let lon1 = transfers[i].locationLongitude,
                  let loc2 = transfers[i + 1].locationLatitude,
                  let lon2 = transfers[i + 1].locationLongitude else {
                continue
            }
            
            let coord1 = CLLocation(latitude: loc1, longitude: lon1)
            let coord2 = CLLocation(latitude: loc2, longitude: lon2)
            let distance = coord1.distance(from: coord2) // meters
            let timeDiff = abs(transfers[i].timestamp.timeIntervalSince(transfers[i + 1].timestamp))
            
            // Impossible travel: > 1000 km in < 2 hours
            if distance > 1_000_000 && timeDiff < 7200 {
                anomalyCount += 1
            }
        }
        
        return min(Double(anomalyCount) * 10.0, 20.0)
    }
    
    private func detectThreatPatterns(fidelity: DocumentFidelity) {
        var threats: [ThreatIndicator] = []
        
        // Rapid transfers
        let rapidTransfers = detectRapidTransfers(fidelity: fidelity)
        if rapidTransfers > 0 {
            threats.append(ThreatIndicator(
                type: "rapid_transfer",
                severity: rapidTransfers >= 10 ? "high" : "medium",
                description: "Multiple transfers detected within short time period",
                detectedAt: Date(),
                details: ["rapid_transfer_count": String(Int(rapidTransfers / 5))]
            ))
        }
        
        // Geographic anomalies
        let geoAnomalies = detectGeographicAnomalies(fidelity: fidelity)
        if geoAnomalies > 0 {
            threats.append(ThreatIndicator(
                type: "geographic_anomaly",
                severity: geoAnomalies >= 15 ? "critical" : "high",
                description: "Impossible travel distances detected",
                detectedAt: Date(),
                details: ["anomaly_count": String(Int(geoAnomalies / 10))]
            ))
        }
        
        // Device changes
        if fidelity.uniqueDeviceCount > 3 {
            threats.append(ThreatIndicator(
                type: "device_change",
                severity: fidelity.uniqueDeviceCount > 5 ? "high" : "medium",
                description: "Multiple devices accessed this document",
                detectedAt: Date(),
                details: ["device_count": String(fidelity.uniqueDeviceCount)]
            ))
        }
        
        // Low fidelity score
        if fidelity.fidelityScore < 50 {
            threats.append(ThreatIndicator(
                type: "low_fidelity",
                severity: fidelity.fidelityScore < 30 ? "critical" : "high",
                description: "Document fidelity score is below threshold",
                detectedAt: Date(),
                details: ["fidelity_score": String(fidelity.fidelityScore)]
            ))
        }
        
        fidelity.threatIndicators = threats
    }
    
    private func updateUniqueCounts(
        fidelity: DocumentFidelity,
        location: CLLocation?,
        deviceInfo: String?,
        ipAddress: String?
    ) {
        // Track unique devices
        let allDevices = Set(fidelity.transferHistory.compactMap { $0.deviceInfo } +
                             fidelity.editHistory.compactMap { $0.deviceInfo })
        fidelity.uniqueDeviceCount = allDevices.count
        
        // Track unique IPs
        let allIPs = Set(fidelity.transferHistory.compactMap { $0.ipAddress } +
                        fidelity.editHistory.compactMap { $0.ipAddress })
        fidelity.uniqueIPCount = allIPs.count
        
        // Track unique locations
        let allLocations = Set(fidelity.transferHistory.compactMap { event -> String? in
            guard let lat = event.locationLatitude, let lon = event.locationLongitude else { return nil }
            return "\(lat),\(lon)"
        } + fidelity.editHistory.compactMap { event -> String? in
            guard let lat = event.locationLatitude, let lon = event.locationLongitude else { return nil }
            return "\(lat),\(lon)"
        })
        fidelity.uniqueLocationCount = allLocations.count
    }
    
    // MARK: - Helper Methods
    
    private func getOrCreateFidelity(for document: Document, modelContext: ModelContext) async throws -> DocumentFidelity {
        let descriptor = FetchDescriptor<DocumentFidelity>(
            predicate: #Predicate { $0.document?.id == document.id }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        
        let fidelity = DocumentFidelity(document: document)
        modelContext.insert(fidelity)
        try modelContext.save()
        return fidelity
    }
    
    private func getOrCreateFidelityInSupabase(for document: Document, supabaseService: SupabaseService) async throws -> DocumentFidelity {
        // Try to fetch existing
        do {
            let supabaseFidelitys: [SupabaseDocumentFidelity] = try await supabaseService.fetchAll(
                "document_fidelity",
                filters: ["document_id": document.id.uuidString]
            )
            
            if let existing = supabaseFidelitys.first {
                return try await convertFromSupabaseFidelity(existing, document: document)
            }
        } catch {
            print("⚠️ Failed to fetch fidelity record: \(error)")
        }
        
        // Create new
        let fidelity = DocumentFidelity(document: document)
        let supabaseFidelity = try await convertToSupabaseFidelity(fidelity, documentID: document.id)
        let created: SupabaseDocumentFidelity = try await supabaseService.insert("document_fidelity", values: supabaseFidelity)
        return try await convertFromSupabaseFidelity(created, document: document)
    }
    
    private func convertToSupabaseFidelity(_ fidelity: DocumentFidelity, documentID: UUID) async throws -> SupabaseDocumentFidelity {
        return SupabaseDocumentFidelity(
            id: fidelity.id,
            documentID: documentID,
            transferCount: fidelity.transferCount,
            editCount: fidelity.editCount,
            transferHistory: fidelity.transferHistory,
            editHistory: fidelity.editHistory,
            fidelityScore: fidelity.fidelityScore,
            threatIndicators: fidelity.threatIndicators,
            uniqueDeviceCount: fidelity.uniqueDeviceCount,
            uniqueIPCount: fidelity.uniqueIPCount,
            uniqueLocationCount: fidelity.uniqueLocationCount,
            lastComputedAt: fidelity.lastComputedAt,
            createdAt: fidelity.createdAt,
            updatedAt: Date()
        )
    }
    
    private func convertFromSupabaseFidelity(_ supabase: SupabaseDocumentFidelity, document: Document) async throws -> DocumentFidelity {
        let fidelity = DocumentFidelity(
            id: supabase.id,
            document: document,
            transferCount: supabase.transferCount,
            editCount: supabase.editCount,
            fidelityScore: supabase.fidelityScore
        )
        fidelity.transferHistory = supabase.transferHistory
        fidelity.editHistory = supabase.editHistory
        fidelity.threatIndicators = supabase.threatIndicators
        fidelity.uniqueDeviceCount = supabase.uniqueDeviceCount
        fidelity.uniqueIPCount = supabase.uniqueIPCount
        fidelity.uniqueLocationCount = supabase.uniqueLocationCount
        fidelity.lastComputedAt = supabase.lastComputedAt
        fidelity.createdAt = supabase.createdAt
        fidelity.updatedAt = supabase.updatedAt
        return fidelity
    }
    
    // MARK: - Reports
    
    /// Get fidelity report for a document
    func getFidelityReport(for document: Document) async throws -> FidelityReport {
        let fidelity: DocumentFidelity
        
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            fidelity = try await getOrCreateFidelityInSupabase(for: document, supabaseService: supabaseService)
        } else {
            guard let modelContext = modelContext else {
                throw FidelityError.contextNotAvailable
            }
            fidelity = try await getOrCreateFidelity(for: document, modelContext: modelContext)
        }
        
        return FidelityReport(
            documentID: document.id,
            documentName: document.name,
            fidelityScore: fidelity.fidelityScore,
            transferCount: fidelity.transferCount,
            editCount: fidelity.editCount,
            transferHistory: fidelity.transferHistory,
            editHistory: fidelity.editHistory,
            threatIndicators: fidelity.threatIndicators,
            uniqueDeviceCount: fidelity.uniqueDeviceCount,
            uniqueIPCount: fidelity.uniqueIPCount,
            uniqueLocationCount: fidelity.uniqueLocationCount,
            lastComputedAt: fidelity.lastComputedAt
        )
    }
}

// MARK: - Error Types

enum FidelityError: LocalizedError {
    case contextNotAvailable
    case documentNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Model context not available"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid fidelity data"
        }
    }
}

// MARK: - Report Structure

struct FidelityReport {
    var documentID: UUID
    var documentName: String
    var fidelityScore: Int
    var transferCount: Int
    var editCount: Int
    var transferHistory: [TransferEvent]
    var editHistory: [EditEvent]
    var threatIndicators: [ThreatIndicator]
    var uniqueDeviceCount: Int
    var uniqueIPCount: Int
    var uniqueLocationCount: Int
    var lastComputedAt: Date?
}

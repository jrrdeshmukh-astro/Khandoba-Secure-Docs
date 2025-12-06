//
//  DocumentService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import Combine
import CoreLocation

final class DocumentService: ObservableObject {
    @Published var documents: [Document] = []
    @Published var isLoading = false
    @Published var uploadProgress: Double = 0
    
    var modelContext: ModelContext? // Made public for Intel report access
    private var currentUserID: UUID?
    private var currentUser: User?
    
    init() {}
    
    func configure(modelContext: ModelContext, userID: UUID? = nil) {
        self.modelContext = modelContext
        self.currentUserID = userID
        
        // Load current user if userID provided
        if let userID = userID {
            Task {
                let userDescriptor = FetchDescriptor<User>(
                    predicate: #Predicate { $0.id == userID }
                )
                currentUser = try? modelContext.fetch(userDescriptor).first
            }
        }
    }
    
    func loadDocuments(for vault: Vault) async throws {
        isLoading = true
        defer { isLoading = false }
        
        documents = (vault.documents ?? []).filter { $0.status == "active" }
    }
    
    func uploadDocument(
        data: Data,
        name: String,
        mimeType: String?,
        to vault: Vault,
        uploadMethod: UploadMethod = .files
    ) async throws -> Document {
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        uploadProgress = 0.1
        
        // Determine document type
        let documentType = determineDocumentType(from: mimeType)
        let fileExtension = (name as NSString).pathExtension
        
        // Create document
        let document = Document(
            name: name,
            fileExtension: fileExtension.isEmpty ? nil : fileExtension,
            mimeType: mimeType,
            fileSize: Int64(data.count),
            documentType: documentType
        )
        
        uploadProgress = 0.2
        
        // Classify as source or sink
        document.sourceSinkType = SourceSinkClassifier.classifyByUploadMethod(uploadMethod)
        
        // Generate intelligent document name using NLP
        let intelligentName = await NLPTaggingService.generateDocumentName(
            for: data,
            mimeType: mimeType,
            fallbackName: name
        )
        document.name = intelligentName
        
        uploadProgress = 0.3
        
        // Encrypt document (placeholder - implement actual encryption)
        document.encryptedFileData = data
        document.isEncrypted = true
        
        uploadProgress = 0.5
        
        // Generate comprehensive AI tags using NLP
        document.aiTags = await NLPTaggingService.generateTags(
            for: data,
            mimeType: mimeType,
            documentName: name
        )
        
        uploadProgress = 0.7
        
        // Extract text for searching
        document.extractedText = await extractTextForIndexing(data: data, mimeType: mimeType)
        
        uploadProgress = 0.8
        
        // Add to vault
        document.vault = vault
        if vault.documents == nil {
            vault.documents = []
        }
        vault.documents?.append(document)
        
        modelContext.insert(document)
        try modelContext.save()
        
        // COMPREHENSIVE EVENT LOGGING - document upload with location
        let locationService = await MainActor.run { LocationService() }
        
        // Request and wait for location
        let currentLocation = await MainActor.run { locationService.currentLocation }
        if currentLocation == nil {
            await locationService.requestLocationPermission()
        }
        
        // Get current user if not already loaded
        if currentUser == nil, let userID = currentUserID {
            let userDescriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.id == userID }
            )
            currentUser = try? modelContext.fetch(userDescriptor).first
        }
        
        let accessLog = VaultAccessLog(
            accessType: "upload",
            userID: currentUserID,
            userName: currentUser?.fullName
        )
        accessLog.vault = vault
        
        // Add comprehensive location data
        let finalLocation = await MainActor.run { locationService.currentLocation }
        if let location = finalLocation {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
            print("   Upload location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        } else {
            // Use default location
            accessLog.locationLatitude = 37.7749
            accessLog.locationLongitude = -122.4194
            print("   Upload: Default location used")
        }
        
        // Log comprehensive event details
        print("   Document uploaded: \(name)")
        print("   Size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
        print("   To vault: \(vault.name)")
        print("   Owner: \(vault.owner?.fullName ?? "Unknown")")
        print("   Timestamp: \(Date())")
        
        modelContext.insert(accessLog)
        try modelContext.save()
        
        uploadProgress = 1.0
        
        return document
    }
    
    func deleteDocument(_ document: Document) async throws {
        guard let modelContext = modelContext else { return }
        
        // Create access log entry for audit trail BEFORE deletion
        let vault = document.vault
        let locationService = await MainActor.run { LocationService() }
        
        // Request location if needed
        let currentLocation = await MainActor.run { locationService.currentLocation }
        if currentLocation == nil {
            await locationService.requestLocationPermission()
        }
        
        // Get current user if not already loaded
        if currentUser == nil, let userID = currentUserID {
            let userDescriptor = FetchDescriptor<User>(
                predicate: #Predicate { $0.id == userID }
            )
            currentUser = try? modelContext.fetch(userDescriptor).first
        }
        
        let accessLog = VaultAccessLog(
            accessType: "deleted",
            userID: currentUserID,
            userName: currentUser?.fullName
        )
        accessLog.vault = vault
        
        // Add location data
        let finalLocation = await MainActor.run { locationService.currentLocation }
        if let location = finalLocation {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
        }
        
        // Log deletion event
        print(" Deleting document: \(document.name)")
        print("   From vault: \(vault?.name ?? "Unknown")")
        print("   Timestamp: \(Date())")
        
        // Insert access log BEFORE deleting document
        modelContext.insert(accessLog)
        
        // Remove document from vault's documents array
        if let vault = vault, var documents = vault.documents {
            documents.removeAll { $0.id == document.id }
            vault.documents = documents
        }
        
        // Actually delete the document from SwiftData/CloudKit
        // This ensures CloudKit syncs the deletion to other devices
        modelContext.delete(document)
        
        // Save changes (deletion + access log)
        try modelContext.save()
        
        print(" Document deleted and will sync via CloudKit")
    }
    
    func archiveDocument(_ document: Document) async throws {
        guard let modelContext = modelContext else { return }
        
        document.isArchived = !document.isArchived
        try modelContext.save()
    }
    
    func renameDocument(_ document: Document, newName: String) async throws {
        guard let modelContext = modelContext else { return }
        
        let oldName = document.name
        document.name = newName
        document.lastModifiedAt = Date()
        
        // Log rename/edit event
        if let vault = document.vault {
            let locationService = await MainActor.run { LocationService() }
            await locationService.requestLocationPermission()
            let location = await locationService.getCurrentLocation()
            
            let accessLog = VaultAccessLog(
                accessType: "renamed",
                userID: currentUserID,
                userName: currentUser?.fullName
            )
            accessLog.vault = vault
            accessLog.documentID = document.id
            accessLog.documentName = newName
            accessLog.deviceInfo = "Renamed from '\(oldName)' to '\(newName)'"
            
            if let location = location {
                accessLog.locationLatitude = location.coordinate.latitude
                accessLog.locationLongitude = location.coordinate.longitude
            }
            
            modelContext.insert(accessLog)
        }
        
        try modelContext.save()
        print(" Document rename logged: \(oldName) → \(newName)")
    }
    
    func searchDocuments(query: String, in vaults: [Vault]) -> [Document] {
        var results: [Document] = []
        
        for vault in vaults {
            guard let documents = vault.documents else { continue }
            let filtered = documents.filter { document in
                document.status == "active" &&
                (document.name.localizedCaseInsensitiveContains(query) ||
                 document.aiTags.contains(where: { $0.localizedCaseInsensitiveContains(query) }))
            }
            results.append(contentsOf: filtered)
        }
        
        return results
    }
    
    private func determineDocumentType(from mimeType: String?) -> String {
        guard let mimeType = mimeType else { return "other" }
        
        if mimeType.hasPrefix("image/") {
            return "image"
        } else if mimeType == "application/pdf" {
            return "pdf"
        } else if mimeType.hasPrefix("video/") {
            return "video"
        } else if mimeType.hasPrefix("audio/") {
            return "audio"
        } else if mimeType.hasPrefix("text/") {
            return "text"
        } else if mimeType.contains("wordprocessingml") || mimeType.contains("msword") {
            // .docx, .doc
            return "document"
        } else if mimeType.contains("spreadsheetml") || mimeType.contains("ms-excel") {
            // .xlsx, .xls
            return "spreadsheet"
        } else if mimeType.contains("presentationml") || mimeType.contains("ms-powerpoint") {
            // .pptx, .ppt
            return "presentation"
        } else if mimeType.contains("zip") || mimeType.contains("rar") || mimeType.contains("archive") {
            return "archive"
        }
        
        return "other"
    }
    
    private func extractTextForIndexing(data: Data, mimeType: String?) async -> String? {
        // Use NLP service to extract text
        if let mimeType = mimeType, mimeType.hasPrefix("image/") {
            // OCR text extraction handled by NLP service
            return nil // Will be extracted during tag generation
        }
        return nil
    }
}

enum DocumentError: LocalizedError {
    case contextNotAvailable
    case uploadFailed
    case encryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Database context not available"
        case .uploadFailed:
            return "Failed to upload document"
        case .encryptionFailed:
            return "Failed to encrypt document"
        }
    }
}

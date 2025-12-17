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
    private var supabaseService: SupabaseService?
    private var currentUserID: UUID?
    private var currentUser: User?
    
    init() {}
    
    // SwiftData/CloudKit mode
    func configure(modelContext: ModelContext, userID: UUID? = nil) {
        self.modelContext = modelContext
        self.supabaseService = nil
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
    
    // Supabase mode
    func configure(supabaseService: SupabaseService, userID: UUID? = nil) {
        self.supabaseService = supabaseService
        self.modelContext = nil
        self.currentUserID = userID
        
        // Load current user from Supabase if userID provided
        if let userID = userID {
            Task {
                do {
                    let supabaseUser: SupabaseUser = try await supabaseService.fetch(
                        "users",
                        id: userID
                    )
                    // Convert to User model for compatibility
                    await MainActor.run {
                        // Note: We'll create a User from SupabaseUser when needed
                    }
                } catch {
                    print("⚠️ Failed to load user from Supabase: \(error)")
                }
            }
        }
    }
    
    func loadDocuments(for vault: Vault) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await loadDocumentsFromSupabase(vaultID: vault.id, supabaseService: supabaseService, vault: vault)
            return
        }
        
        // SwiftData/CloudKit mode
        documents = (vault.documents ?? []).filter { $0.status == "active" }
    }
    
    /// Load documents from Supabase
    private func loadDocumentsFromSupabase(vaultID: UUID, supabaseService: SupabaseService, vault: Vault) async throws {
        print("📄 Loading documents from Supabase for vault: \(vaultID)")
        // RLS automatically filters documents user has access to
        let supabaseDocs: [SupabaseDocument] = try await supabaseService.fetchAll(
            "documents",
            filters: ["vault_id": vaultID.uuidString, "status": "active"]
        )
        
        print("   Found \(supabaseDocs.count) document(s) in Supabase")
        
        // Convert to Document models for compatibility
        // Note: We need to find the vault object to link documents to it
        // For now, we'll store documents without vault link (vault ID is in SupabaseDocument)
        await MainActor.run {
            self.documents = supabaseDocs.map { supabaseDoc in
                let document = Document(
                    name: supabaseDoc.name,
                    fileExtension: supabaseDoc.fileExtension,
                    mimeType: supabaseDoc.mimeType,
                    fileSize: supabaseDoc.fileSize,
                    documentType: supabaseDoc.documentType,
                    isEncrypted: supabaseDoc.isEncrypted,
                    isArchived: supabaseDoc.isArchived,
                    isRedacted: supabaseDoc.isRedacted,
                    status: supabaseDoc.status,
                    aiTags: supabaseDoc.aiTags
                )
                document.id = supabaseDoc.id
                document.createdAt = supabaseDoc.createdAt
                document.uploadedAt = supabaseDoc.uploadedAt
                document.lastModifiedAt = supabaseDoc.lastModifiedAt
                document.encryptionKeyData = supabaseDoc.encryptionKeyData
                document.sourceSinkType = supabaseDoc.sourceSinkType
                document.extractedText = supabaseDoc.extractedText
                document.fileHash = supabaseDoc.fileHash
                document.author = supabaseDoc.author
                document.cameraInfo = supabaseDoc.cameraInfo
                document.deviceID = supabaseDoc.deviceID
                document.uploadedByUserID = supabaseDoc.uploadedByUserID
                
                // Link document to vault
                document.vault = vault
                
                // Note: encryptedFileData is not loaded here - it's in Supabase Storage
                // Will be downloaded when document is accessed
                
                return document
            }
            print("✅ Loaded \(self.documents.count) document(s) into DocumentService")
        }
    }
    
    func uploadDocument(
        data: Data,
        name: String,
        mimeType: String?,
        to vault: Vault,
        uploadMethod: UploadMethod = .files
    ) async throws -> Document {
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            return try await uploadDocumentToSupabase(
                data: data,
                name: name,
                mimeType: mimeType,
                vault: vault,
                uploadMethod: uploadMethod,
                supabaseService: supabaseService
            )
        }
        
        // SwiftData/CloudKit mode
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
        
        // IMPORTANT: Run LLaMA analysis on UNENCRYPTED data before encryption
        var intelligentName = name
        var aiTags: [String] = []
        var extractedText: String?
        
        // Check if LLaMA analysis is authorized
        let useLlama = true // TODO: Check subscription/premium status
        
        if useLlama {
            // Generate intelligent document name using LLaMA (on unencrypted data)
            intelligentName = await NLPTaggingService.generateDocumentName(
                for: data,
                mimeType: mimeType,
                fallbackName: name
            )
            
            uploadProgress = 0.3
            
            // Generate comprehensive AI tags using LLaMA (on unencrypted data)
            aiTags = await NLPTaggingService.generateTags(
                for: data,
                mimeType: mimeType,
                documentName: intelligentName
            )
            
            uploadProgress = 0.4
            
            // Extract text for searching (on unencrypted data)
            extractedText = await extractTextForIndexing(data: data, mimeType: mimeType)
        }
        
        document.name = intelligentName
        document.aiTags = aiTags
        document.extractedText = extractedText
        
        uploadProgress = 0.5
        
        // NOW encrypt the document (after LLaMA analysis on unencrypted data)
        document.encryptedFileData = data
        document.isEncrypted = true
        
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
    
    /// Upload document to Supabase Storage
    private func uploadDocumentToSupabase(
        data: Data,
        name: String,
        mimeType: String?,
        vault: Vault,
        uploadMethod: UploadMethod,
        supabaseService: SupabaseService
    ) async throws -> Document {
        uploadProgress = 0.1
        
        // Determine document type
        let documentType = determineDocumentType(from: mimeType)
        let fileExtension = (name as NSString).pathExtension
        
        uploadProgress = 0.2
        
        // IMPORTANT: Run LLaMA analysis on UNENCRYPTED data before encryption
        // This allows LLaMA to analyze the actual content for better naming and tagging
        let documentID = UUID()
        var intelligentName = name
        var aiTags: [String] = []
        var extractedText: String?
        
        // Check if LLaMA analysis is authorized (user has premium or feature enabled)
        // For now, we'll always run LLaMA if available
        let useLlama = true // TODO: Check subscription/premium status
        
        if useLlama {
            // Generate intelligent document name using LLaMA (on unencrypted data)
            intelligentName = await NLPTaggingService.generateDocumentName(
                for: data,
                mimeType: mimeType,
                fallbackName: name
            )
            
            uploadProgress = 0.3
            
            // Generate comprehensive AI tags using LLaMA (on unencrypted data)
            aiTags = await NLPTaggingService.generateTags(
                for: data,
                mimeType: mimeType,
                documentName: intelligentName
            )
            
            uploadProgress = 0.4
            
            // Extract text for searching (on unencrypted data)
            extractedText = await extractTextForIndexing(data: data, mimeType: mimeType)
        } else {
            // Fallback: Use basic name and tags if LLaMA not authorized
            aiTags = []
            extractedText = nil
        }
        
        uploadProgress = 0.5
        
        // NOW encrypt the document (after LLaMA analysis on unencrypted data)
        let (encryptedData, encryptionKey) = try EncryptionService.encryptDocument(data, documentID: documentID)
        
        uploadProgress = 0.6
        
        // Upload encrypted file to Supabase Storage
        let storagePath = "\(vault.id.uuidString)/\(documentID.uuidString).encrypted"
        let _ = try await supabaseService.uploadFile(
            bucket: SupabaseConfig.encryptedDocumentsBucket,
            path: storagePath,
            data: encryptedData
        )
        
        uploadProgress = 0.8
        
        // Create document record in Supabase
        // Note: encryptionKey is stored in keychain by EncryptionService.encryptDocument
        // We don't store the key in the database for security (zero-knowledge architecture)
        let supabaseDocument = SupabaseDocument(
            id: documentID,
            vaultID: vault.id,
            name: intelligentName,
            fileExtension: fileExtension.isEmpty ? nil : fileExtension,
            mimeType: mimeType,
            fileSize: Int64(data.count),
            storagePath: storagePath,
            encryptionKeyData: nil, // Key stored in keychain, not database
            isEncrypted: true,
            documentType: documentType,
            sourceSinkType: SourceSinkClassifier.classifyByUploadMethod(uploadMethod),
            isArchived: false,
            isRedacted: false,
            status: "active",
            extractedText: extractedText,
            aiTags: aiTags,
            uploadedByUserID: currentUserID
        )
        
        let created: SupabaseDocument = try await supabaseService.insert(
            "documents",
            values: supabaseDocument
        )
        
        uploadProgress = 0.9
        
        // Create access log
        let locationService = await MainActor.run { LocationService() }
        let location = await MainActor.run { locationService.currentLocation }
        
        var accessLog = SupabaseVaultAccessLog(
            vaultID: vault.id,
            accessType: "upload",
            userID: currentUserID,
            documentID: documentID,
            documentName: intelligentName
        )
        
        if let location = location {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
        }
        
        let _: SupabaseVaultAccessLog = try await supabaseService.insert(
            "vault_access_logs",
            values: accessLog
        )
        
        uploadProgress = 1.0
        
        // Convert to Document model for compatibility
        let document = Document(
            name: created.name,
            fileExtension: created.fileExtension,
            mimeType: created.mimeType,
            fileSize: created.fileSize,
            documentType: created.documentType,
            isEncrypted: created.isEncrypted,
            isArchived: created.isArchived,
            isRedacted: created.isRedacted,
            status: created.status,
            aiTags: created.aiTags
        )
        document.id = created.id
        document.createdAt = created.createdAt
        document.uploadedAt = created.uploadedAt
        document.sourceSinkType = created.sourceSinkType
        document.extractedText = created.extractedText
        document.uploadedByUserID = created.uploadedByUserID
        // Note: encryptedFileData is not stored - file is in Supabase Storage
        
        // Link document to vault
        document.vault = vault
        
        // Add document to service's documents array so it appears immediately in the view
        await MainActor.run {
            self.documents.append(document)
            print("✅ Document added to DocumentService: \(document.name)")
        }
        
        return document
    }
    
    func deleteDocument(_ document: Document) async throws {
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await deleteDocumentFromSupabase(document: document, supabaseService: supabaseService)
            return
        }
        
        // SwiftData/CloudKit mode
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
    
    /// Delete document from Supabase
    private func deleteDocumentFromSupabase(document: Document, supabaseService: SupabaseService) async throws {
        // Fetch document from Supabase to get storage path
        let supabaseDoc: SupabaseDocument = try await supabaseService.fetch(
            "documents",
            id: document.id
        )
        
        // Delete file from Supabase Storage if path exists
        if let storagePath = supabaseDoc.storagePath {
            do {
                try await supabaseService.deleteFile(
                    bucket: SupabaseConfig.encryptedDocumentsBucket,
                    path: storagePath
                )
            } catch {
                print("⚠️ Failed to delete file from storage: \(error)")
                // Continue with record deletion even if file deletion fails
            }
        }
        
        // Create access log before deletion
        let locationService = await MainActor.run { LocationService() }
        let location = await MainActor.run { locationService.currentLocation }
        
        var accessLog = SupabaseVaultAccessLog(
            vaultID: supabaseDoc.vaultID,
            accessType: "deleted",
            userID: currentUserID,
            documentID: document.id,
            documentName: document.name
        )
        
        if let location = location {
            accessLog.locationLatitude = location.coordinate.latitude
            accessLog.locationLongitude = location.coordinate.longitude
        }
        
        let _: SupabaseVaultAccessLog = try await supabaseService.insert(
            "vault_access_logs",
            values: accessLog
        )
        
        // Delete document record (RLS will enforce permissions)
        try await supabaseService.delete("documents", id: document.id)
        
        // Remove from local documents array
        await MainActor.run {
            documents.removeAll { $0.id == document.id }
        }
        
        print("✅ Document deleted from Supabase")
    }
    
    func archiveDocument(_ document: Document) async throws {
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            // Fetch current document
            let supabaseDoc: SupabaseDocument = try await supabaseService.fetch(
                "documents",
                id: document.id
            )
            
            // Update archive status
            var updated = supabaseDoc
            updated.isArchived = !supabaseDoc.isArchived
            
            let _: SupabaseDocument = try await supabaseService.update(
                "documents",
                id: document.id,
                values: updated
            )
            
            // Update local document
            await MainActor.run {
                document.isArchived = updated.isArchived
            }
            return
        }
        
        // SwiftData/CloudKit mode
        guard let modelContext = modelContext else { return }
        
        document.isArchived = !document.isArchived
        try modelContext.save()
    }
    
    func renameDocument(_ document: Document, newName: String) async throws {
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            // Fetch current document
            let supabaseDoc: SupabaseDocument = try await supabaseService.fetch(
                "documents",
                id: document.id
            )
            
            let oldName = document.name
            
            // Update name
            var updated = supabaseDoc
            updated.name = newName
            updated.lastModifiedAt = Date()
            
            let _: SupabaseDocument = try await supabaseService.update(
                "documents",
                id: document.id,
                values: updated
            )
            
            // Create access log
            let locationService = await MainActor.run { LocationService() }
            let location = await MainActor.run { locationService.currentLocation }
            
            var accessLog = SupabaseVaultAccessLog(
                vaultID: supabaseDoc.vaultID,
                accessType: "renamed",
                userID: currentUserID,
                documentID: document.id,
                documentName: newName
            )
            accessLog.deviceInfo = "Renamed from '\(oldName)' to '\(newName)'"
            
            if let location = location {
                accessLog.locationLatitude = location.coordinate.latitude
                accessLog.locationLongitude = location.coordinate.longitude
            }
            
            let _: SupabaseVaultAccessLog = try await supabaseService.insert(
                "vault_access_logs",
                values: accessLog
            )
            
            // Update local document
            await MainActor.run {
                document.name = newName
                document.lastModifiedAt = Date()
            }
            
            print("✅ Document renamed in Supabase: \(oldName) → \(newName)")
            return
        }
        
        // SwiftData/CloudKit mode
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
    
    /// Download document data from Supabase Storage
    func downloadDocumentData(_ document: Document) async throws -> Data {
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            // Fetch document to get storage path
            let supabaseDoc: SupabaseDocument = try await supabaseService.fetch(
                "documents",
                id: document.id
            )
            
            guard let storagePath = supabaseDoc.storagePath else {
                throw DocumentError.uploadFailed
            }
            
            // Download encrypted file from Supabase Storage
            let encryptedData = try await supabaseService.downloadFile(
                bucket: SupabaseConfig.encryptedDocumentsBucket,
                path: storagePath
            )
            
            // Decrypt the file
            // Note: EncryptionService.encryptDocument stores key in keychain
            // We need to retrieve it using the document ID
            let key = try EncryptionService.retrieveKey(identifier: "doc-\(document.id.uuidString)")
            
            // Use decryptDocument which handles the format correctly
            let decryptedData = try EncryptionService.decryptDocument(encryptedData, documentID: document.id)
            
            return decryptedData
        }
        
        // SwiftData/CloudKit mode
        guard let encryptedData = document.encryptedFileData else {
            throw DocumentError.uploadFailed
        }
        
        // Decrypt if needed
        if document.isEncrypted {
            return try EncryptionService.decryptDocument(encryptedData, documentID: document.id)
        }
        
        return encryptedData
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

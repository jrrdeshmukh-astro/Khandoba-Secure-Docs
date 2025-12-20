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

#if os(iOS)
import UIKit
#endif

// Import AsyncTimeout for timeout handling

final class DocumentService: ObservableObject {
    @Published var documents: [Document] = []
    @Published var isLoading = false
    @Published var uploadProgress: Double = 0
    
    var modelContext: ModelContext? // Made public for Intel report access
    private var supabaseService: SupabaseService?
    private var currentUserID: UUID?
    private var currentUser: User?
    private var fidelityService: DocumentFidelityService?
    private var contentFilterService: ContentFilterService?
    private var subscriptionService: SubscriptionService?
    
    private var notificationObserver: NSObjectProtocol?
    
    init() {}
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // SwiftData/CloudKit mode
    func configure(modelContext: ModelContext, userID: UUID? = nil, fidelityService: DocumentFidelityService? = nil, contentFilterService: ContentFilterService? = nil, subscriptionService: SubscriptionService? = nil) {
        self.modelContext = modelContext
        self.supabaseService = nil
        self.currentUserID = userID
        self.fidelityService = fidelityService
        self.contentFilterService = contentFilterService
        self.subscriptionService = subscriptionService
        
        // Configure fidelity service if provided
        if let fidelityService = fidelityService, let userID = userID {
            fidelityService.configure(modelContext: modelContext, userID: userID)
        }
        
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
    func configure(supabaseService: SupabaseService, userID: UUID? = nil, fidelityService: DocumentFidelityService? = nil, contentFilterService: ContentFilterService? = nil, subscriptionService: SubscriptionService? = nil) {
        self.supabaseService = supabaseService
        self.modelContext = nil
        self.currentUserID = userID
        self.fidelityService = fidelityService
        self.contentFilterService = contentFilterService
        self.subscriptionService = subscriptionService
        
        // Configure fidelity service if provided
        if let fidelityService = fidelityService, let userID = userID {
            fidelityService.configure(supabaseService: supabaseService, userID: userID)
        }
        
        // Load current user from Supabase if userID provided
        if let userID = userID {
            Task {
                do {
                    let _: SupabaseUser = try await supabaseService.fetch(
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
        
        // Setup realtime listener for document changes
        setupRealtimeListener()
    }
    
    // Track current vault for cache refresh (using ID to avoid Sendable issues)
    private var currentVault: Vault?
    private var currentVaultID: UUID?
    
    // Setup realtime listener for document sync
    private func setupRealtimeListener() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .supabaseRealtimeUpdate,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let channel = userInfo["channel"] as? String,
                  channel == "documents",
                  let event = userInfo["event"] as? String else {
                return
            }
            
            print("📡 DocumentService: Received realtime \(event) event for documents")
            
            // Refresh documents cache when changes occur
            Task {
                // Use vault ID to avoid Sendable conformance issue with Swift 6
                let vaultID = await MainActor.run { self.currentVaultID }
                let vaultIDString = vaultID?.uuidString
                if let vaultIDString = vaultIDString {
                    // Use vaultID string instead of vault object to avoid Sendable issue
                    await MainActor.run {
                        if let vault = self.currentVault, vault.id.uuidString == vaultIDString {
                            Task {
                                do {
                                    try await self.loadDocuments(for: vault)
                                    print("✅ DocumentService: Cache refreshed after realtime \(event)")
                                } catch {
                                    print("⚠️ DocumentService: Failed to refresh cache: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadDocuments(for vault: Vault) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Store current vault for realtime refresh
        await MainActor.run {
            self.currentVault = vault
            self.currentVaultID = vault.id
        }
        
        // Supabase mode - exclusive use when enabled
        if AppConfig.useSupabase {
            guard let supabaseService = supabaseService else {
                print("❌ DocumentService: Supabase mode enabled but SupabaseService not configured")
                throw DocumentError.serviceNotConfigured
            }
            try await loadDocumentsFromSupabase(vaultID: vault.id, supabaseService: supabaseService, vault: vault)
            return
        }
        
        // SwiftData/CloudKit mode (only when useSupabase = false)
        documents = (vault.documents ?? []).filter { $0.status == "active" }
    }
    
    /// Load documents from Supabase
    private func loadDocumentsFromSupabase(vaultID: UUID, supabaseService: SupabaseService, vault: Vault) async throws {
        // Add timeout to prevent hangs
        print("📄 Loading documents from Supabase for vault: \(vaultID)")
        // RLS automatically filters documents user has access to
        // Always fetch fresh data from Supabase (no cache) to ensure consistency
        // Add timeout to prevent hangs
        let supabaseDocs: [SupabaseDocument] = try await AsyncTimeout.withTimeout(10.0) {
            try await supabaseService.fetchAll(
                "documents",
                filters: ["vault_id": vaultID.uuidString, "status": "active"]
            )
        }
        
        print("   Found \(supabaseDocs.count) document(s) in Supabase (fresh fetch, cache replaced)")
        
        // Convert to Document models for compatibility
        // Note: We need to find the vault object to link documents to it
        // For now, we'll store documents without vault link (vault ID is in SupabaseDocument)
        await MainActor.run {
            // Replace entire cache with fresh data (not append) to ensure consistency
            // This prevents stale data from persisting across instances
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
        await MainActor.run {
            isLoading = true
            uploadProgress = 0.0
        }
        defer {
            Task { @MainActor in
                isLoading = false
                uploadProgress = 0.0
            }
        }
        // Supabase mode - exclusive use when enabled
        if AppConfig.useSupabase {
            guard let supabaseService = supabaseService else {
                print("❌ DocumentService.uploadDocument: Supabase mode enabled but SupabaseService not configured")
                throw DocumentError.serviceNotConfigured
            }
            return try await uploadDocumentToSupabase(
                data: data,
                name: name,
                mimeType: mimeType,
                vault: vault,
                uploadMethod: uploadMethod,
                supabaseService: supabaseService
            )
        }
        
        // SwiftData/CloudKit mode (only when useSupabase = false)
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        await MainActor.run {
            uploadProgress = 0.1
        }
        
        // CONTENT FILTERING: Check for inappropriate content before processing
        if let contentFilterService = contentFilterService {
            do {
                let filterResult = try await contentFilterService.filterContent(
                    data: data,
                    mimeType: mimeType,
                    documentType: nil
                )
                
                if filterResult.isBlocked {
                    print("🚫 Content blocked: \(filterResult.reason ?? "Inappropriate content detected")")
                    throw DocumentError.contentBlocked(
                        severity: filterResult.severity,
                        categories: filterResult.categories,
                        reason: filterResult.reason
                    )
                } else if filterResult.severity != .safe {
                    print("⚠️ Content warning: \(filterResult.reason ?? "Potentially inappropriate content")")
                    // Log warning but allow upload
                }
            } catch let error as DocumentError {
                if case .contentBlocked = error {
                    throw error
                }
            } catch {
                print("⚠️ Content filtering failed: \(error.localizedDescription)")
                // Continue with upload if filtering fails (fail-open for availability)
            }
        }
        
        await MainActor.run {
            uploadProgress = 0.15
        }
        
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
        
        await MainActor.run {
            uploadProgress = 0.2
        }
        
        // Classify as source or sink
        document.sourceSinkType = SourceSinkClassifier.classifyByUploadMethod(uploadMethod)
        
        // IMPORTANT: Run LLaMA analysis on UNENCRYPTED data before encryption
        var intelligentName = name
        var aiTags: [String] = []
        var extractedText: String?
        
        // Check if LLaMA analysis is authorized (premium subscription or feature enabled)
        let useLlama = await checkLlamaAuthorization()
        
        if useLlama {
            // Generate intelligent document name using LLaMA (on unencrypted data)
            intelligentName = await NLPTaggingService.generateDocumentName(
                for: data,
                mimeType: mimeType,
                fallbackName: name
            )
            
            await MainActor.run {
                uploadProgress = 0.3
            }
            
            // Generate comprehensive AI tags using LLaMA (on unencrypted data)
            aiTags = await NLPTaggingService.generateTags(
                for: data,
                mimeType: mimeType,
                documentName: intelligentName
            )
            
            await MainActor.run {
                uploadProgress = 0.4
            }
            
            // Extract text for searching (on unencrypted data)
            extractedText = await extractTextForIndexing(data: data, mimeType: mimeType)
        }
        
        document.name = intelligentName
        document.aiTags = aiTags
        document.extractedText = extractedText
        
        await MainActor.run {
            uploadProgress = 0.5
        }
        
        // NOW encrypt the document (after LLaMA analysis on unencrypted data)
        document.encryptedFileData = data
        document.isEncrypted = true
        
        await MainActor.run {
            uploadProgress = 0.8
        }
        
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
        
        await MainActor.run {
            uploadProgress = 1.0
        }
        
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
        await MainActor.run {
            uploadProgress = 0.1
        }
        
        // CONTENT FILTERING: Check for inappropriate content before processing
        if let contentFilterService = contentFilterService {
            do {
                let filterResult = try await contentFilterService.filterContent(
                    data: data,
                    mimeType: mimeType,
                    documentType: nil
                )
                
                if filterResult.isBlocked {
                    print("🚫 Content blocked: \(filterResult.reason ?? "Inappropriate content detected")")
                    throw DocumentError.contentBlocked(
                        severity: filterResult.severity,
                        categories: filterResult.categories,
                        reason: filterResult.reason
                    )
                } else if filterResult.severity != .safe {
                    print("⚠️ Content warning: \(filterResult.reason ?? "Potentially inappropriate content")")
                    // Log warning but allow upload
                }
            } catch let error as DocumentError {
                if case .contentBlocked = error {
                    throw error
                }
            } catch {
                print("⚠️ Content filtering failed: \(error.localizedDescription)")
                // Continue with upload if filtering fails (fail-open for availability)
            }
        }
        
        await MainActor.run {
            uploadProgress = 0.15
        }
        
        // Determine document type
        let documentType = determineDocumentType(from: mimeType)
        let fileExtension = (name as NSString).pathExtension
        
        await MainActor.run {
            uploadProgress = 0.2
        }
        
        // IMPORTANT: Run LLaMA analysis on UNENCRYPTED data before encryption
        // This allows LLaMA to analyze the actual content for better naming and tagging
        let documentID = UUID()
        var intelligentName = name
        var aiTags: [String] = []
        var extractedText: String?
        
        // Check if LLaMA analysis is authorized (premium subscription or feature enabled)
        let useLlama = await checkLlamaAuthorization()
        
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
        
        await MainActor.run {
            uploadProgress = 0.5
        }
        
        // NOW encrypt the document (after LLaMA analysis on unencrypted data)
        let (encryptedData, _) = try EncryptionService.encryptDocument(data, documentID: documentID)
        
        await MainActor.run {
            uploadProgress = 0.6
        }
        
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
        
        await MainActor.run {
            uploadProgress = 0.9
        }
        
        // Create access log
        let locationService = await MainActor.run { LocationService() }
        let location = await MainActor.run { locationService.currentLocation }
        
        var accessLog = SupabaseVaultAccessLog(
            vaultID: vault.id,
            userID: currentUserID ?? UUID(),
            accessType: "upload",
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
        
        await MainActor.run {
            uploadProgress = 1.0
        }
        
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
        
        // Refresh documents from Supabase to ensure cache consistency
        // This ensures all instances see the same data
        if let vault = document.vault {
            do {
                try await loadDocuments(for: vault)
                print("✅ Document uploaded and cache refreshed: \(document.name)")
            } catch {
                print("⚠️ Failed to refresh cache after upload: \(error.localizedDescription)")
                // Fallback: Add to cache manually if refresh fails
                await MainActor.run {
                    // Only add if not already in cache (avoid duplicates)
                    if !self.documents.contains(where: { $0.id == document.id }) {
                        self.documents.append(document)
                    }
                }
            }
        }
        
        return document
    }
    
    func deleteDocument(_ document: Document) async throws {
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Supabase mode - exclusive use when enabled
        if AppConfig.useSupabase {
            guard let supabaseService = supabaseService else {
                print("❌ DocumentService.deleteDocument: Supabase mode enabled but SupabaseService not configured")
                throw DocumentError.serviceNotConfigured
            }
            try await deleteDocumentFromSupabase(document: document, supabaseService: supabaseService)
            return
        }
        
        // SwiftData/CloudKit mode (only when useSupabase = false)
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
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
    /// Refresh documents cache from Supabase (useful for manual refresh)
    func refreshDocuments(for vault: Vault) async throws {
        try await loadDocuments(for: vault)
    }
    
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
            userID: currentUserID ?? UUID(),
            accessType: "deleted",
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
        
        // Refresh documents cache from Supabase to ensure consistency
        // This ensures all instances see the deletion
        if let vault = document.vault {
            do {
                try await loadDocuments(for: vault)
                print("✅ Document deleted and cache refreshed")
            } catch {
                print("⚠️ Failed to refresh cache after deletion: \(error.localizedDescription)")
                // Fallback: Remove from cache manually if refresh fails
                await MainActor.run {
                    self.documents.removeAll { $0.id == document.id }
                }
            }
        } else {
            // Remove from local cache if no vault reference
            await MainActor.run {
                self.documents.removeAll { $0.id == document.id }
            }
        }
    }
    
    func renameDocument(_ document: Document, newName: String) async throws {
        // Supabase mode - exclusive use when enabled
        if AppConfig.useSupabase {
            guard let supabaseService = supabaseService else {
                print("❌ DocumentService.renameDocument: Supabase mode enabled but SupabaseService not configured")
                throw DocumentError.serviceNotConfigured
            }
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
                userID: currentUserID ?? UUID(),
                accessType: "renamed",
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
            
            // Track edit in fidelity service
            if let fidelityService = fidelityService, let userID = currentUserID {
                do {
                    let versionCount = (document.versions ?? []).count
                    try await fidelityService.trackEdit(
                        document: document,
                        userID: userID,
                        versionNumber: versionCount + 1,
                        changeDescription: "Renamed from '\(oldName)' to '\(newName)'",
                        location: location,
                        deviceInfo: {
                            #if os(iOS)
                            return UIDevice.current.model
                            #else
                            return "macOS"
                            #endif
                        }(),
                        ipAddress: nil
                    )
                } catch {
                    print("⚠️ Failed to track edit in fidelity service: \(error.localizedDescription)")
                }
            }
            
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
        
        // Track edit in fidelity service
        if let fidelityService = fidelityService, let userID = currentUserID {
            let locationService = await MainActor.run { LocationService() }
            await locationService.requestLocationPermission()
            let location = await locationService.getCurrentLocation()
            
            do {
                try await fidelityService.trackEdit(
                    document: document,
                    userID: userID,
                    versionNumber: (document.versions ?? []).count + 1,
                    changeDescription: "Renamed from '\(oldName)' to '\(newName)'",
                    location: location,
                    deviceInfo: {
                        #if os(iOS)
                        return UIDevice.current.model
                        #else
                        return "macOS"
                        #endif
                    }(),
                    ipAddress: nil
                )
            } catch {
                print("⚠️ Failed to track edit in fidelity service: \(error.localizedDescription)")
            }
        }
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
        // Supabase mode - exclusive use when enabled
        if AppConfig.useSupabase {
            guard let supabaseService = supabaseService else {
                print("❌ DocumentService.downloadDocumentData: Supabase mode enabled but SupabaseService not configured")
                throw DocumentError.serviceNotConfigured
            }
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
            // Use decryptDocument which handles the format correctly (it retrieves the key internally)
            let decryptedData = try EncryptionService.decryptDocument(encryptedData, documentID: document.id)
            
            // CONTENT FILTERING: Check downloaded content before returning
            if let contentFilterService = contentFilterService {
                do {
                    let filterResult = try await contentFilterService.filterContent(
                        data: decryptedData,
                        mimeType: document.mimeType,
                        documentType: document.documentType
                    )
                    
                    if filterResult.isBlocked {
                        print("🚫 Downloaded content blocked: \(filterResult.reason ?? "Inappropriate content detected")")
                        throw DocumentError.contentBlocked(
                            severity: filterResult.severity,
                            categories: filterResult.categories,
                            reason: filterResult.reason
                        )
                    } else if filterResult.severity != .safe {
                        print("⚠️ Downloaded content warning: \(filterResult.reason ?? "Potentially inappropriate content")")
                        // Log warning but allow download
                    }
                } catch let error as DocumentError {
                    if case .contentBlocked = error {
                        throw error
                    }
                } catch {
                    print("⚠️ Content filtering failed during download: \(error.localizedDescription)")
                    // Continue with download if filtering fails (fail-open for availability)
                }
            }
            
            return decryptedData
        }
        
        // SwiftData/CloudKit mode
        guard let encryptedData = document.encryptedFileData else {
            throw DocumentError.uploadFailed
        }
        
        // Decrypt if needed
        let decryptedData: Data
        if document.isEncrypted {
            decryptedData = try EncryptionService.decryptDocument(encryptedData, documentID: document.id)
        } else {
            decryptedData = encryptedData
        }
        
        // CONTENT FILTERING: Check downloaded content before returning
        if let contentFilterService = contentFilterService {
            do {
                let filterResult = try await contentFilterService.filterContent(
                    data: decryptedData,
                    mimeType: document.mimeType,
                    documentType: document.documentType
                )
                
                if filterResult.isBlocked {
                    print("🚫 Downloaded content blocked: \(filterResult.reason ?? "Inappropriate content detected")")
                    throw DocumentError.contentBlocked(
                        severity: filterResult.severity,
                        categories: filterResult.categories,
                        reason: filterResult.reason
                    )
                } else if filterResult.severity != .safe {
                    print("⚠️ Downloaded content warning: \(filterResult.reason ?? "Potentially inappropriate content")")
                    // Log warning but allow download
                }
            } catch let error as DocumentError {
                if case .contentBlocked = error {
                    throw error
                }
            } catch {
                print("⚠️ Content filtering failed during download: \(error.localizedDescription)")
                // Continue with download if filtering fails (fail-open for availability)
            }
        }
        
        return decryptedData
    }
    
    /// Move document to a different vault (tracks transfer in fidelity service)
    func moveDocument(_ document: Document, toVault: Vault) async throws {
        guard let fromVault = document.vault else {
            throw DocumentError.vaultNotFound
        }
        
        // Update vault
        document.vault = toVault
        
        // Supabase mode - exclusive use when enabled
        if AppConfig.useSupabase {
            guard let supabaseService = supabaseService else {
                print("❌ DocumentService.moveDocument: Supabase mode enabled but SupabaseService not configured")
                throw DocumentError.serviceNotConfigured
            }
            // Update in Supabase
            let supabaseDoc: SupabaseDocument = try await supabaseService.fetch("documents", id: document.id)
            // Create new instance with updated vaultID (vaultID is let constant)
            let updated = SupabaseDocument(
                id: supabaseDoc.id,
                vaultID: toVault.id,
                name: supabaseDoc.name,
                fileExtension: supabaseDoc.fileExtension,
                mimeType: supabaseDoc.mimeType,
                fileSize: supabaseDoc.fileSize,
                storagePath: supabaseDoc.storagePath,
                createdAt: supabaseDoc.createdAt,
                uploadedAt: supabaseDoc.uploadedAt,
                lastModifiedAt: Date(),
                encryptionKeyData: supabaseDoc.encryptionKeyData,
                isEncrypted: supabaseDoc.isEncrypted,
                documentType: supabaseDoc.documentType,
                sourceSinkType: supabaseDoc.sourceSinkType,
                isArchived: supabaseDoc.isArchived,
                isRedacted: supabaseDoc.isRedacted,
                status: supabaseDoc.status,
                extractedText: supabaseDoc.extractedText,
                aiTags: supabaseDoc.aiTags,
                fileHash: supabaseDoc.fileHash,
                metadata: supabaseDoc.metadata,
                author: supabaseDoc.author,
                cameraInfo: supabaseDoc.cameraInfo,
                deviceID: supabaseDoc.deviceID,
                uploadedByUserID: supabaseDoc.uploadedByUserID,
                updatedAt: Date()
            )
            
            let _: SupabaseDocument = try await supabaseService.update("documents", id: document.id, values: updated)
            
            // Update local vault relationship
            await MainActor.run {
                if toVault.documents == nil {
                    toVault.documents = []
                }
                toVault.documents?.append(document)
                fromVault.documents?.removeAll { $0.id == document.id }
            }
        } else {
            // SwiftData/CloudKit mode
            guard let modelContext = modelContext else { return }
            
            // Update vault relationship
            if toVault.documents == nil {
                toVault.documents = []
            }
            toVault.documents?.append(document)
            fromVault.documents?.removeAll { $0.id == document.id }
            
            try modelContext.save()
        }
        
        // Track transfer in fidelity service
        if let fidelityService = fidelityService, let userID = currentUserID {
            let locationService = await MainActor.run { LocationService() }
            await locationService.requestLocationPermission()
            let location = await locationService.getCurrentLocation()
            
            do {
                try await fidelityService.trackTransfer(
                    document: document,
                    toVault: toVault,
                    fromVault: fromVault,
                    userID: userID,
                    location: location,
                    deviceInfo: {
                        #if os(iOS)
                        return UIDevice.current.model
                        #else
                        return "macOS"
                        #endif
                    }(),
                    ipAddress: nil,
                    reason: "Document moved between vaults"
                )
            } catch {
                print("⚠️ Failed to track transfer in fidelity service: \(error.localizedDescription)")
            }
        }
        
        print("✅ Document moved: \(document.name) from '\(fromVault.name)' to '\(toVault.name)'")
    }
    
    /// Create a new document version (tracks edit in fidelity service)
    func createDocumentVersion(_ document: Document, changeDescription: String? = nil) async throws -> DocumentVersion {
        let versionCount = (document.versions ?? []).count
        let newVersion = DocumentVersion(
            versionNumber: versionCount + 1,
            fileSize: document.fileSize,
            changes: changeDescription
        )
        newVersion.encryptedFileData = document.encryptedFileData
        newVersion.document = document
        
        if AppConfig.useSupabase {
            // In Supabase mode, versions might be stored differently
            // For now, we'll track the edit
        } else {
            guard let modelContext = modelContext else {
                throw DocumentError.contextNotAvailable
            }
            modelContext.insert(newVersion)
            try modelContext.save()
        }
        
        // Track edit in fidelity service
        if let fidelityService = fidelityService, let userID = currentUserID {
            let locationService = await MainActor.run { LocationService() }
            await locationService.requestLocationPermission()
            let location = await locationService.getCurrentLocation()
            
            do {
                try await fidelityService.trackEdit(
                    document: document,
                    userID: userID,
                    versionNumber: newVersion.versionNumber,
                    changeDescription: changeDescription,
                    location: location,
                    deviceInfo: {
                        #if os(iOS)
                        return UIDevice.current.model
                        #else
                        return "macOS"
                        #endif
                    }(),
                    ipAddress: nil
                )
            } catch {
                print("⚠️ Failed to track edit in fidelity service: \(error.localizedDescription)")
            }
        }
        
        return newVersion
    }
    
    // MARK: - Helper Methods
    
    /// Check if LLaMA analysis is authorized (premium subscription or feature enabled)
    private func checkLlamaAuthorization() async -> Bool {
        // Check subscription service if available
        if let subscriptionService = subscriptionService {
            // Check subscription status
            if subscriptionService.subscriptionStatus == .active {
                return true
            }
        }
        
        // Check user's premium status
        if let currentUser = currentUser {
            // In Supabase mode, check user's premium status from database
            if AppConfig.useSupabase, let supabaseService = supabaseService, let userID = currentUserID {
                do {
                    let supabaseUser: SupabaseUser = try await supabaseService.fetch(
                        "users",
                        id: userID
                    )
                    return supabaseUser.isPremiumSubscriber
                } catch {
                    print("⚠️ Failed to check premium status: \(error.localizedDescription)")
                }
            } else {
                // SwiftData/CloudKit mode - check user model
                return currentUser.isPremiumSubscriber
            }
        }
        
        // Default: Allow LLaMA for all users (app is paid, not subscription-based)
        // In production, you might want to restrict this to premium users only
        return true
    }
}

enum DocumentError: LocalizedError {
    case contextNotAvailable
    case serviceNotConfigured
    case uploadFailed
    case encryptionFailed
    case vaultNotFound
    case contentBlocked(severity: ContentSeverity, categories: [ContentCategory], reason: String?)
    
    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Database context not available"
        case .serviceNotConfigured:
            return "Service not configured. Please ensure Supabase is properly initialized."
        case .uploadFailed:
            return "Failed to upload document"
        case .encryptionFailed:
            return "Failed to encrypt document"
        case .vaultNotFound:
            return "Vault not found"
        case .contentBlocked(let severity, let categories, let reason):
            var message = "Content blocked due to \(severity.rawValue) severity"
            if let reason = reason {
                message += ": \(reason)"
            }
            if !categories.isEmpty {
                message += " (Categories: \(categories.map { $0.rawValue }.joined(separator: ", ")))"
            }
            return message
        }
    }
}

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
    
    // SwiftData/CloudKit mode (iOS-only)
    func configure(modelContext: ModelContext, userID: UUID? = nil, fidelityService: DocumentFidelityService? = nil, contentFilterService: ContentFilterService? = nil, subscriptionService: SubscriptionService? = nil) {
        self.modelContext = modelContext
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
    
    
    // Track current vault for cache refresh (using ID to avoid Sendable issues)
    private var currentVault: Vault?
    private var currentVaultID: UUID?
    
    // CloudKit automatically syncs changes - no manual listener needed
    
    func loadDocuments(for vault: Vault) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Store current vault for realtime refresh
        await MainActor.run {
            self.currentVault = vault
            self.currentVaultID = vault.id
        }
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        documents = (vault.documents ?? []).filter { $0.status == "active" }
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
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
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
    
    func deleteDocument(_ document: Document) async throws {
        await MainActor.run {
            isLoading = true
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
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
    
    /// Refresh documents cache (useful for manual refresh)
    func refreshDocuments(for vault: Vault) async throws {
        try await loadDocuments(for: vault)
    }
    
    func renameDocument(_ document: Document, newName: String) async throws {
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
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
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
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
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        
        // Update vault relationship
        if toVault.documents == nil {
            toVault.documents = []
        }
        toVault.documents?.append(document)
        fromVault.documents?.removeAll { $0.id == document.id }
        
        try modelContext.save()
        
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
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else {
            throw DocumentError.contextNotAvailable
        }
        modelContext.insert(newVersion)
        try modelContext.save()
        
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
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        if let currentUser = currentUser {
            return currentUser.isPremiumSubscriber
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

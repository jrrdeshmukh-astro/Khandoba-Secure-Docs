//
//  Document.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftData
import Combine

@Model
final class Document {
    var id: UUID = UUID()
    var name: String = ""
    var fileExtension: String?
    var mimeType: String?
    var fileSize: Int64 = 0
    var createdAt: Date = Date()
    var uploadedAt: Date = Date()
    var lastModifiedAt: Date?
    
    // Encryption
    var encryptedFileData: Data?
    var encryptionKeyData: Data?
    var isEncrypted: Bool = true
    
    // Document classification
    var documentType: String = "other" // "image", "pdf", "video", "audio", "text", "other"
    var sourceSinkType: String? // "source", "sink", "both"
    
    // Status
    var isArchived: Bool = false
    var isRedacted: Bool = false
    var status: String = "active" // "active", "archived", "deleted"
    
    // Indexing and search
    var extractedText: String?
    var aiTags: [String] = []
    var fileHash: String?
    var metadata: String? // JSON string for additional metadata
    
    // EXIF/Metadata
    var author: String?
    var cameraInfo: String?
    var deviceID: String?
    
    // Relationships
    var vault: Vault?
    var uploadedByUserID: UUID?
    
    @Relationship(deleteRule: .cascade, inverse: \DocumentVersion.document)
    var versions: [DocumentVersion]?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        fileExtension: String? = nil,
        mimeType: String? = nil,
        fileSize: Int64 = 0,
        createdAt: Date = Date(),
        uploadedAt: Date = Date(),
        documentType: String = "other",
        isEncrypted: Bool = true,
        isArchived: Bool = false,
        isRedacted: Bool = false,
        status: String = "active",
        aiTags: [String] = []
    ) {
        self.id = id
        self.name = name.isEmpty ? "Document" : name
        self.fileExtension = fileExtension
        self.mimeType = mimeType
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.uploadedAt = uploadedAt
        self.documentType = documentType
        self.isEncrypted = isEncrypted
        self.isArchived = isArchived
        self.isRedacted = isRedacted
        self.status = status
        self.aiTags = aiTags
        self.versions = []
    }
}

@Model
final class DocumentVersion {
    var id: UUID = UUID()
    var versionNumber: Int = 1
    var createdAt: Date = Date()
    var fileSize: Int64 = 0
    var encryptedFileData: Data?
    var changes: String?
    
    var document: Document?
    
    init(
        id: UUID = UUID(),
        versionNumber: Int = 1,
        createdAt: Date = Date(),
        fileSize: Int64 = 0,
        changes: String? = nil
    ) {
        self.id = id
        self.versionNumber = versionNumber
        self.createdAt = createdAt
        self.fileSize = fileSize
        self.changes = changes
    }
}


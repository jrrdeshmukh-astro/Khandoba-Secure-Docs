//
//  SupabaseDocument.swift
//  Khandoba Secure Docs
//
//  Created for Supabase Migration
//

import Foundation

struct SupabaseDocument: Codable, Identifiable {
    let id: UUID
    let vaultID: UUID
    var name: String
    var fileExtension: String?
    var mimeType: String?
    var fileSize: Int64
    var storagePath: String? // Path in Supabase Storage
    let createdAt: Date
    let uploadedAt: Date
    var lastModifiedAt: Date?
    var encryptionKeyData: Data? // BYTEA in PostgreSQL
    var isEncrypted: Bool
    var documentType: String // "image", "pdf", "video", "audio", "text", "other"
    var sourceSinkType: String? // "source", "sink", "both"
    var isArchived: Bool
    var isRedacted: Bool
    var status: String // "active", "archived", "deleted"
    var extractedText: String?
    var aiTags: [String]
    var fileHash: String?
    var metadata: [String: Any]? // JSONB in PostgreSQL
    var author: String?
    var cameraInfo: String?
    var deviceID: String?
    var uploadedByUserID: UUID?
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case vaultID = "vault_id"
        case name
        case fileExtension = "file_extension"
        case mimeType = "mime_type"
        case fileSize = "file_size"
        case storagePath = "storage_path"
        case createdAt = "created_at"
        case uploadedAt = "uploaded_at"
        case lastModifiedAt = "last_modified_at"
        case encryptionKeyData = "encryption_key_data"
        case isEncrypted = "is_encrypted"
        case documentType = "document_type"
        case sourceSinkType = "source_sink_type"
        case isArchived = "is_archived"
        case isRedacted = "is_redacted"
        case status
        case extractedText = "extracted_text"
        case aiTags = "ai_tags"
        case fileHash = "file_hash"
        case metadata
        case author
        case cameraInfo = "camera_info"
        case deviceID = "device_id"
        case uploadedByUserID = "uploaded_by_user_id"
        case updatedAt = "updated_at"
    }
    
    // Custom encoding for metadata (JSONB)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        vaultID = try container.decode(UUID.self, forKey: .vaultID)
        name = try container.decode(String.self, forKey: .name)
        fileExtension = try container.decodeIfPresent(String.self, forKey: .fileExtension)
        mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
        fileSize = try container.decode(Int64.self, forKey: .fileSize)
        storagePath = try container.decodeIfPresent(String.self, forKey: .storagePath)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        uploadedAt = try container.decode(Date.self, forKey: .uploadedAt)
        lastModifiedAt = try container.decodeIfPresent(Date.self, forKey: .lastModifiedAt)
        
        // Decode encryption key data (base64 string from PostgreSQL BYTEA)
        if let keyDataString = try? container.decodeIfPresent(String.self, forKey: .encryptionKeyData),
           let keyData = Data(base64Encoded: keyDataString) {
            encryptionKeyData = keyData
        } else {
            encryptionKeyData = nil
        }
        
        isEncrypted = try container.decode(Bool.self, forKey: .isEncrypted)
        documentType = try container.decode(String.self, forKey: .documentType)
        sourceSinkType = try container.decodeIfPresent(String.self, forKey: .sourceSinkType)
        isArchived = try container.decode(Bool.self, forKey: .isArchived)
        isRedacted = try container.decode(Bool.self, forKey: .isRedacted)
        status = try container.decode(String.self, forKey: .status)
        extractedText = try container.decodeIfPresent(String.self, forKey: .extractedText)
        aiTags = try container.decode([String].self, forKey: .aiTags)
        fileHash = try container.decodeIfPresent(String.self, forKey: .fileHash)
        
        // Decode metadata JSONB
        if let metadataData = try? container.decodeIfPresent(Data.self, forKey: .metadata),
           let json = try? JSONSerialization.jsonObject(with: metadataData) as? [String: Any] {
            metadata = json
        } else {
            metadata = nil
        }
        
        author = try container.decodeIfPresent(String.self, forKey: .author)
        cameraInfo = try container.decodeIfPresent(String.self, forKey: .cameraInfo)
        deviceID = try container.decodeIfPresent(String.self, forKey: .deviceID)
        uploadedByUserID = try container.decodeIfPresent(UUID.self, forKey: .uploadedByUserID)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(vaultID, forKey: .vaultID)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(fileExtension, forKey: .fileExtension)
        try container.encodeIfPresent(mimeType, forKey: .mimeType)
        try container.encode(fileSize, forKey: .fileSize)
        try container.encodeIfPresent(storagePath, forKey: .storagePath)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(uploadedAt, forKey: .uploadedAt)
        try container.encodeIfPresent(lastModifiedAt, forKey: .lastModifiedAt)
        
        // Encode encryption key data as base64 string
        if let keyData = encryptionKeyData {
            try container.encode(keyData.base64EncodedString(), forKey: .encryptionKeyData)
        }
        
        try container.encode(isEncrypted, forKey: .isEncrypted)
        try container.encode(documentType, forKey: .documentType)
        try container.encodeIfPresent(sourceSinkType, forKey: .sourceSinkType)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encode(isRedacted, forKey: .isRedacted)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(extractedText, forKey: .extractedText)
        try container.encode(aiTags, forKey: .aiTags)
        try container.encodeIfPresent(fileHash, forKey: .fileHash)
        
        // Encode metadata as JSONB
        if let metadata = metadata,
           let jsonData = try? JSONSerialization.data(withJSONObject: metadata) {
            try container.encode(jsonData, forKey: .metadata)
        }
        
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(cameraInfo, forKey: .cameraInfo)
        try container.encodeIfPresent(deviceID, forKey: .deviceID)
        try container.encodeIfPresent(uploadedByUserID, forKey: .uploadedByUserID)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // Convert from SwiftData Document model
    init(from document: Document) {
        self.id = document.id
        self.vaultID = document.vault?.id ?? UUID() // Should always have vault
        self.name = document.name
        self.fileExtension = document.fileExtension
        self.mimeType = document.mimeType
        self.fileSize = document.fileSize
        self.storagePath = nil // Will be set when uploading to Supabase Storage
        self.createdAt = document.createdAt
        self.uploadedAt = document.uploadedAt
        self.lastModifiedAt = document.lastModifiedAt
        self.encryptionKeyData = document.encryptionKeyData
        self.isEncrypted = document.isEncrypted
        self.documentType = document.documentType
        self.sourceSinkType = document.sourceSinkType
        self.isArchived = document.isArchived
        self.isRedacted = document.isRedacted
        self.status = document.status
        self.extractedText = document.extractedText
        
        // Convert metadata string to dictionary if present
        if let metadataString = document.metadata,
           let data = metadataString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            self.metadata = json
        } else {
            self.metadata = nil
        }
        
        self.aiTags = document.aiTags
        self.fileHash = document.fileHash
        self.author = document.author
        self.cameraInfo = document.cameraInfo
        self.deviceID = document.deviceID
        self.uploadedByUserID = document.uploadedByUserID
        self.updatedAt = Date()
    }
    
    // Standard init
    init(
        id: UUID = UUID(),
        vaultID: UUID,
        name: String,
        fileExtension: String? = nil,
        mimeType: String? = nil,
        fileSize: Int64 = 0,
        storagePath: String? = nil,
        createdAt: Date = Date(),
        uploadedAt: Date = Date(),
        lastModifiedAt: Date? = nil,
        encryptionKeyData: Data? = nil,
        isEncrypted: Bool = true,
        documentType: String = "other",
        sourceSinkType: String? = nil,
        isArchived: Bool = false,
        isRedacted: Bool = false,
        status: String = "active",
        extractedText: String? = nil,
        aiTags: [String] = [],
        fileHash: String? = nil,
        metadata: [String: Any]? = nil,
        author: String? = nil,
        cameraInfo: String? = nil,
        deviceID: String? = nil,
        uploadedByUserID: UUID? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.vaultID = vaultID
        self.name = name
        self.fileExtension = fileExtension
        self.mimeType = mimeType
        self.fileSize = fileSize
        self.storagePath = storagePath
        self.createdAt = createdAt
        self.uploadedAt = uploadedAt
        self.lastModifiedAt = lastModifiedAt
        self.encryptionKeyData = encryptionKeyData
        self.isEncrypted = isEncrypted
        self.documentType = documentType
        self.sourceSinkType = sourceSinkType
        self.isArchived = isArchived
        self.isRedacted = isRedacted
        self.status = status
        self.extractedText = extractedText
        self.aiTags = aiTags
        self.fileHash = fileHash
        self.metadata = metadata
        self.author = author
        self.cameraInfo = cameraInfo
        self.deviceID = deviceID
        self.uploadedByUserID = uploadedByUserID
        self.updatedAt = updatedAt
    }
}

struct SupabaseDocumentVersion: Codable, Identifiable {
    let id: UUID
    let documentID: UUID
    var versionNumber: Int
    let createdAt: Date
    var fileSize: Int64
    var storagePath: String? // Path in Supabase Storage
    var changes: String?
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case documentID = "document_id"
        case versionNumber = "version_number"
        case createdAt = "created_at"
        case fileSize = "file_size"
        case storagePath = "storage_path"
        case changes
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        documentID: UUID,
        versionNumber: Int = 1,
        createdAt: Date = Date(),
        fileSize: Int64 = 0,
        storagePath: String? = nil,
        changes: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.documentID = documentID
        self.versionNumber = versionNumber
        self.createdAt = createdAt
        self.fileSize = fileSize
        self.storagePath = storagePath
        self.changes = changes
        self.updatedAt = updatedAt
    }
}

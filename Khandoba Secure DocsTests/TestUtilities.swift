//
//  TestUtilities.swift
//  Khandoba Secure DocsTests
//
//  Created for comprehensive unit testing
//

import Foundation
import SwiftData
import XCTest

/// Test utilities and helpers for unit tests
final class TestUtilities {
    
    /// Create an in-memory ModelContainer for testing
    static func createTestModelContainer() -> ModelContainer {
        let schema = Schema([
            User.self,
            Vault.self,
            Document.self,
            ChatMessage.self,
            Nominee.self,
            Device.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create test model container: \(error)")
        }
    }
    
    /// Create a test ModelContext
    static func createTestModelContext() -> ModelContext {
        let container = createTestModelContainer()
        return ModelContext(container)
    }
    
    /// Create a mock User for testing
    static func createMockUser(
        id: UUID = UUID(),
        appleUserID: String = "test.apple.id",
        fullName: String = "Test User",
        email: String? = "test@example.com"
    ) -> User {
        let user = User()
        user.id = id
        user.appleUserID = appleUserID
        user.fullName = fullName
        user.email = email
        user.createdAt = Date()
        user.lastActiveAt = Date()
        return user
    }
    
    /// Create a mock Vault for testing
    static func createMockVault(
        id: UUID = UUID(),
        name: String = "Test Vault",
        owner: User? = nil,
        keyType: String = "single",
        isSystemVault: Bool = false
    ) -> Vault {
        let vault = Vault()
        vault.id = id
        vault.name = name
        vault.vaultDescription = "Test vault description"
        vault.createdAt = Date()
        vault.status = "locked"
        vault.keyType = keyType
        vault.isSystemVault = isSystemVault
        vault.isEncrypted = true
        vault.isZeroKnowledge = true
        
        if let owner = owner {
            vault.owner = owner
        }
        
        return vault
    }
    
    /// Create a mock Document for testing
    static func createMockDocument(
        id: UUID = UUID(),
        name: String = "test-document.pdf",
        vault: Vault? = nil,
        fileSize: Int64 = 1024
    ) -> Document {
        let document = Document()
        document.id = id
        document.name = name
        document.fileExtension = "pdf"
        document.mimeType = "application/pdf"
        document.fileSize = fileSize
        document.createdAt = Date()
        document.uploadedAt = Date()
        document.documentType = "pdf"
        document.isEncrypted = true
        document.status = "active"
        
        if let vault = vault {
            document.vault = vault
        }
        
        return document
    }
    
    /// Create test data
    static func createTestData(size: Int = 1024) -> Data {
        var data = Data(count: size)
        _ = data.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, size, bytes.baseAddress!)
        }
        return data
    }
}

// MARK: - Debugging Helpers for SwiftData

extension TestUtilities {
    /// Helper to debug FetchDescriptor without predicate inspection issues
    /// Use this in debugger instead of inspecting the descriptor directly
    static func debugFetchDescriptor<T>(_ descriptor: FetchDescriptor<T>, context: ModelContext) throws -> [T] {
        return try context.fetch(descriptor)
    }
    
    /// Create a FetchDescriptor for User by ID (avoids predicate inspection in debugger)
    static func createUserFetchDescriptor(userID: UUID) -> FetchDescriptor<User> {
        return FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userID }
        )
    }
    
    /// Create a FetchDescriptor for Vault by ID
    static func createVaultFetchDescriptor(vaultID: UUID) -> FetchDescriptor<Vault> {
        return FetchDescriptor<Vault>(
            predicate: #Predicate { $0.id == vaultID }
        )
    }
    
    /// Create a FetchDescriptor for Document by ID
    static func createDocumentFetchDescriptor(documentID: UUID) -> FetchDescriptor<Document> {
        return FetchDescriptor<Document>(
            predicate: #Predicate { $0.id == documentID }
        )
    }
}

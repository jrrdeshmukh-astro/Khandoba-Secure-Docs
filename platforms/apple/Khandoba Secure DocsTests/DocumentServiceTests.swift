//
//  DocumentServiceTests.swift
//  Khandoba Secure DocsTests
//
//  Comprehensive unit tests for DocumentService
//

import XCTest
import SwiftData

@MainActor
final class DocumentServiceTests: XCTestCase {
    
    var service: DocumentService!
    var modelContext: ModelContext!
    var testUser: User!
    var testVault: Vault!
    
    override func setUp() async throws {
        try await super.setUp()
        modelContext = TestUtilities.createTestModelContext()
        testUser = TestUtilities.createMockUser()
        testVault = TestUtilities.createMockVault(owner: testUser)
        
        modelContext.insert(testUser)
        modelContext.insert(testVault)
        try modelContext.save()
        
        service = DocumentService()
        service.configure(modelContext: modelContext, userID: testUser.id)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        testUser = nil
        testVault = nil
        try await super.tearDown()
    }
    
    // MARK: - Document Loading Tests
    
    func testLoadDocuments() async throws {
        // Create a test document
        let document = TestUtilities.createMockDocument(vault: testVault)
        modelContext.insert(document)
        try modelContext.save()
        
        // Load documents
        try await service.loadDocuments(for: testVault)
        
        // Wait for async updates
        try await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertFalse(service.documents.isEmpty)
    }
    
    // MARK: - Document Search Tests
    
    func testSearchDocuments() async throws {
        let doc1 = TestUtilities.createMockDocument(name: "invoice.pdf", vault: testVault)
        let doc2 = TestUtilities.createMockDocument(name: "receipt.jpg", vault: testVault)
        
        modelContext.insert(doc1)
        modelContext.insert(doc2)
        try modelContext.save()
        
        try await service.loadDocuments(for: testVault)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let results = service.searchDocuments(query: "invoice")
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.name.contains("invoice") })
    }
    
    // MARK: - Document Filtering Tests
    
    func testFilterDocumentsByType() async throws {
        let pdfDoc = TestUtilities.createMockDocument(name: "test.pdf", vault: testVault)
        pdfDoc.documentType = "pdf"
        
        let imageDoc = TestUtilities.createMockDocument(name: "test.jpg", vault: testVault)
        imageDoc.documentType = "image"
        
        modelContext.insert(pdfDoc)
        modelContext.insert(imageDoc)
        try modelContext.save()
        
        try await service.loadDocuments(for: testVault)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let pdfDocs = service.documents.filter { $0.documentType == "pdf" }
        XCTAssertFalse(pdfDocs.isEmpty)
    }
}

//
//  ModelTests.swift
//  Khandoba Secure DocsTests
//
//  Comprehensive unit tests for data models
//

import XCTest
import SwiftData

final class ModelTests: XCTestCase {
    
    // MARK: - User Model Tests
    
    func testUserCreation() {
        let user = TestUtilities.createMockUser()
        
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.fullName, "Test User")
        XCTAssertEqual(user.appleUserID, "test.apple.id")
        XCTAssertNotNil(user.createdAt)
    }
    
    func testUserWithCustomProperties() {
        let customID = UUID()
        let user = TestUtilities.createMockUser(
            id: customID,
            fullName: "Custom User",
            email: "custom@example.com"
        )
        
        XCTAssertEqual(user.id, customID)
        XCTAssertEqual(user.fullName, "Custom User")
        XCTAssertEqual(user.email, "custom@example.com")
    }
    
    // MARK: - Vault Model Tests
    
    func testVaultCreation() {
        let vault = TestUtilities.createMockVault()
        
        XCTAssertNotNil(vault.id)
        XCTAssertEqual(vault.name, "Test Vault")
        XCTAssertEqual(vault.status, "locked")
        XCTAssertEqual(vault.keyType, "single")
        XCTAssertTrue(vault.isEncrypted)
    }
    
    func testVaultWithOwner() {
        let user = TestUtilities.createMockUser()
        let vault = TestUtilities.createMockVault(owner: user)
        
        XCTAssertNotNil(vault.owner)
        XCTAssertEqual(vault.owner?.id, user.id)
    }
    
    func testDualKeyVault() {
        let vault = TestUtilities.createMockVault(keyType: "dual")
        
        XCTAssertEqual(vault.keyType, "dual")
    }
    
    func testSystemVault() {
        let vault = TestUtilities.createMockVault(isSystemVault: true)
        
        XCTAssertTrue(vault.isSystemVault)
    }
    
    // MARK: - Document Model Tests
    
    func testDocumentCreation() {
        let document = TestUtilities.createMockDocument()
        
        XCTAssertNotNil(document.id)
        XCTAssertEqual(document.name, "test-document.pdf")
        XCTAssertEqual(document.fileExtension, "pdf")
        XCTAssertEqual(document.documentType, "pdf")
        XCTAssertTrue(document.isEncrypted)
    }
    
    func testDocumentWithVault() {
        let vault = TestUtilities.createMockVault()
        let document = TestUtilities.createMockDocument(vault: vault)
        
        XCTAssertNotNil(document.vault)
        XCTAssertEqual(document.vault?.id, vault.id)
    }
    
    func testDocumentFileSize() {
        let document = TestUtilities.createMockDocument(fileSize: 2048)
        
        XCTAssertEqual(document.fileSize, 2048)
    }
}

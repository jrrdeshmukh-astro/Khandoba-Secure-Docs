//
//  VaultServiceTests.swift
//  Khandoba Secure DocsTests
//
//  Comprehensive unit tests for VaultService
//

import XCTest
import SwiftData

@MainActor
final class VaultServiceTests: XCTestCase {
    
    var service: VaultService!
    var modelContext: ModelContext!
    var testUser: User!
    
    override func setUp() async throws {
        try await super.setUp()
        modelContext = TestUtilities.createTestModelContext()
        testUser = TestUtilities.createMockUser()
        modelContext.insert(testUser)
        try modelContext.save()
        
        service = VaultService()
        service.configure(modelContext: modelContext, userID: testUser.id)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        testUser = nil
        try await super.tearDown()
    }
    
    // MARK: - Vault Creation Tests
    
    func testCreateVault() async throws {
        let vaultName = "Test Vault"
        let vaultDescription = "Test Description"
        
        let vault = try await service.createVault(
            name: vaultName,
            description: vaultDescription,
            keyType: "single",
            password: "test-password"
        )
        
        XCTAssertNotNil(vault)
        XCTAssertEqual(vault.name, vaultName)
        XCTAssertEqual(vault.vaultDescription, vaultDescription)
        XCTAssertEqual(vault.keyType, "single")
        XCTAssertEqual(vault.owner?.id, testUser.id)
    }
    
    func testCreateDualKeyVault() async throws {
        let vault = try await service.createVault(
            name: "Dual Key Vault",
            description: nil,
            keyType: "dual",
            password: "test-password"
        )
        
        XCTAssertNotNil(vault)
        XCTAssertEqual(vault.keyType, "dual")
    }
    
    func testCreateVaultWithEmptyName() async throws {
        await XCTAssertThrowsError(
            try await service.createVault(
                name: "",
                description: nil,
                keyType: "single",
                password: "test-password"
            )
        )
    }
    
    // MARK: - Vault Loading Tests
    
    func testLoadVaults() async throws {
        // Create a vault first
        _ = try await service.createVault(
            name: "Test Vault",
            description: nil,
            keyType: "single",
            password: "test-password"
        )
        
        // Load vaults
        try await service.loadVaults()
        
        // Wait a bit for async updates
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertFalse(service.vaults.isEmpty)
        XCTAssertTrue(service.vaults.contains { $0.name == "Test Vault" })
    }
    
    // MARK: - Vault Access Tests
    
    func testUnlockVault() async throws {
        let vault = try await service.createVault(
            name: "Locked Vault",
            description: nil,
            keyType: "single",
            password: "test-password"
        )
        
        let unlocked = try await service.unlockVault(vault: vault, password: "test-password")
        
        XCTAssertTrue(unlocked)
        XCTAssertNotNil(service.activeSessions[vault.id])
    }
    
    func testUnlockVaultWithWrongPassword() async throws {
        let vault = try await service.createVault(
            name: "Locked Vault",
            description: nil,
            keyType: "single",
            password: "correct-password"
        )
        
        await XCTAssertThrowsError(
            try await service.unlockVault(vault: vault, password: "wrong-password")
        )
    }
    
    func testLockVault() async throws {
        let vault = try await service.createVault(
            name: "Test Vault",
            description: nil,
            keyType: "single",
            password: "test-password"
        )
        
        _ = try await service.unlockVault(vault: vault, password: "test-password")
        try await service.lockVault(vault: vault)
        
        XCTAssertNil(service.activeSessions[vault.id])
    }
    
    // MARK: - Vault Deletion Tests
    
    func testDeleteVault() async throws {
        let vault = try await service.createVault(
            name: "To Delete",
            description: nil,
            keyType: "single",
            password: "test-password"
        )
        
        let vaultID = vault.id
        try await service.deleteVault(vault)
        
        // Verify vault is deleted
        let descriptor = FetchDescriptor<Vault>(
            predicate: #Predicate { $0.id == vaultID }
        )
        let deletedVaults = try modelContext.fetch(descriptor)
        XCTAssertTrue(deletedVaults.isEmpty)
    }
}

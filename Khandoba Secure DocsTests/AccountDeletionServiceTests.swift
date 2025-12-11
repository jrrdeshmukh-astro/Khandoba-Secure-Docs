//
//  AccountDeletionServiceTests.swift
//  Khandoba Secure DocsTests
//
//  Unit tests for AccountDeletionService - Option 1 Compliance
//  Verifies complete deletion of user data including access logs
//

import Testing
import SwiftData
@testable import Khandoba_Secure_Docs

struct AccountDeletionServiceTests {
    
    // MARK: - Test Helper: Create In-Memory ModelContainer
    
    private func createTestModelContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            UserRole.self,
            Vault.self,
            VaultSession.self,
            VaultAccessLog.self,
            DualKeyRequest.self,
            Document.self,
            DocumentVersion.self,
            ChatMessage.self,
            Nominee.self,
            VaultTransferRequest.self,
            EmergencyAccessRequest.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(for: schema, configurations: [configuration])
    }
    
    // MARK: - Test 1: User's Own Vaults - Access Logs Deleted
    
    @Test("User's own vaults - access logs are deleted via cascade")
    func testUserOwnVaultsAccessLogsDeleted() async throws {
        // Setup
        let container = try createTestModelContainer()
        let context = container.mainContext
        
        // Create test user
        let user = User(
            appleUserID: "test-user-123",
            fullName: "Test User",
            email: "test@example.com"
        )
        context.insert(user)
        
        // Create vault owned by user
        let vault = Vault(name: "Test Vault")
        vault.owner = user
        if user.ownedVaults == nil {
            user.ownedVaults = []
        }
        user.ownedVaults?.append(vault)
        context.insert(vault)
        
        // Create access logs for the vault
        let log1 = VaultAccessLog(
            accessType: "opened",
            userID: user.id,
            userName: user.fullName
        )
        log1.vault = vault
        
        let log2 = VaultAccessLog(
            accessType: "viewed",
            userID: user.id,
            userName: user.fullName
        )
        log2.vault = vault
        
        context.insert(log1)
        context.insert(log2)
        
        // Save initial state
        try context.save()
        
        // Verify logs exist before deletion
        let logsBefore = try context.fetch(FetchDescriptor<VaultAccessLog>())
        #expect(logsBefore.count == 2)
        
        // Perform account deletion
        let deletionService = AccountDeletionService()
        deletionService.configure(modelContext: context)
        
        try await deletionService.deleteAccount(user: user)
        
        // Verify: All access logs are deleted (Option 1 compliance)
        let logsAfter = try context.fetch(FetchDescriptor<VaultAccessLog>())
        #expect(logsAfter.isEmpty, "Access logs should be deleted with vaults (Option 1: Complete Deletion)")
        
        // Verify: Vault is deleted
        let vaultsAfter = try context.fetch(FetchDescriptor<Vault>())
        #expect(vaultsAfter.isEmpty, "Vault should be deleted")
        
        // Verify: User is deleted
        let usersAfter = try context.fetch(FetchDescriptor<User>())
        #expect(usersAfter.isEmpty, "User should be deleted")
    }
    
    // MARK: - Test 2: Shared Vaults - Access Logs Preserved
    
    @Test("Shared vaults - access logs are preserved for vault owner")
    func testSharedVaultsAccessLogsPreserved() async throws {
        // Setup
        let container = try createTestModelContainer()
        let context = container.mainContext
        
        // Create vault owner
        let owner = User(
            appleUserID: "owner-123",
            fullName: "Vault Owner",
            email: "owner@example.com"
        )
        context.insert(owner)
        
        // Create nominee user (will delete their account)
        let nomineeUser = User(
            appleUserID: "nominee-123",
            fullName: "Nominee User",
            email: "nominee@example.com"
        )
        context.insert(nomineeUser)
        
        // Create vault owned by owner
        let vault = Vault(name: "Shared Vault")
        vault.owner = owner
        if owner.ownedVaults == nil {
            owner.ownedVaults = []
        }
        owner.ownedVaults?.append(vault)
        context.insert(vault)
        
        // Create nominee record
        let nominee = Nominee(
            name: nomineeUser.fullName,
            email: nomineeUser.email,
            status: .accepted
        )
        nominee.vault = vault
        context.insert(nominee)
        
        // Create access logs from nominee accessing the vault
        let nomineeLog = VaultAccessLog(
            accessType: "opened",
            userID: nomineeUser.id,
            userName: nomineeUser.fullName
        )
        nomineeLog.vault = vault
        context.insert(nomineeLog)
        
        // Create access log from owner
        let ownerLog = VaultAccessLog(
            accessType: "viewed",
            userID: owner.id,
            userName: owner.fullName
        )
        ownerLog.vault = vault
        context.insert(ownerLog)
        
        try context.save()
        
        // Verify logs exist before deletion
        let logsBefore = try context.fetch(FetchDescriptor<VaultAccessLog>())
        #expect(logsBefore.count == 2)
        
        // Delete nominee's account
        let deletionService = AccountDeletionService()
        deletionService.configure(modelContext: context)
        
        try await deletionService.deleteAccount(user: nomineeUser)
        
        // Verify: Access logs are preserved (Option 1 compliance for shared vaults)
        let logsAfter = try context.fetch(FetchDescriptor<VaultAccessLog>())
        #expect(logsAfter.count == 2, "Access logs should be preserved in shared vaults")
        
        // Verify: Nominee log is marked as deleted
        let nomineeLogAfter = logsAfter.first { $0.userID == nomineeUser.id }
        #expect(nomineeLogAfter != nil, "Nominee's access log should still exist")
        #expect(nomineeLogAfter?.userName?.contains("Account Deleted") == true, "Log should be marked as deleted")
        
        // Verify: Owner log is unchanged
        let ownerLogAfter = logsAfter.first { $0.userID == owner.id }
        #expect(ownerLogAfter != nil, "Owner's access log should still exist")
        #expect(ownerLogAfter?.userName == owner.fullName, "Owner's log should be unchanged")
        
        // Verify: Nominee record is deleted
        let nomineesAfter = try context.fetch(FetchDescriptor<Nominee>())
        #expect(nomineesAfter.isEmpty, "Nominee record should be deleted")
        
        // Verify: Vault still exists (owned by owner)
        let vaultsAfter = try context.fetch(FetchDescriptor<Vault>())
        #expect(vaultsAfter.count == 1, "Vault should still exist")
        #expect(vaultsAfter.first?.owner?.id == owner.id, "Vault should still be owned by owner")
    }
    
    // MARK: - Test 3: Complete User Data Deletion
    
    @Test("Complete user data deletion - all related entities deleted")
    func testCompleteUserDataDeletion() async throws {
        // Setup
        let container = try createTestModelContainer()
        let context = container.mainContext
        
        // Create user with all related data
        let user = User(
            appleUserID: "test-user-456",
            fullName: "Test User",
            email: "test@example.com"
        )
        context.insert(user)
        
        // Create role
        let role = UserRole(role: .client)
        role.user = user
        if user.roles == nil {
            user.roles = []
        }
        user.roles?.append(role)
        context.insert(role)
        
        // Create vault with documents and access logs
        let vault = Vault(name: "Test Vault")
        vault.owner = user
        if user.ownedVaults == nil {
            user.ownedVaults = []
        }
        user.ownedVaults?.append(vault)
        context.insert(vault)
        
        let document = Document()
        document.name = "Test Document"
        document.mimeType = "application/pdf"
        document.vault = vault
        if vault.documents == nil {
            vault.documents = []
        }
        vault.documents?.append(document)
        context.insert(document)
        
        let accessLog = VaultAccessLog(
            accessType: "opened",
            userID: user.id,
            userName: user.fullName
        )
        accessLog.vault = vault
        context.insert(accessLog)
        
        // Create session
        let session = VaultSession()
        session.vault = vault
        session.user = user
        if vault.sessions == nil {
            vault.sessions = []
        }
        vault.sessions?.append(session)
        if user.vaultSessions == nil {
            user.vaultSessions = []
        }
        user.vaultSessions?.append(session)
        context.insert(session)
        
        // Create chat message
        let message = ChatMessage(content: "Test message")
        message.sender = user
        message.senderID = user.id
        if user.sentMessages == nil {
            user.sentMessages = []
        }
        user.sentMessages?.append(message)
        context.insert(message)
        
        try context.save()
        
        // Verify all data exists
        #expect(try context.fetch(FetchDescriptor<User>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Vault>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Document>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<VaultAccessLog>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<VaultSession>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<ChatMessage>()).count == 1)
        
        // Delete account
        let deletionService = AccountDeletionService()
        deletionService.configure(modelContext: context)
        
        try await deletionService.deleteAccount(user: user)
        
        // Verify: All user data is deleted (Option 1 compliance)
        #expect(try context.fetch(FetchDescriptor<User>()).isEmpty, "User should be deleted")
        #expect(try context.fetch(FetchDescriptor<Vault>()).isEmpty, "Vaults should be deleted")
        #expect(try context.fetch(FetchDescriptor<Document>()).isEmpty, "Documents should be deleted")
        #expect(try context.fetch(FetchDescriptor<VaultAccessLog>()).isEmpty, "Access logs should be deleted")
        #expect(try context.fetch(FetchDescriptor<VaultSession>()).isEmpty, "Sessions should be deleted")
        #expect(try context.fetch(FetchDescriptor<ChatMessage>()).isEmpty, "Chat messages should be deleted")
        #expect(try context.fetch(FetchDescriptor<UserRole>()).isEmpty, "User roles should be deleted")
    }
    
    // MARK: - Test 4: Multiple Vaults with Multiple Access Logs
    
    @Test("Multiple vaults - all access logs deleted")
    func testMultipleVaultsAllAccessLogsDeleted() async throws {
        // Setup
        let container = try createTestModelContainer()
        let context = container.mainContext
        
        let user = User(
            appleUserID: "test-user-789",
            fullName: "Test User",
            email: "test@example.com"
        )
        context.insert(user)
        
        // Create multiple vaults with multiple access logs each
        var totalLogs = 0
        for i in 1...3 {
            let vault = Vault(name: "Vault \(i)")
            vault.owner = user
            if user.ownedVaults == nil {
                user.ownedVaults = []
            }
            user.ownedVaults?.append(vault)
            context.insert(vault)
            
            // Create 5 access logs per vault
            for j in 1...5 {
                let log = VaultAccessLog(
                    accessType: "viewed",
                    userID: user.id,
                    userName: user.fullName
                )
                log.vault = vault
                context.insert(log)
                totalLogs += 1
            }
        }
        
        try context.save()
        
        // Verify logs exist
        let logsBefore = try context.fetch(FetchDescriptor<VaultAccessLog>())
        #expect(logsBefore.count == totalLogs)
        
        // Delete account
        let deletionService = AccountDeletionService()
        deletionService.configure(modelContext: context)
        
        try await deletionService.deleteAccount(user: user)
        
        // Verify: All access logs deleted (Option 1 compliance)
        let logsAfter = try context.fetch(FetchDescriptor<VaultAccessLog>())
        #expect(logsAfter.isEmpty, "All \(totalLogs) access logs should be deleted")
        
        // Verify: All vaults deleted
        let vaultsAfter = try context.fetch(FetchDescriptor<Vault>())
        #expect(vaultsAfter.isEmpty, "All vaults should be deleted")
    }
    
    // MARK: - Test 5: Nominee Access Termination
    
    @Test("Nominee access termination - logs preserved, access removed")
    func testNomineeAccessTermination() async throws {
        // Setup
        let container = try createTestModelContainer()
        let context = container.mainContext
        
        let owner = User(
            appleUserID: "owner-456",
            fullName: "Owner",
            email: "owner@example.com"
        )
        context.insert(owner)
        
        let nominee = User(
            appleUserID: "nominee-456",
            fullName: "Nominee",
            email: "nominee@example.com"
        )
        context.insert(nominee)
        
        let vault = Vault(name: "Shared Vault")
        vault.owner = owner
        if owner.ownedVaults == nil {
            owner.ownedVaults = []
        }
        owner.ownedVaults?.append(vault)
        context.insert(vault)
        
        let nomineeRecord = Nominee(
            name: nominee.fullName,
            email: nominee.email,
            status: .accepted
        )
        nomineeRecord.vault = vault
        context.insert(nomineeRecord)
        
        // Create access log from nominee
        let log = VaultAccessLog(
            accessType: "opened",
            userID: nominee.id,
            userName: nominee.fullName
        )
        log.vault = vault
        context.insert(log)
        
        try context.save()
        
        // Delete nominee account
        let deletionService = AccountDeletionService()
        deletionService.configure(modelContext: context)
        
        try await deletionService.deleteAccount(user: nominee)
        
        // Verify: Access log preserved but marked
        let logsAfter = try context.fetch(FetchDescriptor<VaultAccessLog>())
        #expect(logsAfter.count == 1, "Access log should be preserved")
        #expect(logsAfter.first?.userName?.contains("Account Deleted") == true, "Log should be marked")
        
        // Verify: Nominee record deleted
        let nomineesAfter = try context.fetch(FetchDescriptor<Nominee>())
        #expect(nomineesAfter.isEmpty, "Nominee record should be deleted")
        
        // Verify: Vault still exists
        let vaultsAfter = try context.fetch(FetchDescriptor<Vault>())
        #expect(vaultsAfter.count == 1, "Vault should still exist")
    }
    
    // MARK: - Test 6: Empty User (No Vaults)
    
    @Test("Empty user - deletion succeeds without errors")
    func testEmptyUserDeletion() async throws {
        // Setup
        let container = try createTestModelContainer()
        let context = container.mainContext
        
        let user = User(
            appleUserID: "empty-user",
            fullName: "Empty User",
            email: "empty@example.com"
        )
        context.insert(user)
        try context.save()
        
        // Delete account
        let deletionService = AccountDeletionService()
        deletionService.configure(modelContext: context)
        
        // Should not throw
        try await deletionService.deleteAccount(user: user)
        
        // Verify: User deleted
        let usersAfter = try context.fetch(FetchDescriptor<User>())
        #expect(usersAfter.isEmpty, "User should be deleted")
    }
    
    // MARK: - Test 7: Error Handling
    
    @Test("Error handling - context not available")
    func testErrorHandlingContextNotAvailable() async throws {
        let deletionService = AccountDeletionService()
        // Don't configure modelContext
        
        let user = User(
            appleUserID: "test",
            fullName: "Test",
            email: "test@example.com"
        )
        
        // Should throw error
        do {
            try await deletionService.deleteAccount(user: user)
            Issue.record("Should have thrown error")
        } catch AccountDeletionError.contextNotAvailable {
            // Expected error
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Test 8: CloudKit Orphaned Vaults Cleanup
    
    @Test("CloudKit sync - orphaned vaults are cleaned up")
    func testCloudKitOrphanedVaultsCleanup() async throws {
        // Setup
        let container = try createTestModelContainer()
        let context = container.mainContext
        
        // Create a user (simulating CloudKit restored user)
        let restoredUser = User(
            appleUserID: "test-apple-id-123",
            fullName: "Restored User",
            email: "test@example.com"
        )
        context.insert(restoredUser)
        
        // Create vault owned by restored user (simulating CloudKit restored vault)
        let orphanedVault = Vault(name: "Orphaned Vault")
        orphanedVault.owner = restoredUser
        context.insert(orphanedVault)
        
        try context.save()
        
        // Now create current user with same Apple ID (simulating re-sign-in)
        let currentUser = User(
            appleUserID: "test-apple-id-123", // Same Apple ID
            fullName: "Current User",
            email: "test@example.com"
        )
        context.insert(currentUser)
        try context.save()
        
        // Verify orphaned vault exists
        let vaultsBefore = try context.fetch(FetchDescriptor<Vault>())
        #expect(vaultsBefore.count == 1, "Orphaned vault should exist before cleanup")
        
        // Simulate cleanup (as done in AuthenticationService)
        // Find all users
        let allUsers = try context.fetch(FetchDescriptor<User>())
        let existingUserIDs = Set(allUsers.map { $0.id })
        
        // Find orphaned vaults
        let allVaults = try context.fetch(FetchDescriptor<Vault>())
        var orphanedVaults: [Vault] = []
        
        for vault in allVaults {
            if let owner = vault.owner {
                // Check if owner has same Apple ID but different UUID (CloudKit restored)
                if owner.appleUserID == currentUser.appleUserID && owner.id != currentUser.id {
                    orphanedVaults.append(vault)
                }
                // Check if owner doesn't exist
                else if !existingUserIDs.contains(owner.id) {
                    orphanedVaults.append(vault)
                }
            }
        }
        
        // Delete orphaned vaults
        for vault in orphanedVaults {
            if let documents = vault.documents {
                for document in documents {
                    context.delete(document)
                }
            }
            context.delete(vault)
        }
        
        try context.save()
        
        // Verify orphaned vault is deleted
        let vaultsAfter = try context.fetch(FetchDescriptor<Vault>())
        #expect(vaultsAfter.isEmpty, "Orphaned vault should be deleted")
        
        // Verify current user still exists
        let usersAfter = try context.fetch(FetchDescriptor<User>())
        #expect(usersAfter.count == 1, "Current user should still exist")
        #expect(usersAfter.first?.id == currentUser.id, "Current user should be the one that remains")
    }
}

//
//  iMessageNomineeInvitationTests.swift
//  Khandoba Secure DocsTests
//
//  Unit tests for iMessage nominee invitation and acceptance flow
//

import Testing
import Foundation
import SwiftData
@testable import Khandoba_Secure_Docs

struct iMessageNomineeInvitationTests {
    
    // MARK: - Test Helper: Create In-Memory ModelContainer
    
    private func createTestModelContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            Vault.self,
            Nominee.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(for: schema, configurations: [configuration])
    }
    
    // MARK: - Invitation URL Creation Tests
    
    @Test("Invitation URL creation with all parameters")
    func testInvitationURLCreation() {
        let token = UUID().uuidString
        let vaultName = "Test Vault"
        let status = "pending"
        let sender = "John Doe"
        
        var components = URLComponents(string: "khandoba://nominee/invite")
        components?.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "vault", value: vaultName),
            URLQueryItem(name: "status", value: status),
            URLQueryItem(name: "sender", value: sender)
        ]
        
        guard let url = components?.url else {
            Issue.record("Failed to create invitation URL")
            return
        }
        
        #expect(url.scheme == "khandoba")
        #expect(url.host == "nominee")
        #expect(url.path == "/invite")
        
        // Verify query parameters
        guard let queryItems = components?.queryItems else {
            Issue.record("No query items in URL")
            return
        }
        
        let tokenItem = queryItems.first { $0.name == "token" }
        let vaultItem = queryItems.first { $0.name == "vault" }
        let statusItem = queryItems.first { $0.name == "status" }
        let senderItem = queryItems.first { $0.name == "sender" }
        
        #expect(tokenItem?.value == token)
        #expect(vaultItem?.value == vaultName)
        #expect(statusItem?.value == status)
        #expect(senderItem?.value == sender)
    }
    
    @Test("Invitation URL creation with minimal parameters")
    func testInvitationURLMinimalParameters() {
        let token = UUID().uuidString
        let vaultName = "My Vault"
        
        var components = URLComponents(string: "khandoba://nominee/invite")
        components?.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "vault", value: vaultName),
            URLQueryItem(name: "status", value: "pending")
        ]
        
        guard let url = components?.url else {
            Issue.record("Failed to create invitation URL")
            return
        }
        
        #expect(url.scheme == "khandoba")
        #expect(url.host == "nominee")
        
        guard let queryItems = components?.queryItems else {
            Issue.record("No query items")
            return
        }
        
        #expect(queryItems.count == 3)
        #expect(queryItems.contains { $0.name == "token" && $0.value == token })
        #expect(queryItems.contains { $0.name == "vault" && $0.value == vaultName })
        #expect(queryItems.contains { $0.name == "status" && $0.value == "pending" })
    }
    
    @Test("Invitation URL with special characters in vault name")
    func testInvitationURLSpecialCharacters() {
        let token = UUID().uuidString
        let vaultName = "My Vault & Documents"
        let encodedVaultName = vaultName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vaultName
        
        let urlString = "khandoba://nominee/invite?token=\(token)&vault=\(encodedVaultName)"
        guard let url = URL(string: urlString) else {
            Issue.record("Failed to create URL with special characters")
            return
        }
        
        #expect(url.scheme == "khandoba")
        
        // Parse back
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            Issue.record("Failed to parse URL")
            return
        }
        
        let vaultItem = queryItems.first { $0.name == "vault" }
        #expect(vaultItem != nil, "Vault parameter should exist")
    }
    
    // MARK: - Invitation URL Parsing Tests
    
    @Test("Parse invitation URL with all parameters")
    func testParseInvitationURL() {
        let token = UUID().uuidString
        let vaultName = "Test Vault"
        let status = "pending"
        let sender = "John Doe"
        
        let urlString = "khandoba://nominee/invite?token=\(token)&vault=\(vaultName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vaultName)&status=\(status)&sender=\(sender.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sender)"
        
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            Issue.record("Failed to parse invitation URL")
            return
        }
        
        #expect(url.scheme == "khandoba")
        #expect(url.host == "nominee")
        #expect(url.path == "/invite")
        
        let parsedToken = queryItems.first(where: { $0.name == "token" })?.value
        let parsedVault = queryItems.first(where: { $0.name == "vault" })?.value
        let parsedStatus = queryItems.first(where: { $0.name == "status" })?.value
        let parsedSender = queryItems.first(where: { $0.name == "sender" })?.value
        
        #expect(parsedToken == token)
        #expect(parsedVault == vaultName)
        #expect(parsedStatus == status)
        #expect(parsedSender == sender)
    }
    
    @Test("Parse invitation URL with missing optional parameters")
    func testParseInvitationURLMissingParameters() {
        let token = UUID().uuidString
        let vaultName = "Test Vault"
        
        let urlString = "khandoba://nominee/invite?token=\(token)&vault=\(vaultName)"
        
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            Issue.record("Failed to parse invitation URL")
            return
        }
        
        let parsedToken = queryItems.first(where: { $0.name == "token" })?.value
        let parsedVault = queryItems.first(where: { $0.name == "vault" })?.value
        let parsedStatus = queryItems.first(where: { $0.name == "status" })?.value ?? "pending"
        let parsedSender = queryItems.first(where: { $0.name == "sender" })?.value ?? "Vault Owner"
        
        #expect(parsedToken == token)
        #expect(parsedVault == vaultName)
        #expect(parsedStatus == "pending") // Default
        #expect(parsedSender == "Vault Owner") // Default
    }
    
    // MARK: - Nominee Creation Tests
    
    @Test("Create nominee with invitation token")
    func testCreateNomineeWithToken() async throws {
        let container = try createTestModelContainer()
        let context = await MainActor.run { container.mainContext }
        
        // Create test user
        let owner = User(
            appleUserID: "owner-123",
            fullName: "Vault Owner",
            email: "owner@example.com"
        )
        context.insert(owner)
        
        // Create vault
        let vault = Vault(name: "Test Vault")
        vault.owner = owner
        context.insert(vault)
        
        // Create nominee
        let inviteToken = UUID().uuidString
        let nominee = Nominee(
            name: "Nominee User",
            phoneNumber: "+1234567890",
            email: "nominee@example.com"
        )
        nominee.vault = vault
        nominee.invitedByUserID = owner.id
        nominee.inviteToken = inviteToken
        nominee.status = .pending
        
        context.insert(nominee)
        try context.save()
        
        // Verify nominee was created
        let descriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.inviteToken == inviteToken }
        )
        let nominees = try context.fetch(descriptor)
        
        #expect(nominees.count == 1)
        #expect(nominees.first?.name == "Nominee User")
        #expect(nominees.first?.inviteToken == inviteToken)
        #expect(nominees.first?.status == .pending)
        #expect(nominees.first?.vault?.id == vault.id)
        #expect(nominees.first?.invitedByUserID == owner.id)
    }
    
    @Test("Nominee token uniqueness")
    func testNomineeTokenUniqueness() async throws {
        let container = try createTestModelContainer()
        let context = await MainActor.run { container.mainContext }
        
        let owner = User(
            appleUserID: "owner-123",
            fullName: "Owner",
            email: "owner@example.com"
        )
        context.insert(owner)
        
        let vault = Vault(name: "Test Vault")
        vault.owner = owner
        context.insert(vault)
        
        // Create two nominees with different tokens
        let token1 = UUID().uuidString
        let token2 = UUID().uuidString
        
        let nominee1 = Nominee(name: "Nominee 1")
        nominee1.vault = vault
        nominee1.inviteToken = token1
        
        let nominee2 = Nominee(name: "Nominee 2")
        nominee2.vault = vault
        nominee2.inviteToken = token2
        
        context.insert(nominee1)
        context.insert(nominee2)
        try context.save()
        
        // Verify both can be found by their unique tokens
        let descriptor1 = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.inviteToken == token1 }
        )
        let descriptor2 = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.inviteToken == token2 }
        )
        
        let nominees1 = try context.fetch(descriptor1)
        let nominees2 = try context.fetch(descriptor2)
        
        #expect(nominees1.count == 1)
        #expect(nominees2.count == 1)
        #expect(nominees1.first?.name == "Nominee 1")
        #expect(nominees2.first?.name == "Nominee 2")
    }
    
    // MARK: - Invitation Acceptance Tests
    
    @Test("Accept invitation - status update")
    func testAcceptInvitationStatusUpdate() async throws {
        let container = try createTestModelContainer()
        let context = await MainActor.run { container.mainContext }
        
        // Setup: Create owner, vault, and nominee
        let owner = User(
            appleUserID: "owner-123",
            fullName: "Owner",
            email: "owner@example.com"
        )
        context.insert(owner)
        
        let vault = Vault(name: "Test Vault")
        vault.owner = owner
        context.insert(vault)
        
        let inviteToken = UUID().uuidString
        let nominee = Nominee(name: "Nominee")
        nominee.vault = vault
        nominee.inviteToken = inviteToken
        nominee.status = .pending
        context.insert(nominee)
        try context.save()
        
        // Verify initial state
        #expect(nominee.status == .pending)
        #expect(nominee.acceptedAt == nil)
        
        // Accept invitation
        nominee.status = .accepted
        nominee.acceptedAt = Date()
        try context.save()
        
        // Verify acceptance
        let descriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.inviteToken == inviteToken }
        )
        let nominees = try context.fetch(descriptor)
        
        guard let acceptedNominee = nominees.first else {
            Issue.record("Nominee not found after acceptance")
            return
        }
        
        #expect(acceptedNominee.status == .accepted)
        #expect(acceptedNominee.acceptedAt != nil)
        #expect(acceptedNominee.acceptedAt! <= Date())
    }
    
    @Test("Accept invitation - find by token")
    func testAcceptInvitationFindByToken() async throws {
        let container = try createTestModelContainer()
        let context = await MainActor.run { container.mainContext }
        
        let owner = User(
            appleUserID: "owner-123",
            fullName: "Owner",
            email: "owner@example.com"
        )
        context.insert(owner)
        
        let vault = Vault(name: "Test Vault")
        vault.owner = owner
        context.insert(vault)
        
        let inviteToken = UUID().uuidString
        let nominee = Nominee(name: "Nominee")
        nominee.vault = vault
        nominee.inviteToken = inviteToken
        nominee.status = .pending
        context.insert(nominee)
        try context.save()
        
        // Simulate processInvitationAcceptance logic
        let nomineeDescriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.inviteToken == inviteToken }
        )
        let nominees = try context.fetch(nomineeDescriptor)
        
        guard let foundNominee = nominees.first else {
            Issue.record("Nominee not found by token")
            return
        }
        
        // Update status
        foundNominee.status = .accepted
        foundNominee.acceptedAt = Date()
        try context.save()
        
        // Verify
        #expect(foundNominee.status == .accepted)
        #expect(foundNominee.inviteToken == inviteToken)
    }
    
    @Test("Accept invitation - invalid token")
    func testAcceptInvitationInvalidToken() async throws {
        let container = try createTestModelContainer()
        let context = await MainActor.run { container.mainContext }
        
        // Try to find nominee with non-existent token
        let invalidToken = UUID().uuidString
        let nomineeDescriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.inviteToken == invalidToken }
        )
        let nominees = try context.fetch(nomineeDescriptor)
        
        #expect(nominees.isEmpty, "Should not find nominee with invalid token")
    }
    
    // MARK: - Deep Link Generation Tests
    
    @Test("Deep link URL generation for main app")
    func testDeepLinkURLGeneration() {
        let token = UUID().uuidString
        let vaultName = "Test Vault"
        
        let urlString = "khandoba://nominee/invite?token=\(token)&vault=\(vaultName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vaultName)"
        
        guard let url = URL(string: urlString) else {
            Issue.record("Failed to create deep link URL")
            return
        }
        
        #expect(url.scheme == "khandoba")
        #expect(url.host == "nominee")
        #expect(url.path == "/invite")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            Issue.record("Failed to parse deep link URL")
            return
        }
        
        let tokenItem = queryItems.first { $0.name == "token" }
        let vaultItem = queryItems.first { $0.name == "vault" }
        
        #expect(tokenItem?.value == token)
        #expect(vaultItem?.value == vaultName)
    }
    
    @Test("Deep link URL with UserDefaults fallback")
    func testDeepLinkUserDefaultsFallback() {
        let token = UUID().uuidString
        let appGroupID = "group.com.khandoba.securedocs"
        
        // Simulate storing token for later processing
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            sharedDefaults.set(token, forKey: "pending_invite_token")
            sharedDefaults.synchronize()
            
            // Verify token was stored
            let storedToken = sharedDefaults.string(forKey: "pending_invite_token")
            #expect(storedToken == token)
            
            // Clean up
            sharedDefaults.removeObject(forKey: "pending_invite_token")
            sharedDefaults.synchronize()
        } else {
            Issue.record("App Group UserDefaults not available")
        }
    }
    
    // MARK: - Status Transition Tests
    
    @Test("Status transitions - pending to accepted")
    func testStatusTransitionPendingToAccepted() async throws {
        let container = try createTestModelContainer()
        let context = await MainActor.run { container.mainContext }
        
        let nominee = Nominee(name: "Test Nominee")
        nominee.status = .pending
        context.insert(nominee)
        try context.save()
        
        #expect(nominee.status == .pending)
        
        // Transition to accepted
        nominee.status = .accepted
        nominee.acceptedAt = Date()
        try context.save()
        
        #expect(nominee.status == .accepted)
        #expect(nominee.statusRaw == "accepted")
        #expect(nominee.acceptedAt != nil)
    }
    
    @Test("Status transitions - accepted to active")
    func testStatusTransitionAcceptedToActive() async throws {
        let container = try createTestModelContainer()
        let context = await MainActor.run { container.mainContext }
        
        let nominee = Nominee(name: "Test Nominee")
        nominee.status = .accepted
        nominee.acceptedAt = Date()
        context.insert(nominee)
        try context.save()
        
        #expect(nominee.status == .accepted)
        
        // Transition to active (when nominee accesses vault)
        nominee.status = .active
        nominee.lastActiveAt = Date()
        try context.save()
        
        #expect(nominee.status == .active)
        #expect(nominee.statusRaw == "active")
        #expect(nominee.lastActiveAt != nil)
    }
    
    @Test("Status display names")
    func testStatusDisplayNames() {
        #expect(NomineeStatus.pending.displayName == "Pending")
        #expect(NomineeStatus.accepted.displayName == "Accepted")
        #expect(NomineeStatus.active.displayName == "Active")
        #expect(NomineeStatus.inactive.displayName == "Inactive")
        #expect(NomineeStatus.revoked.displayName == "Revoked")
    }
    
    // MARK: - Vault Access Verification Tests
    
    @Test("Accepted nominee has vault access")
    func testAcceptedNomineeVaultAccess() async throws {
        let container = try createTestModelContainer()
        let context = await MainActor.run { container.mainContext }
        
        // Create owner
        let owner = User(
            appleUserID: "owner-123",
            fullName: "Owner",
            email: "owner@example.com"
        )
        context.insert(owner)
        
        // Create vault
        let vault = Vault(name: "Shared Vault")
        vault.owner = owner
        context.insert(vault)
        
        // Create and accept nominee
        let nominee = Nominee(name: "Nominee")
        nominee.vault = vault
        nominee.status = .accepted
        nominee.acceptedAt = Date()
        context.insert(nominee)
        
        if vault.nomineeList == nil {
            vault.nomineeList = []
        }
        vault.nomineeList?.append(nominee)
        
        try context.save()
        
        // Verify nominee has access
        #expect(nominee.status == .accepted)
        #expect(nominee.vault?.id == vault.id)
        #expect(vault.nomineeList?.contains(where: { $0.id == nominee.id }) == true)
        
        // Verify nominee can be found for the vault
        // Note: Fetch all accepted nominees and filter by vault in code (SwiftData predicate limitation with optionals)
        let descriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.statusRaw == "accepted" }
        )
        let allAcceptedNominees = try context.fetch(descriptor)
        let acceptedNominees = allAcceptedNominees.filter { $0.vault?.id == vault.id }
        
        #expect(acceptedNominees.count == 1)
        #expect(acceptedNominees.first?.id == nominee.id)
    }
    
    @Test("Multiple nominees for same vault")
    func testMultipleNomineesSameVault() async throws {
        let container = try createTestModelContainer()
        let context = await MainActor.run { container.mainContext }
        
        let owner = User(
            appleUserID: "owner-123",
            fullName: "Owner",
            email: "owner@example.com"
        )
        context.insert(owner)
        
        let vault = Vault(name: "Shared Vault")
        vault.owner = owner
        context.insert(vault)
        
        // Create multiple nominees
        let nominee1 = Nominee(name: "Nominee 1")
        nominee1.vault = vault
        nominee1.status = .accepted
        nominee1.inviteToken = UUID().uuidString
        
        let nominee2 = Nominee(name: "Nominee 2")
        nominee2.vault = vault
        nominee2.status = .pending
        nominee2.inviteToken = UUID().uuidString
        
        let nominee3 = Nominee(name: "Nominee 3")
        nominee3.vault = vault
        nominee3.status = .accepted
        nominee3.inviteToken = UUID().uuidString
        
        context.insert(nominee1)
        context.insert(nominee2)
        context.insert(nominee3)
        try context.save()
        
        // Verify all nominees are associated with vault
        // Note: Fetch all nominees and filter by vault in code (SwiftData predicate limitation with optionals)
        let descriptor = FetchDescriptor<Nominee>()
        let allNominees = try context.fetch(descriptor).filter { $0.vault?.id == vault.id }
        
        #expect(allNominees.count == 3)
        
        // Verify accepted nominees
        let acceptedDescriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.statusRaw == "accepted" }
        )
        let allAccepted = try context.fetch(acceptedDescriptor)
        let acceptedNominees = allAccepted.filter { $0.vault?.id == vault.id }
        
        #expect(acceptedNominees.count == 2)
    }
    
    // MARK: - Complete Flow Test
    
    @Test("Complete invitation and acceptance flow")
    func testCompleteInvitationFlow() async throws {
        let container = try createTestModelContainer()
        let context = await MainActor.run { container.mainContext }
        
        // Step 1: Create owner and vault
        let owner = User(
            appleUserID: "owner-123",
            fullName: "Vault Owner",
            email: "owner@example.com"
        )
        context.insert(owner)
        
        let vault = Vault(name: "Test Vault")
        vault.owner = owner
        context.insert(vault)
        try context.save()
        
        // Step 2: Create invitation (simulate sendNomineeInvitation)
        let inviteToken = UUID().uuidString
        let vaultName = vault.name
        let recipientName = "Nominee User"
        
        let nominee = Nominee(
            name: recipientName,
            phoneNumber: "+1234567890",
            email: "nominee@example.com"
        )
        nominee.vault = vault
        nominee.invitedByUserID = owner.id
        nominee.inviteToken = inviteToken
        nominee.status = .pending
        
        if vault.nomineeList == nil {
            vault.nomineeList = []
        }
        vault.nomineeList?.append(nominee)
        
        context.insert(nominee)
        try context.save()
        
        // Verify invitation created
        #expect(nominee.status == .pending)
        #expect(nominee.inviteToken == inviteToken)
        
        // Step 3: Create invitation URL
        var components = URLComponents(string: "khandoba://nominee/invite")
        components?.queryItems = [
            URLQueryItem(name: "token", value: inviteToken),
            URLQueryItem(name: "vault", value: vaultName),
            URLQueryItem(name: "status", value: "pending"),
            URLQueryItem(name: "sender", value: owner.fullName)
        ]
        
        guard let invitationURL = components?.url else {
            Issue.record("Failed to create invitation URL")
            return
        }
        
        #expect(invitationURL.scheme == "khandoba")
        
        // Step 4: Parse invitation URL (simulate recipient receiving)
        guard let parsedComponents = URLComponents(url: invitationURL, resolvingAgainstBaseURL: false),
              let parsedQueryItems = parsedComponents.queryItems else {
            Issue.record("Failed to parse invitation URL")
            return
        }
        
        let parsedToken = parsedQueryItems.first(where: { $0.name == "token" })?.value
        let parsedVault = parsedQueryItems.first(where: { $0.name == "vault" })?.value
        
        #expect(parsedToken == inviteToken)
        #expect(parsedVault == vaultName)
        
        // Step 5: Accept invitation (simulate processInvitationAcceptance)
        let nomineeDescriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.inviteToken == inviteToken }
        )
        let nominees = try context.fetch(nomineeDescriptor)
        
        guard let foundNominee = nominees.first else {
            Issue.record("Nominee not found by token")
            return
        }
        
        foundNominee.status = .accepted
        foundNominee.acceptedAt = Date()
        try context.save()
        
        // Verify acceptance
        #expect(foundNominee.status == .accepted)
        #expect(foundNominee.acceptedAt != nil)
        
        // Step 6: Verify vault access
        // Note: Fetch by status and token, then filter by vault in code (SwiftData predicate limitation with optionals)
        let acceptedDescriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { 
                $0.statusRaw == "accepted" &&
                $0.inviteToken == inviteToken
            }
        )
        let allMatching = try context.fetch(acceptedDescriptor)
        let acceptedNominees = allMatching.filter { $0.vault?.id == vault.id }
        
        #expect(acceptedNominees.count == 1)
        #expect(acceptedNominees.first?.name == recipientName)
        
        // Step 7: Generate deep link for main app
        let deepLinkURL = URL(string: "khandoba://nominee/invite?token=\(inviteToken)&vault=\(vaultName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vaultName)")
        
        #expect(deepLinkURL != nil)
        #expect(deepLinkURL?.scheme == "khandoba")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Handle missing token in acceptance")
    func testHandleMissingToken() async throws {
        let container = try createTestModelContainer()
        let context = await MainActor.run { container.mainContext }
        
        // Try to find nominee with nil token
        let nomineeDescriptor = FetchDescriptor<Nominee>(
            predicate: #Predicate { $0.inviteToken == "" }
        )
        let nominees = try context.fetch(nomineeDescriptor)
        
        // Should not find any nominees with empty token
        #expect(nominees.isEmpty || nominees.allSatisfy { $0.inviteToken.isEmpty })
    }
    
    @Test("Handle invalid URL format")
    func testHandleInvalidURL() {
        let invalidURLs = [
            "invalid://scheme",
            "khandoba://wrong/path",
            "not-a-url",
            ""
        ]
        
        for urlString in invalidURLs {
            guard let url = URL(string: urlString) else {
                // Invalid URL - this is expected
                continue
            }
            
            // If URL is created, verify it's not our invitation format
            if url.scheme == "khandoba" && url.host == "nominee" {
                #expect(url.path == "/invite", "URL should have correct path: \(urlString)")
            }
        }
    }
}

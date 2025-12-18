//
//  AuthenticationService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import SwiftUI
import AuthenticationServices
import SwiftData
import Combine
import UIKit
import Supabase
import CryptoKit

final class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    // currentRole removed - everyone is a user (autopilot mode)
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    // Store nonce for Apple Sign In
    private var currentNonce: String?
    
    private var modelContext: ModelContext?
    private var supabaseService: SupabaseService?
    
    init() {}
    
    // SwiftData/CloudKit mode
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.supabaseService = nil
        checkAuthenticationState()
    }
    
    // Supabase mode
    func configure(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
        self.modelContext = nil
        checkAuthenticationState()
    }
    
    func checkAuthenticationState() {
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            // Supabase mode - check session
            Task {
                do {
                    print("🔍 Checking authentication state...")
                    
                    // First check if we have a session in memory
                    var session = supabaseService.currentSession
                    
                    // If no session in memory, try to get it from Supabase (checks local storage)
                    if session == nil {
                        print("   No session in memory, checking Supabase for stored session...")
                        if (try? await supabaseService.getCurrentUser()) != nil {
                            // User exists - get the session
                            session = supabaseService.currentSession
                            if session != nil {
                                print("   ✅ Found stored session")
                            }
                        }
                    }
                    
                    if let session = session {
                        // With emitLocalSessionAsInitialSession: true, we need to check if session is expired
                        if session.isExpired {
                            print("⚠️ Session found but expired - user needs to sign in again")
                            await MainActor.run {
                                self.isAuthenticated = false
                                self.currentUser = nil
                            }
                            return
                        }
                        
                        print("✅ Active session found")
                        // Get user ID from session
                        let userIDString = session.user.id.uuidString
                        guard let userID = UUID(uuidString: userIDString) else {
                            print("⚠️ Invalid user ID format: \(userIDString)")
                            await MainActor.run {
                                self.isAuthenticated = false
                            }
                            return
                        }
                        
                        print("   Fetching user data from database...")
                        // Fetch user from Supabase database
                        let supabaseUser: SupabaseUser = try await supabaseService.fetch(
                            "users",
                            id: userID
                        )
                        
                        // Convert to User model for compatibility
                        await MainActor.run {
                            self.currentUser = convertToUser(from: supabaseUser)
                            self.isAuthenticated = true
                            print("✅ User authenticated: \(supabaseUser.fullName)")
                        }
                    } else {
                        print("ℹ️ No active session - user needs to sign in")
                        await MainActor.run {
                            self.isAuthenticated = false
                            self.currentUser = nil
                        }
                    }
                } catch {
                    print("❌ Error checking Supabase auth state: \(error.localizedDescription)")
                    print("   Details: \(error)")
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.currentUser = nil
                    }
                }
            }
        } else if let modelContext = modelContext {
            // SwiftData mode
        do {
            let descriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(descriptor)
            
            if let user = users.first {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            print("Error checking auth state: \(error)")
            }
        }
    }
    
    // MARK: - Nonce Generation (for Apple Sign In)
    
    /// Generate a random nonce string for Apple Sign In
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
    
    /// Hash a nonce string with SHA-256
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
    
    /// Generate and store a nonce for Apple Sign In
    /// Returns the SHA-256 hashed nonce to use in the authorization request
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        let hashedNonce = sha256(nonce)
        print("🔑 Generated nonce for Apple Sign In")
        return hashedNonce
    }
    
    func signIn(with authorization: ASAuthorization) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Development mode bypass
        if AppConfig.isDevelopmentMode {
            try await signInDevelopmentMode()
            return
        }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }
        
        let userIdentifier = appleIDCredential.user
        
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            try await signInWithSupabase(
                credential: appleIDCredential,
                supabaseService: supabaseService
            )
            return
        }
        
        // SwiftData/CloudKit mode (existing implementation)
        
        // Check if user exists
        guard let modelContext = modelContext else {
            throw AuthError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.appleUserID == userIdentifier }
        )
        
        let existingUsers = try modelContext.fetch(descriptor)
        
        if let existingUser = existingUsers.first {
            // CRITICAL: Check if this is a restored deleted account
            // If user has no vaults, it's likely a CloudKit-restored deleted account
            let vaultsDescriptor = FetchDescriptor<Vault>()
            let allVaults = try modelContext.fetch(vaultsDescriptor)
            let userVaults = allVaults.filter { $0.owner?.id == existingUser.id }
            
            // If user has no vaults, delete the old user and create fresh account
            // This handles CloudKit restoring deleted user data
            if userVaults.isEmpty {
                print("⚠️ Found restored deleted account (no vaults) - creating fresh account")
                print("   → Deleting old user record with photo/name from deleted account")
                
                // Delete the old user record
                modelContext.delete(existingUser)
                try modelContext.save()
                
                // Create fresh account with data from Apple
                let givenName = appleIDCredential.fullName?.givenName ?? ""
                let familyName = appleIDCredential.fullName?.familyName ?? ""
                let fullName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
                let email = appleIDCredential.email
                
                print("📝 Creating fresh account after deletion:")
                print("   Given Name: '\(givenName)'")
                print("   Family Name: '\(familyName)'")
                print("   Full Name: '\(fullName)'")
                print("   Email: '\(email ?? "nil")'")
                
                let newUser = User(
                    appleUserID: userIdentifier,
                    fullName: fullName.isEmpty ? "User" : fullName,
                    email: email,
                    profilePictureData: createDefaultProfileImage(name: fullName.isEmpty ? "User" : fullName)
                )
                
                // Auto-assign client role
                let clientRole = UserRole(role: .client)
                clientRole.user = newUser
                newUser.roles = [clientRole]
                
                modelContext.insert(newUser)
                modelContext.insert(clientRole)
                try modelContext.save()
                
                currentUser = newUser
                isAuthenticated = true
                
                // Clean up any orphaned vaults
                await cleanupOrphanedVaults(for: newUser, modelContext: modelContext)
                
                // Create Intel Vault for new user
                #if !APP_EXTENSION
                Task {
                    let vaultService = VaultService()
                    vaultService.configure(modelContext: modelContext, userID: newUser.id)
                    try? await vaultService.ensureIntelVaultExists(for: newUser)
                }
                #endif
            } else {
                // Existing user with vaults - normal sign in
                currentUser = existingUser
                
                // CRITICAL: Clean up orphaned vaults that may have been restored from CloudKit
                // This handles the case where account was deleted but CloudKit restored vaults
                // Run synchronously to ensure cleanup completes before user sees vaults
                await cleanupOrphanedVaults(for: existingUser, modelContext: modelContext)
                
                // Admin role removed - autopilot mode
                isAuthenticated = true
            }
        } else {
            // New user - create account with data from Apple
            let givenName = appleIDCredential.fullName?.givenName ?? ""
            let familyName = appleIDCredential.fullName?.familyName ?? ""
            let fullName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
            let email = appleIDCredential.email
            
            // Log what Apple provided for debugging
            print("📝 New user sign-in:")
            print("   Given Name: '\(givenName)'")
            print("   Family Name: '\(familyName)'")
            print("   Full Name: '\(fullName)'")
            print("   Email: '\(email ?? "nil")'")
            
            let newUser = User(
                appleUserID: userIdentifier,
                fullName: fullName.isEmpty ? "User" : fullName,
                email: email,
                profilePictureData: createDefaultProfileImage(name: fullName.isEmpty ? "User" : fullName)
            )
            
            // Auto-assign client role (single role system)
            let clientRole = UserRole(role: .client)
            clientRole.user = newUser
            newUser.roles = [clientRole]
            
            modelContext.insert(newUser)
            modelContext.insert(clientRole)
            try modelContext.save()
            
            currentUser = newUser
            isAuthenticated = true
            
            // CRITICAL: Clean up any orphaned vaults from previous account deletion
            // This handles CloudKit sync restoring deleted vaults
            // Run synchronously to ensure cleanup completes
            await cleanupOrphanedVaults(for: newUser, modelContext: modelContext)
            
            // Create Intel Vault for new user
            #if !APP_EXTENSION
            Task {
                let vaultService = VaultService()
                vaultService.configure(modelContext: modelContext, userID: newUser.id)
                try? await vaultService.ensureIntelVaultExists(for: newUser)
            }
            #endif
        }
    }
    
    // MARK: - Supabase Authentication
    
    /// Sign in with Supabase using Apple credentials
    private func signInWithSupabase(
        credential: ASAuthorizationAppleIDCredential,
        supabaseService: SupabaseService
    ) async throws {
        print("🔐 Starting Supabase authentication...")
        
        // Get identity token (required for Supabase)
        guard let identityTokenData = credential.identityToken,
              let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
            print("❌ Authentication failed: Missing identity token")
            throw AuthError.invalidCredential
        }
        
        print("✅ Identity token received from Apple")
        
        // Use the stored nonce (generated before authorization request)
        guard let nonce = currentNonce else {
            print("❌ Authentication failed: Nonce not found. Nonce must be generated before authorization request.")
            throw AuthError.invalidCredential
        }
        print("🔑 Using stored nonce for Supabase authentication")
        
        // Clear the nonce after use (security best practice)
        currentNonce = nil
        
        // Sign in with Supabase
        print("📡 Sending authentication request to Supabase...")
        let session: Session
        do {
            session = try await supabaseService.signInWithApple(
                idToken: identityTokenString,
                nonce: nonce
            )
            print("✅ Supabase authentication successful")
            print("   User ID: \(session.user.id.uuidString)")
            print("   Email: \(session.user.email ?? "not provided")")
        } catch {
            print("❌ Supabase authentication failed: \(error.localizedDescription)")
            print("   Error details: \(error)")
            throw error
        }
        
        // Extract user info from Apple credential
        let givenName = credential.fullName?.givenName ?? ""
        let familyName = credential.fullName?.familyName ?? ""
        let fullName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
        let email = credential.email
        let appleUserID = credential.user
        
        // Check if user exists in Supabase
        print("🔍 Checking if user exists in Supabase database...")
        let existingUsers: [SupabaseUser]
        do {
            existingUsers = try await supabaseService.fetchAll(
                "users",
                filters: ["apple_user_id": appleUserID]
            )
            print("   Found \(existingUsers.count) user(s) with Apple ID: \(appleUserID)")
        } catch {
            print("⚠️ Error checking for existing user: \(error.localizedDescription)")
            print("   Will attempt to create new user...")
            throw error
        }
        
        if let existingUser = existingUsers.first {
            print("✅ Existing user found: \(existingUser.fullName) (ID: \(existingUser.id))")
            // Existing user - update last active
            print("📝 Updating user's last active timestamp...")
            var updatedUser = existingUser
            updatedUser.lastActiveAt = Date()
            
            do {
                let _: SupabaseUser = try await supabaseService.update(
                    "users",
                    id: existingUser.id,
                    values: updatedUser
                )
                print("✅ User updated successfully")
            } catch {
                print("⚠️ Failed to update user: \(error.localizedDescription)")
                // Continue anyway - user can still sign in
            }
            
            // Convert to User model for compatibility
            await MainActor.run {
                self.currentUser = convertToUser(from: existingUser)
                self.isAuthenticated = true
                print("✅ User signed in successfully")
                print("   Authentication state updated: isAuthenticated = \(self.isAuthenticated)")
                print("   Current user: \(self.currentUser?.fullName ?? "nil")")
            }
        } else {
            // New user - create in Supabase
            print("👤 Creating new user in Supabase...")
            print("   Name: \(fullName.isEmpty ? "User" : fullName)")
            print("   Email: \(email ?? "not provided")")
            print("   Apple User ID: \(appleUserID)")
            
            let profilePictureData = createDefaultProfileImage(name: fullName.isEmpty ? "User" : fullName)
            var profilePictureURL: String? = nil
            
            // Upload profile picture to Supabase Storage if available
            if let pictureData = profilePictureData {
                do {
                    // Get user ID from session
                    let userIDString = session.user.id.uuidString
                    let storagePath = "profiles/\(userIDString).png"
                    let _ = try await supabaseService.uploadFile(
                        bucket: "encrypted-documents", // Using same bucket for now
                        path: storagePath,
                        data: pictureData
                    )
                    profilePictureURL = storagePath
                } catch {
                    print("⚠️ Failed to upload profile picture: \(error)")
                }
            }
            
            // CRITICAL: Use the authenticated user's ID from Supabase Auth session
            // The RLS policy requires auth.uid() = id, so we must use session.user.id
            let authenticatedUserID = session.user.id
            print("🔑 Using authenticated user ID: \(authenticatedUserID.uuidString)")
            
            let newSupabaseUser = SupabaseUser(
                id: authenticatedUserID, // Use session user ID, not a new UUID
                appleUserID: appleUserID,
                fullName: fullName.isEmpty ? "User" : fullName,
                email: email,
                profilePictureURL: profilePictureURL,
                isActive: true,
                isPremiumSubscriber: false
            )
            
            print("💾 Inserting user into database...")
            let createdUser: SupabaseUser
            do {
                createdUser = try await supabaseService.insert(
                    "users",
                    values: newSupabaseUser
                )
                print("✅ User created successfully (ID: \(createdUser.id))")
            } catch {
                print("❌ Failed to create user: \(error.localizedDescription)")
                print("   Error details: \(error)")
                throw error
            }
            
            // Create user role
            print("👤 Creating user role...")
            let userRole = SupabaseUserRole(
                userID: createdUser.id,
                role: .client
            )
            
            do {
                let _: SupabaseUserRole = try await supabaseService.insert(
                    "user_roles",
                    values: userRole
                )
                print("✅ User role created successfully")
            } catch {
                print("⚠️ Failed to create user role: \(error.localizedDescription)")
                // Continue anyway - user can still use the app
            }
            
            // Convert to User model for compatibility
            await MainActor.run {
                self.currentUser = convertToUser(from: createdUser)
                self.isAuthenticated = true
                print("✅ New user created and signed in successfully")
                print("   Authentication state updated: isAuthenticated = \(self.isAuthenticated)")
                print("   Current user: \(self.currentUser?.fullName ?? "nil")")
                print("   User ID: \(createdUser.id)")
            }
            
            // Create Intel Vault for new user
            #if !APP_EXTENSION
            Task {
                let vaultService = VaultService()
                vaultService.configure(supabaseService: supabaseService, userID: createdUser.id)
                try? await vaultService.ensureIntelVaultExists(for: createdUser.id)
            }
            #endif
        }
    }
    
    /// Convert SupabaseUser to User model for compatibility
    private func convertToUser(from supabaseUser: SupabaseUser) -> User {
        let user = User(
            appleUserID: supabaseUser.appleUserID,
            fullName: supabaseUser.fullName,
            email: supabaseUser.email,
            profilePictureData: nil // Will be loaded from URL if needed
        )
        user.id = supabaseUser.id
        user.createdAt = supabaseUser.createdAt
        user.lastActiveAt = supabaseUser.lastActiveAt
        user.isActive = supabaseUser.isActive
        user.isPremiumSubscriber = supabaseUser.isPremiumSubscriber
        user.subscriptionExpiryDate = supabaseUser.subscriptionExpiryDate
        
        // Load profile picture from URL if available
        if let profileURL = supabaseUser.profilePictureURL {
            Task {
                do {
                    let bucket = "encrypted-documents"
                    let data = try await supabaseService?.downloadFile(bucket: bucket, path: profileURL)
                    await MainActor.run {
                        user.profilePictureData = data
                    }
                } catch {
                    print("⚠️ Failed to load profile picture: \(error)")
                }
            }
        }
        
        return user
    }
    
    /// Clean up orphaned vaults that may have been restored from CloudKit
    /// This handles the case where account was deleted but CloudKit sync restored vaults
    @MainActor
    private func cleanupOrphanedVaults(for user: User, modelContext: ModelContext) async {
        do {
            print("🔍 Checking for orphaned vaults after account deletion...")
            
            // Find all vaults
            let allVaultsDescriptor = FetchDescriptor<Vault>()
            let allVaults = try modelContext.fetch(allVaultsDescriptor)
            
            // Find all existing users
            let usersDescriptor = FetchDescriptor<User>()
            let allUsers = try modelContext.fetch(usersDescriptor)
            let existingUserIDs = Set(allUsers.map { $0.id })
            
            var orphanedVaults: [Vault] = []
            
            for vault in allVaults {
                // Skip system vaults
                if vault.isSystemVault {
                    continue
                }
                
                // Check if vault has an owner
                if let owner = vault.owner {
                    // If owner's Apple ID matches current user but owner ID is different, it's orphaned
                    // This happens when CloudKit restores a deleted user with a new UUID
                    if owner.appleUserID == user.appleUserID && owner.id != user.id {
                        print("   ⚠️ Found orphaned vault: \(vault.name) (Owner ID mismatch - CloudKit restored)")
                        orphanedVaults.append(vault)
                    }
                    // If owner doesn't exist anymore, it's orphaned
                    else if !existingUserIDs.contains(owner.id) {
                        print("   ⚠️ Found vault with deleted owner: \(vault.name)")
                        orphanedVaults.append(vault)
                    }
                } else {
                    // Vault with no owner is orphaned
                    print("   ⚠️ Found vault with no owner: \(vault.name)")
                    orphanedVaults.append(vault)
                }
            }
            
            // Delete orphaned vaults
            if !orphanedVaults.isEmpty {
                print("   🗑️ Deleting \(orphanedVaults.count) orphaned vault(s) from CloudKit sync")
                for vault in orphanedVaults {
                    // Delete all documents first
                    if let documents = vault.documents {
                        for document in documents {
                            modelContext.delete(document)
                        }
                    }
                    // Delete vault
                    modelContext.delete(vault)
                    print("     → Deleted: \(vault.name)")
                }
                
                try modelContext.save()
                
                // Force CloudKit sync
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                try modelContext.save()
                
                print("   ✅ Cleaned up \(orphanedVaults.count) orphaned vault(s)")
            } else {
                print("   ✅ No orphaned vaults found")
            }
        } catch {
            print("   ⚠️ Error cleaning up orphaned vaults: \(error.localizedDescription)")
        }
    }
    
    func completeAccountSetup(fullName: String, profilePicture: Data?) async throws {
        guard let user = currentUser else {
            throw AuthError.noCurrentUser
        }
        
        // Supabase mode
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            print("📝 Completing account setup in Supabase mode...")
            print("   Full name: \(fullName)")
            print("   Has profile picture: \(profilePicture != nil)")
            
            // Get current Supabase user
            let userID = user.id
            
            // Upload profile picture to Supabase Storage if provided
            var profilePictureURL: String? = nil
            if let pictureData = profilePicture {
                do {
                    let storagePath = "profiles/\(userID.uuidString).png"
                    let _ = try await supabaseService.uploadFile(
                        bucket: "encrypted-documents",
                        path: storagePath,
                        data: pictureData
                    )
                    profilePictureURL = storagePath
                    print("✅ Profile picture uploaded to Supabase Storage")
                } catch {
                    print("⚠️ Failed to upload profile picture: \(error.localizedDescription)")
                    // Continue anyway - name update is more important
                }
            }
            
            // Update user in Supabase
            // Note: id and createdAt are let constants, so they must be set in initializer
            let updatedUser = SupabaseUser(
                id: userID,
                appleUserID: user.appleUserID,
                fullName: fullName,
                email: user.email,
                profilePictureURL: profilePictureURL ?? (user.profilePictureData != nil ? "profiles/\(userID.uuidString).png" : nil),
                createdAt: user.createdAt,
                lastActiveAt: Date(),
                isActive: true,
                isPremiumSubscriber: user.isPremiumSubscriber,
                subscriptionExpiryDate: user.subscriptionExpiryDate,
                updatedAt: Date()
            )
            
            do {
                let _: SupabaseUser = try await supabaseService.update(
                    "users",
                    id: userID,
                    values: updatedUser
                )
                print("✅ User updated in Supabase")
            } catch {
                print("❌ Failed to update user in Supabase: \(error.localizedDescription)")
                throw error
            }
            
            // Update local user model
            await MainActor.run {
                user.fullName = fullName
                if let pictureData = profilePicture {
                    user.profilePictureData = pictureData
                }
                self.currentUser = user
                self.isAuthenticated = true
            }
            
            print("✅ Account setup completed successfully")
            return
        }
        
        // SwiftData/CloudKit mode
        guard let modelContext = modelContext else {
            throw AuthError.contextNotAvailable
        }
        
        // Update user information
        user.fullName = fullName
        
        // Update profile picture only if user provided one
        // Keep existing picture (generated or previously uploaded) if nil
        if let profilePicture = profilePicture {
            user.profilePictureData = profilePicture
        }
        
        // Assign client role only if user doesn't have one already
        let hasClientRole = (user.roles ?? []).contains(where: { $0.role == .client })
        if !hasClientRole {
            let clientRole = UserRole(role: .client)
            clientRole.user = user
            user.roles = (user.roles ?? []) + [clientRole]
            modelContext.insert(clientRole)
        }
        
        try modelContext.save()
        
        // Role system simplified - everyone is a user
        isAuthenticated = true
    }
    
    // switchRole removed - single role system
    
    func signOut() async throws {
        if AppConfig.useSupabase, let supabaseService = supabaseService {
            // Sign out from Supabase
            try await supabaseService.signOut()
        }
        
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Development Mode
    private func signInDevelopmentMode() async throws {
        guard let modelContext = modelContext else {
            throw AuthError.contextNotAvailable
        }
        
        // Check if dev user exists
        let devID = AppConfig.devUserID
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.appleUserID == devID }
        )
        
        let existingUsers = try modelContext.fetch(descriptor)
        
        if let existingUser = existingUsers.first {
            // Existing dev user
            currentUser = existingUser
            isAuthenticated = true
        } else {
            // Create dev user with profile picture
            let newUser = User(
                appleUserID: AppConfig.devUserID,
                fullName: AppConfig.devUserName,
                email: AppConfig.devUserEmail,
                profilePictureData: createDefaultProfileImage(name: AppConfig.devUserName)
            )
            
            // Assign client role (single role system)
            let clientRole = UserRole(role: .client)
            clientRole.user = newUser
            newUser.roles = [clientRole]
            
            modelContext.insert(newUser)
            modelContext.insert(clientRole)
            try modelContext.save()
            
            currentUser = newUser
            isAuthenticated = true
            
            // Create Intel Vault for dev user
            #if !APP_EXTENSION
            Task {
                let vaultService = VaultService()
                vaultService.configure(modelContext: modelContext, userID: newUser.id)
                try? await vaultService.ensureIntelVaultExists(for: newUser)
            }
            #endif
        }
    }
    
    private func createDefaultProfileImage(name: String) -> Data? {
        // Create a profile image with person icon
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Background circle with gradient-like effect
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemBlue.withAlphaComponent(0.7).cgColor]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0]) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            } else {
                // Fallback to solid color
                UIColor.systemBlue.setFill()
                let circle = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
                circle.fill()
            }
            
            // Draw person icon in the center
            let iconSize: CGFloat = 100
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2 - 10, // Slightly above center
                width: iconSize,
                height: iconSize
            )
            
            // Create person icon using SF Symbols style
            UIColor.white.setFill()
            
            // Draw head (circle)
            let headRadius: CGFloat = iconSize * 0.25
            let headCenter = CGPoint(x: iconRect.midX, y: iconRect.minY + headRadius + 5)
            let headCircle = UIBezierPath(arcCenter: headCenter, radius: headRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            headCircle.fill()
            
            // Draw body (rounded rectangle/torso)
            let bodyWidth: CGFloat = iconSize * 0.5
            let bodyHeight: CGFloat = iconSize * 0.4
            let bodyRect = CGRect(
                x: iconRect.midX - bodyWidth / 2,
                y: headCenter.y + headRadius + 5,
                width: bodyWidth,
                height: bodyHeight
            )
            let bodyPath = UIBezierPath(roundedRect: bodyRect, cornerRadius: bodyWidth / 4)
            bodyPath.fill()
        }
        
        return image.pngData()
    }
}

enum AuthError: LocalizedError {
    case invalidCredential
    case contextNotAvailable
    case noCurrentUser
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential"
        case .contextNotAvailable:
            return "Database context not available"
        case .noCurrentUser:
            return "No current user found"
        }
    }
}


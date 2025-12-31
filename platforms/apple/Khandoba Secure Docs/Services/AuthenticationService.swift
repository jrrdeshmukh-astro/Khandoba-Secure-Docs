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
// Supabase removed - iOS-only uses CloudKit
import CryptoKit

#if os(iOS)
import UIKit
#endif

final class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    // currentRole removed - everyone is a user (autopilot mode)
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    // Store nonce for Apple Sign In
    private var currentNonce: String?
    
    private var modelContext: ModelContext?
    
    init() {}
    
    // iOS-ONLY: Using SwiftData/CloudKit exclusively
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkAuthenticationState()
    }
    
    func checkAuthenticationState() {
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        guard let modelContext = modelContext else { return }
        
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
                    // Instead of fatalError, use a fallback random value
                    // This prevents app crashes from security framework failures
                    print("⚠️ SecRandomCopyBytes failed with OSStatus \(errorCode), using fallback")
                    random = UInt8.random(in: 0...255)
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
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
        
        // Check if user exists
        guard let modelContext = modelContext else {
            throw AuthError.contextNotAvailable
        }
        
        // Use explicit predicate construction to avoid SwiftData reflection issues
        // Fetch all users and filter in Swift to avoid predicate metadata issues
        let descriptor = FetchDescriptor<User>()
        let allUsers = try modelContext.fetch(descriptor)
        let existingUsers = allUsers.filter { $0.appleUserID == userIdentifier }
        
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
                
                // Check and authorize device
                #if !APP_EXTENSION
                Task {
                    let deviceService = DeviceManagementService()
                    deviceService.configure(modelContext: modelContext, userID: existingUser.id)
                    await deviceService.checkCurrentDeviceAuthorization()
                    
                    // If device not authorized, authorize it (but not as irrevocable if one already exists)
                    if !deviceService.isDeviceAuthorized {
                        let hasIrrevocable = await deviceService.getIrrevocableDevice(for: existingUser.id) != nil
                        try? await deviceService.authorizeCurrentDevice(isIrrevocable: !hasIrrevocable)
                    }
                }
                #endif
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
                
                // Authorize current device (first device is irrevocable)
                let deviceService = DeviceManagementService()
                deviceService.configure(modelContext: modelContext, userID: newUser.id)
                try? await deviceService.authorizeCurrentDevice(isIrrevocable: true)
            }
            #endif
        }
    }
    
    // MARK: - Supabase Authentication (REMOVED)
    
    // All Supabase authentication code removed - iOS app uses SwiftData/CloudKit exclusively
    
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
        
        // iOS-ONLY: Using SwiftData/CloudKit exclusively
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
        // iOS-ONLY: Using SwiftData/CloudKit exclusively - no server-side session to sign out from
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
        // Fetch all users and filter in Swift to avoid predicate metadata issues
        let descriptor = FetchDescriptor<User>()
        let allUsers = try modelContext.fetch(descriptor)
        let existingUsers = allUsers.filter { $0.appleUserID == devID }
        
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
        #if os(iOS)
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
        #else
        // macOS: Return nil or create a simple placeholder
        return nil
        #endif
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


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

final class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    // currentRole removed - everyone is a user (autopilot mode)
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    
    init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkAuthenticationState()
    }
    
    func checkAuthenticationState() {
        // Check if user is already signed in
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(descriptor)
            
            if let user = users.first {
                self.currentUser = user
                self.isAuthenticated = true
                // No role selection - everyone has full access
            }
        } catch {
            print("Error checking auth state: \(error)")
        }
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
        
        // Check if user exists
        guard let modelContext = modelContext else {
            throw AuthError.contextNotAvailable
        }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.appleUserID == userIdentifier }
        )
        
        let existingUsers = try modelContext.fetch(descriptor)
        
        if let existingUser = existingUsers.first {
            // Existing user - sign in
            currentUser = existingUser
            
            // Admin role removed - autopilot mode
            isAuthenticated = true
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
            
            // Create Intel Vault for new user
            Task {
                let vaultService = VaultService()
                vaultService.configure(modelContext: modelContext, userID: newUser.id)
                try? await vaultService.ensureIntelVaultExists(for: newUser)
            }
        }
    }
    
    func completeAccountSetup(fullName: String, profilePicture: Data?) async throws {
        guard let user = currentUser, let modelContext = modelContext else {
            throw AuthError.noCurrentUser
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
    
    func signOut() {
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
            Task {
                let vaultService = VaultService()
                vaultService.configure(modelContext: modelContext, userID: newUser.id)
                try? await vaultService.ensureIntelVaultExists(for: newUser)
            }
        }
    }
    
    private func createDefaultProfileImage(name: String) -> Data? {
        // Create a simple colored circle as profile image
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Background circle
            UIColor.systemBlue.setFill()
            let circle = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
            circle.fill()
            
            // Initial letter(s)
            let initials = name.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined()
            let text = initials.isEmpty ? "?" : initials.uppercased()
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 80, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
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


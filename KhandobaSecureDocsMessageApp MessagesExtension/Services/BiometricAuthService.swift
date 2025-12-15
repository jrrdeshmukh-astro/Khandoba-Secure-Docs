//
//  BiometricAuthService.swift
//  Khandoba Secure Docs
//
//  Face ID/Touch ID authentication service for iMessage extension
//

import Foundation
import LocalAuthentication

@MainActor
final class BiometricAuthService {
    static let shared = BiometricAuthService()
    
    private init() {}
    
    /// Check if biometric authentication is available
    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Authenticate using Face ID or Touch ID
    /// - Parameter reason: User-facing reason for authentication
    /// - Returns: true if authentication succeeded, false if cancelled
    /// - Throws: BiometricAuthError if authentication fails
    func authenticate(reason: String = "Authenticate to continue") async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .userFallback:
                throw BiometricAuthError.cancelled
            case .biometryNotAvailable:
                throw BiometricAuthError.notAvailable
            case .biometryNotEnrolled:
                throw BiometricAuthError.notEnrolled
            case .biometryLockout:
                throw BiometricAuthError.lockedOut
            default:
                throw BiometricAuthError.failed(error.localizedDescription)
            }
        } catch {
            throw BiometricAuthError.failed(error.localizedDescription)
        }
    }
    
    /// Get biometric type (Face ID, Touch ID, or None)
    func biometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        default:
            return .none
        }
    }
}

enum BiometricType {
    case faceID
    case touchID
    case opticID
    case none
    
    var displayName: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "Biometric"
        }
    }
}

enum BiometricAuthError: LocalizedError {
    case cancelled
    case notAvailable
    case notEnrolled
    case lockedOut
    case failed(String)
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Authentication was cancelled"
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "No biometrics enrolled. Please set up Face ID or Touch ID in Settings"
        case .lockedOut:
            return "Biometric authentication is locked. Please unlock your device first"
        case .failed(let message):
            return "Authentication failed: \(message)"
        }
    }
}

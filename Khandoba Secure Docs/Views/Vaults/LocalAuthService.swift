// LocalAuthService.swift
import Foundation
import LocalAuthentication

final class LocalAuthService {
    static let shared = LocalAuthService()
    private init() {}

    enum BiometricType {
        case faceID, touchID, none
    }

    func biometricType() -> BiometricType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .none
        }
    }

    @MainActor
    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "" // mimic Wallet: no passcode fallback here
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}

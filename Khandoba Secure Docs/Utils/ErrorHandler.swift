//
//  ErrorHandler.swift
//  Khandoba Secure Docs
//
//  Centralized error handling

import Foundation
import SwiftUI
import Combine

@MainActor
final class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showError = false
    
    static let shared = ErrorHandler()
    
    private init() {}
    
    func handle(_ error: Error, context: String = "") {
        print(" Error in \(context): \(error.localizedDescription)")
        
        // Convert to AppError
        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = AppError.unknown(error.localizedDescription)
        }
        
        showError = true
    }
    
    func clearError() {
        currentError = nil
        showError = false
    }
}

enum AppError: LocalizedError, Identifiable {
    case networkError(String)
    case authenticationFailed(String)
    case storageError(String)
    case encryptionError(String)
    case invalidData(String)
    case permissionDenied(String)
    case subscriptionRequired
    case unknown(String)
    
    var id: String {
        errorDescription ?? "Unknown error"
    }
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .authenticationFailed(let message):
            return "Authentication Failed: \(message)"
        case .storageError(let message):
            return "Storage Error: \(message)"
        case .encryptionError(let message):
            return "Encryption Error: \(message)"
        case .invalidData(let message):
            return "Invalid Data: \(message)"
        case .permissionDenied(let message):
            return "Permission Denied: \(message)"
        case .subscriptionRequired:
            return "Premium subscription required for this feature"
        case .unknown(let message):
            return "Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again"
        case .authenticationFailed:
            return "Please sign in again"
        case .storageError:
            return "Check available storage space"
        case .encryptionError:
            return "Document encryption failed. Please try again"
        case .invalidData:
            return "The selected file may be corrupted"
        case .permissionDenied:
            return "Grant the required permissions in Settings"
        case .subscriptionRequired:
            return "Subscribe to Premium for unlimited access"
        case .unknown:
            return "Please try again or contact support"
        }
    }
}

// MARK: - Error Handling Extensions

extension View {
    func handleErrors() -> some View {
        self.modifier(ErrorHandlingModifier())
    }
}

struct ErrorHandlingModifier: ViewModifier {
    @StateObject private var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.errorDescription ?? "Error",
                isPresented: $errorHandler.showError,
                presenting: errorHandler.currentError
            ) { _ in
                Button("OK", role: .cancel) {
                    errorHandler.clearError()
                }
            } message: { error in
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                }
            }
    }
}

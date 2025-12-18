//
//  ErrorHandler.swift
//  Khandoba Secure Docs
//
//  Created for improved error handling and user-friendly messages
//

import Foundation
import SwiftUI
import OSLog

/// Error context for better error handling
enum ErrorContext {
    case upload
    case download
    case auth
    case vault
    case document
    case network
    case storage
    case validation
    case encryption
    case general
}

/// Recovery action for errors
enum RecoveryAction {
    case retry
    case signIn
    case checkConnection
    case freeUpSpace
    case contactSupport
    case none
}

/// Centralized error handling with user-friendly messages
struct ErrorHandler {
    
    private static let logger = Logger(subsystem: "com.khandoba.securedocs", category: "ErrorHandler")
    
    /// Log error with context
    static func logError(_ error: Error, context: ErrorContext) {
        let errorMessage = userFriendlyMessage(for: error)
        logger.error("Error in \(String(describing: context)): \(errorMessage, privacy: .public)")
        
        // Log to crash reporting if enabled
        if AppConfig.enableCrashReporting {
            // TODO: Integrate with crash reporting service
            print("📊 Error logged: \(context) - \(errorMessage)")
        }
    }
    
    /// Categorize error
    static func categorize(_ error: Error) -> ErrorContext {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("network") || errorString.contains("connection") || errorString.contains("timeout") {
            return .network
        }
        if errorString.contains("unauthorized") || errorString.contains("authentication") || errorString.contains("sign in") {
            return .auth
        }
        if errorString.contains("quota") || errorString.contains("limit") || errorString.contains("storage") {
            return .storage
        }
        if errorString.contains("encryption") || errorString.contains("decrypt") || errorString.contains("key") {
            return .encryption
        }
        if errorString.contains("permission") || errorString.contains("access") {
            return .validation
        }
        
        return .general
    }
    
    /// Convert errors to user-friendly messages
    static func userFriendlyMessage(for error: Error, context: ErrorContext? = nil) -> String {
        if let localizedError = error as? LocalizedError {
            return localizedError.errorDescription ?? localizedError.localizedDescription
        }
        
        let errorString = error.localizedDescription
        
        // Network errors
        if errorString.contains("network") || errorString.contains("connection") || errorString.contains("timeout") {
            return "Network connection failed. Please check your internet connection and try again."
        }
        
        if errorString.contains("unauthorized") || errorString.contains("authentication") {
            return "Authentication failed. Please sign in again."
        }
        
        if errorString.contains("permission") || errorString.contains("access") {
            return "Permission denied. Please check your access rights."
        }
        
        if errorString.contains("not found") {
            return "The requested item could not be found."
        }
        
        if errorString.contains("already exists") || errorString.contains("duplicate") {
            return "This item already exists."
        }
        
        if errorString.contains("quota") || errorString.contains("limit") {
            return "Storage limit reached. Please free up space and try again."
        }
        
        if errorString.contains("encryption") || errorString.contains("decrypt") {
            return "Security error. Please try again or contact support."
        }
        
        // Context-specific messages
        if let context = context {
            switch context {
            case .upload:
                return "Failed to upload document. Please check your connection and try again."
            case .download:
                return "Failed to download document. Please check your connection and try again."
            case .auth:
                return "Authentication failed. Please sign in again."
            case .vault:
                return "Vault operation failed. Please try again."
            case .document:
                return "Document operation failed. Please try again."
            case .network:
                return "Network connection failed. Please check your internet connection."
            case .storage:
                return "Storage limit reached. Please free up space."
            case .validation:
                return "Invalid input. Please check your data and try again."
            case .encryption:
                return "Security error. Please try again or contact support."
            case .general:
                break
            }
        }
        
        // Generic fallback
        return "An error occurred. Please try again. If the problem persists, contact support."
    }
    
    /// Check if error is recoverable
    static func isRecoverable(_ error: Error) -> Bool {
        let errorString = error.localizedDescription.lowercased()
        
        // Network errors are usually recoverable
        if errorString.contains("network") || errorString.contains("connection") || errorString.contains("timeout") {
            return true
        }
        
        // Permission errors might be recoverable
        if errorString.contains("permission") {
            return true
        }
        
        // Not found errors are usually not recoverable
        if errorString.contains("not found") {
            return false
        }
        
        // Default to recoverable
        return true
    }
    
    /// Get retry suggestion for error
    static func retrySuggestion(for error: Error) -> String? {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("network") || errorString.contains("connection") || errorString.contains("timeout") {
            return "Check your internet connection and try again"
        }
        
        if errorString.contains("permission") {
            return "Check your permissions and try again"
        }
        
        return nil
    }
    
    /// Check if error should trigger retry
    static func shouldRetry(_ error: Error) -> Bool {
        let context = categorize(error)
        return context == .network || context == .storage || isRecoverable(error)
    }
    
    /// Get recovery action for error
    static func recoveryAction(for error: Error) -> RecoveryAction? {
        let context = categorize(error)
        
        switch context {
        case .network:
            return .checkConnection
        case .auth:
            return .signIn
        case .storage:
            return .freeUpSpace
        case .encryption:
            return .contactSupport
        case .upload, .download, .vault, .document:
            if shouldRetry(error) {
                return .retry
            }
            return .none
        case .validation:
            return .none
        case .general:
            if shouldRetry(error) {
                return .retry
            }
            return .contactSupport
        }
    }
}

/// View modifier for error handling
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?
    @State private var showAlert = false
    @State private var errorMessage = ""
    @State private var currentError: Error?
    @State private var errorMessageString: String = ""
    
    // Computed property to convert error to a comparable string
    private var errorString: String {
        if let err = error {
            return ErrorHandler.userFriendlyMessage(for: err)
        }
        return ""
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: errorString) { oldValue, newValue in
                // Error changed - update UI
                if !newValue.isEmpty && oldValue != newValue {
                    if let newError = error {
                        currentError = newError
                        errorMessage = newValue
                        errorMessageString = newValue
                        showAlert = true
                    }
                } else if newValue.isEmpty {
                    currentError = nil
                    errorMessage = ""
                    errorMessageString = ""
                    showAlert = false
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") {
                    error = nil
                }
                if let currentError = currentError, ErrorHandler.retrySuggestion(for: currentError) != nil {
                    Button("Retry") {
                        // Retry logic would be handled by parent view
                        error = nil
                    }
                }
            } message: {
                Text(errorMessage)
            }
    }
}

extension View {
    func errorAlert(error: Binding<Error?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}

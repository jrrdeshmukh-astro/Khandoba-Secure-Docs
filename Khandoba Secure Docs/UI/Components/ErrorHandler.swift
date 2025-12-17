//
//  ErrorHandler.swift
//  Khandoba Secure Docs
//
//  Created for improved error handling and user-friendly messages
//

import Foundation
import SwiftUI

/// Centralized error handling with user-friendly messages
struct ErrorHandler {
    
    /// Convert errors to user-friendly messages
    static func userFriendlyMessage(for error: Error) -> String {
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
}

/// View modifier for error handling
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?
    @State private var showAlert = false
    @State private var errorMessage = ""
    
    func body(content: Content) -> some View {
        content
            .onChange(of: error) { oldValue, newValue in
                if newValue != nil {
                    errorMessage = ErrorHandler.userFriendlyMessage(for: newValue!)
                    showAlert = true
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") {
                    error = nil
                }
                if let retrySuggestion = error.flatMap({ ErrorHandler.retrySuggestion(for: $0) }) {
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

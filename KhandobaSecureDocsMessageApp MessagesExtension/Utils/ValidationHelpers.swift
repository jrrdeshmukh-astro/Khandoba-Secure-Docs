//
//  ValidationHelpers.swift
//  Khandoba Secure Docs
//
//  Validation utilities for nominee invitation and transfer flows
//

import Foundation

enum ValidationError: LocalizedError {
    case invalidEmail
    case invalidPhone
    case emptyName
    case emptyRecipient
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPhone:
            return "Please enter a valid phone number"
        case .emptyName:
            return "Recipient name cannot be empty"
        case .emptyRecipient:
            return "Please provide at least a name, phone number, or email"
        }
    }
}

struct ValidationHelpers {
    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validate phone number format (basic validation - accepts various formats)
    static func isValidPhone(_ phone: String) -> Bool {
        // Remove common phone number characters
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "+", with: "")
        
        // Check if it's all digits and has reasonable length (7-15 digits)
        let digitsOnly = cleaned.allSatisfy { $0.isNumber }
        return digitsOnly && cleaned.count >= 7 && cleaned.count <= 15
    }
    
    /// Validate recipient information
    static func validateRecipient(name: String, phone: String?, email: String?) throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.emptyName
        }
        
        if let phone = phone, !phone.isEmpty {
            guard isValidPhone(phone) else {
                throw ValidationError.invalidPhone
            }
        }
        
        if let email = email, !email.isEmpty {
            guard isValidEmail(email) else {
                throw ValidationError.invalidEmail
            }
        }
        
        // At least one contact method (phone or email) should be provided
        if (phone?.isEmpty ?? true) && (email?.isEmpty ?? true) {
            // Name only is acceptable for iMessage invitations (can use phone from conversation)
            // But we'll still allow it
        }
    }
}

//
//  EncryptionService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/2/25.
//

import Foundation
import CryptoKit
import Security
import CommonCrypto

class EncryptionService {
    
    // MARK: - AES-256-GCM Encryption
    
    /// Encrypt data using AES-256-GCM
    static func encrypt(data: Data, key: SymmetricKey) throws -> EncryptedData {
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        return EncryptedData(
            ciphertext: combined,
            nonce: Data(sealedBox.nonce),
            tag: Data(sealedBox.tag)
        )
    }
    
    /// Decrypt data using AES-256-GCM
    static func decrypt(encryptedData: EncryptedData, key: SymmetricKey) throws -> Data {
        guard let sealedBox = try? AES.GCM.SealedBox(combined: encryptedData.ciphertext) else {
            throw EncryptionError.invalidData
        }
        
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Key Generation
    
    /// Generate a new 256-bit encryption key
    static func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }
    
    /// Derive key from password using PBKDF2
    static func deriveKey(from password: String, salt: Data) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            throw EncryptionError.invalidPassword
        }
        
        // Use PBKDF2 with 100,000 iterations
        let derivedKey = try PBKDF2.deriveKey(
            from: passwordData,
            salt: salt,
            iterations: 100_000,
            keyLength: 32
        )
        
        return SymmetricKey(data: derivedKey)
    }
    
    /// Generate random salt for key derivation
    static func generateSalt() -> Data {
        var salt = Data(count: 32)
        _ = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
        }
        return salt
    }
    
    // MARK: - Keychain Storage
    
    /// Store key in keychain
    static func storeKey(_ key: SymmetricKey, identifier: String) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing
        SecItemDelete(query as CFDictionary)
        
        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError
        }
    }
    
    /// Retrieve key from keychain
    static func retrieveKey(identifier: String) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw EncryptionError.keyNotFound
        }
        
        return SymmetricKey(data: keyData)
    }
    
    /// Delete key from keychain
    static func deleteKey(identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw EncryptionError.keychainError
        }
    }
    
    // MARK: - Document Encryption
    
    /// Encrypt document with auto-generated key
    static func encryptDocument(_ data: Data, documentID: UUID) throws -> (encryptedData: Data, key: SymmetricKey) {
        let key = generateKey()
        let encrypted = try encrypt(data: data, key: key)
        
        // Store key in keychain
        try storeKey(key, identifier: "doc-\(documentID.uuidString)")
        
        return (encrypted.ciphertext, key)
    }
    
    /// Decrypt document using stored key
    static func decryptDocument(_ data: Data, documentID: UUID) throws -> Data {
        let key = try retrieveKey(identifier: "doc-\(documentID.uuidString)")
        
        let encryptedData = EncryptedData(
            ciphertext: data,
            nonce: Data(), // Would be stored separately
            tag: Data()    // Would be stored separately
        )
        
        return try decrypt(encryptedData: encryptedData, key: key)
    }
}

// MARK: - Models

struct EncryptedData {
    let ciphertext: Data
    let nonce: Data
    let tag: Data
}

// MARK: - PBKDF2 Implementation

struct PBKDF2 {
    static func deriveKey(
        from password: Data,
        salt: Data,
        iterations: Int,
        keyLength: Int
    ) throws -> Data {
        var derivedKeyData = Data(count: keyLength)
        
        let result = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                password.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress, password.count,
                        saltBytes.baseAddress, salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.baseAddress, keyLength
                    )
                }
            }
        }
        
        guard result == kCCSuccess else {
            throw EncryptionError.keyDerivationFailed
        }
        
        return derivedKeyData
    }
}

// MARK: - Errors

enum EncryptionError: LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case invalidPassword
    case keychainError
    case keyNotFound
    case keyDerivationFailed
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidData:
            return "Invalid encrypted data"
        case .invalidPassword:
            return "Invalid password"
        case .keychainError:
            return "Keychain operation failed"
        case .keyNotFound:
            return "Encryption key not found"
        case .keyDerivationFailed:
            return "Failed to derive encryption key"
        }
    }
}


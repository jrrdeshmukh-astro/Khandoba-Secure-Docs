//
//  EncryptionServiceTests.swift
//  Khandoba Secure DocsTests
//
//  Comprehensive unit tests for EncryptionService
//

import XCTest
import CryptoKit

final class EncryptionServiceTests: XCTestCase {
    
    var testKey: SymmetricKey!
    var testData: Data!
    
    override func setUp() {
        super.setUp()
        testKey = EncryptionService.generateKey()
        testData = TestUtilities.createTestData(size: 1024)
    }
    
    override func tearDown() {
        testKey = nil
        testData = nil
        super.tearDown()
    }
    
    // MARK: - Key Generation Tests
    
    func testGenerateKey() {
        let key = EncryptionService.generateKey()
        XCTAssertNotNil(key)
        XCTAssertEqual(key.bitCount, 256)
    }
    
    func testGenerateKeyUniqueness() {
        let key1 = EncryptionService.generateKey()
        let key2 = EncryptionService.generateKey()
        XCTAssertNotEqual(key1.withUnsafeBytes { Data($0) }, key2.withUnsafeBytes { Data($0) })
    }
    
    func testGenerateSalt() {
        let salt1 = EncryptionService.generateSalt()
        let salt2 = EncryptionService.generateSalt()
        XCTAssertEqual(salt1.count, 32)
        XCTAssertEqual(salt2.count, 32)
        XCTAssertNotEqual(salt1, salt2)
    }
    
    // MARK: - Encryption/Decryption Tests
    
    func testEncryptDecryptRoundTrip() throws {
        let originalData = testData!
        let key = testKey!
        
        let encrypted = try EncryptionService.encrypt(data: originalData, key: key)
        let decrypted = try EncryptionService.decrypt(encryptedData: encrypted, key: key)
        
        XCTAssertEqual(decrypted, originalData)
        XCTAssertNotEqual(encrypted.ciphertext, originalData)
        XCTAssertFalse(encrypted.nonce.isEmpty)
        XCTAssertFalse(encrypted.tag.isEmpty)
    }
    
    func testEncryptWithDifferentKeys() throws {
        let data = testData!
        let key1 = EncryptionService.generateKey()
        let key2 = EncryptionService.generateKey()
        
        let encrypted1 = try EncryptionService.encrypt(data: data, key: key1)
        let encrypted2 = try EncryptionService.encrypt(data: data, key: key2)
        
        XCTAssertNotEqual(encrypted1.ciphertext, encrypted2.ciphertext)
    }
    
    func testEncryptSameDataProducesDifferentCiphertext() throws {
        let data = testData!
        let key = testKey!
        
        let encrypted1 = try EncryptionService.encrypt(data: data, key: key)
        let encrypted2 = try EncryptionService.encrypt(data: data, key: key)
        
        XCTAssertNotEqual(encrypted1.ciphertext, encrypted2.ciphertext)
        XCTAssertNotEqual(encrypted1.nonce, encrypted2.nonce)
    }
    
    func testDecryptWithWrongKey() throws {
        let data = testData!
        let correctKey = testKey!
        let wrongKey = EncryptionService.generateKey()
        
        let encrypted = try EncryptionService.encrypt(data: data, key: correctKey)
        
        XCTAssertThrowsError(try EncryptionService.decrypt(encryptedData: encrypted, key: wrongKey))
    }
    
    func testDeriveKeyFromPassword() throws {
        let password = "test-password-123"
        let salt = EncryptionService.generateSalt()
        
        let derivedKey = try EncryptionService.deriveKey(from: password, salt: salt)
        
        XCTAssertNotNil(derivedKey)
        XCTAssertEqual(derivedKey.bitCount, 256)
    }
    
    func testDeriveKeyConsistency() throws {
        let password = "test-password-123"
        let salt = EncryptionService.generateSalt()
        
        let key1 = try EncryptionService.deriveKey(from: password, salt: salt)
        let key2 = try EncryptionService.deriveKey(from: password, salt: salt)
        
        XCTAssertEqual(
            key1.withUnsafeBytes { Data($0) },
            key2.withUnsafeBytes { Data($0) }
        )
    }
}

package com.khandoba.securedocs.service

import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import kotlinx.coroutines.test.runTest

class EncryptionServiceTest {
    private lateinit var encryptionService: EncryptionService
    
    @Before
    fun setup() {
        encryptionService = EncryptionService()
    }
    
    @Test
    fun `test encrypt and decrypt data`() = runTest {
        val originalData = "Test data to encrypt".toByteArray()
        val encryptionKey = encryptionService.generateKey()
        
        val encryptedData = encryptionService.encrypt(originalData, encryptionKey)
        
        assertNotNull("Encrypted data should not be null", encryptedData)
        assertNotEquals("Encrypted data should differ from original", originalData, encryptedData)
        
        val decryptedData = encryptionService.decrypt(encryptedData, encryptionKey)
        
        assertNotNull("Decrypted data should not be null", decryptedData)
        assertArrayEquals("Decrypted data should match original", originalData, decryptedData)
    }
    
    @Test
    fun `test encrypt with default key generation`() = runTest {
        val originalData = "Test data".toByteArray()
        val encryptedData = encryptionService.encrypt(originalData)
        
        assertNotNull("Encrypted data should not be null", encryptedData)
        assertTrue("Encrypted data should not be empty", encryptedData.isNotEmpty())
    }
    
    @Test
    fun `test encryption key generation`() {
        val key1 = encryptionService.generateKey()
        val key2 = encryptionService.generateKey()
        
        assertNotNull("Key should not be null", key1)
        assertNotNull("Key should not be null", key2)
        assertNotEquals("Keys should be unique", key1, key2)
        assertTrue("Key should have valid length", key1.size > 0)
    }
    
    @Test
    fun `test decrypt with wrong key fails`() = runTest {
        val originalData = "Test data".toByteArray()
        val encryptionKey = encryptionService.generateKey()
        val wrongKey = encryptionService.generateKey()
        
        val encryptedData = encryptionService.encrypt(originalData, encryptionKey)
        
        try {
            encryptionService.decrypt(encryptedData, wrongKey)
            fail("Decryption with wrong key should fail")
        } catch (e: Exception) {
            // Expected - decryption should fail with wrong key
            assertTrue(true)
        }
    }
    
    @Test
    fun `test encrypt empty data`() = runTest {
        val emptyData = ByteArray(0)
        val encryptionKey = encryptionService.generateKey()
        
        val encryptedData = encryptionService.encrypt(emptyData, encryptionKey)
        
        assertNotNull("Encrypted data should not be null", encryptedData)
        val decryptedData = encryptionService.decrypt(encryptedData, encryptionKey)
        assertArrayEquals("Decrypted empty data should match", emptyData, decryptedData)
    }
    
    @Test
    fun `test encrypt large data`() = runTest {
        val largeData = ByteArray(1024 * 1024) { it.toByte() } // 1MB
        val encryptionKey = encryptionService.generateKey()
        
        val encryptedData = encryptionService.encrypt(largeData, encryptionKey)
        val decryptedData = encryptionService.decrypt(encryptedData, encryptionKey)
        
        assertArrayEquals("Large data should encrypt and decrypt correctly", largeData, decryptedData)
    }
}

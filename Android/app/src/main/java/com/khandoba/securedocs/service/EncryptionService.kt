package com.khandoba.securedocs.service

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import java.nio.ByteBuffer
import java.util.Base64

class EncryptionService {
    private val keyStore: KeyStore = KeyStore.getInstance("AndroidKeyStore").apply {
        load(null)
    }
    
    private val keyAlias = "khandoba_encryption_key"
    private val algorithm = "AES/GCM/NoPadding"
    private val keySize = 256
    private val gcmTagLength = 128
    
    init {
        ensureKeyExists()
    }
    
    private fun ensureKeyExists() {
        if (!keyStore.containsAlias(keyAlias)) {
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                keyAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(keySize)
                .build()
            
            keyGenerator.init(keyGenParameterSpec)
            keyGenerator.generateKey()
        }
    }
    
    fun encrypt(data: ByteArray): ByteArray {
        val cipher = Cipher.getInstance(algorithm)
        val key = keyStore.getKey(keyAlias, null) as SecretKey
        cipher.init(Cipher.ENCRYPT_MODE, key)
        
        val iv = cipher.iv
        val encrypted = cipher.doFinal(data)
        
        // Combine IV + encrypted data
        val buffer = ByteBuffer.allocate(iv.size + encrypted.size)
        buffer.put(iv)
        buffer.put(encrypted)
        return buffer.array()
    }
    
    fun decrypt(encryptedData: ByteArray): ByteArray {
        val buffer = ByteBuffer.wrap(encryptedData)
        val iv = ByteArray(12) // GCM IV is 12 bytes
        buffer.get(iv)
        val encrypted = ByteArray(buffer.remaining())
        buffer.get(encrypted)
        
        val cipher = Cipher.getInstance(algorithm)
        val key = keyStore.getKey(keyAlias, null) as SecretKey
        val spec = GCMParameterSpec(gcmTagLength, iv)
        cipher.init(Cipher.DECRYPT_MODE, key, spec)
        
        return cipher.doFinal(encrypted)
    }
    
    fun generateKey(): ByteArray {
        val keyGenerator = KeyGenerator.getInstance("AES")
        keyGenerator.init(keySize)
        val secretKey = keyGenerator.generateKey()
        return secretKey.encoded
    }
    
    fun deriveKeyFromPassword(password: String, salt: ByteArray): ByteArray {
        // Use PBKDF2 for key derivation
        val keyFactory = javax.crypto.spec.PBEKeySpec(
            password.toCharArray(),
            salt,
            100000, // iterations
            keySize
        )
        val secretKeyFactory = javax.crypto.SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
        val secretKey = secretKeyFactory.generateSecret(keyFactory)
        return secretKey.encoded
    }
    
    fun generateSalt(): ByteArray {
        val salt = ByteArray(32)
        java.security.SecureRandom().nextBytes(salt)
        return salt
    }
}

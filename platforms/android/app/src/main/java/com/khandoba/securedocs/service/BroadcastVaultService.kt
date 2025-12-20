package com.khandoba.securedocs.service

import android.util.Log
import com.khandoba.securedocs.config.AppConfig
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.data.repository.VaultRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Date
import java.util.UUID

/**
 * Service for managing broadcast vaults (publicly accessible vaults).
 * The "Open Street" vault is a special broadcast vault that is auto-created.
 */
class BroadcastVaultService(
    private val vaultRepository: VaultRepository
) {
    companion object {
        const val OPEN_STREET_VAULT_NAME = "Open Street"
        const val OPEN_STREET_VAULT_DESCRIPTION = "A public broadcast vault accessible to everyone"
    }
    
    private val _broadcastVaults = MutableStateFlow<List<VaultEntity>>(emptyList())
    val broadcastVaults: StateFlow<List<VaultEntity>> = _broadcastVaults.asStateFlow()
    
    /**
     * Checks if a vault is a broadcast vault.
     * Broadcast vaults are system vaults with special names or flags.
     */
    fun isBroadcastVault(vault: VaultEntity): Boolean {
        return vault.isSystemVault && (
            vault.name == OPEN_STREET_VAULT_NAME ||
            vault.name.contains("Broadcast", ignoreCase = true)
        )
    }
    
    /**
     * Creates or retrieves the "Open Street" broadcast vault.
     * This vault should be auto-created if it doesn't exist.
     */
    suspend fun getOrCreateOpenStreetVault(): Result<VaultEntity> {
        return try {
            // Try to find existing Open Street vault
            val systemVaults = vaultRepository.getSystemVaults()
            val openStreetVault = systemVaults.firstOrNull { 
                it.name == OPEN_STREET_VAULT_NAME && it.isSystemVault 
            }
            
            if (openStreetVault != null) {
                Log.d("BroadcastVaultService", "✅ Found existing Open Street vault")
                return Result.success(openStreetVault)
            }
            
            // Create new Open Street vault
            val newVault = VaultEntity(
                id = UUID.randomUUID(),
                name = OPEN_STREET_VAULT_NAME,
                vaultDescription = OPEN_STREET_VAULT_DESCRIPTION,
                createdAt = Date(),
                status = "active", // Broadcast vaults are always active
                keyType = "single", // Simple access
                vaultType = "both",
                isSystemVault = true, // System-owned vault
                isEncrypted = false, // Public vault, no encryption needed
                isZeroKnowledge = false,
                ownerId = null // System-owned, no specific owner
            )
            
            vaultRepository.insertVault(newVault)
            Log.d("BroadcastVaultService", "✅ Created Open Street broadcast vault")
            
            Result.success(newVault)
        } catch (e: Exception) {
            Log.e("BroadcastVaultService", "Error creating Open Street vault: ${e.message}")
            Result.failure(e)
        }
    }
    
    /**
     * Loads all broadcast vaults.
     */
    suspend fun loadBroadcastVaults() {
        try {
            // Ensure Open Street vault exists
            getOrCreateOpenStreetVault()
            
            // Load all broadcast vaults
            val systemVaults = vaultRepository.getSystemVaults()
            val broadcast = systemVaults.filter { isBroadcastVault(it) }
            _broadcastVaults.value = broadcast
            Log.d("BroadcastVaultService", "Loaded ${broadcast.size} broadcast vaults")
        } catch (e: Exception) {
            Log.e("BroadcastVaultService", "Error loading broadcast vaults: ${e.message}")
        }
    }
    
    /**
     * Checks if a user has access to a broadcast vault.
     * Broadcast vaults are publicly accessible, so this always returns true.
     */
    fun hasAccessToBroadcastVault(vault: VaultEntity, userId: UUID?): Boolean {
        return isBroadcastVault(vault) // Broadcast vaults are public
    }
}

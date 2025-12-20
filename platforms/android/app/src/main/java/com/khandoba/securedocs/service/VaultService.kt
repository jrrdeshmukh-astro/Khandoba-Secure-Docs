package com.khandoba.securedocs.service

import com.khandoba.securedocs.config.AppConfig
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.data.entity.VaultSessionEntity
import com.khandoba.securedocs.data.repository.VaultRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Date
import java.util.UUID

class VaultService(
    private val vaultRepository: VaultRepository
) {
    private val _vaults = MutableStateFlow<List<VaultEntity>>(emptyList())
    val vaults: StateFlow<List<VaultEntity>> = _vaults.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _activeSessions = MutableStateFlow<Map<UUID, VaultSessionEntity>>(emptyMap())
    val activeSessions: StateFlow<Map<UUID, VaultSessionEntity>> = _activeSessions.asStateFlow()
    
    private var currentUserID: UUID? = null
    
    fun configure(userID: UUID) {
        this.currentUserID = userID
        loadVaults()
    }
    
    suspend fun loadVaults() {
        _isLoading.value = true
        try {
            if (currentUserID != null) {
                // In Supabase mode, RLS automatically filters by owner
                // Just collect from repository which handles Supabase sync
                vaultRepository.getVaultsByOwner(currentUserID!!).collect { vaultList ->
                    _vaults.value = vaultList.filter { !it.isSystemVault }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("VaultService", "Error loading vaults: ${e.message}")
        } finally {
            _isLoading.value = false
        }
    }
    
    suspend fun createVault(
        name: String,
        description: String? = null,
        keyType: String = "single"
    ): Result<VaultEntity> {
        return try {
            if (currentUserID == null) {
                return Result.failure(Exception("User not authenticated"))
            }
            
            val vault = VaultEntity(
                id = UUID.randomUUID(),
                name = name,
                vaultDescription = description,
                ownerId = currentUserID,
                createdAt = Date(),
                status = "locked",
                keyType = keyType,
                vaultType = "both",
                isEncrypted = true,
                isZeroKnowledge = true
            )
            
            vaultRepository.insertVault(vault)
            loadVaults() // Reload to get updated list
            
            Result.success(vault)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun unlockVault(vaultId: UUID, password: String? = null): Result<VaultSessionEntity> {
        return try {
            val vault = _vaults.value.firstOrNull { it.id == vaultId }
                ?: return Result.failure(Exception("Vault not found"))
            
            // Create session (30 minutes)
            val expiresAt = Date(System.currentTimeMillis() + AppConfig.SESSION_TIMEOUT_MINUTES * 60 * 1000)
            val session = VaultSessionEntity(
                id = UUID.randomUUID(),
                vaultId = vaultId,
                userId = currentUserID,
                startedAt = Date(),
                expiresAt = expiresAt,
                isActive = true,
                wasExtended = false
            )
            
            // Update vault status
            val updatedVault = vault.copy(
                status = "active",
                lastAccessedAt = Date()
            )
            vaultRepository.updateVault(updatedVault)
            
            // Store active session
            _activeSessions.value = _activeSessions.value + (vaultId to session)
            
            Result.success(session)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    suspend fun lockVault(vaultId: UUID) {
        val vault = _vaults.value.firstOrNull { it.id == vaultId }
            ?: return
        
        val updatedVault = vault.copy(status = "locked")
        vaultRepository.updateVault(updatedVault)
        
        _activeSessions.value = _activeSessions.value - vaultId
    }
    
    suspend fun deleteVault(vaultId: UUID): Result<Unit> {
        return try {
            val vault = _vaults.value.firstOrNull { it.id == vaultId }
                ?: return Result.failure(Exception("Vault not found"))
            
            vaultRepository.deleteVault(vault)
            loadVaults()
            
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}


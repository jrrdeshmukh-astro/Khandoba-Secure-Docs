package com.khandoba.securedocs.data.repository

import com.khandoba.securedocs.config.AppConfig
import com.khandoba.securedocs.data.dao.VaultDao
import com.khandoba.securedocs.data.entity.VaultEntity
import com.khandoba.securedocs.data.supabase.SupabaseService
import com.khandoba.securedocs.data.supabase.SupabaseVault
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.launch
import java.util.Base64
import java.util.Date
import java.util.UUID

class VaultRepository(
    private val vaultDao: VaultDao,
    private val supabaseService: SupabaseService?
) {
    fun getVaultById(id: UUID): Flow<VaultEntity?> {
        return vaultDao.getAllVaults().map { vaults ->
            vaults.firstOrNull { it.id == id }
        }
    }
    
    fun getVaultsByOwner(ownerId: UUID): Flow<List<VaultEntity>> {
        // Always use Room for local caching, but sync with Supabase in background
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            // Load from Supabase and sync to Room
            kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO).launch {
                try {
                    val supabaseVaults: List<SupabaseVault> = supabaseService.fetchAll(
                        table = "vaults",
                        filters = mapOf("owner_id" to ownerId),
                        orderBy = "created_at",
                        ascending = false
                    )
                    
                    // Convert and store in Room
                    supabaseVaults.forEach { supabaseVault ->
                        val entity = convertFromSupabase(supabaseVault)
                        vaultDao.insertVault(entity)
                    }
                } catch (e: Exception) {
                    android.util.Log.e("VaultRepository", "Error syncing from Supabase: ${e.message}")
                }
            }
        }
        
        // Return Flow from Room (which will be updated by sync)
        return vaultDao.getVaultsByOwner(ownerId)
    }
    
    suspend fun insertVault(vault: VaultEntity) {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                val supabaseVault = convertToSupabase(vault)
                supabaseService.insert("vaults", supabaseVault)
            } catch (e: Exception) {
                vaultDao.insertVault(vault)
            }
        } else {
            vaultDao.insertVault(vault)
        }
    }
    
    suspend fun updateVault(vault: VaultEntity) {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                val supabaseVault = convertToSupabase(vault)
                supabaseService.update("vaults", vault.id, supabaseVault)
            } catch (e: Exception) {
                vaultDao.updateVault(vault)
            }
        } else {
            vaultDao.updateVault(vault)
        }
    }
    
    suspend fun deleteVault(vault: VaultEntity) {
        if (AppConfig.USE_SUPABASE && supabaseService != null) {
            try {
                supabaseService.delete("vaults", vault.id)
            } catch (e: Exception) {
                vaultDao.deleteVault(vault)
            }
        } else {
            vaultDao.deleteVault(vault)
        }
    }
    
    suspend fun getAllVaults(): List<VaultEntity> {
        // Get all vaults from Room (which should be synced from Supabase)
        // Note: This is a suspend function that collects the Flow once
        return kotlinx.coroutines.runBlocking {
            vaultDao.getAllVaults().first()
        }
    }
    
    fun getAllVaultsFlow(): Flow<List<VaultEntity>> {
        return vaultDao.getAllVaults()
    }
    
    suspend fun getSystemVaults(): List<VaultEntity> {
        return getAllVaults().filter { it.isSystemVault }
    }
    
    private fun convertToSupabase(entity: VaultEntity): SupabaseVault {
        return SupabaseVault(
            id = entity.id,
            name = entity.name,
            vault_description = entity.vaultDescription,
            owner_id = entity.ownerId ?: UUID.randomUUID(),
            created_at = entity.createdAt.toISOString(),
            last_accessed_at = entity.lastAccessedAt?.toISOString(),
            status = entity.status,
            key_type = entity.keyType,
            vault_type = entity.vaultType,
            is_system_vault = entity.isSystemVault,
            encryption_key_data = entity.encryptionKeyData?.let { 
                Base64.getEncoder().encodeToString(it)
            },
            is_encrypted = entity.isEncrypted,
            is_zero_knowledge = entity.isZeroKnowledge,
            relationship_officer_id = entity.relationshipOfficerID,
            is_anti_vault = entity.isAntiVault,
            monitored_vault_id = entity.monitoredVaultID,
            anti_vault_id = entity.antiVaultID,
            updated_at = Date().toISOString()
        )
    }
    
    private fun convertFromSupabase(supabase: SupabaseVault): VaultEntity {
        return VaultEntity(
            id = supabase.id,
            name = supabase.name,
            vaultDescription = supabase.vault_description,
            createdAt = supabase.created_at.toDate(),
            lastAccessedAt = supabase.last_accessed_at?.toDate(),
            status = supabase.status,
            keyType = supabase.key_type,
            vaultType = supabase.vault_type,
            isSystemVault = supabase.is_system_vault,
            isAntiVault = supabase.is_anti_vault,
            monitoredVaultID = supabase.monitored_vault_id,
            antiVaultID = supabase.anti_vault_id,
            encryptionKeyData = supabase.encryption_key_data?.let {
                Base64.getDecoder().decode(it)
            },
            isEncrypted = supabase.is_encrypted,
            isZeroKnowledge = supabase.is_zero_knowledge,
            ownerId = supabase.owner_id,
            relationshipOfficerID = supabase.relationship_officer_id
        )
    }
    
    private fun Date.toISOString(): String {
        return java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
            timeZone = java.util.TimeZone.getTimeZone("UTC")
        }.format(this)
    }
    
    private fun String.toDate(): Date {
        return java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
            timeZone = java.util.TimeZone.getTimeZone("UTC")
        }.parse(this) ?: Date()
    }
}


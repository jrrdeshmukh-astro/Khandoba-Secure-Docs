package com.khandoba.securedocs.data.dao

import androidx.room.*
import com.khandoba.securedocs.data.entity.VaultEntity
import kotlinx.coroutines.flow.Flow
import java.util.UUID

@Dao
interface VaultDao {
    @Query("SELECT * FROM vaults WHERE id = :id")
    suspend fun getVaultById(id: UUID): VaultEntity?
    
    @Query("SELECT * FROM vaults WHERE ownerId = :ownerId")
    fun getVaultsByOwner(ownerId: UUID): Flow<List<VaultEntity>>
    
    @Query("SELECT * FROM vaults WHERE status = :status")
    fun getVaultsByStatus(status: String): Flow<List<VaultEntity>>
    
    @Query("SELECT * FROM vaults")
    fun getAllVaults(): Flow<List<VaultEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertVault(vault: VaultEntity)
    
    @Update
    suspend fun updateVault(vault: VaultEntity)
    
    @Delete
    suspend fun deleteVault(vault: VaultEntity)
}

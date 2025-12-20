package com.khandoba.securedocs.data.dao

import androidx.room.*
import com.khandoba.securedocs.data.entity.VaultAccessLogEntity
import kotlinx.coroutines.flow.Flow
import java.util.UUID

@Dao
interface VaultAccessLogDao {
    @Query("SELECT * FROM vault_access_logs WHERE vaultId = :vaultId ORDER BY timestamp DESC")
    fun getLogsForVault(vaultId: UUID): Flow<List<VaultAccessLogEntity>>
    
    @Insert
    suspend fun insertLog(log: VaultAccessLogEntity)
}

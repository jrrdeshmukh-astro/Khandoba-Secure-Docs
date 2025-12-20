package com.khandoba.securedocs.data.dao

import androidx.room.*
import com.khandoba.securedocs.data.entity.VaultSessionEntity
import kotlinx.coroutines.flow.Flow
import java.util.Date
import java.util.UUID

@Dao
interface VaultSessionDao {
    @Query("SELECT * FROM vault_sessions WHERE vaultId = :vaultId AND isActive = 1")
    suspend fun getActiveSessionForVault(vaultId: UUID): VaultSessionEntity?
    
    @Query("SELECT * FROM vault_sessions WHERE userId = :userId")
    fun getSessionsForUser(userId: UUID): Flow<List<VaultSessionEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSession(session: VaultSessionEntity)
    
    @Update
    suspend fun updateSession(session: VaultSessionEntity)
    
    @Query("UPDATE vault_sessions SET isActive = 0 WHERE expiresAt < :now")
    suspend fun expireSessions(now: Date)
}

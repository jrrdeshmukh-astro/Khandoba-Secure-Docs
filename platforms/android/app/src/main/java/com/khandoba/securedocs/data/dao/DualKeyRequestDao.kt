package com.khandoba.securedocs.data.dao

import androidx.room.*
import com.khandoba.securedocs.data.entity.DualKeyRequestEntity
import kotlinx.coroutines.flow.Flow
import java.util.UUID

@Dao
interface DualKeyRequestDao {
    @Query("SELECT * FROM dual_key_requests WHERE vaultId = :vaultId")
    fun getRequestsForVault(vaultId: UUID): Flow<List<DualKeyRequestEntity>>
    
    @Query("SELECT * FROM dual_key_requests WHERE status = 'pending'")
    fun getPendingRequests(): Flow<List<DualKeyRequestEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRequest(request: DualKeyRequestEntity)
    
    @Update
    suspend fun updateRequest(request: DualKeyRequestEntity)
}

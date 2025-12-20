package com.khandoba.securedocs.data.dao

import androidx.room.*
import com.khandoba.securedocs.data.entity.NomineeEntity
import kotlinx.coroutines.flow.Flow
import java.util.UUID

@Dao
interface NomineeDao {
    @Query("SELECT * FROM nominees WHERE vaultId = :vaultId")
    fun getNomineesForVault(vaultId: UUID): Flow<List<NomineeEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNominee(nominee: NomineeEntity)
    
    @Update
    suspend fun updateNominee(nominee: NomineeEntity)
    
    @Delete
    suspend fun deleteNominee(nominee: NomineeEntity)
}

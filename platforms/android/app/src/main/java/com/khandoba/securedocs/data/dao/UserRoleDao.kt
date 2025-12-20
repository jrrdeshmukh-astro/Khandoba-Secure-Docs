package com.khandoba.securedocs.data.dao

import androidx.room.*
import com.khandoba.securedocs.data.entity.UserRoleEntity
import kotlinx.coroutines.flow.Flow
import java.util.UUID

@Dao
interface UserRoleDao {
    @Query("SELECT * FROM user_roles WHERE userId = :userId")
    fun getRolesForUser(userId: UUID): Flow<List<UserRoleEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRole(role: UserRoleEntity)
    
    @Delete
    suspend fun deleteRole(role: UserRoleEntity)
}

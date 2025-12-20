package com.khandoba.securedocs.data.dao

import androidx.room.*
import com.khandoba.securedocs.data.entity.DocumentEntity
import kotlinx.coroutines.flow.Flow
import java.util.UUID

@Dao
interface DocumentDao {
    @Query("SELECT * FROM documents WHERE id = :id")
    suspend fun getDocumentById(id: UUID): DocumentEntity?
    
    @Query("SELECT * FROM documents WHERE vaultId = :vaultId")
    fun getDocumentsByVault(vaultId: UUID): Flow<List<DocumentEntity>>
    
    @Query("SELECT * FROM documents WHERE vaultId = :vaultId AND status = :status")
    fun getDocumentsByVaultAndStatus(vaultId: UUID, status: String): Flow<List<DocumentEntity>>
    
    @Query("SELECT * FROM documents WHERE vaultId = :vaultId AND isArchived = 0")
    fun getActiveDocumentsByVault(vaultId: UUID): Flow<List<DocumentEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertDocument(document: DocumentEntity)
    
    @Update
    suspend fun updateDocument(document: DocumentEntity)
    
    @Delete
    suspend fun deleteDocument(document: DocumentEntity)
}

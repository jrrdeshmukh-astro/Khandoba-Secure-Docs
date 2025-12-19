package com.khandoba.securedocs.data.dao

import androidx.room.*
import com.khandoba.securedocs.data.entity.ChatMessageEntity
import kotlinx.coroutines.flow.Flow
import java.util.UUID

@Dao
interface ChatMessageDao {
    @Query("SELECT * FROM chat_messages WHERE conversationID = :conversationID ORDER BY timestamp ASC")
    fun getMessagesForConversation(conversationID: String): Flow<List<ChatMessageEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessage(message: ChatMessageEntity)
    
    @Update
    suspend fun updateMessage(message: ChatMessageEntity)
}

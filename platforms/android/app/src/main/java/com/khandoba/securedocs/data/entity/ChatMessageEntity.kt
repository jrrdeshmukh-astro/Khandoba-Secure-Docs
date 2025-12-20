package com.khandoba.securedocs.data.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date
import java.util.UUID

@Entity(
    tableName = "chat_messages",
    foreignKeys = [
        ForeignKey(
            entity = UserEntity::class,
            parentColumns = ["id"],
            childColumns = ["senderID"],
            onDelete = ForeignKey.SET_NULL
        )
    ],
    indices = [Index(value = ["senderID"]), Index(value = ["receiverID"]), Index(value = ["conversationID"])]
)
data class ChatMessageEntity(
    @PrimaryKey
    val id: UUID = UUID.randomUUID(),
    val content: String = "",
    val timestamp: Date = Date(),
    val isRead: Boolean = false,
    val isEncrypted: Boolean = true,
    val senderID: UUID? = null,
    val receiverID: UUID? = null,
    val conversationID: String = ""
)
